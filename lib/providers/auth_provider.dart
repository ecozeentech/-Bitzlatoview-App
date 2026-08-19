import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../services/cookie_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({CookieService? cookieService})
      : _cookieService = cookieService ?? CookieService();

  final CookieService _cookieService;
  bool _isSessionRestored = false;
  bool _isAuthenticated = false;

  bool get isSessionRestored => _isSessionRestored;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> restoreSession({
    InAppWebViewController? webViewController,
  }) async {
    await _cookieService.restoreCookies(
      webViewController: webViewController,
    );
    _isSessionRestored = true;
    notifyListeners();
  }

  Future<void> persistSession({
    InAppWebViewController? webViewController,
  }) async {
    await _cookieService.saveCookies(
      webViewController: webViewController,
    );
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout({InAppWebViewController? webViewController}) async {
    await _cookieService.clearCookies(
      webViewController: webViewController,
    );
    _isAuthenticated = false;
    notifyListeners();
  }
}
