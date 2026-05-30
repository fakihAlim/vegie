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

    // Get unique dates
    final Set<String> dateSet = {};
    for (var log in logs) {
      dateSet.add(log.mealTime.toIso8601String().substring(0, 10));
    }

    final dates = dateSet.toList()..sort((a, b) => b.compareTo(a)); // descending

    if (dates.isEmpty) {
      return {'streak': 0, 'dates': <String>[]};
    }

    final today = DateTime.now();
    final todayStr = today.toIso8601String().substring(0, 10);
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr = yesterday.toIso8601String().substring(0, 10);

    // Streak must start from today or yesterday
    if (dates[0] != todayStr && dates[0] != yesterdayStr) {
      return {'streak': 0, 'dates': dates};
    }

    int streak = 1;
    for (int i = 1; i < dates.length; i++) {
      final current = DateTime.parse(dates[i - 1]);
      final previous = DateTime.parse(dates[i]);
      final diff = current.difference(previous).inDays;

      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }

    return {'streak': streak, 'dates': dates};
  }
}
