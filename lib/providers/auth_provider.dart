import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../services/cookie_service.dart';
import '../utils/helpers.dart';

/// Tracks the (web) session state and the optional biometric app-lock, and
/// centralizes logout / cache-clearing so both the Settings screen and any
/// future flows (e.g. session expiry detected by the WebView) share one
/// code path.
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    CookieService? cookieService,
    LocalAuthentication? localAuth,
  })  : _cookieService = cookieService ?? CookieService(),
        _localAuth = localAuth ?? LocalAuthentication();

  final CookieService _cookieService;
  final LocalAuthentication _localAuth;

  bool _hasSession = false;
  bool _biometricLockEnabled = false;
  bool _unlockedThisLaunch = false;

  bool get hasSession => _hasSession;
  bool get biometricLockEnabled => _biometricLockEnabled;

  /// Whether the app-lock screen should currently block WebView content.
  bool get requiresUnlock => _biometricLockEnabled && !_unlockedThisLaunch;

  Future<void> initialize() async {
    _hasSession = await _cookieService.hasStoredSession();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _biometricLockEnabled =
        prefs.getBool(AppConstants.secureStorageBiometricEnabledKey) ?? false;
    notifyListeners();
  }

  /// Called after the WebView successfully loads an authenticated page, so
  /// we can back up the freshly-issued session cookies.
  Future<void> onSessionEstablished() async {
    await _cookieService.backupCookies();
    _hasSession = true;
    notifyListeners();
  }

  Future<bool> canUseBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics && await _localAuth.isDeviceSupported();
    } catch (e) {
      Helpers.debugLog('Biometric availability check failed: $e');
      return false;
    }
  }

  Future<void> setBiometricLockEnabled(bool enabled) async {
    _biometricLockEnabled = enabled;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.secureStorageBiometricEnabledKey, enabled);
    notifyListeners();
  }

  Future<bool> unlock({String reason = 'Unlock Bitzlatoview'}) async {
    if (!_biometricLockEnabled) {
      _unlockedThisLaunch = true;
      return true;
    }
    try {
      final bool ok = await _localAuth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
      _unlockedThisLaunch = ok;
      notifyListeners();
      return ok;
    } catch (e) {
      Helpers.debugLog('Biometric unlock failed: $e');
      return false;
    }
  }

  /// Clears the session (cookies) but keeps app preferences like the
  /// biometric-lock setting intact.
  Future<void> logout() async {
    await _cookieService.clearAll();
    _hasSession = false;
    notifyListeners();
  }

  /// Full reset used by "Clear cache" in Settings.
  Future<void> clearAllLocalData() async {
    await _cookieService.clearAll();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _hasSession = false;
    _biometricLockEnabled = false;
    notifyListeners();
  }

  CookieService get cookieService => _cookieService;
}
