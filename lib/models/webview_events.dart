class BridgeAction {
  final String action;
  final Map<String, dynamic> params;
  final String? callbackId;

  const BridgeAction({
    required this.action,
    this.params = const {},
    this.callbackId,
  });

  factory BridgeAction.fromJson(Map<String, dynamic> json) {
    return BridgeAction(
      action: json['action'] as String? ?? '',
      params: Map<String, dynamic>.from(json['params'] as Map? ?? {}),
      callbackId: json['callbackId'] as String?,
    );
  }
}

class BridgeResponse {
  final String? callbackId;
  final bool success;
  final dynamic data;
  final String? error;

  const BridgeResponse({
    this.callbackId,
    required this.success,
    this.data,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'callbackId': callbackId,
        'success': success,
        'data': data,
        'error': error,
      };
}

class WebViewLoadState {
  final bool isLoading;
  final double progress;
  final String? currentUrl;
  final String? errorMessage;

  const WebViewLoadState({
    this.isLoading = true,
    this.progress = 0,
    this.currentUrl,
    this.errorMessage,
  });

  WebViewLoadState copyWith({
    bool? isLoading,
    double? progress,
    String? currentUrl,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WebViewLoadState(
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
      currentUrl: currentUrl ?? this.currentUrl,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class NotificationPayload {
  final String? title;
  final String? body;
  final Map<String, dynamic> data;

  const NotificationPayload({
    this.title,
    this.body,
    this.data = const {},
  });

  factory NotificationPayload.fromMap(Map<String, dynamic> map) {
    return NotificationPayload(
      title: map['title'] as String?,
      body: map['body'] as String?,
      data: Map<String, dynamic>.from(map['data'] as Map? ?? map),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'data': data,
      };
}
