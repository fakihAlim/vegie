import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_service.dart';
import '../config/constants.dart';

class ActivityLogService {
  ActivityLogService._();
  static final ActivityLogService instance = ActivityLogService._();

  final ApiService _apiService = ApiService();
  
  String? _sessionId;
  DateTime? _sessionStartTime;
  
  // Cached device information
  String? _platform;
  String? _deviceName;
  String? _osVersion;
  String? _appVersion;
  bool _deviceInfoLoaded = false;

  /// Initializes a new session. Should be called when the app starts.
  Future<void> initializeSession() async {
    _sessionId = _generateSessionId();
    _sessionStartTime = DateTime.now();
    await _loadDeviceInfo();
    
    // Log the app open event
    logEvent('app_open');
  }

  /// Returns the current session ID, or generates one if it doesn't exist
  String get sessionId {
    _sessionId ??= _generateSessionId();
    return _sessionId!;
  }

  /// Logs the app close event with calculated duration
  void logAppClose() {
    if (_sessionStartTime != null) {
      final duration = DateTime.now().difference(_sessionStartTime!).inSeconds;
      logEvent('app_close', duration: duration);
    } else {
      logEvent('app_close');
    }
  }

  /// Fire-and-forget logging of an activity event
  void logEvent(String action, {String? screen, int? duration, Map<String, dynamic>? extraData}) {
    // Run asynchronously without waiting
    unawaited(_sendLog(action, screen: screen, duration: duration, extraData: extraData));
  }

  /// Helper to send log to the backend server
  Future<void> _sendLog(String action, {String? screen, int? duration, Map<String, dynamic>? extraData}) async {
    try {
      // Check network connection first
      final hasConnection = await _hasInternet();
      if (!hasConnection) return;

      // Make sure device info is loaded
      if (!_deviceInfoLoaded) {
        await _loadDeviceInfo();
      }

      final payload = {
        'action': action,
        'session_id': sessionId,
        'screen': screen,
        'duration': duration,
        'extra_data': extraData,
        'platform': _platform,
        'device_name': _deviceName,
        'os_version': _osVersion,
        'app_version': _appVersion,
      };

      await _apiService.post(
        Constants.endpointActivityLogs,
        payload,
      );
    } catch (e) {
      debugPrint('Error sending activity log: $e');
      // Fire-and-forget: ignore all errors so the user is not impacted
    }
  }

  /// Loads platform, device and app version details
  Future<void> _loadDeviceInfo() async {
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      
      if (kIsWeb) {
        _platform = 'web';
        _deviceName = 'Browser';
        _osVersion = 'Web';
      } else if (Platform.isAndroid) {
        _platform = 'android';
        final androidInfo = await deviceInfo.androidInfo;
        _deviceName = '${androidInfo.brand} ${androidInfo.model}';
        _osVersion = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        _platform = 'ios';
        final iosInfo = await deviceInfo.iosInfo;
        _deviceName = iosInfo.name;
        _osVersion = 'iOS ${iosInfo.systemVersion}';
      } else {
        _platform = Platform.operatingSystem;
        _deviceName = Platform.localHostname;
        _osVersion = Platform.operatingSystemVersion;
      }

      try {
        final packageInfo = await PackageInfo.fromPlatform();
        _appVersion = packageInfo.version;
      } catch (_) {
        _appVersion = '1.0.0';
      }

      _deviceInfoLoaded = true;
    } catch (e) {
      debugPrint('Failed to get device info: $e');
      // Fallback details in case of exceptions
      _platform ??= Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'unknown');
      _deviceName ??= 'Generic Device';
      _osVersion ??= 'Unknown OS';
      _appVersion ??= '1.0.0';
      _deviceInfoLoaded = true;
    }
  }

  /// Generates a simple cryptographically resilient session ID in Dart
  String _generateSessionId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Check connectivity status
  Future<bool> _hasInternet() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }
}
