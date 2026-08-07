import 'package:bitzlatoview_mobile/providers/auth_provider.dart';
import 'package:bitzlatoview_mobile/services/cookie_service.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart'
    show AuthMessages;
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory stand-in for [CookieService] so tests never touch the real
/// (platform-channel backed) secure storage or WebView cookie jar.
class FakeCookieService implements CookieService {
  bool storedSession = false;
  bool backedUp = false;
  bool cleared = false;

  @override
  Future<void> backupCookies({String? url}) async {
    backedUp = true;
    storedSession = true;
  }

  @override
  Future<void> clearAll() async {
    cleared = true;
    storedSession = false;
  }

  @override
  Future<bool> hasStoredSession() async => storedSession;

  @override
  Future<List<Cookie>> getCookies({String? url}) async => <Cookie>[];

  @override
  Future<bool> restoreCookies() async => false;

  @override
  Future<void> setCookie({
    required String name,
    required String value,
    String? url,
    String? domain,
    String path = '/',
    bool isSecure = true,
    bool isHttpOnly = false,
  }) async {}
}

/// Controllable fake for [LocalAuthentication] biometric checks.
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late FakeCookieService cookieService;
  late FakeLocalAuthentication localAuth;
  late AuthProvider provider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cookieService = FakeCookieService();
    localAuth = FakeLocalAuthentication();
    provider = AuthProvider(cookieService: cookieService, localAuth: localAuth);
  });

  test('initialize picks up an existing stored session', () async {
    cookieService.storedSession = true;
    await provider.initialize();
    expect(provider.hasSession, isTrue);
    expect(provider.biometricLockEnabled, isFalse);
  });

  test('onSessionEstablished backs up cookies and flips hasSession on', () async {
    await provider.initialize();
    expect(provider.hasSession, isFalse);

    await provider.onSessionEstablished();
    expect(cookieService.backedUp, isTrue);
    expect(provider.hasSession, isTrue);
  });

  test('logout clears cookies and hasSession', () async {
    await provider.onSessionEstablished();
    await provider.logout();
    expect(cookieService.cleared, isTrue);
    expect(provider.hasSession, isFalse);
  });

  test('requiresUnlock is false until biometric lock is enabled', () async {
    await provider.initialize();
    expect(provider.requiresUnlock, isFalse);

    await provider.setBiometricLockEnabled(true);
    expect(provider.requiresUnlock, isTrue);
  });

  test('unlock() clears requiresUnlock only on successful authentication', () async {
    await provider.setBiometricLockEnabled(true);
    localAuth.authenticateResult = false;
    expect(await provider.unlock(), isFalse);
    expect(provider.requiresUnlock, isTrue);

    localAuth.authenticateResult = true;
    expect(await provider.unlock(), isTrue);
    expect(provider.requiresUnlock, isFalse);
  });

  test('canUseBiometrics reflects device availability', () async {
    localAuth.available = false;
    expect(await provider.canUseBiometrics(), isFalse);
    localAuth.available = true;
    expect(await provider.canUseBiometrics(), isTrue);
  });

  test('clearAllLocalData resets session and biometric lock', () async {
    await provider.setBiometricLockEnabled(true);
    await provider.onSessionEstablished();

    await provider.clearAllLocalData();

    expect(cookieService.cleared, isTrue);
    expect(provider.hasSession, isFalse);
    expect(provider.biometricLockEnabled, isFalse);
  });
}
