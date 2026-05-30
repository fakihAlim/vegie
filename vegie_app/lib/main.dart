import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'config/constants.dart';
import 'services/fcm_service.dart';
import 'services/activity_log_service.dart';
import 'services/local_notification_service.dart';
import 'app.dart';

Future<void> _initializeServerConfig() async {
  try {
    // Try to reach the local server with a short timeout
    final response = await http
        .get(Uri.parse(Constants.localUrl))
        .timeout(const Duration(seconds: 2));
    
    if (response.statusCode >= 200 && response.statusCode < 500) {
      Constants.baseUrl = Constants.localUrl;
      print("Connected to Local Server");
    } else {
      Constants.baseUrl = Constants.onlineUrl;
      print("Local Server returned error, falling back to Online Server");
    }
  } catch (e) {
    // If timeout or connection refused, fallback to online
    Constants.baseUrl = Constants.onlineUrl;
    print("Local Server unreachable, falling back to Online Server");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  await _initializeServerConfig();
  
  // Initialize services in the background so they do not block the UI boot
  FCMService.initialize();
  ActivityLogService.instance.initializeSession();
  await LocalNotificationService.initialize();
  
  runApp(const LovingHarmonyApp());
}
