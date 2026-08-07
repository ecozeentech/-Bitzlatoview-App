import 'package:flutter/foundation.dart';

import '../models/webview_events.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({NotificationService? notificationService})
      : _notificationService = notificationService ?? NotificationService();

  final NotificationService _notificationService;
  NotificationPayload? _latestNotification;
  String? _fcmToken;

  NotificationPayload? get latestNotification => _latestNotification;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    await _notificationService.initialize();
    _fcmToken = await _notificationService.getToken();
    _notificationService.notificationStream.listen((payload) {
      _latestNotification = payload;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<bool> requestPermission() {
    return _notificationService.requestPermission();
  }

  void clearLatest() {
    _latestNotification = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }
}
