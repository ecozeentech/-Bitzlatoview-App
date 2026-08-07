import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/webview_events.dart';
import '../services/notification_service.dart';

/// Thin, testable façade over [NotificationService] exposed to the widget
/// tree: current permission state, the last push payload (so the WebView
/// screen can forward it to `window.handlePushNotification`) and the FCM
/// token.
class NotificationProvider extends ChangeNotifier {
  NotificationProvider({NotificationService? notificationService})
      : _service = notificationService ?? NotificationService();

  final NotificationService _service;
  StreamSubscription<PushNotificationPayload>? _subscription;

  bool _permissionGranted = false;
  String? _token;
  PushNotificationPayload? _lastNotification;

  bool get permissionGranted => _permissionGranted;
  String? get token => _token;
  PushNotificationPayload? get lastNotification => _lastNotification;

  NotificationService get service => _service;

  Future<void> initialize() async {
    await _service.initialize();
    _token = await _service.getToken();
    _subscription = _service.onNotification.listen((payload) {
      _lastNotification = payload;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<bool> requestPermission() async {
    _permissionGranted = await _service.requestPermission();
    notifyListeners();
    return _permissionGranted;
  }

  /// Clears the last notification once the WebView screen has consumed it,
  /// so it isn't re-delivered on the next page load.
  void consumeLastNotification() {
    _lastNotification = null;
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _service.dispose();
    super.dispose();
  }
}
