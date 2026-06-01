import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config/constants.dart';
import 'services/fcm_service.dart';
import 'services/activity_log_service.dart';
import 'services/local_notification_service.dart';
import 'app.dart';

Future<void> _initializeServerConfig() async {
  try {
    // Try to reach the local server's quotes endpoint which requires database access
    final response = await http
        .get(Uri.parse('${Constants.localUrl}/index.php?route=quotes/today'))
        .timeout(const Duration(seconds: 2));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data['success'] == true) {
        Constants.baseUrl = Constants.localUrl;
        debugPrint("Connected to Local Server successfully (Database is OK)");
        return;
      }
    }
    
    // If not successful or DB is down, fallback to online
    Constants.baseUrl = Constants.onlineUrl;
    debugPrint("Local Server returned error or DB down, falling back to Online Server");
  } catch (e) {
    // If timeout, connection refused, or JSON parsing error, fallback to online
    Constants.baseUrl = Constants.onlineUrl;
    debugPrint("Local Server unreachable ($e), falling back to Online Server");
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
