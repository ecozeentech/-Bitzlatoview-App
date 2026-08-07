import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../config/constants.dart';
import '../models/webview_events.dart';

class WebViewProvider extends ChangeNotifier {
  InAppWebViewController? _controller;
  WebViewLoadState _loadState = const WebViewLoadState();
  bool _isOffline = false;
  String _currentUrl = AppConstants.baseUrl;
  bool _showSplash = true;

  InAppWebViewController? get controller => _controller;
  WebViewLoadState get loadState => _loadState;
  bool get isOffline => _isOffline;
  String get currentUrl => _currentUrl;
  bool get showSplash => _showSplash;

  void setController(InAppWebViewController controller) {
    _controller = controller;
    notifyListeners();
  }

  void setOffline(bool offline) {
    if (_isOffline != offline) {
      _isOffline = offline;
      notifyListeners();
    }
  }

  void onLoadStart(String? url) {
    _currentUrl = url ?? _currentUrl;
    _loadState = _loadState.copyWith(
      isLoading: true,
      progress: 0,
      currentUrl: _currentUrl,
      clearError: true,
    );
    notifyListeners();
  }

  void onProgress(int progress) {
    _loadState = _loadState.copyWith(
      isLoading: progress < 100,
      progress: progress / 100,
    );
    notifyListeners();
  }

  void onLoadStop(String? url) {
    _currentUrl = url ?? _currentUrl;
    _loadState = _loadState.copyWith(
      isLoading: false,
      progress: 1,
      currentUrl: _currentUrl,
      clearError: true,
    );
    _showSplash = false;
    notifyListeners();
  }

  void onError(String message) {
    _loadState = _loadState.copyWith(
      isLoading: false,
      errorMessage: message,
    );
    notifyListeners();
  }

  Future<void> loadUrl(String url) async {
    _currentUrl = url;
    await _controller?.loadUrl(
      urlRequest: URLRequest(url: WebUri(url)),
    );
    notifyListeners();
  }

  Future<void> reload() async {
    await _controller?.reload();
  }

  Future<void> clearCache() async {
    await InAppWebViewController.clearAllCache();
  }

  Future<void> runJavaScript(String script) async {
    await _controller?.evaluateJavascript(source: script);
  }

  Future<void> handlePushNotification(Map<String, dynamic> data) async {
    final encoded = jsonEncode(data);
    await runJavaScript('''
      if (typeof window.handlePushNotification === 'function') {
        window.handlePushNotification($encoded);
      }
    ''');
  }
}
