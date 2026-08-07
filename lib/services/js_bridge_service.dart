import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../config/constants.dart';
import '../models/webview_events.dart';

/// Handles JavaScript ↔ Flutter bridge calls from the WebView.
class JsBridgeService {
  JsBridgeService({
    LocalAuthentication? localAuth,
    ImagePicker? imagePicker,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _imagePicker = imagePicker ?? ImagePicker();

  final LocalAuthentication _localAuth;
  final ImagePicker _imagePicker;

  WebViewController? _controller;

  void attachController(WebViewController controller) {
    _controller = controller;
  }

  /// Parses an incoming bridge message and dispatches to native handlers.
  Future<void> handleMessage(String raw) async {
    try {
      final message = BridgeMessage.fromRaw(raw);
      final response = await _dispatch(message);
      await _sendResponse(response);
    } catch (e) {
      debugPrint('JsBridgeService.handleMessage error: $e');
      await _sendResponse(
        BridgeResponse(success: false, error: e.toString()),
      );
    }
  }

  Future<BridgeResponse> _dispatch(BridgeMessage message) async {
    switch (message.action) {
      case BridgeAction.pickFile:
        return _pickFile(message);
      case BridgeAction.takePhoto:
        return _takePhoto(message);
      case BridgeAction.getLocation:
        return _getLocation(message);
      case BridgeAction.shareContent:
        return _shareContent(message);
      case BridgeAction.copyToClipboard:
        return _copyToClipboard(message);
      case BridgeAction.requestNotificationPermission:
        return _requestNotificationPermission(message);
      case BridgeAction.getDeviceInfo:
        return _getDeviceInfo(message);
      case BridgeAction.biometricAuthenticate:
        return _biometricAuthenticate(message);
      case BridgeAction.openSettings:
        return BridgeResponse(
          success: true,
          data: {'route': '/settings'},
          requestId: message.requestId,
        );
      case BridgeAction.unknown:
        return BridgeResponse(
          success: false,
          error: 'Unknown bridge action',
          requestId: message.requestId,
        );
    }
  }

  Future<BridgeResponse> _pickFile(BridgeMessage message) async {
    final accept = message.params['accept'] as String?;
    final type = accept != null && accept.contains('image')
        ? FileType.image
        : FileType.any;

    final result = await FilePicker.platform.pickFiles(
      type: type,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return BridgeResponse(
        success: false,
        error: 'cancelled',
        requestId: message.requestId,
      );
    }

    final file = result.files.first;
    String? base64Data;
    if (file.bytes != null) {
      base64Data = base64Encode(file.bytes!);
    }

    return BridgeResponse(
      success: true,
      data: {
        'name': file.name,
        'size': file.size,
        'path': file.path,
        'extension': file.extension,
        if (base64Data != null) 'base64': base64Data,
      },
      requestId: message.requestId,
    );
  }

  Future<BridgeResponse> _takePhoto(BridgeMessage message) async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      return BridgeResponse(
        success: false,
        error: 'camera_permission_denied',
        requestId: message.requestId,
      );
    }

    final photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1920,
    );

    if (photo == null) {
      return BridgeResponse(
        success: false,
        error: 'cancelled',
        requestId: message.requestId,
      );
    }

