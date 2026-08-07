import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../config/constants.dart';
import '../services/js_bridge_service.dart';
import '../utils/helpers.dart';

enum WebViewLoadState { idle, loading, loaded, error }

/// Holds WebView navigation / connectivity state.
class WebViewProvider extends ChangeNotifier {
  WebViewProvider({
    JsBridgeService? bridgeService,
    Connectivity? connectivity,
  })  : _bridgeService = bridgeService ?? JsBridgeService(),
        _connectivity = connectivity ?? Connectivity();

  final JsBridgeService _bridgeService;
  final Connectivity _connectivity;

  WebViewController? _controller;
  WebViewLoadState _loadState = WebViewLoadState.idle;
  String _currentUrl = AppConstants.baseUrl;
  String? _errorMessage;
  bool _isOffline = false;
  int _progress = 0;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  WebViewController? get controller => _controller;
  WebViewLoadState get loadState => _loadState;
  String get currentUrl => _currentUrl;
  String? get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;
  bool get isLoading => _loadState == WebViewLoadState.loading;
  int get progress => _progress;
  JsBridgeService get bridgeService => _bridgeService;

  Future<void> initialize({String? initialUrl}) async {
    _currentUrl = initialUrl ?? AppConstants.baseUrl;
    await _checkConnectivity();
    _connectivitySub =
        _connectivity.onConnectivityChanged.listen((results) async {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (offline != _isOffline) {
        _isOffline = offline;
        notifyListeners();
        if (!offline && _controller != null) {
          await Future<void>.delayed(AppConstants.connectivityDebounce);
          await reload();
        }
      }
    });
  }

  void attachController(WebViewController controller) {
    _controller = controller;
    _bridgeService.attachController(controller);
  }

  Future<void> _checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _isOffline = results.every((r) => r == ConnectivityResult.none);
  }

  void onPageStarted(String url) {
    _currentUrl = url;
    _loadState = WebViewLoadState.loading;
    _errorMessage = null;
    _progress = 0;
    notifyListeners();
  }

  void onProgress(int progress) {
    _progress = progress;
    notifyListeners();
  }

  Future<void> onPageFinished(String url) async {
    _currentUrl = url;
    _loadState = WebViewLoadState.loaded;
    _progress = 100;
    try {
      await _controller?.runJavaScript(JsBridgeService.bootstrapScript());
    } catch (_) {}
    notifyListeners();
  }

  void onWebResourceError(WebResourceError error) {
    // Ignore subframe / cancelled errors for the main chrome.
    if (error.isForMainFrame ?? true) {
      _loadState = WebViewLoadState.error;
      _errorMessage = error.description;
      notifyListeners();
    }
  }

  Future<void> loadUrl(String url) async {
    final controller = _controller;
    if (controller == null) return;
    if (!Helpers.shouldHandleInternally(url) &&
        Uri.tryParse(url)?.scheme.startsWith('http') == true) {
      await Helpers.openExternal(url);
      return;
    }
    _currentUrl = url;
    _loadState = WebViewLoadState.loading;
    notifyListeners();
    await controller.loadRequest(Uri.parse(url));
  }

  Future<void> reload() async {
    await _checkConnectivity();
    if (_isOffline) {
      notifyListeners();
      return;
    }
    _errorMessage = null;
    _loadState = WebViewLoadState.loading;
    notifyListeners();
    await _controller?.reload();
  }

  Future<void> goBack() async {
    if (_controller != null && await _controller!.canGoBack()) {
      await _controller!.goBack();
    }
  }

  Future<void> clearCache() async {
    await _controller?.clearCache();
    await _controller?.clearLocalStorage();
  }

  NavigationDecision navigationDelegate(NavigationRequest request) {
    final url = request.url;
    if (Helpers.shouldHandleInternally(url)) {
      return NavigationDecision.navigate;
    }
    Helpers.openExternal(url);
    return NavigationDecision.prevent;
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
