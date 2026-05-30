import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../database/local_db.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    // 1. Ambil user dari cache lokal secara instan
    _user = await _authService.getCachedUser();
    
    _isInitialized = true;
    _isLoading = false;
    notifyListeners();

    // 2. Perbarui profil di latar belakang asinkron
    if (_user != null) {
      _refreshProfileInBackground();
    }
  }

  Future<void> _refreshProfileInBackground() async {
    try {
      final freshUser = await _authService.getProfile();
      if (freshUser != null) {
        _user = freshUser;
        notifyListeners();
      } else {
        await logout();
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('Unauthorized') || errorStr.contains('401')) {
        await logout();
      }
      print("Background profile refresh error: $e");
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.login(email, password);
      if (user != null) {
        _user = user;
        
        // Clear any leftover data from a previous user session
        await LocalDatabase.instance.clearAllFoodLogs();
        
        // Trigger FCM token registration
        await FCMService.initialize();
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Login error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.register(name, email, password);
      if (user != null) {
        _user = user;

        // Clear any leftover data from a previous user session
        await LocalDatabase.instance.clearAllFoodLogs();

        // Trigger FCM token registration
        await FCMService.initialize();

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Register error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await LocalDatabase.instance.clearAllFoodLogs(); // Wipe local data before logout
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  Future<bool> submitOnboardingStage(String stage) async {
    _isLoading = true;
    notifyListeners();

    bool success = await _authService.submitOnboardingStage(stage);
    
    _isLoading = false;
    notifyListeners();
    return success;
  }

  void updateTtmState(String stage, bool isLocked) {
    if (_user != null) {
      _user = _user!.copyWith(ttmStage: stage, isFeatureLocked: isLocked);
      _authService.saveUser(_user!);
      notifyListeners();
    }
  }
}
