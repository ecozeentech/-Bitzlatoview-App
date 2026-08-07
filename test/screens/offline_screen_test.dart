import 'package:bitzlatoview_mobile/config/theme.dart';
import 'package:bitzlatoview_mobile/screens/offline_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const MethodChannel connectivityMethodChannel =
      MethodChannel('dev.fluttercommunity.plus/connectivity');
  const EventChannel connectivityEventChannel =
      EventChannel('dev.fluttercommunity.plus/connectivity_status');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityMethodChannel, (call) async {
      if (call.method == 'check') return <String>['none'];
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(connectivityEventChannel, _NoOpMockStreamHandler());
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityMethodChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(connectivityEventChannel, null);
  });

  testWidgets('shows the offline message and a retry button', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: OfflineScreen(onRetry: () => retried = true),
      ),
    );
    await tester.pump();

    expect(find.text("You're offline"), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

    await tester.tap(find.text('Retry now'));
    await tester.pump();
    expect(retried, isTrue);
  });
}

class _NoOpMockStreamHandler extends MockStreamHandler {
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {}

  @override
  void onCancel(Object? arguments) {}
}
