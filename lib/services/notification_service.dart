import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/webview_events.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  NotificationService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  late final StreamController<NotificationPayload> _controller;

  Stream<NotificationPayload> get notificationStream => _controller.stream;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _controller = StreamController<NotificationPayload>.broadcast();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          _controller.add(
            NotificationPayload.fromMap(
              jsonDecode(response.payload!) as Map<String, dynamic>,
            ),
          );
        }
      },
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleOpenedMessage(initial);
    }

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('FCM token unavailable: $e');
      return null;
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final payload = NotificationPayload(
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data,
    );
    _controller.add(payload);
    _showLocalNotification(payload);
  }

  void _handleOpenedMessage(RemoteMessage message) {
    _controller.add(
      NotificationPayload(
        title: message.notification?.title,
        body: message.notification?.body,
        data: message.data,
      ),
    );
  }

  Future<void> _showLocalNotification(NotificationPayload payload) async {
    const androidDetails = AndroidNotificationDetails(
      'bitzlatoview_channel',
      'Bitzlatoview Notifications',
      channelDescription: 'Push notifications for Bitzlatoview',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      payload.title,
      payload.body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(payload.toJson()),
    );
  }

  void dispose() {
    _controller.close();
  }
}