    final bytes = await photo.readAsBytes();
    return BridgeResponse(
      success: true,
      data: {
        'name': photo.name,
        'path': photo.path,
        'mimeType': photo.mimeType,
        'base64': base64Encode(bytes),
      },
      requestId: message.requestId,
    );
  }

  Future<BridgeResponse> _getLocation(BridgeMessage message) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return BridgeResponse(
        success: false,
        error: 'location_disabled',
        requestId: message.requestId,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return BridgeResponse(
        success: false,
        error: 'location_permission_denied',
        requestId: message.requestId,
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );

    return BridgeResponse(
      success: true,
      data: {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      },
      requestId: message.requestId,
    );
  }

  Future<BridgeResponse> _shareContent(BridgeMessage message) async {
    final text = message.params['text'] as String? ?? '';
    if (text.isEmpty) {
      return BridgeResponse(
        success: false,
        error: 'empty_text',
        requestId: message.requestId,
      );
    }
    await SharePlus.instance.share(ShareParams(text: text));
    return BridgeResponse(success: true, requestId: message.requestId);
  }

  Future<BridgeResponse> _copyToClipboard(BridgeMessage message) async {
    final text = message.params['text'] as String? ?? '';
    await Clipboard.setData(ClipboardData(text: text));
    return BridgeResponse(success: true, requestId: message.requestId);
  }

  Future<BridgeResponse> _requestNotificationPermission(
    BridgeMessage message,
  ) async {
    final status = await Permission.notification.request();
    return BridgeResponse(
      success: status.isGranted,
      data: {'granted': status.isGranted, 'status': status.name},
      requestId: message.requestId,
    );
  }

  Future<BridgeResponse> _getDeviceInfo(BridgeMessage message) async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    final Map<String, dynamic> info = {
      'appName': packageInfo.appName,
      'packageName': packageInfo.packageName,
      'version': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
      'platform': Platform.operatingSystem,
    };

    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      info.addAll({
        'model': android.model,
        'manufacturer': android.manufacturer,
        'osVersion': android.version.release,
        'sdkInt': android.version.sdkInt,
      });
    } else if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      info.addAll({
        'model': ios.utsname.machine,
        'name': ios.name,
        'osVersion': ios.systemVersion,
      });
    }

    return BridgeResponse(
      success: true,
      data: info,
      requestId: message.requestId,
    );
  }

  Future<BridgeResponse> _biometricAuthenticate(BridgeMessage message) async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    if (!canCheck && !isSupported) {
      return BridgeResponse(
        success: false,
        error: 'biometrics_unavailable',
        requestId: message.requestId,
      );
    }

    final reason = message.params['reason'] as String? ??
        'Authenticate to continue with Bitzlatoview';

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      return BridgeResponse(
        success: authenticated,
        data: {'authenticated': authenticated},
        requestId: message.requestId,
      );
    } on PlatformException catch (e) {
      return BridgeResponse(
        success: false,
        error: e.code,
        requestId: message.requestId,
      );
    }
  }

  Future<void> _sendResponse(BridgeResponse response) async {
    final controller = _controller;
    if (controller == null) return;

    final js = '''
(function() {
  var payload = ${response.toJavaScript()};
  if (typeof window.onBitzlatoviewBridgeResult === 'function') {
    window.onBitzlatoviewBridgeResult(payload);
  }
  window.dispatchEvent(new CustomEvent('bitzlatoviewBridgeResult', { detail: payload }));
})();
''';
    try {
      await controller.runJavaScript(js);
    } catch (e) {
      debugPrint('JsBridgeService._sendResponse error: $e');
    }
  }

  /// Injects a push notification payload into the WebView.
  Future<void> injectPushNotification(Map<String, dynamic> data) async {
    final controller = _controller;
    if (controller == null) return;
    final encoded = jsonEncode(data);
    try {
      await controller.runJavaScript('''
(function() {
  var data = $encoded;
  if (typeof window.handlePushNotification === 'function') {
    window.handlePushNotification(data);
  }
  window.dispatchEvent(new CustomEvent('bitzlatoviewPush', { detail: data }));
})();
''');
    } catch (e) {
      debugPrint('JsBridgeService.injectPushNotification error: $e');
    }
  }

  /// Returns the injected bootstrap script that exposes helper APIs.
  static String bootstrapScript() {
    return '''
(function() {
  if (window.__bitzlatoviewBridgeReady) return;
  window.__bitzlatoviewBridgeReady = true;
  window.BitzlatoviewNative = {
    call: function(action, params, requestId) {
      if (window.${AppConstants.jsBridgeChannel}) {
        window.${AppConstants.jsBridgeChannel}.postMessage(JSON.stringify({
          action: action,
          params: params || {},
          requestId: requestId || null
        }));
      }
    }
  };
  document.dispatchEvent(new Event('bitzlatoviewNativeReady'));
})();
''';
  }
}
