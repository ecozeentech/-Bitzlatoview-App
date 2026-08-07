import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/webview_provider.dart';
import '../services/deep_link_service.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_indicator.dart';
import 'offline_screen.dart';

/// Primary screen that renders the Bitzlatoview web platform in a WebView.
class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key, this.initialUrl});

  final String? initialUrl;

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  WebViewController? _controller;
  late final DeepLinkService _deepLinkService;
  StreamSubscription<Uri>? _deepLinkSub;
  bool _controllerReady = false;

  @override
  void initState() {
    super.initState();
    _deepLinkService = DeepLinkService();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final webView = context.read<WebViewProvider>();
    final auth = context.read<AuthProvider>();
    final notifications = context.read<NotificationProvider>();

    final startUrl =
        widget.initialUrl ?? auth.lastUrl ?? AppConstants.baseUrl;

    await webView.initialize(initialUrl: startUrl);
    await _createController(startUrl);

    await _deepLinkService.initialize();
    _deepLinkSub = _deepLinkService.linkStream.listen((uri) {
      webView.loadUrl(uri.toString());
    });

    notifications.service.onNotificationTap.listen((payload) {
      final url = payload['url'] as String? ?? payload['link'] as String?;
      if (url != null) {
        webView.loadUrl(url);
      } else {
        webView.bridgeService.injectPushNotification(payload);
      }
    });
  }

  Future<void> _createController(String startUrl) async {
    final webView = context.read<WebViewProvider>();
    final auth = context.read<AuthProvider>();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: webView.onPageStarted,
          onProgress: webView.onProgress,
          onPageFinished: (url) async {
            await webView.onPageFinished(url);
            await auth.persistSession();
            await auth.saveLastUrl(url);
          },
          onWebResourceError: webView.onWebResourceError,
          onNavigationRequest: webView.navigationDelegate,
        ),
      )
      ..addJavaScriptChannel(
        AppConstants.jsBridgeChannel,
        onMessageReceived: (message) {
          webView.bridgeService.handleMessage(message.message);
        },
      );

    if (controller.platform is AndroidWebViewController) {
      final android = controller.platform as AndroidWebViewController;
      await android.setMediaPlaybackRequiresUserGesture(false);
      AndroidWebViewController.enableDebugging(false);
    }

    if (controller.platform is WebKitWebViewController) {
      final ios = controller.platform as WebKitWebViewController;
      ios.setAllowsBackForwardNavigationGestures(true);
    }

    webView.attachController(controller);
    await controller.loadRequest(Uri.parse(startUrl));

    if (!mounted) return;
    setState(() {
      _controller = controller;
      _controllerReady = true;
    });
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    _deepLinkService.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context.read<WebViewProvider>().reload();
  }

  @override
  Widget build(BuildContext context) {
    final webView = context.watch<WebViewProvider>();

    if (webView.isOffline) {
      return OfflineScreen(onRetry: () => webView.reload());
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: webView.isLoading ? null : _onRefresh,
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
        bottom: webView.isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: webView.progress > 0 && webView.progress < 100
                      ? webView.progress / 100
                      : null,
                  minHeight: 2,
                  color: AppTheme.gold,
                  backgroundColor: AppTheme.border,
                ),
              )
            : null,
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (_controller != null && await _controller!.canGoBack()) {
            await _controller!.goBack();
          }
        },
        child: _buildBody(webView),
      ),
    );
  }

  Widget _buildBody(WebViewProvider webView) {
    if (!_controllerReady || _controller == null) {
      return const LoadingIndicator(message: 'Loading Bitzlatoview…');
    }

    if (webView.loadState == WebViewLoadState.error &&
        webView.errorMessage != null) {
      return AppErrorWidget(
        message: webView.errorMessage!,
        onRetry: () => webView.reload(),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller!),
        if (webView.isLoading && webView.progress < 15)
          const ColoredBox(
            color: AppTheme.background,
            child: LoadingIndicator(message: 'Loading…'),
          ),
      ],
    );
  }
}
