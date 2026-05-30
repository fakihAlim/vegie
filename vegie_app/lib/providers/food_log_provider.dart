import 'package:flutter/material.dart';
import '../models/food_log.dart';
import '../models/daily_quote.dart';
import '../services/food_log_service.dart';
import '../services/sync_service.dart';
import '../services/streak_service.dart';
import '../services/quote_service.dart';

class FoodLogProvider with ChangeNotifier {
  final FoodLogService _foodLogService = FoodLogService();
  final SyncService _syncService = SyncService();
  final StreakService _streakService = StreakService();
  final QuoteService _quoteService = QuoteService();
  
  List<FoodLog> _logs = [];
  bool _isLoading = false;
  
  // Streak
  int _streak = 0;
  List<String> _logDates = []; // yyyy-MM-dd strings of dates that have logs
  
  // Quote
  DailyQuote? _todayQuote;
  
  // Date filter
  DateTime _selectedDate = DateTime.now();

  List<FoodLog> get logs => _logs;
  bool get isLoading => _isLoading;
  int get streak => _streak;
  List<String> get logDates => _logDates;
  DailyQuote? get todayQuote => _todayQuote;
  DateTime get selectedDate => _selectedDate;

  /// Get food logs filtered by the selected date
  List<FoodLog> get filteredLogs {
    final dateStr = _selectedDate.toIso8601String().substring(0, 10);
    return _logs.where((log) {
      final logDateStr = log.mealTime.toIso8601String().substring(0, 10);
      return logDateStr == dateStr;
    }).toList();
  }

  /// Check if a specific date has any food logs
  bool hasLogsOnDate(DateTime date) {
    final dateStr = date.toIso8601String().substring(0, 10);
    return _logDates.contains(dateStr);
  }

  /// Change selected date and notify listeners
  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> fetchLogs() async {
    _isLoading = true;
    notifyListeners();

    try {
      _logs = await _foodLogService.getFoodLogs();
      _updateLogDates();
    } catch (e) {
      print("Error fetching logs: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch streak count from API or local
  Future<void> fetchStreak() async {
    try {
      final result = await _streakService.getStreak();
      _streak = result['streak'] ?? 0;
      if (result['dates'] != null) {
        _logDates = List<String>.from(result['dates']);
      }
      notifyListeners();
    } catch (e) {
      print("Error fetching streak: $e");
    }
  }

  /// Fetch today's daily quote
  Future<void> fetchTodayQuote() async {
    try {
      _todayQuote = await _quoteService.getTodayQuote();
      notifyListeners();
    } catch (e) {
      print("Error fetching quote: $e");
    }
  }

  /// Fetch all dashboard data at once
  Future<void> fetchDashboardData() async {
    await Future.wait([
      fetchLogs(),
      fetchStreak(),
      fetchTodayQuote(),
    ]);
  }

  Future<bool> addLog(FoodLog log) async {
    try {
      final newLog = await _foodLogService.addFoodLog(log);
      _logs.insert(0, newLog);
      // Sort by descending time
      _logs.sort((a, b) => b.mealTime.compareTo(a.mealTime));
      _updateLogDates();
      
      // Refresh streak since a new log was added
      fetchStreak();
      
      notifyListeners();
      return true;
    } catch (e) {
      print("Error adding log: $e");
      return false;
    }
  }

  Future<bool> updateLog(FoodLog log) async {
    try {
      final updatedLog = await _foodLogService.updateFoodLog(log);
      final index = _logs.indexWhere((l) => l.localId == updatedLog.localId);
      if (index != -1) {
        _logs[index] = updatedLog;
        notifyListeners();
      }
      return true;
    } catch (e) {
      print("Error updating log: $e");
      return false;
    }
  }

  Future<void> deleteLog(FoodLog log) async {
    try {
      await _foodLogService.deleteFoodLog(log);
      _logs.removeWhere((l) => l.localId == log.localId);
      _updateLogDates();
      notifyListeners();
      // Refresh from server to ensure consistency
      await fetchLogs();
    } catch (e) {
      print("Error deleting log: $e");
    }
  }

  Future<void> forceSync() async {
    _isLoading = true;
    notifyListeners();

    await _syncService.syncUnsyncedFoodLogs();
    await fetchLogs();
    await fetchStreak();
  }

  Future<bool> toggleShareLog(FoodLog log) async {
    try {
      final updatedLog = await _foodLogService.toggleShareFoodLog(log);
      final index = _logs.indexWhere((l) => l.localId == log.localId);
      if (index != -1) {
        _logs[index] = updatedLog;
        notifyListeners();
      }
      return true;
    } catch (e) {
      print("Error toggling share: $e");
      return false;
    }
  }

  /// Rebuild _logDates from current _logs
  void _updateLogDates() {
    final Set<String> dates = {};
    for (var log in _logs) {
      dates.add(log.mealTime.toIso8601String().substring(0, 10));
    }
    _logDates = dates.toList()..sort((a, b) => b.compareTo(a));
  }
}
