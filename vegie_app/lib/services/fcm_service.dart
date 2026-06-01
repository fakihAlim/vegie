import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../app.dart';
import '../screens/home/home_screen.dart';
import '../screens/news/news_detail_screen.dart';
import '../screens/recipes/recipe_detail_screen.dart';
import '../models/news.dart';
import '../models/recipe.dart';
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
      debugPrint('User granted permission');
      
      // Get the token
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint("FCM Token: $token");
        _sendTokenToServer(token);
      }
    }

    // Handle token refresh
    _fcm.onTokenRefresh.listen(_sendTokenToServer);

    // Handle being in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Foreground message: ${message.notification?.title}");
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
    debugPrint("Notification clicked with data: ${message.data}");
    
    final String? type = message.data['target_type'];
    final String? idStr = message.data['target_id'];
    
    if (type == null || idStr == null) return;
    
    final int? id = int.tryParse(idStr);
    if (id == null && type != 'quiz') return;

    final navigatorState = LovingHarmonyApp.navigatorKey.currentState;
    if (navigatorState == null) {
      debugPrint("NavigatorState is null, cannot perform deep link");
      return;
    }

    if (type == 'news') {
      // Create minimal News placeholder; detail screen will load full content from API
      final placeholderNews = News(
        id: id!,
        title: message.notification?.title ?? 'Berita Baru',
        publishedAt: DateTime.now(),
      );
      navigatorState.push(MaterialPageRoute(
        builder: (context) => NewsDetailScreen(news: placeholderNews),
      ));
    } else if (type == 'recipe') {
      // Create minimal Recipe placeholder; detail screen will load full content from API
      final placeholderRecipe = Recipe(
        id: id!,
        title: message.notification?.title ?? 'Resep Baru',
        publishedAt: DateTime.now(),
      );
      navigatorState.push(MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: placeholderRecipe),
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
        debugPrint("FCM Token registered successfully");
      }
    } catch (e) {
      debugPrint("Error registering FCM token: $e");
    }
  }
}
