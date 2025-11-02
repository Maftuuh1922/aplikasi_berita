import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  // Inisialisasi notifikasi
  static Future<void> initialize() async {
    // Request permission untuk iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    if (kDebugMode) {
      print('FCM Token: $token');
    }

    // Save token ke SharedPreferences
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    }

    // Listen untuk token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      if (kDebugMode) {
        print('FCM Token refreshed: $newToken');
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }

      if (message.notification != null) {
        if (kDebugMode) {
          print(
              'Message also contained a notification: ${message.notification}');
        }
      }
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('A new onMessageOpenedApp event was published!');
        print('Message data: ${message.data}');
      }
    });
  }

  // Get FCM token
  static Future<String?> getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  // Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to topic: $e');
      }
    }
  }

  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unsubscribing from topic: $e');
      }
    }
  }

  // Check notification settings
  static Future<bool> isPushNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('push_notifications') ?? true;
  }

  // Save notification settings
  static Future<void> setPushNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications', enabled);

    if (enabled) {
      // Subscribe to general news topic
      await subscribeToTopic('news');
      await subscribeToTopic('breaking_news');
    } else {
      // Unsubscribe from topics
      await unsubscribeFromTopic('news');
      await unsubscribeFromTopic('breaking_news');
    }
  }

  // Check breaking news setting
  static Future<bool> isBreakingNewsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('breaking_news') ?? true;
  }

  // Save breaking news setting
  static Future<void> setBreakingNewsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('breaking_news', enabled);

    if (enabled) {
      await subscribeToTopic('breaking_news');
    } else {
      await unsubscribeFromTopic('breaking_news');
    }
  }

  // Check email notifications setting
  static Future<bool> isEmailNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('email_notifications') ?? false;
  }

  // Save email notifications setting
  static Future<void> setEmailNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('email_notifications', enabled);
  }

  // Check daily digest setting
  static Future<bool> isDailyDigestEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('daily_digest') ?? false;
  }

  // Save daily digest setting
  static Future<void> setDailyDigestEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_digest', enabled);

    if (enabled) {
      await subscribeToTopic('daily_digest');
    } else {
      await unsubscribeFromTopic('daily_digest');
    }
  }

  // Check weekly report setting
  static Future<bool> isWeeklyReportEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('weekly_report') ?? true;
  }

  // Save weekly report setting
  static Future<void> setWeeklyReportEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('weekly_report', enabled);

    if (enabled) {
      await subscribeToTopic('weekly_report');
    } else {
      await unsubscribeFromTopic('weekly_report');
    }
  }
}

// Background message handler (harus top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Handling a background message: ${message.messageId}');
    print('Message data: ${message.data}');
  }

  if (message.notification != null) {
    if (kDebugMode) {
      print('Message also contained a notification: ${message.notification}');
    }
  }
}
