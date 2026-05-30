import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int _reminderId = 0; // Constant ID for the daily reminder

  /// Initializes the local notification service, registers channels,
  /// and dynamically detects the native device timezone.
  static Future<void> initialize() async {
    tz.initializeTimeZones(); // Initialize timezone DB
    
    // Dynamically detect the native device timezone name
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Robust fallback to Jakarta timezone if detection fails
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    }
    
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const DarwinInitializationSettings iosInitializationSettings = 
        DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  /// Schedules a daily repeating reminder at the specified time
  /// using the native timezone and a power-efficient inexact alarm.
  static Future<void> scheduleDailyReminder(TimeOfDay time) async {
    // Cancel any existing reminder with this specific ID to avoid duplicates
    await _notificationsPlugin.cancel(_reminderId);

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If the scheduled time has already passed today, schedule it for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      _reminderId,
      'Waktunya Mencatat Makanan! 🍽️',
      'Jangan lupa untuk mencatat jurnal makanan (food log) kamu hari ini.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminder',
          channelDescription: 'Pengingat harian untuk mencatat makanan',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      // Use inexact scheduling to protect battery and satisfy Google Play Store Policies
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeats daily at the same time
    );
  }
  
  /// Cancels the scheduled daily reminder specifically by its ID
  static Future<void> cancelReminder() async {
    await _notificationsPlugin.cancel(_reminderId);
  }
}
