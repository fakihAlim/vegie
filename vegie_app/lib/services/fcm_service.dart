import 'package:firebase_messaging/firebase_messaging.dart';
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
