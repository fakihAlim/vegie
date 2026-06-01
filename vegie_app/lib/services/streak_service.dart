import 'api_service.dart';
import '../config/constants.dart';
import '../database/local_db.dart';

class StreakService {
  final ApiService _apiService = ApiService();
  final LocalDatabase _localDb = LocalDatabase.instance;

  /// Get the current streak count.
  /// Tries server first, falls back to local calculation.
  Future<Map<String, dynamic>> getStreak() async {
    try {
      final response = await _apiService.get(Constants.endpointStreak);
      if (response['success'] == true && response['data'] != null) {
        return {
          'streak': response['data']['streak'] ?? 0,
          'dates': (response['data']['dates'] as List?)?.cast<String>() ?? [],
        };
      }
    } catch (e) {
      // Fallback to local calculation
    }

    return await _calculateLocalStreak();
  }

  /// Calculate streak from local SQLite data
  Future<Map<String, dynamic>> _calculateLocalStreak() async {
    final logs = await _localDb.getFoodLogs();
    if (logs.isEmpty) {
      return {'streak': 0, 'dates': <String>[]};
    }

    // Map each date to its minimum points
    final Map<String, int> datePointsMap = {};
    for (var log in logs) {
      final dateStr = log.mealTime.toIso8601String().substring(0, 10);
      final currentPoints = datePointsMap[dateStr];
      if (currentPoints == null || log.points < currentPoints) {
        datePointsMap[dateStr] = log.points;
      }
    }

    final dates = datePointsMap.keys.toList()..sort((a, b) => b.compareTo(a)); // descending

    if (dates.isEmpty) {
      return {'streak': 0, 'dates': <String>[]};
    }

    final today = DateTime.now();
    final todayStr = today.toIso8601String().substring(0, 10);
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr = yesterday.toIso8601String().substring(0, 10);

    final String startStr = (datePointsMap.containsKey(todayStr)) ? todayStr : yesterdayStr;
    if (!datePointsMap.containsKey(startStr)) {
      return {'streak': 0, 'dates': dates};
    }

    int streak = 0;
    String currentDateStr = startStr;
    DateTime currentDate = DateTime.parse(currentDateStr);

    while (true) {
      if (datePointsMap.containsKey(currentDateStr)) {
        if (datePointsMap[currentDateStr]! < 50) {
          break; // Animal-based log resets streak!
        }
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
        currentDateStr = currentDate.toIso8601String().substring(0, 10);
      } else {
        break;
      }
    }

    return {'streak': streak, 'dates': dates};
  }
}
