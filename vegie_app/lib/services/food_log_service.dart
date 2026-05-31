import '../models/food_log.dart';
import '../database/local_db.dart';
import 'sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_service.dart';
import '../config/constants.dart';

class FoodLogService {
  final LocalDatabase _localDb = LocalDatabase.instance;
  final SyncService _syncService = SyncService();

  Future<List<FoodLog>> getFoodLogs() async {
    // Attempt to pull latest from server if online
    final hasConnection = await _hasInternet();
    if (hasConnection) {
      await _syncService.pullFreshFoodLogs();
    }
    
    // Always return from local DB to maintain single source of truth
    return await _localDb.getFoodLogs();
  }

  Future<FoodLog> addFoodLog(FoodLog log) async {
    final hasConnection = await _hasInternet();
    
    // First, save locally
    final savedLog = await _localDb.insertFoodLog(
      FoodLog(
        photoPath: log.photoPath,
        foodName: log.foodName,
        mealTime: log.mealTime,
        category: log.category,
        nutritionNotes: log.nutritionNotes,
        isSynced: false,
      )
    );

    // If online, try to sync immediately
    if (hasConnection) {
      await _syncService.syncUnsyncedFoodLogs();
      // Fetch the updated log from DB to get the AI analysis results
      final allLogs = await _localDb.getFoodLogs();
      final syncedLog = allLogs.firstWhere((l) => l.localId == savedLog.localId, orElse: () => savedLog);
      return syncedLog;
    }
    
    return savedLog;
  }

  /// Save log locally only (used when the caller handles syncing separately).
  Future<FoodLog> addFoodLogLocal(FoodLog log) async {
    return await _localDb.insertFoodLog(
      FoodLog(
        photoPath: log.photoPath,
        foodName: log.foodName,
        mealTime: log.mealTime,
        category: log.category,
        nutritionNotes: log.nutritionNotes,
        isSynced: false,
      ),
    );
  }

  /// Read all logs from local DB (no network call).
  Future<List<FoodLog>> getFoodLogsLocal() async {
    return await _localDb.getFoodLogs();
  }


  Future<FoodLog> updateFoodLog(FoodLog log) async {
    final hasConnection = await _hasInternet();
    
    // Update locally and mark as unsynced
    final updatedLog = log.copyWith(isSynced: false);
    await _localDb.updateFoodLog(updatedLog);

    // If online, try to sync immediately
    if (hasConnection) {
      await _syncService.syncUnsyncedFoodLogs();
    }
    
    return updatedLog;
  }

  Future<void> deleteFoodLog(FoodLog log) async {
    // 1. Delete from local DB immediately
    await _localDb.deleteFoodLog(log.localId!);
    
    // 2. If it has a serverId, let's delete on server if online
    if (log.id != null) {
      final hasConnection = await _hasInternet();
      if (hasConnection) {
        try {
          final ApiService apiService = ApiService();
          await apiService.delete('${Constants.endpointFoodLogs}/${log.id}');
        } catch (_) {}
      }
    }
  }

  Future<FoodLog> toggleShareFoodLog(FoodLog log) async {
    if (log.id == null) {
      throw Exception("Sinkronkan jurnal makanan terlebih dahulu sebelum membagikannya.");
    }
    
    final ApiService apiService = ApiService();
    final response = await apiService.post('${Constants.endpointFoodLogs}/${log.id}/share', {});
    
    if (response['success'] == true) {
      final bool newShareStatus = response['data']['is_shared'] == true;
      final updatedLog = log.copyWith(isShared: newShareStatus);
      await _localDb.updateFoodLog(updatedLog);
      return updatedLog;
    } else {
      throw Exception(response['message'] ?? "Gagal membagikan jurnal makanan.");
    }
  }

  Future<bool> _hasInternet() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return !connectivityResult.contains(ConnectivityResult.none);
  }
}
