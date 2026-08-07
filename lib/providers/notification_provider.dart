import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/notification_service.dart';

/// Exposes push-notification state to the widget tree.
class NotificationProvider extends ChangeNotifier {
  NotificationProvider({NotificationService? service})
      : _service = service ?? NotificationService();

  final NotificationService _service;
  StreamSubscription<Map<String, dynamic>>? _tapSub;
  Map<String, dynamic>? _pendingPayload;
  String? _token;
  bool _initialized = false;

  NotificationService get service => _service;
  Map<String, dynamic>? get pendingPayload => _pendingPayload;
  String? get token => _token;
  bool get isInitialized => _initialized;
  bool get firebaseAvailable => _service.isFirebaseAvailable;

  Future<void> initialize() async {
    if (_initialized) return;
    await _service.initialize();
    _token = await _service.getToken();
    _tapSub = _service.onNotificationTap.listen((payload) {
      _pendingPayload = payload;
      notifyListeners();
    });
    _initialized = true;
    notifyListeners();
  }

  void clearPendingPayload() {
    _pendingPayload = null;
    notifyListeners();
  }

  Future<bool> requestPermission() => _service.requestPermission();

  @override
  void dispose() {
    _tapSub?.cancel();
    _service.dispose();
    super.dispose();
  }
}
