import 'package:flutter/foundation.dart';
import '../services/cookie_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({CookieService? cookieService})
      : _cookieService = cookieService ?? CookieService();

  final CookieService _cookieService;
  bool _isSessionRestored = false;
  bool _isAuthenticated = false;

  bool get isSessionRestored => _isSessionRestored;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> restoreSession() async {
    await _cookieService.restoreCookies();
    _isSessionRestored = true;
    notifyListeners();
  }

  Future<void> persistSession() async {
    await _cookieService.saveCookies();
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await _cookieService.clearCookies();
    _isAuthenticated = false;
    notifyListeners();
  }
}
