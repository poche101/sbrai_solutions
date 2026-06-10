import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _localNotif = FlutterLocalNotificationsPlugin();
  static final _fcm = FirebaseMessaging.instance;

  static Future<void> init() async {
    // ✅ Firebase Messaging is not supported on Windows/Linux/macOS desktop.
    // Skip the entire setup on unsupported platforms to avoid runtime errors.
    if (!_isSupported) {
      debugPrint(
        'ℹ️ NotificationService: skipped on ${defaultTargetPlatform.name}',
      );
      return;
    }

    // 1. Request permission (required on iOS and Android 13+)
    await _fcm.requestPermission(sound: true, badge: true, alert: true);

    // 2. Set up local notifications with sound
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestAlertPermission: true,
    );
    await _localNotif.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // 3. Handle FCM messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 4. Save FCM token to your backend so it can reach this device
    final token = await _fcm.getToken();
    if (token != null) await _saveFcmToken(token);

    // Refresh token if it rotates
    _fcm.onTokenRefresh.listen(_saveFcmToken);
  }

  /// Firebase Messaging getToken() is only supported on Android, iOS, and web.
  static bool get _isSupported =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      kIsWeb;

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'];

    final channelId = type == 'new_listing' ? 'listings' : 'general';
    final channelName = type == 'new_listing' ? 'New Listings' : 'General';

    await _localNotif.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      data['title'] ?? 'Sbrai Hub',
      data['body'] ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('notification'),
        ),
        iOS: const DarwinNotificationDetails(
          presentSound: true,
          presentAlert: true,
          presentBadge: true,
        ),
      ),
    );
  }

  static Future<void> _saveFcmToken(String token) async {
    // POST token to your backend so it lands in users.fcm_token
    // Use your existing ApiService here
  }
}
