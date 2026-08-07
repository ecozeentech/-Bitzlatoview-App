import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/webview_provider.dart';
import 'screens/offline_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/webview_screen.dart';

/// Root application widget with routing and providers.
class BitzlatoviewApp extends StatefulWidget {
  const BitzlatoviewApp({super.key});

  @override
  State<BitzlatoviewApp> createState() => _BitzlatoviewAppState();
}

class _BitzlatoviewAppState extends State<BitzlatoviewApp> {
  late final AuthProvider _authProvider;
  late final WebViewProvider _webViewProvider;
  late final NotificationProvider _notificationProvider;
  late final GoRouter _router;
  bool _showSplash = true;
  bool _servicesReady = false;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _webViewProvider = WebViewProvider();
    _notificationProvider = NotificationProvider();

    _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            final url = state.uri.queryParameters['url'];
            return WebViewScreen(initialUrl: url);
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/offline',
          builder: (context, state) => OfflineScreen(
            onRetry: () => context.go('/'),
          ),
        ),
      ],
    );

    _initServices();
  }

  Future<void> _initServices() async {
    await Future.wait([
      _authProvider.initialize(),
      _notificationProvider.initialize(),
    ]);
    if (mounted) {
      setState(() => _servicesReady = true);
    }
  }

  void _onSplashReady() {
    if (!_servicesReady) {
      // Wait a tick for services, then hide splash.
      Future<void>.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _showSplash = false);
      });
      return;
    }
    setState(() => _showSplash = false);
  }

  @override
  void dispose() {
    _authProvider.dispose();
    _webViewProvider.dispose();
    _notificationProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<WebViewProvider>.value(value: _webViewProvider),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: _notificationProvider,
        ),
      ],
      child: MaterialApp.router(
        title: 'Bitzlatoview',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        routerConfig: _router,
        builder: (context, child) {
          if (_showSplash) {
            return SplashScreen(onReady: _onSplashReady);
          }
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}
