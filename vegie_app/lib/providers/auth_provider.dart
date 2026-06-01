import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/badge_model.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../database/local_db.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  
  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  List<BadgeModel> _userBadges = [];

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  List<BadgeModel> get userBadges => _userBadges;

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
        // Fetch badges in parallel after profile is loaded
        await _fetchBadges(freshUser.unlockedBadges);
      } else {
        await logout();
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('Unauthorized') || errorStr.contains('401')) {
        await logout();
      }
      debugPrint("Background profile refresh error: $e");
    }
  }

  /// Fetches all master badges from the server and marks each
  /// as unlocked if its code appears in [unlockedCodes].
  Future<void> _fetchBadges(List<String> unlockedCodes) async {
    try {
      final response = await _apiService.get('/badges');
      if (response['success'] == true && response['data'] is List) {
        final List<dynamic> rawList = response['data'];
        _userBadges = rawList.map((json) {
          final badge = BadgeModel.fromJson(json as Map<String, dynamic>);
          // Cross-reference with the user's unlocked badge codes
          return badge.copyWith(
            isUnlocked: unlockedCodes.contains(badge.code),
          );
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Fetch badges error: $e");
    }
  }

  /// Force-refresh badges (e.g. after a new badge is awarded).
  Future<void> refreshBadges() async {
    if (_user != null) {
      await _fetchBadges(_user!.unlockedBadges);
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
      debugPrint("Login error: $e");
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
      debugPrint("Register error: $e");
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

  Future<bool> submitOnboardingStage({
    required String stage,
    required int age,
    required double weight,
    required double height,
    required String photo,
    String? gender,
  }) async {
    _isLoading = true;
    notifyListeners();

    bool success = await _authService.submitOnboardingStage(
      stage: stage,
      age: age,
      weight: weight,
      height: height,
      photo: photo,
      gender: gender,
    );
    
    if (success && _user != null) {
      _user = _user!.copyWith(
        isOnboardingCompleted: true,
        ttmStage: stage.toLowerCase(),
        age: age,
        weight: weight,
        height: height,
        photo: photo,
        gender: gender,
      );
      await _authService.saveUser(_user!);
    }
    
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> updateProfile({
    String? name,
    String? bio,
    int? age,
    double? weight,
    double? height,
    String? photo,
    String? gender,
  }) async {
    _isLoading = true;
    notifyListeners();

    final updatedUser = await _authService.updateProfile(
      name: name,
      bio: bio,
      age: age,
      weight: weight,
      height: height,
      photo: photo,
      gender: gender,
    );

    if (updatedUser != null) {
      _user = updatedUser;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void updateTtmState(String stage, bool isLocked) {
    if (_user != null) {
      _user = _user!.copyWith(ttmStage: stage, isFeatureLocked: isLocked);
      _authService.saveUser(_user!);
      notifyListeners();
    }
  }

  void addLocalPoints(int points) {
    if (_user != null) {
      _user!.totalPoints += points;
      _authService.saveUser(_user!);
      notifyListeners();
    }
  }

  void addLocalCarbonSaved(double amount) {
    if (_user != null) {
      _user!.totalCarbonSaved += amount;
      _authService.saveUser(_user!);
      notifyListeners();
    }
  }
}
