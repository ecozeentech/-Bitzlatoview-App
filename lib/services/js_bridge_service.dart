import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../models/webview_events.dart';

class JsBridgeService {
  JsBridgeService({
    LocalAuthentication? localAuth,
    DeviceInfoPlugin? deviceInfo,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final LocalAuthentication _localAuth;
  final DeviceInfoPlugin _deviceInfo;

  Future<BridgeResponse> handleAction(BridgeAction action) async {
    try {
      switch (action.action) {
        case 'pickFile':
          return await _pickFile(action);
        case 'takePhoto':
          return await _takePhoto(action);
        case 'getLocation':
          return await _getLocation(action);
        case 'shareContent':
          return await _shareContent(action);
        case 'copyToClipboard':
          return await _copyToClipboard(action);
        case 'requestNotificationPermission':
          return await _requestNotificationPermission(action);
        case 'getDeviceInfo':
          return await _getDeviceInfo(action);
        case 'biometricAuthenticate':
          return await _biometricAuthenticate(action);
        default:
          return BridgeResponse(
            callbackId: action.callbackId,
            success: false,
            error: 'Unknown action: ${action.action}',
          );
      }
    } catch (e) {
      return BridgeResponse(
        callbackId: action.callbackId,
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<BridgeResponse> _pickFile(BridgeAction action) async {
    final accept = action.params['accept'] as String? ?? '*/*';
    FileType fileType = FileType.any;
    if (accept.contains('image')) {
      fileType = FileType.image;
    } else if (accept.contains('pdf')) {
      fileType = FileType.custom;
    }

    final result = await FilePicker.platform.pickFiles(
      type: fileType,
      allowedExtensions:
          fileType == FileType.custom ? ['pdf', 'jpg', 'jpeg', 'png'] : null,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return BridgeResponse(
        callbackId: action.callbackId,
        success: false,
        error: 'No file selected',
      );
    }

    final file = result.files.first;
    return BridgeResponse(
      callbackId: action.callbackId,
      success: true,
      data: {
        'name': file.name,
        'size': file.size,
        'path': file.path,
        'bytes': file.bytes != null ? base64Encode(file.bytes!) : null,
        'extension': file.extension,
      },
    );
  }

  Future<BridgeResponse> _takePhoto(BridgeAction action) async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      return BridgeResponse(
        callbackId: action.callbackId,
        success: false,
        error: 'Camera permission denied',
      );
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      return BridgeResponse(
        callbackId: action.callbackId,
        success: false,
        error: 'No camera available',
      );
    }

    final lens = action.params['lens'] as String? ?? 'front';
    final selected = cameras.firstWhere(
      (camera) =>
          lens == 'front'
              ? camera.lensDirection == CameraLensDirection.front
              : camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      selected,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await controller.initialize();
    final image = await controller.takePicture();
    await controller.dispose();

    final bytes = await File(image.path).readAsBytes();
    return BridgeResponse(
      callbackId: action.callbackId,
      success: true,
      data: {
        'path': image.path,
        'bytes': base64Encode(bytes),
      },
    );
  }

  Future<BridgeResponse> _getLocation(BridgeAction action) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return BridgeResponse(
        callbackId: action.callbackId,
        success: false,
        error: 'Location services disabled',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return BridgeResponse(
        callbackId: action.callbackId,
        success: false,
        error: 'Location permission denied',
      );
    }

    final position = await Geolocator.getCurrentPosition();
    return BridgeResponse(
      callbackId: action.callbackId,
      success: true,
      data: {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      },
    );
  }

  Future<BridgeResponse> _shareContent(BridgeAction action) async {
    final text = action.params['text'] as String? ?? '';
    await Share.share(text);
    return BridgeResponse(
      callbackId: action.callbackId,
      success: true,
      data: {'shared': true},
    );
  }

  Future<BridgeResponse> _copyToClipboard(BridgeAction action) async {
    final text = action.params['text'] as String? ?? '';
    await Clipboard.setData(ClipboardData(text: text));
    return BridgeResponse(
      callbackId: action.callbackId,
      success: true,
      data: {'copied': true},
    );
  }

  Future<BridgeResponse> _requestNotificationPermission(
    BridgeAction action,
  ) async {
    final status = await Permission.notification.request();
    return BridgeResponse(
      callbackId: action.callbackId,
      success: status.isGranted,
      data: {'granted': status.isGranted},
      error: status.isGranted ? null : 'Notification permission denied',
    );
  }

  Future<BridgeResponse> _getDeviceInfo(BridgeAction action) async {
    Map<String, dynamic> info;
    if (Platform.isAndroid) {
      final android = await _deviceInfo.androidInfo;
      info = {
        'platform': 'android',
        'model': android.model,
        'brand': android.brand,
        'version': android.version.release,
        'sdkInt': android.version.sdkInt,
      };
    } else if (Platform.isIOS) {
      final ios = await _deviceInfo.iosInfo;
      info = {
        'platform': 'ios',
        'model': ios.utsname.machine,
        'name': ios.name,
        'version': ios.systemVersion,
      };
    } else {
      info = {'platform': defaultTargetPlatform.name};
    }

    return BridgeResponse(
      callbackId: action.callbackId,
      success: true,
      data: info,
    );
  }

  Future<BridgeResponse> _biometricAuthenticate(BridgeAction action) async {
    final canCheck = await _localAuth.canCheckBiometrics;
    if (!canCheck) {
      return BridgeResponse(
        callbackId: action.callbackId,
        success: false,
        error: 'Biometrics not available',
      );
    }

    final reason = action.params['reason'] as String? ??
        'Authenticate to continue';
    final authenticated = await _localAuth.authenticate(
      localizedReason: reason,
      options: const AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: true,
      ),
    );

    return BridgeResponse(
      callbackId: action.callbackId,
      success: authenticated,
      data: {'authenticated': authenticated},
      error: authenticated ? null : 'Authentication failed',
    );
  }
}
