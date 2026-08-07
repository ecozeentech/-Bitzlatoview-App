import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../models/webview_events.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/webview_provider.dart';
import '../services/deep_link_service.dart';
import '../services/js_bridge_service.dart';
import '../utils/helpers.dart';
import '../utils/validators.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_indicator.dart';
import 'offline_screen.dart';

/// The primary screen: renders app.bitzlatoview.com (or a deep-linked path)
/// in a high-performance WebView while wiring up cookie persistence, the
/// native JS bridge, pull-to-refresh, offline detection, deep links and
/// push-notification forwarding.
class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key, this.initialUrl});

  final String? initialUrl;

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _controller;
  PullToRefreshController? _pullToRefreshController;
  final JsBridgeService _bridge = JsBridgeService();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<Uri>? _deepLinkSubscription;
  bool _isOffline = false;

  late final String _startUrl = widget.initialUrl ?? AppConstants.baseUrl;

  static final InAppWebViewSettings _webViewSettings = InAppWebViewSettings(
    javaScriptEnabled: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    thirdPartyCookiesEnabled: true,
    sharedCookiesEnabled: true,
    useShouldOverrideUrlLoading: true,
    useOnLoadResource: false,
    cacheEnabled: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    supportMultipleWindows: false,
    allowsBackForwardNavigationGestures: true,
    transparentBackground: false,
    mixedContentMode: MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
    hardwareAcceleration: true,
  );

  @override
  void initState() {
    super.initState();
    _watchConnectivity();
    _watchDeepLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().cookieService.restoreCookies();
      final NotificationProvider notifications = context.read<NotificationProvider>();
      notifications.addListener(_onNotificationChanged);
    });
  }

  void _watchConnectivity() {
    Connectivity().checkConnectivity().then(_updateConnectivity);
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectivity);
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    final bool offline = results.every((r) => r == ConnectivityResult.none);
    if (offline != _isOffline && mounted) {
      setState(() => _isOffline = offline);
    }
  }

  void _watchDeepLinks() {
    final DeepLinkService deepLinkService = context.read<DeepLinkService>();
    _deepLinkSubscription = deepLinkService.onLink.listen((uri) {
      final String target = deepLinkService.resolveTargetUrl(uri);
      _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(target)));
    });
  }

  void _onNotificationChanged() {
    final PushNotificationPayload? payload =
        context.read<NotificationProvider>().lastNotification;
    if (payload == null || _controller == null) return;
    context.read<NotificationProvider>().consumeLastNotification();

    final String json = Helpers.encodeJson(payload.toJson());
    _controller!.evaluateJavascript(
      source: 'if (window.handlePushNotification) { '
          'window.handlePushNotification($json); '
          '}',
    );
    if (payload.deepLink != null &&
        Validators.isSafeHttpsUrl(
          payload.deepLink,
          allowedHosts: AppConstants.allowedNavigationHosts,
        )) {
      _controller!.loadUrl(urlRequest: URLRequest(url: WebUri(payload.deepLink!)));
    }
  }

  Future<void> _persistLastUrl(String url) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefsLastUrlKey, url);
  }

  Future<void> _reload() async {
    if (_controller == null) {
      setState(() {});
      return;
    }
    await _controller!.reload();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _deepLinkSubscription?.cancel();
    context.read<NotificationProvider>().removeListener(_onNotificationChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isOffline) {
      return OfflineScreen(onRetry: _reload);
    }

    final WebViewProvider webViewProvider = context.watch<WebViewProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            _buildWebView(webViewProvider),
            TopProgressBar(progress: webViewProvider.progress),
            if (webViewProvider.status == WebViewLoadStatus.loading &&
                !webViewProvider.hasLoadedOnce)
              const LoadingIndicator(),
            if (webViewProvider.hasError)
              AppErrorView(
                message: webViewProvider.errorMessage ??
                    'We couldn\'t load ${AppConstants.appName}.',
                onRetry: _reload,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebView(WebViewProvider webViewProvider) {
    _pullToRefreshController ??= PullToRefreshController(
      settings: PullToRefreshSettings(color: AppTheme.gold),
      onRefresh: () async {
        if (Platform.isAndroid) {
          await _controller?.reload();
        } else if (Platform.isIOS) {
          await _controller?.loadUrl(
            urlRequest: URLRequest(url: await _controller?.getUrl()),
          );
        }
      },
    );

    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(_startUrl)),
      initialSettings: _webViewSettings,
      pullToRefreshController: _pullToRefreshController,
      onWebViewCreated: (controller) {
        _controller = controller;
        _bridge.attach(controller);
      },
      onLoadStart: (controller, url) {
        webViewProvider.startLoading(url?.toString() ?? _startUrl);
      },
      onProgressChanged: (controller, progress) {
        webViewProvider.updateProgress(progress / 100);
      },
      onLoadStop: (controller, url) async {
        _pullToRefreshController?.endRefreshing();
        await _bridge.injectShim(controller);
        final bool canGoBack = await controller.canGoBack();
        webViewProvider.updateCanGoBack(canGoBack);
        webViewProvider.finishLoading(url?.toString() ?? _startUrl);
        if (url != null && mounted) {
          unawaited(_persistLastUrl(url.toString()));
          unawaited(context.read<AuthProvider>().onSessionEstablished());
        }
      },
      onReceivedError: (controller, request, error) {
        _pullToRefreshController?.endRefreshing();
        if (request.isForMainFrame ?? true) {
          webViewProvider.setError(error.description);
        }
      },
      onReceivedHttpError: (controller, request, errorResponse) {
        _pullToRefreshController?.endRefreshing();
        if ((request.isForMainFrame ?? true) &&
            (errorResponse.statusCode ?? 0) >= 500) {
          webViewProvider.setError('Server error (${errorResponse.statusCode}).');
        }
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final Uri? uri = navigationAction.request.url;
        if (uri == null) return NavigationActionPolicy.ALLOW;

        final bool isAllowedHost = AppConstants.allowedNavigationHosts
            .any((host) => uri.host == host || uri.host.endsWith('.$host'));

        if (isAllowedHost || uri.scheme == 'about') {
          return NavigationActionPolicy.ALLOW;
        }

        // mailto:, tel:, and third-party links (e.g. a payment provider or
        // KYC vendor) are handed off to the OS instead of loading inside
        // the app's WebView.
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        return NavigationActionPolicy.CANCEL;
      },
    );
  }
}
