/// Typed models describing the contract of the JavaScript ↔ Flutter bridge.
///
/// The web platform sends a JSON payload of the shape:
/// ```json
/// { "action": "pickFile", "params": { "accept": "image/*" }, "requestId": "abc123" }
/// ```
/// and Flutter replies (when a reply is expected) with a [BridgeResponse]
/// that is injected back into the page as `window.BitzlatoviewBridge.__resolve(...)`.
library;

/// All native capabilities exposed to the web app via the bridge.
enum BridgeAction {
  pickFile,
  takePhoto,
  getLocation,
  shareContent,
  copyToClipboard,
  requestNotificationPermission,
  getDeviceInfo,
  biometricAuthenticate,
  unknown;

  static BridgeAction fromWire(String value) {
    return BridgeAction.values.firstWhere(
      (action) => action.wireName == value,
      orElse: () => BridgeAction.unknown,
    );
  }

  /// The exact string used on the JavaScript side, e.g. `pickFile`.
  String get wireName {
    switch (this) {
      case BridgeAction.pickFile:
        return 'pickFile';
      case BridgeAction.takePhoto:
        return 'takePhoto';
      case BridgeAction.getLocation:
        return 'getLocation';
      case BridgeAction.shareContent:
        return 'shareContent';
      case BridgeAction.copyToClipboard:
        return 'copyToClipboard';
      case BridgeAction.requestNotificationPermission:
        return 'requestNotificationPermission';
      case BridgeAction.getDeviceInfo:
        return 'getDeviceInfo';
      case BridgeAction.biometricAuthenticate:
        return 'biometricAuthenticate';
      case BridgeAction.unknown:
        return 'unknown';
    }
  }
}

/// A single inbound request from the web page.
class BridgeRequest {
  const BridgeRequest({
    required this.action,
    this.params = const <String, dynamic>{},
    this.requestId,
  });

  final BridgeAction action;
  final Map<String, dynamic> params;
  final String? requestId;

  factory BridgeRequest.fromJson(Map<String, dynamic> json) {
    return BridgeRequest(
      action: BridgeAction.fromWire(json['action'] as String? ?? ''),
      params: (json['params'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
      requestId: json['requestId'] as String?,
    );
  }
}

/// The reply Flutter sends back for a given [BridgeRequest].
class BridgeResponse {
  const BridgeResponse({
    required this.requestId,
    this.success = true,
    this.data,
    this.error,
  });

  final String? requestId;
  final bool success;
  final Object? data;
  final String? error;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'requestId': requestId,
        'success': success,
        if (data != null) 'data': data,
        if (error != null) 'error': error,
      };
}

/// Payload describing a push notification, shared between
/// [NotificationService] and the JS bridge (`window.handlePushNotification`).
class PushNotificationPayload {
  const PushNotificationPayload({
    required this.title,
    required this.body,
    this.deepLink,
    this.data = const <String, dynamic>{},
  });

  final String title;
  final String body;
  final String? deepLink;
  final Map<String, dynamic> data;

  factory PushNotificationPayload.fromRemoteMessageData(
    Map<String, dynamic> data, {
    String? title,
    String? body,
  }) {
    return PushNotificationPayload(
      title: title ?? data['title']?.toString() ?? '',
      body: body ?? data['body']?.toString() ?? '',
      deepLink: data['deep_link']?.toString() ?? data['url']?.toString(),
      data: data,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'body': body,
        if (deepLink != null) 'deepLink': deepLink,
        'data': data,
      };
}
