import 'package:flutter/foundation.dart';

import '../config/constants.dart';

enum WebViewLoadStatus { idle, loading, loaded, error }

/// Drives the loading/error/progress UI around the WebView (splash fade-out,
/// progress bar, pull-to-refresh, the error/offline screens) without the
/// screen itself needing to track all of that state imperatively.
class WebViewProvider extends ChangeNotifier {
  WebViewLoadStatus _status = WebViewLoadStatus.idle;
  double _progress = 0;
  String _currentUrl = AppConstants.baseUrl;
  String? _errorMessage;
  bool _canGoBack = false;
  bool _hasLoadedOnce = false;

  WebViewLoadStatus get status => _status;
  double get progress => _progress;
  String get currentUrl => _currentUrl;
  String? get errorMessage => _errorMessage;
  bool get canGoBack => _canGoBack;
  bool get isLoading => _status == WebViewLoadStatus.loading;
  bool get hasError => _status == WebViewLoadStatus.error;

  /// Whether the WebView has ever successfully finished a page load - used
  /// to decide whether the splash screen should still be shown.
  bool get hasLoadedOnce => _hasLoadedOnce;

  void startLoading(String url) {
    _status = WebViewLoadStatus.loading;
    _currentUrl = url;
    _errorMessage = null;
    _progress = 0;
    notifyListeners();
  }

  void updateProgress(double value) {
    _progress = value.clamp(0, 1);
    notifyListeners();
  }

  void finishLoading(String url) {
    _status = WebViewLoadStatus.loaded;
    _currentUrl = url;
    _progress = 1;
    _hasLoadedOnce = true;
    notifyListeners();
  }

  void setError(String message) {
    _status = WebViewLoadStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  void updateCanGoBack(bool value) {
    if (_canGoBack == value) return;
    _canGoBack = value;
    notifyListeners();
  }

  void updateCurrentUrl(String url) {
    _currentUrl = url;
    notifyListeners();
  }

  void reset() {
    _status = WebViewLoadStatus.idle;
    _progress = 0;
    _errorMessage = null;
    notifyListeners();
  }
}
