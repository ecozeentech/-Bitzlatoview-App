import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:webview_cookie_manager_plus/webview_cookie_manager_plus.dart';

import '../config/constants.dart';

/// Persists WebView session cookies securely across app restarts.
class CookieService {
  CookieService({
    FlutterSecureStorage? storage,
    WebviewCookieManager? cookieManager,
  })  : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            ),
        _cookieManager = cookieManager ?? WebviewCookieManager();

  final FlutterSecureStorage _storage;
  final WebviewCookieManager _cookieManager;

  /// Reads cookies from the WebView and stores them encrypted.
  Future<void> persistCookies({String url = AppConstants.baseUrl}) async {
    try {
      final cookies = await _cookieManager.getCookies(url);
      final serializable = cookies
          .map(
            (c) => {
              'name': c.name,
              'value': c.value,
              'domain': c.domain,
              'path': c.path,
              'secure': c.secure,
              'httpOnly': c.httpOnly,
              if (c.expires != null)
                'expires': c.expires!.millisecondsSinceEpoch,
            },
          )
          .toList();
      await _storage.write(
        key: AppConstants.cookiesStorageKey,
        value: jsonEncode(serializable),
      );
    } catch (e) {
      debugPrint('CookieService.persistCookies error: $e');
    }
  }

  /// Restores previously saved cookies into the WebView cookie jar.
  Future<void> restoreCookies({String url = AppConstants.baseUrl}) async {
    try {
      final raw = await _storage.read(key: AppConstants.cookiesStorageKey);
      if (raw == null || raw.isEmpty) return;

      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      final cookies = <Cookie>[];
      for (final item in list) {
        if (item is! Map) continue;
        final map = item.cast<String, dynamic>();
        final name = map['name'] as String?;
        final value = map['value'] as String?;
        if (name == null || value == null) continue;

        final cookie = Cookie(name, value)
          ..domain = (map['domain'] as String?) ?? Uri.parse(url).host
          ..path = (map['path'] as String?) ?? '/'
          ..secure = (map['secure'] as bool?) ?? true
          ..httpOnly = (map['httpOnly'] as bool?) ?? false;

        final expiresMs = map['expires'] as int?;
        if (expiresMs != null) {
          cookie.expires = DateTime.fromMillisecondsSinceEpoch(expiresMs);
        }
        cookies.add(cookie);
      }

      if (cookies.isNotEmpty) {
        await _cookieManager.setCookies(cookies, origin: url);
      }
    } catch (e) {
      debugPrint('CookieService.restoreCookies error: $e');
    }
  }

  /// Clears WebView cookies and encrypted storage.
  Future<void> clearCookies() async {
    try {
      await _cookieManager.clearCookies();
      await _storage.delete(key: AppConstants.cookiesStorageKey);
    } catch (e) {
      debugPrint('CookieService.clearCookies error: $e');
    }
  }

  /// Returns whether any session cookies are currently stored.
  Future<bool> hasStoredSession() async {
    final raw = await _storage.read(key: AppConstants.cookiesStorageKey);
    return raw != null && raw.isNotEmpty;
  }
}
