import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../config/constants.dart';
import '../models/webview_events.dart';
import '../utils/helpers.dart';
import 'notification_service.dart';

/// JavaScript ↔ Flutter bridge.
///
/// The web app calls `window.BitzlatoviewBridge.postMessage(JSON.stringify({
/// action, params }))`. That shim (installed by [injectShim]) forwards the
/// call to a native `flutter_inappwebview` JavaScript handler, which this
/// service handles and resolves/rejects the returned Promise with a
/// [BridgeResponse].
///
/// This is the single place native device capabilities are exposed to the
/// (untrusted) web content, so every action is deliberately whitelisted via
/// [BridgeAction] and wrapped in a try/catch that never lets a bad payload
/// crash the app.
class JsBridgeService {
  JsBridgeService({
    ImagePicker? imagePicker,
    LocalAuthentication? localAuth,
    this.notificationService,
  })  : _imagePicker = imagePicker ?? ImagePicker(),
        _localAuth = localAuth ?? LocalAuthentication();

  final ImagePicker _imagePicker;
  final LocalAuthentication _localAuth;
  final NotificationService? notificationService;

  /// Registers the native handler on [controller]. Call this from
  /// `onWebViewCreated`, before the first page load.
  void attach(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: AppConstants.jsBridgeHandlerName,
      callback: (List<dynamic> args) async {
        if (args.isEmpty) {
          return const BridgeResponse(
            requestId: null,
            success: false,
            error: 'Empty bridge payload',
          ).toJson();
        }
        final Map<String, dynamic> payload = args.first is String
            ? Helpers.tryDecodeJsonMap(args.first as String)
            : (args.first as Map).cast<String, dynamic>();
        final BridgeRequest request = BridgeRequest.fromJson(payload);
        return (await dispatch(request)).toJson();
      },
    );
  }

  /// Injects the `window.BitzlatoviewBridge` shim expected by the web app.
  /// Safe to call multiple times (e.g. on every `onLoadStop`).
  Future<void> injectShim(InAppWebViewController controller) {
    return controller.evaluateJavascript(source: _shimScript);
  }

  /// Executes a single bridge request and returns its response. Public
  /// (rather than private) so it is directly unit-testable without a real
  /// WebView.
  Future<BridgeResponse> dispatch(BridgeRequest request) async {
    try {
      final Object? data = await _handle(request);
      return BridgeResponse(requestId: request.requestId, data: data);
    } on PlatformException catch (e) {
      return BridgeResponse(
        requestId: request.requestId,
        success: false,
        error: e.message ?? e.code,
      );
    } catch (e) {
      return BridgeResponse(
        requestId: request.requestId,
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<Object?> _handle(BridgeRequest request) async {
    switch (request.action) {
      case BridgeAction.pickFile:
        return _pickFile(request.params);
      case BridgeAction.takePhoto:
        return _takePhoto(request.params);
      case BridgeAction.getLocation:
        return _getLocation();
      case BridgeAction.shareContent:
        return _shareContent(request.params);
      case BridgeAction.copyToClipboard:
        return _copyToClipboard(request.params);
      case BridgeAction.requestNotificationPermission:
        return _requestNotificationPermission();
      case BridgeAction.getDeviceInfo:
        return _getDeviceInfo();
      case BridgeAction.biometricAuthenticate:
        return _biometricAuthenticate(request.params);
      case BridgeAction.unknown:
        throw ArgumentError('Unknown bridge action');
    }
  }

  /// Native file picker, used by the web app for KYC document uploads.
  Future<Map<String, dynamic>> _pickFile(Map<String, dynamic> params) async {
    final String accept = params['accept']?.toString() ?? '*/*';
    final FileType type = accept.startsWith('image/') ? FileType.image : FileType.any;
    final bool multiple = params['multiple'] == true;

    final List<PlatformFile> files;
    if (multiple) {
      // pickFiles() defaults to multi-selection; pickFile() (used below) is
      // the single-selection counterpart.
      final FilePickerResult? result = await FilePicker.pickFiles(type: type);
      files = result?.files ?? const <PlatformFile>[];
    } else {
      final PlatformFile? file = await FilePicker.pickFile(type: type);
      files = file == null ? const <PlatformFile>[] : <PlatformFile>[file];
    }

    if (files.isEmpty) {
      return <String, dynamic>{'cancelled': true, 'files': <dynamic>[]};
    }

    final List<Map<String, dynamic>> encoded = await Future.wait(
      files.map((file) async {
        return <String, dynamic>{
          'name': file.name,
          'size': file.size,
          'extension': file.extension,
          'base64': base64Encode(await file.readAsBytes()),
        };
      }),
    );

    return <String, dynamic>{'cancelled': false, 'files': encoded};
  }

  /// Opens the camera for selfie / liveness KYC verification.
  Future<Map<String, dynamic>> _takePhoto(Map<String, dynamic> params) async {
    final XFile? photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice:
          params['front'] == false ? CameraDevice.rear : CameraDevice.front,
      imageQuality: 85,
    );
    if (photo == null) {
      return <String, dynamic>{'cancelled': true};
    }
    final Uint8List bytes = await photo.readAsBytes();
    return <String, dynamic>{
      'cancelled': false,
      'name': photo.name,
      'base64': base64Encode(bytes),
      'mimeType': 'image/jpeg',
    };
  }

  /// Device location, used for P2P trade matching by region.
  Future<Map<String, dynamic>> _getLocation() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw StateError('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location permission denied');
    }

    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    );
    return <String, dynamic>{
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
    };
  }

  Future<Map<String, dynamic>> _shareContent(Map<String, dynamic> params) async {
    final String text = params['text']?.toString() ?? '';
    final String? subject = params['subject']?.toString();
    final ShareResult result = await SharePlus.instance.share(
      ShareParams(text: text, subject: subject),
    );
    return <String, dynamic>{'status': result.status.name};
  }

  Future<Map<String, dynamic>> _copyToClipboard(Map<String, dynamic> params) async {
    final String text = params['text']?.toString() ?? '';
    await Clipboard.setData(ClipboardData(text: text));
    return <String, dynamic>{'copied': true};
  }

  Future<Map<String, dynamic>> _requestNotificationPermission() async {
    final service = notificationService;
    if (service == null) {
      return <String, dynamic>{'granted': false, 'reason': 'unavailable'};
    }
    final bool granted = await service.requestPermission();
    return <String, dynamic>{'granted': granted};
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return <String, dynamic>{
      'platform': Platform.operatingSystem,
      'osVersion': Platform.operatingSystemVersion,
      'appVersion': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
      'packageName': packageInfo.packageName,
    };
  }

  /// Biometric gate for sensitive actions like withdrawals, as requested by
  /// the web app before it submits the operation to the server.
  Future<Map<String, dynamic>> _biometricAuthenticate(
    Map<String, dynamic> params,
  ) async {
    final bool canCheck = await _localAuth.canCheckBiometrics;
    final bool isSupported = await _localAuth.isDeviceSupported();
    if (!canCheck || !isSupported) {
      return <String, dynamic>{'authenticated': false, 'reason': 'unsupported'};
    }

    final bool authenticated = await _localAuth.authenticate(
      localizedReason: params['reason']?.toString() ??
          'Confirm your identity to continue',
      biometricOnly: false,
      persistAcrossBackgrounding: true,
    );
    return <String, dynamic>{'authenticated': authenticated};
  }

  static const String _shimScript = '''
(function() {
  if (window.BitzlatoviewBridge && window.BitzlatoviewBridge.__native) return;
  var pending = {};
  var seq = 0;

  window.BitzlatoviewBridge = {
    __native: true,
    postMessage: function(message) {
      var payload = typeof message === 'string' ? JSON.parse(message) : message;
      var requestId = payload.requestId || ('req_' + (++seq));
      payload.requestId = requestId;
      return new Promise(function(resolve, reject) {
        pending[requestId] = { resolve: resolve, reject: reject };
        window.flutter_inappwebview.callHandler('${AppConstants.jsBridgeHandlerName}', payload)
          .then(function(response) {
            if (pending[requestId]) {
              if (response && response.success === false) {
                pending[requestId].reject(response.error);
              } else {
                pending[requestId].resolve(response ? response.data : undefined);
              }
              delete pending[requestId];
            }
          })
          .catch(function(err) {
            if (pending[requestId]) {
              pending[requestId].reject(err);
              delete pending[requestId];
            }
          });
      });
    }
  };

  window.dispatchEvent(new Event('BitzlatoviewBridgeReady'));
})();
''';
}
