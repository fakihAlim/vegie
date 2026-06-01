import 'package:flutter/material.dart';
import '../services/myth_fact_service.dart';

class MythFactProvider with ChangeNotifier {
  final MythFactService _service = MythFactService();

  List<MythFact> _myths = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MythFact> get myths => _myths;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
