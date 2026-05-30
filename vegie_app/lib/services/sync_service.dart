import 'dart:io';
import '../models/food_log.dart';
import '../database/local_db.dart';
import 'api_service.dart';
import '../config/constants.dart';
import 'activity_log_service.dart';

class SyncService {
  final ApiService _apiService = ApiService();
  final LocalDatabase _localDb = LocalDatabase.instance;

  Future<bool> syncUnsyncedFoodLogs() async {
    try {
      final unsyncedLogs = await _localDb.getUnsyncedFoodLogs();
      if (unsyncedLogs.isEmpty) return true;

      // In real scenario we might bulk upload texts, but since files are multipart,
      // it's easier to upload them one by one if they contain photos
      
      bool allSynced = true;
      
      for (var log in unsyncedLogs) {
        try {
          if (log.photoPath != null && File(log.photoPath!).existsSync()) {
            // Always use multipart POST when photo exists
            print('[SyncService] Uploading with photo: ${log.photoPath}');
            print('[SyncService] Photo size: ${File(log.photoPath!).lengthSync()} bytes');

            // If it has ID, it's an update, else it's a create
            final endpoint = log.id != null 
                ? '${Constants.endpointFoodLogs}/${log.id}/update'
                : Constants.endpointFoodLogs;

            final response = await _apiService.multipartPost(
              endpoint,
              {
                'food_name': log.foodName,
                'category': log.category,
                'meal_time': log.mealTime.toIso8601String(),
                if (log.nutritionNotes != null) 'nutrition_notes': log.nutritionNotes!,
              },
              'photo',
              log.photoPath,
            );

            print('[SyncService] Response success=${response['success']}, food=${response['data']?['food_name']}');

            if (response['success'] == true) {
              await _markAsSynced(log, response['data']);
              
              // Log the food log addition event with AI metadata!
              ActivityLogService.instance.logEvent(
                'food_log_add',
                extraData: {
                  'category': log.category,
                  'has_notes': log.nutritionNotes != null && log.nutritionNotes!.isNotEmpty,
                  'ai_provider': response['data']?['ai_provider'],
                  'ai_raw_response': response['data']?['ai_raw_response'],
                  'ai_response_time': response['data']?['ai_response_time'],
                },
              );
            } else {
              allSynced = false;
              print('[SyncService] Upload failed: ${response['message']}');
            }
          } else {
            // Upload without photo or photo not found locally anymore
            final payload = log.toApiMap();
            
            // If it has ID, it's an update, else it's a create
            final endpoint = log.id != null 
                ? '${Constants.endpointFoodLogs}/${log.id}/update'
                : Constants.endpointFoodLogs;
            
            final response = await _apiService.post(endpoint, payload);
            
            if (response['success'] == true) {
              await _markAsSynced(log, response['data']);
              
              // Log the food log addition event (no photo = no AI metadata)
              ActivityLogService.instance.logEvent(
                'food_log_add',
                extraData: {
                  'category': log.category,
                  'has_notes': log.nutritionNotes != null && log.nutritionNotes!.isNotEmpty,
                  'ai_provider': null,
                  'ai_raw_response': null,
                  'ai_response_time': null,
                },
              );
            } else {
              allSynced = false;
            }
          }
        } catch (e) {
          allSynced = false;
          print("Error syncing log ${log.localId}: $e");
        }
      }
      
      return allSynced;
    } catch (e) {
      print("Sync error: $e");
      return false;
    }
  }
  
  Future<void> _markAsSynced(FoodLog log, Map<String, dynamic> data) async {
    final updatedLog = FoodLog(
      localId: log.localId,
      id: data['id'],
      photoPath: log.photoPath,
      photoUrl: data['photo'],
      foodName: data['food_name'] ?? log.foodName,
      mealTime: log.mealTime,
      category: log.category,
      nutritionNotes: log.nutritionNotes,
      calories: data['calories'] != null ? (data['calories'] as num).toDouble() : log.calories,
      carbs: data['carbs'] != null ? (data['carbs'] as num).toDouble() : log.carbs,
      fat: data['fat'] != null ? (data['fat'] as num).toDouble() : log.fat,
      protein: data['protein'] != null ? (data['protein'] as num).toDouble() : log.protein,
      isSynced: true,
      createdAt: log.createdAt,
    );
    await _localDb.updateFoodLog(updatedLog);
  }

  // Pull fresh data from server and overwrite local
  Future<void> pullFreshFoodLogs() async {
    try {
      final response = await _apiService.get('${Constants.endpointFoodLogs}?per_page=1000');
      if (response['success'] == true && response['data'] != null) {
        // Data is paginated from API now, so it's inside response['data']['data']
        // Fallback for when pagination is disabled
        final List<dynamic> jsonList = response['data']['data'] ?? response['data'];
        final logs = jsonList.map((json) => FoodLog.fromJson(json)).toList();
        
        await _localDb.replaceAllFoodLogs(logs);
      }
    } catch (e) {
      print("Pull logs error: $e");
    }
  }
}
