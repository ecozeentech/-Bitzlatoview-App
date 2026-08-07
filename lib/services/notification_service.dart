import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../models/webview_events.dart';
import '../utils/helpers.dart';

/// Must be a top-level (or static) function: the platform invokes this in a
/// separate isolate when a data message arrives while the app is
/// terminated / backgrounded.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase.initializeApp() is required here because this runs in its own
  // isolate. Guarded because notification_service.initialize() may already
  // have run it in the main isolate for foreground delivery.
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Already initialized - safe to ignore.
  }
  Helpers.debugLog('Handled background message: ${message.messageId}');
}

/// Wraps Firebase Cloud Messaging (Android) / APNs (iOS, via Firebase) and
/// `flutter_local_notifications` to display foreground notifications, plus
/// the plumbing to forward a tapped notification's deep link into the
/// WebView via `window.handlePushNotification(...)`.
class NotificationService {
  NotificationService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final StreamController<PushNotificationPayload> _notificationController =
      StreamController<PushNotificationPayload>.broadcast();

  /// Emits whenever a push notification is received in the foreground or
  /// tapped from the tray, so the WebView screen can forward it to the page.
  Stream<PushNotificationPayload> get onNotification =>
      _notificationController.stream;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp();
    } catch (e) {
      // Firebase config files (google-services.json /
      // GoogleService-Info.plist) are intentionally not committed with real
      // project credentials - see README. Fail soft so the WebView still
      // works without push notifications configured.
      Helpers.debugLog('Firebase initialization skipped/failed: $e');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpenedApp);

    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _onNotificationOpenedApp(initialMessage);
    }
  }

  /// Requests notification permission and returns whether it was granted.
  /// Called both at first launch and on-demand via the JS bridge
  /// (`requestNotificationPermission`).
  Future<bool> requestPermission() async {
    if (!_initialized) await initialize();
    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    final bool granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefsNotificationsEnabledKey, granted);
    return granted;
  }

  /// The FCM registration token for this device, persisted so it survives
  /// process restarts without an extra round trip on every launch.
  Future<String?> getToken() async {
    try {
      final String? token = await _messaging.getToken();
      if (token != null) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.prefsPushTokenKey, token);
      }
      return token;
    } catch (e) {
      Helpers.debugLog('Failed to fetch FCM token: $e');
      return null;
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final PushNotificationPayload payload = _toPayload(message);
    _showLocalNotification(payload);
    _notificationController.add(payload);
  }

  void _onNotificationOpenedApp(RemoteMessage message) {
    _notificationController.add(_toPayload(message));
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload == null) return;
    _notificationController.add(
      PushNotificationPayload.fromRemoteMessageData(
        Helpers.tryDecodeJsonMap(payload),
      ),
    );
  }

  PushNotificationPayload _toPayload(RemoteMessage message) {
    return PushNotificationPayload.fromRemoteMessageData(
      message.data,
      title: message.notification?.title,
      body: message.notification?.body,
    );
  }

  Future<void> _showLocalNotification(PushNotificationPayload payload) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'bitzlatoview_default',
      'Bitzlatoview Notifications',
      channelDescription: 'Trade updates, P2P orders and account alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: payload.title.isEmpty ? AppConstants.appName : payload.title,
      body: payload.body,
      notificationDetails: const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: Helpers.encodeJson(payload.toJson()),
    );
  }

  void dispose() {
    unawaited(_notificationController.close());
  }
}
