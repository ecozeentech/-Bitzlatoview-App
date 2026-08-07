import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/webview_provider.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/webview_screen.dart';

class BitzlatoviewApp extends StatefulWidget {
  const BitzlatoviewApp({
    super.key,
    this.initialDeepLink,
  });

  final String? initialDeepLink;

  @override
  State<BitzlatoviewApp> createState() => _BitzlatoviewAppState();
}

class _BitzlatoviewAppState extends State<BitzlatoviewApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => WebViewScreen(
            initialUrl: state.uri.queryParameters['url'] ?? widget.initialDeepLink,
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WebViewProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: _AppInitializer(
        child: MaterialApp.router(
          title: 'Bitzlatoview',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          routerConfig: _router,
        ),
      ),
    );
  }
}

class _AppInitializer extends StatefulWidget {
  const _AppInitializer({required this.child});

  final Widget child;

  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  NotificationProvider? _notificationProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _notificationProvider = context.read<NotificationProvider>();
      await _notificationProvider!.initialize();
      _notificationProvider!.addListener(_onNotification);
    });
  }

  void _onNotification() {
    if (!mounted) return;
    final payload = context.read<NotificationProvider>().latestNotification;
    if (payload != null) {
      context.read<WebViewProvider>().handlePushNotification(payload.toJson());
      context.read<NotificationProvider>().clearLatest();
    }
  }

  @override
  void dispose() {
    _notificationProvider?.removeListener(_onNotification);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
