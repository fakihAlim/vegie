import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/myth_fact_service.dart';

class MythFactProvider with ChangeNotifier {
  final MythFactService _service = MythFactService();

  List<MythFact> _myths = [];
  List<int> _readMythIds = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MythFact> get myths => _myths;
  List<int> get readMythIds => _readMythIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  MythFactProvider() {
    loadReadMyths();
  }

  Future<void> loadReadMyths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final read = prefs.getStringList('read_myths') ?? [];
      _readMythIds = read.map((id) => int.tryParse(id)).whereType<int>().toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading read myths: $e");
    }
  }

  Future<void> markMythAsRead(int mythId) async {
    if (!_readMythIds.contains(mythId)) {
      _readMythIds.add(mythId);
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('read_myths', _readMythIds.map((id) => id.toString()).toList());
      } catch (e) {
        debugPrint("Error saving read myth: $e");
      }
    }
  }

  Future<void> fetchMyths() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myths = await _service.getMyths();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
