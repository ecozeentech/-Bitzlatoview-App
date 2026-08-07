import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'
    show FlutterSecureStorage, KeychainAccessibility, IOSOptions;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as secure_storage
    show AndroidOptions;

import '../config/constants.dart';
import '../utils/helpers.dart';

/// Owns all cookie persistence for the WebView session.
///
/// `flutter_inappwebview` already persists cookies to native, on-disk
/// cookie storage (CookieManager on Android / WKHTTPCookieStore on iOS), so
/// the login session already survives an app restart. On top of that we
/// keep an *encrypted* backup of the session cookies in
/// [FlutterSecureStorage] so that:
///  - the app can restore the session even if the OS evicts the native
///    WebView cookie jar (e.g. low storage cleanup on some OEM Android
///    skins), and
///  - "Clear cache" in Settings can wipe everything deterministically.
///
/// No sensitive financial data is ever stored here - only the session
/// cookies required to keep the user signed in, which is the same data the
/// browser itself would hold.
class CookieService {
  CookieService({FlutterSecureStorage? secureStorage, CookieManager? cookieManager})
      :         _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: secure_storage.AndroidOptions(),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            ),
        _cookieManager = cookieManager ?? CookieManager.instance();

  final FlutterSecureStorage _secureStorage;
  final CookieManager _cookieManager;

  Uri get _baseUri => Uri.parse(AppConstants.baseUrl);

  /// Reads the live cookies from the WebView's native cookie jar.
  Future<List<Cookie>> getCookies({String? url}) {
    return _cookieManager.getCookies(url: WebUri(url ?? AppConstants.baseUrl));
  }

  /// Writes a single cookie into the native cookie jar (e.g. to seed a
  /// session token obtained outside the WebView).
  Future<void> setCookie({
    required String name,
    required String value,
    String? url,
    String? domain,
    String path = '/',
    bool isSecure = true,
    bool isHttpOnly = false,
  }) {
    return _cookieManager.setCookie(
      url: WebUri(url ?? AppConstants.baseUrl),
      name: name,
      value: value,
      domain: domain ?? _baseUri.host,
      path: path,
      isSecure: isSecure,
      isHttpOnly: isHttpOnly,
    );
  }

  /// Persists the current cookie jar into encrypted secure storage so it can
  /// be restored later even if the native cookie store is cleared.
  Future<void> backupCookies({String? url}) async {
    final List<Cookie> cookies = await getCookies(url: url);
    final List<Map<String, dynamic>> serialized = cookies
        .map(
          (cookie) => <String, dynamic>{
            'name': cookie.name,
            'value': cookie.value,
            'domain': cookie.domain,
            'path': cookie.path,
            'isSecure': cookie.isSecure,
          },
        )
        .toList();
    await _secureStorage.write(
      key: AppConstants.secureStorageCookiesKey,
      value: jsonEncode(serialized),
    );
    Helpers.debugLog('Backed up ${cookies.length} cookies to secure storage');
  }

  /// Restores cookies previously saved with [backupCookies] into the native
  /// WebView cookie jar. Safe to call before the first page load.
  Future<bool> restoreCookies() async {
    final String? raw = await _secureStorage.read(
      key: AppConstants.secureStorageCookiesKey,
    );
    if (raw == null || raw.isEmpty) return false;

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      for (final dynamic item in decoded) {
        final Map<String, dynamic> cookie = (item as Map).cast<String, dynamic>();
        await setCookie(
          name: cookie['name'] as String,
          value: cookie['value'] as String,
          domain: cookie['domain'] as String?,
          path: cookie['path'] as String? ?? '/',
          isSecure: cookie['isSecure'] as bool? ?? true,
        );
      }
      Helpers.debugLog('Restored ${decoded.length} cookies from secure storage');
      return decoded.isNotEmpty;
    } catch (e) {
      Helpers.debugLog('Failed to restore cookies: $e');
      return false;
    }
  }

  /// Whether a session cookie backup exists (used as a cheap "was the user
  /// logged in before?" heuristic without inspecting cookie contents).
  Future<bool> hasStoredSession() async {
    final String? raw = await _secureStorage.read(
      key: AppConstants.secureStorageCookiesKey,
    );
    return raw != null && raw.isNotEmpty;
  }

  /// Clears cookies from both the native WebView store and secure storage.
  /// Used by "Logout" and "Clear cache" in Settings.
  Future<void> clearAll() async {
    await _cookieManager.deleteAllCookies();
    await _secureStorage.delete(key: AppConstants.secureStorageCookiesKey);
    Helpers.debugLog('Cleared all cookies');
  }
}
