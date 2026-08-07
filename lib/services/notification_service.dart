import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/constants.dart';

/// Top-level background message handler (must be a top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background FCM: ${message.messageId}');
}

/// Manages FCM / APNs registration and local notification display.
class NotificationService {
  NotificationService({
    FlutterSecureStorage? storage,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            ),
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  final FlutterSecureStorage _storage;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final StreamController<Map<String, dynamic>> _notificationTapController =
      StreamController<Map<String, dynamic>>.broadcast();

  bool _initialized = false;
  bool _firebaseAvailable = false;

  Stream<Map<String, dynamic>> get onNotificationTap =>
      _notificationTapController.stream;

  bool get isFirebaseAvailable => _firebaseAvailable;

  /// Initializes Firebase + local notifications. Safe to call when Firebase
  /// config files are missing — the service degrades gracefully.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _initLocalNotifications();

    try {
      await Firebase.initializeApp();
      _firebaseAvailable = true;
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _configureFcm();
    } catch (e) {
      _firebaseAvailable = false;
      debugPrint(
        'NotificationService: Firebase unavailable (add google-services.json / '
        'GoogleService-Info.plist). Continuing without push. Error: $e',
      );
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data =
                jsonDecode(response.payload!) as Map<String, dynamic>;
            _notificationTapController.add(data);
          } catch (_) {
            _notificationTapController.add({'payload': response.payload});
          }
        }
      },
    );

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'bitzlatoview_default',
        'Bitzlatoview Notifications',
        description: 'Trade alerts, P2P updates, and account notifications',
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _configureFcm() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    final token = await messaging.getToken();
    if (token != null) {
      await _storage.write(key: AppConstants.fcmTokenStorageKey, value: token);
      debugPrint('FCM token registered');
    }

    messaging.onTokenRefresh.listen((newToken) async {
      await _storage.write(
        key: AppConstants.fcmTokenStorageKey,
        value: newToken,
      );
    });

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _notificationTapController.add({
        ...message.data,
        if (message.notification?.title != null)
          'title': message.notification!.title,
        if (message.notification?.body != null)
          'body': message.notification!.body,
      });
    });

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _notificationTapController.add(Map<String, dynamic>.from(initial.data));
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bitzlatoview_default',
          'Bitzlatoview Notifications',
          channelDescription:
              'Trade alerts, P2P updates, and account notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<String?> getToken() async {
    return _storage.read(key: AppConstants.fcmTokenStorageKey);
  }

  Future<bool> requestPermission() async {
    if (!_firebaseAvailable) return false;
    final settings = await FirebaseMessaging.instance.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  void dispose() {
    _notificationTapController.close();
  }
}
