import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:webview_cookie_manager_plus/webview_cookie_manager_plus.dart';

import '../config/constants.dart';

class CookieService {
  CookieService({
    FlutterSecureStorage? secureStorage,
    WebviewCookieManager? cookieManager,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _cookieManager = cookieManager ?? WebviewCookieManager();

  final FlutterSecureStorage _secureStorage;
  final WebviewCookieManager _cookieManager;

  Future<void> saveCookies() async {
    final cookies = await _cookieManager.getCookies(AppConstants.baseUrl);
    final serialized = cookies
        .map((cookie) => {
              'name': cookie.name,
              'value': cookie.value,
              'domain': cookie.domain,
              'path': cookie.path,
              'expires': cookie.expires?.millisecondsSinceEpoch,
              'secure': cookie.secure,
              'httpOnly': cookie.httpOnly,
            })
        .toList();
    await _secureStorage.write(
      key: AppConstants.cookieStorageKey,
      value: jsonEncode(serialized),
    );
  }

  Future<void> restoreCookies() async {
    final stored = await _secureStorage.read(key: AppConstants.cookieStorageKey);
    if (stored == null || stored.isEmpty) return;

    final List<dynamic> cookies = jsonDecode(stored) as List<dynamic>;
    final restored = <Cookie>[];
    for (final raw in cookies) {
      final map = Map<String, dynamic>.from(raw as Map);
      final cookie = Cookie(
        map['name'] as String,
        map['value'] as String,
      )
        ..domain = map['domain'] as String? ?? AppConstants.deepLinkHost
        ..path = map['path'] as String? ?? '/'
        ..secure = map['secure'] as bool? ?? true
        ..httpOnly = map['httpOnly'] as bool? ?? false;

      final expires = map['expires'] as int?;
      if (expires != null) {
        cookie.expires = DateTime.fromMillisecondsSinceEpoch(expires);
      }
      restored.add(cookie);
    }

    if (restored.isNotEmpty) {
      await _cookieManager.setCookies(restored, origin: AppConstants.baseUrl);
    }
  }

  Future<void> clearCookies() async {
    await _cookieManager.clearCookies();
    await _secureStorage.delete(key: AppConstants.cookieStorageKey);
  }
}
