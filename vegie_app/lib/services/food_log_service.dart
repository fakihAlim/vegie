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

  Future<bool> hasInternetConnection() async {
    return await _hasInternet();
  }

  Future<Map<String, dynamic>> addFoodLogOnline(FoodLog log) async {
    final ApiService apiService = ApiService();
    
    // Upload directly to server first
    final response = await apiService.multipartPost(
      Constants.endpointFoodLogs,
      {
        'food_name': log.foodName,
        'category': log.category,
        'meal_time': log.mealTime.toIso8601String(),
        if (log.nutritionNotes != null) 'nutrition_notes': log.nutritionNotes!,
        'points': log.points.toString(),
      },
      'photo',
      log.photoPath,
    );

    if (response['success'] == true) {
      final data = response['data'];
      final newlyUnlockedBadges = data['newly_unlocked_badges'] as List? ?? [];
      
      // Save the returned synced log directly to SQLite local database
      final syncedLog = FoodLog(
        id: data['id'],
        photoPath: log.photoPath,
        photoUrl: data['photo'],
        foodName: data['food_name'] ?? log.foodName,
        mealTime: log.mealTime,
        category: log.category,
        nutritionNotes: log.nutritionNotes,
        calories: data['calories'] != null ? (data['calories'] as num).toDouble() : null,
        carbs: data['carbs'] != null ? (data['carbs'] as num).toDouble() : null,
        fat: data['fat'] != null ? (data['fat'] as num).toDouble() : null,
        protein: data['protein'] != null ? (data['protein'] as num).toDouble() : null,
        isShared: data['is_shared'] == true || data['is_shared'] == 1,
        isSynced: true,
        rawResponse: data['raw_response'] ?? data['ai_raw_response'],
        points: data['points'] != null ? (data['points'] as num).toInt() : 0,
      );

      final savedLog = await _localDb.insertFoodLog(syncedLog);
      return {
        'badges': newlyUnlockedBadges,
        'log': savedLog,
      };
    } else if (response['error_code'] == 'not_food') {
      // Image was not food — throw a typed exception to trigger the popup
      throw Exception('not_food: ${response['message'] ?? 'Foto yang Anda upload bukan makanan. Silahkan ulangi mengambil foto.'}');
    } else {
      throw Exception(response['message'] ?? "Gagal menyimpan jurnal makanan ke server.");
    }
  }

  Future<FoodLog> addFoodLog(FoodLog log) async {
    final hasConnection = await _hasInternet();
    
    if (hasConnection) {
      final result = await addFoodLogOnline(log);
      return result['log'] as FoodLog;
    }
    
    // Fallback: save locally only if offline
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
