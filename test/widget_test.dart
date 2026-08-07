import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bitzlatoview_mobile/config/theme.dart';
import 'package:bitzlatoview_mobile/providers/auth_provider.dart';
import 'package:bitzlatoview_mobile/providers/webview_provider.dart';
import 'package:bitzlatoview_mobile/screens/offline_screen.dart';
import 'package:bitzlatoview_mobile/screens/settings_screen.dart';
import 'package:bitzlatoview_mobile/screens/splash_screen.dart';
import 'package:bitzlatoview_mobile/widgets/error_widget.dart';
import 'package:bitzlatoview_mobile/widgets/loading_indicator.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('SplashScreen shows brand name', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const SplashScreen(),
      ),
    );
    expect(find.text('Bitzlatoview'), findsOneWidget);
    expect(find.textContaining('Secure trading'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1300));
  });

  testWidgets('OfflineScreen shows retry CTA', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: OfflineScreen(onRetry: () => retried = true),
      ),
    );
    expect(find.text("You're offline"), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(retried, isTrue);
  });

  testWidgets('AppErrorWidget invokes retry', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: AppErrorWidget(
            message: 'Network failed',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );
    expect(find.text('Something went wrong'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(retried, isTrue);
  });

  testWidgets('LoadingIndicator renders optional message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LoadingIndicator(message: 'Please wait'),
        ),
      ),
    );
    expect(find.text('Please wait'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('SettingsScreen lists legal and app actions', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => WebViewProvider()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.dark,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Risk Disclosure'), findsOneWidget);
    expect(find.text('Clear Cache'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('App Version'), findsOneWidget);
  });
}
