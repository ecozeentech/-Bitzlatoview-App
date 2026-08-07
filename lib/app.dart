import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/constants.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/webview_provider.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';
import 'services/deep_link_service.dart';

/// Root widget: wires up all providers (state management) and the
/// `go_router` route table (splash -> home), and applies the app-wide dark
/// / gold theme.
class BitzlatoviewApp extends StatefulWidget {
  const BitzlatoviewApp({super.key});

  @override
  State<BitzlatoviewApp> createState() => _BitzlatoviewAppState();
}

class _BitzlatoviewAppState extends State<BitzlatoviewApp> {
  late final DeepLinkService _deepLinkService = DeepLinkService();
  late final GoRouter _router = _buildRouter();

  GoRouter _buildRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => SplashScreen(
            onReady: () => context.go('/home'),
          ),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => MainShell(
            initialUrl: state.uri.queryParameters['url'],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
        ChangeNotifierProvider<WebViewProvider>(create: (_) => WebViewProvider()),
        Provider<DeepLinkService>.value(value: _deepLinkService),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        routerConfig: _router,
      ),
    );
  }
}
