import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../app.dart';
import '../screens/home/home_screen.dart';
import '../screens/news/news_detail_screen.dart';
import '../screens/recipes/recipe_detail_screen.dart';
import 'auth_service.dart';

class FCMService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final AuthService _authService = AuthService();

  static Future<void> initialize() async {
    // Request permission for iOS/Android 13+
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      
      // Get the token
      String? token = await _fcm.getToken();
      if (token != null) {
        print("FCM Token: $token");
        _sendTokenToServer(token);
      }
    }

    // Handle token refresh
    _fcm.onTokenRefresh.listen(_sendTokenToServer);

    // Handle being in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground message: ${message.notification?.title}");
      // You could show a local notification here if needed
    });

    // Handle notification click when app is in background but still running
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

    // Handle notification click when app is completely terminated
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNotificationClick(message);
        });
      }
    });
  }

  static void _handleNotificationClick(RemoteMessage message) {
    print("Notification clicked with data: ${message.data}");
    
    final String? type = message.data['target_type'];
    final String? idStr = message.data['target_id'];
    
    if (type == null || idStr == null) return;
    
    final int? id = int.tryParse(idStr);
    if (id == null && type != 'quiz') return;

    final navigatorState = LovingHarmonyApp.navigatorKey.currentState;
    if (navigatorState == null) {
      print("NavigatorState is null, cannot perform deep link");
      return;
    }

    if (type == 'news') {
      navigatorState.push(MaterialPageRoute(
        builder: (context) => NewsDetailScreen(newsId: id!, title: 'Berita Baru'),
      ));
    } else if (type == 'recipe') {
      navigatorState.push(MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipeId: id!, title: 'Resep Baru'),
      ));
    } else if (type == 'quiz') {
      navigatorState.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen(initialIndex: 1)),
        (route) => false,
      );
    }
  }

  static Future<void> _sendTokenToServer(String token) async {
    try {
      if (await _authService.isLoggedIn()) {
        await _authService.registerFcmToken(token);
        print("FCM Token registered successfully");
      }
    } catch (e) {
      print("Error registering FCM token: $e");
    }
  }
}
