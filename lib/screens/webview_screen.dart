import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../models/webview_events.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/webview_provider.dart';
import '../services/deep_link_service.dart';
import '../services/js_bridge_service.dart';
import '../utils/helpers.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_indicator.dart';
import 'offline_screen.dart';
import 'settings_screen.dart';
import 'splash_screen.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({
    super.key,
    this.initialUrl,
  });

  final String? initialUrl;

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  final JsBridgeService _bridgeService = JsBridgeService();
  final DeepLinkService _deepLinkService = DeepLinkService();

  late final String _initialUrl;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialUrl = widget.initialUrl ?? AppConstants.baseUrl;
    _initialize();
  }

  Future<void> _initialize() async {
    await context.read<AuthProvider>().restoreSession();
    await _deepLinkService.initialize();
    final resolved = _deepLinkService.resolveInitialUrl(_initialUrl);
    if (resolved != _initialUrl && mounted) {
      context.read<WebViewProvider>().loadUrl(resolved);
    }

    _deepLinkService.linkStream.listen((uri) {
      if (mounted) {
        context.read<WebViewProvider>().loadUrl(uri.toString());
      }
    });

    Connectivity().onConnectivityChanged.listen((results) {
      final isOffline = results.every(
        (result) => result == ConnectivityResult.none,
      );
      if (mounted) {
        context.read<WebViewProvider>().setOffline(isOffline);
      }
    });

    final connectivity = await Connectivity().checkConnectivity();
    final isOffline = connectivity.every(
      (result) => result == ConnectivityResult.none,
    );
    if (mounted) {
      context.read<WebViewProvider>().setOffline(isOffline);
      setState(() => _initialized = true);
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _deepLinkService.dispose();
    super.dispose();
  }

  Future<void> _handleBridgeMessage(String message) async {
    final webViewProvider = context.read<WebViewProvider>();
    try {
      final Map<String, dynamic> data =
          jsonDecode(message) as Map<String, dynamic>;
      final action = BridgeAction.fromJson(data);
      final response = await _bridgeService.handleAction(action);
      final script = '''
        if (window.handleNativeBridgeResponse) {
          window.handleNativeBridgeResponse(${jsonEncode(response.toJson())});
        }
      ''';
      await webViewProvider.runJavaScript(script);
    } catch (e) {
      debugPrint('Bridge error: $e');
    }
  }

  Future<void> _onRefresh() async {
    await context.read<WebViewProvider>().reload();
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SplashScreen();
    }

    return Consumer<WebViewProvider>(
      builder: (context, webViewProvider, _) {
        if (webViewProvider.isOffline) {
          return OfflineScreen(
            onRetry: () async {
              final connectivity = await Connectivity().checkConnectivity();
              final isOffline = connectivity.every(
                (result) => result == ConnectivityResult.none,
              );
              webViewProvider.setOffline(isOffline);
              if (!isOffline) await webViewProvider.reload();
            },
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.darkBackground,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            toolbarHeight: 48,
            title: const SizedBox.shrink(),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              SmartRefresher(
                controller: _refreshController,
                enablePullDown: true,
                onRefresh: _onRefresh,
                header: const WaterDropMaterialHeader(
                  backgroundColor: AppTheme.darkSurface,
                  color: AppTheme.primaryGold,
                ),
                child: InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri(_initialUrl),
                  ),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    domStorageEnabled: true,
                    databaseEnabled: true,
                    cacheEnabled: true,
                    cacheMode: CacheMode.LOAD_DEFAULT,
                    mediaPlaybackRequiresUserGesture: false,
                    allowsInlineMediaPlayback: true,
                    useHybridComposition: true,
                    transparentBackground: true,
                  ),
                  onWebViewCreated: (controller) {
                    webViewProvider.setController(controller);
                    controller.addJavaScriptHandler(
                      handlerName: AppConstants.jsBridgeName,
                      callback: (args) {
                        if (args.isNotEmpty) {
                          _handleBridgeMessage(args.first.toString());
                        }
                      },
                    );
                  },
                  onLoadStart: (controller, url) {
                    webViewProvider.onLoadStart(url?.toString());
                  },
                  onProgressChanged: (controller, progress) {
                    webViewProvider.onProgress(progress);
                  },
                  onLoadStop: (controller, url) async {
                    final authProvider = context.read<AuthProvider>();
                    final notificationProvider =
                        context.read<NotificationProvider>();
                    webViewProvider.onLoadStop(url?.toString());
                    await authProvider.persistSession();
                    await controller.evaluateJavascript(
                      source: Helpers.getBridgeInjectionScript(),
                    );

                    final fcmToken = notificationProvider.fcmToken;
                    if (fcmToken != null) {
                      await controller.evaluateJavascript(
                        source:
                            "if (window.registerFCMToken) window.registerFCMToken('$fcmToken');",
                      );
                    }
                  },
                  onReceivedError: (controller, request, error) {
                    webViewProvider.onError(error.description);
                  },
                  shouldOverrideUrlLoading: (controller, navigationAction) async {
                    final uri = navigationAction.request.url;
                    if (uri == null) return NavigationActionPolicy.CANCEL;
                    return Helpers.shouldAllowNavigation(Uri.parse(uri.toString()));
                  },
                ),
              ),
              if (webViewProvider.loadState.isLoading &&
                  webViewProvider.loadState.progress < 1)
                LoadingIndicator(
                  progress: webViewProvider.loadState.progress,
                  message: 'Loading...',
                ),
              if (webViewProvider.loadState.errorMessage != null)
                AppErrorWidget(
                  message: webViewProvider.loadState.errorMessage!,
                  onRetry: () => webViewProvider.reload(),
                ),
              if (webViewProvider.showSplash)
                const SplashScreen(),
            ],
          ),
        );
      },
    );
  }
}
