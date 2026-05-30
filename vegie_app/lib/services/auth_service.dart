import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<User?> login(String email, String password) async {
    final response = await _apiService.post(
      Constants.endpointLogin,
      {'email': email, 'password': password},
      requireAuth: false,
    );

    if (response['success'] == true) {
      final token = response['data']['token'];
      final userData = response['data']['user'];
      
      await _saveAuthData(token, userData);
      return User.fromJson(userData);
    }
    return null;
  }

  Future<User?> register(String name, String email, String password) async {
    final response = await _apiService.post(
      Constants.endpointRegister,
      {'name': name, 'email': email, 'password': password},
      requireAuth: false,
    );

    if (response['success'] == true) {
      final token = response['data']['token'];
      final userData = response['data']['user'];
      
      await _saveAuthData(token, userData);
      return User.fromJson(userData);
    }
    return null;
  }

  Future<User?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(Constants.keyToken)) return null;
    final userStr = prefs.getString(Constants.keyUser);
    if (userStr != null) {
      try {
        return User.fromJson(jsonDecode(userStr));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<User?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(Constants.keyToken)) return null;

    try {
      final response = await _apiService.get(Constants.endpointProfile);
      if (response['success'] == true) {
        final userData = response['data'];
        
        // Update stored user data
        prefs.setString(Constants.keyUser, jsonEncode(userData));
        if (userData.containsKey('is_onboarding_completed')) {
          await prefs.setBool(Constants.keyOnboardingCompleted, userData['is_onboarding_completed'] == true || userData['is_onboarding_completed'] == 1);
        }
        return User.fromJson(userData);
      }
    } catch (e) {
      // If network fails but we have cached user, return cached
      final userStr = prefs.getString(Constants.keyUser);
      if (userStr != null) {
        return User.fromJson(jsonDecode(userStr));
      }
    }
    return null;
  }

  Future<void> _saveAuthData(String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.keyToken, token);
    await prefs.setString(Constants.keyUser, jsonEncode(userData));
    if (userData.containsKey('is_onboarding_completed')) {
      await prefs.setBool(Constants.keyOnboardingCompleted, userData['is_onboarding_completed'] == true || userData['is_onboarding_completed'] == 1);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(Constants.keyToken);
    await prefs.remove(Constants.keyUser);
  }

  Future<bool> registerFcmToken(String token) async {
    final response = await _apiService.post(
      Constants.endpointFcmToken,
      {'token': token},
    );
    return response['success'] == true;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(Constants.keyToken);
  }

  Future<bool> submitOnboardingStage(String stage) async {
    try {
      final response = await _apiService.post(
        Constants.endpointOnboarding,
        {'stage': stage},
      );
      return response['success'] == true;
    } catch (e) {
      print("Submit onboarding error: $e");
      return false;
    }
  }
}
