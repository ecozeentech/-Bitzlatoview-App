import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/constants.dart';

class CookieService {
  CookieService({
    FlutterSecureStorage? secureStorage,
    CookieManager? cookieManager,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _cookieManager = cookieManager ?? CookieManager.instance();

  final FlutterSecureStorage _secureStorage;
  final CookieManager _cookieManager;

  static final WebUri _baseWebUri = WebUri(AppConstants.baseUrl);

  Future<void> saveCookies({InAppWebViewController? webViewController}) async {
    final cookies = await _cookieManager.getCookies(
      url: _baseWebUri,
      webViewController: webViewController,
    );

    final serialized = cookies
        .map(
          (cookie) => {
            'name': cookie.name,
            'value': cookie.value,
            'domain': cookie.domain,
            'path': cookie.path,
            'expiresDate': cookie.expiresDate,
            'isSecure': cookie.isSecure,
            'isHttpOnly': cookie.isHttpOnly,
            'sameSite': cookie.sameSite?.toValue(),
          },
        )
        .toList();

    await _secureStorage.write(
      key: AppConstants.cookieStorageKey,
      value: jsonEncode(serialized),
    );
  }

  Future<void> restoreCookies({InAppWebViewController? webViewController}) async {
    final stored = await _secureStorage.read(key: AppConstants.cookieStorageKey);
    if (stored == null || stored.isEmpty) return;

    final List<dynamic> cookies = jsonDecode(stored) as List<dynamic>;
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final raw in cookies) {
      final map = Map<String, dynamic>.from(raw as Map);
      final expiresDate = map['expiresDate'] as int?;
      if (expiresDate != null && expiresDate <= now) {
        continue;
      }

      await _cookieManager.setCookie(
        url: _baseWebUri,
        name: map['name'] as String,
        value: map['value'] as String,
        domain: map['domain'] as String?,
        path: map['path'] as String? ?? '/',
        expiresDate: expiresDate,
        isSecure: map['isSecure'] as bool? ?? true,
        isHttpOnly: map['isHttpOnly'] as bool? ?? false,
        sameSite: _parseSameSite(map['sameSite'] as String?),
        webViewController: webViewController,
      );
    }
  }

  Future<void> clearCookies({InAppWebViewController? webViewController}) async {
    await _cookieManager.deleteCookies(
      url: _baseWebUri,
      webViewController: webViewController,
    );
    await _secureStorage.delete(key: AppConstants.cookieStorageKey);
  }

  HTTPCookieSameSitePolicy? _parseSameSite(String? value) {
    if (value == null) return HTTPCookieSameSitePolicy.LAX;
    return HTTPCookieSameSitePolicy.fromValue(value) ??
        HTTPCookieSameSitePolicy.LAX;
  }
}
