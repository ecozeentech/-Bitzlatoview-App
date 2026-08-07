import 'package:bitzlatoview_mobile/models/webview_events.dart';
import 'package:bitzlatoview_mobile/services/js_bridge_service.dart';
import 'package:bitzlatoview_mobile/services/notification_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart'
    show AuthMessages;
import 'package:package_info_plus/package_info_plus.dart';

class FakeLocalAuthentication implements LocalAuthentication {
  bool available = true;
  bool authenticateResult = true;

  @override
  Future<bool> get canCheckBiometrics async => available;

  @override
  Future<bool> isDeviceSupported() async => available;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<AuthMessages> authMessages = const <AuthMessages>[],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async =>
      authenticateResult;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeNotificationService implements NotificationService {
  bool granted = true;

  @override
  Future<bool> requestPermission() async => granted;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeLocalAuthentication localAuth;
  late FakeNotificationService notificationService;
  late JsBridgeService bridge;

  setUp(() {
    localAuth = FakeLocalAuthentication();
    notificationService = FakeNotificationService();
    bridge = JsBridgeService(
      localAuth: localAuth,
      notificationService: notificationService,
    );

    // Clipboard.setData goes through SystemChannels.platform - stub it so
    // copyToClipboard doesn't hit a real (unavailable in tests) platform.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') return null;
      return null;
    });

    PackageInfo.setMockInitialValues(
      appName: 'Bitzlatoview',
      packageName: 'com.bitzlatoview.bitzlatoview_mobile',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('unknown actions fail gracefully instead of throwing', () async {
    final response = await bridge.dispatch(
      const BridgeRequest(action: BridgeAction.unknown, requestId: 'r1'),
    );
    expect(response.success, isFalse);
    expect(response.requestId, 'r1');
    expect(response.error, isNotNull);
  });

  test('copyToClipboard reports success', () async {
    final response = await bridge.dispatch(
      const BridgeRequest(
        action: BridgeAction.copyToClipboard,
        params: {'text': 'BTCADDR123'},
        requestId: 'r2',
      ),
    );
    expect(response.success, isTrue);
    expect((response.data as Map)['copied'], isTrue);
  });

  test('getDeviceInfo returns platform + app version metadata', () async {
    final response = await bridge.dispatch(
      const BridgeRequest(action: BridgeAction.getDeviceInfo, requestId: 'r3'),
    );
    expect(response.success, isTrue);
    final data = response.data as Map;
    expect(data['appVersion'], '1.0.0');
    expect(data['packageName'], 'com.bitzlatoview.bitzlatoview_mobile');
  });

  test('biometricAuthenticate returns unsupported when unavailable', () async {
    localAuth.available = false;
    final response = await bridge.dispatch(
      const BridgeRequest(action: BridgeAction.biometricAuthenticate, requestId: 'r4'),
    );
    expect(response.success, isTrue);
    expect((response.data as Map)['authenticated'], isFalse);
    expect((response.data as Map)['reason'], 'unsupported');
  });

  test('biometricAuthenticate forwards the authentication result', () async {
    localAuth.available = true;
    localAuth.authenticateResult = true;
    final response = await bridge.dispatch(
      const BridgeRequest(action: BridgeAction.biometricAuthenticate, requestId: 'r5'),
    );
    expect((response.data as Map)['authenticated'], isTrue);
  });

  test('requestNotificationPermission delegates to NotificationService', () async {
    notificationService.granted = false;
    final response = await bridge.dispatch(
      const BridgeRequest(
        action: BridgeAction.requestNotificationPermission,
        requestId: 'r6',
      ),
    );
    expect((response.data as Map)['granted'], isFalse);
  });
}
