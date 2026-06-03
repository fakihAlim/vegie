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
  List<String> _logDates = []; 
  
  // --- OPTIMASI: Set untuk Lookup Tanggal secepat O(1) ---
  Set<String> _logDatesSet = {};

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
  /// OPTIMIZED: Memakai komparasi Integer yang jauh lebih hemat CPU daripada parsing ISO String
  List<FoodLog> get filteredLogs {
    return _logs.where((log) {
      return log.mealTime.year == _selectedDate.year &&
             log.mealTime.month == _selectedDate.month &&
             log.mealTime.day == _selectedDate.day;
    }).toList();
  }

  /// Check if a specific date has any food logs
  /// OPTIMIZED: Tidak membuat memori string baru dalam skala besar & pencarian secepat O(1) berkat 'Set'
  bool hasLogsOnDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final dateStr = '${date.year}-$m-$d';
    return _logDatesSet.contains(dateStr);
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
      debugPrint("Error fetching logs: $e");
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
        _logDatesSet = _logDates.toSet(); // Menyimpan ke format Set juga
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching streak: $e");
    }
  }

  /// Fetch today's daily quote
  Future<void> fetchTodayQuote() async {
    try {
      _todayQuote = await _quoteService.getTodayQuote();
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching quote: $e");
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

  /// Add a food log.
  Future<Map<String, dynamic>> addLog(FoodLog log) async {
    try {
      final hasConnection = await _foodLogService.hasInternetConnection();
      
      if (hasConnection) {
        try {
          // Try direct save to online server first for real-time AI analysis
          final result = await _foodLogService.addFoodLogOnline(log);
          final FoodLog syncedLog = result['log'] as FoodLog;
          final newlyUnlockedBadges = result['badges'] as List? ?? [];
          
          _logs.insert(0, syncedLog);
          _logs.sort((a, b) => b.mealTime.compareTo(a.mealTime));
          _updateLogDates();
          
          await fetchStreak();
          notifyListeners();
          
          return {
            'badges': newlyUnlockedBadges,
            'points': syncedLog.points,
            'log': syncedLog,
          };
        } catch (serverError) {
          debugPrint("Server save failed: $serverError. Falling back to offline save.");
          // Fall through to offline path below
        }
      }
      
      // Offline fallback: save locally first
      final savedLog = await _foodLogService.addFoodLogLocal(log);
      _logs.insert(0, savedLog);
      _logs.sort((a, b) => b.mealTime.compareTo(a.mealTime));
      _updateLogDates();
      notifyListeners();

      // Background sync trigger (errors won't block)
      List<dynamic> newBadges = [];
      try {
        newBadges = await _syncService.syncUnsyncedFoodLogs();
      } catch (syncError) {
        debugPrint("Background sync error: $syncError");
      }

      // Refresh local log mapping
      final allLogs = await _foodLogService.getFoodLogsLocal();
      final syncedLog = allLogs.firstWhere((l) => l.localId == savedLog.localId, orElse: () => savedLog);
      final idx = _logs.indexWhere((l) => l.localId == savedLog.localId);
      if (idx != -1) _logs[idx] = syncedLog;

      await fetchStreak();
      notifyListeners();

      return {
        'badges': newBadges,
        'points': syncedLog.points,
        'log': syncedLog,
      };
    } catch (e) {
      debugPrint("Error adding log: $e");
      return {
        'badges': <Map<String, dynamic>>[],
        'points': 50, // Default to 50 instead of 0 to avoid false hewani warning!
        'log': log,
      };
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
      debugPrint("Error updating log: $e");
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
      debugPrint("Error deleting log: $e");
    }
  }

  Future<void> forceSync() async {
    _isLoading = true;
    notifyListeners();

    await _syncService.syncUnsyncedFoodLogs(); // badges ignored during manual sync
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
      debugPrint("Error toggling share: $e");
      return false;
    }
  }

  /// Rebuild _logDates and _logDatesSet from current _logs
  void _updateLogDates() {
    _logDatesSet.clear();
    for (var log in _logs) {
      final m = log.mealTime.month.toString().padLeft(2, '0');
      final d = log.mealTime.day.toString().padLeft(2, '0');
      _logDatesSet.add('${log.mealTime.year}-$m-$d');
    }
    
    // Sort array for legacy use
    _logDates = _logDatesSet.toList()..sort((a, b) => b.compareTo(a));
  }
}