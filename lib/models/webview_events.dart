import 'dart:convert';

/// Event models for the JavaScript ↔ Flutter bridge.
enum BridgeAction {
  pickFile,
  takePhoto,
  getLocation,
  shareContent,
  copyToClipboard,
  requestNotificationPermission,
  getDeviceInfo,
  biometricAuthenticate,
  openSettings,
  unknown;

  static BridgeAction fromString(String? value) {
    if (value == null) return BridgeAction.unknown;
    return BridgeAction.values.firstWhere(
      (a) => a.name == value,
      orElse: () => BridgeAction.unknown,
    );
  }
}

class BridgeMessage {
  const BridgeMessage({
    required this.action,
    this.params = const {},
    this.requestId,
  });

  final BridgeAction action;
  final Map<String, dynamic> params;
  final String? requestId;

  factory BridgeMessage.fromJson(Map<String, dynamic> json) {
    return BridgeMessage(
      action: BridgeAction.fromString(json['action'] as String?),
      params: Map<String, dynamic>.from(
        (json['params'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      requestId: json['requestId'] as String?,
    );
  }

  factory BridgeMessage.fromRaw(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return BridgeMessage.fromJson(decoded);
    }
    if (decoded is Map) {
      return BridgeMessage.fromJson(decoded.cast<String, dynamic>());
    }
    return const BridgeMessage(action: BridgeAction.unknown);
  }

  Map<String, dynamic> toJson() => {
        'action': action.name,
        'params': params,
        if (requestId != null) 'requestId': requestId,
      };
}

class BridgeResponse {
  const BridgeResponse({
    required this.success,
    this.data,
    this.error,
    this.requestId,
  });

  final bool success;
  final dynamic data;
  final String? error;
  final String? requestId;

  String toJavaScript() {
    final payload = <String, dynamic>{
      'success': success,
      if (data != null) 'data': data,
      if (error != null) 'error': error,
      if (requestId != null) 'requestId': requestId,
    };
    return jsonEncode(payload);
  }
}
