import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bitzlatoview_mobile/config/theme.dart';
import 'package:bitzlatoview_mobile/providers/auth_provider.dart';
import 'package:bitzlatoview_mobile/providers/webview_provider.dart';
import 'package:bitzlatoview_mobile/screens/offline_screen.dart';
import 'package:bitzlatoview_mobile/screens/settings_screen.dart';
import 'package:bitzlatoview_mobile/screens/splash_screen.dart';
import 'package:bitzlatoview_mobile/widgets/bitzlatoview_logo.dart';

Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => WebViewProvider()),
    ],
    child: MaterialApp(theme: AppTheme.darkTheme, home: child),
  );
}

void main() {
  group('OfflineScreen', () {
    testWidgets('displays offline message and retry button', (tester) async {
      var retried = false;

      await tester.pumpWidget(
        _wrap(OfflineScreen(onRetry: () => retried = true)),
      );

      expect(find.text('No Internet Connection'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retried, isTrue);
    });
  });

  group('SplashScreen', () {
    testWidgets('shows branded splash content', (tester) async {
      await tester.pumpWidget(_wrap(const SplashScreen()));

      expect(find.byType(BitzlatoviewLogo), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('SettingsScreen', () {
    testWidgets('shows legal and account sections', (tester) async {
      await tester.pumpWidget(_wrap(const SettingsScreen()));

      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Risk Disclosure'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });
  });
}
