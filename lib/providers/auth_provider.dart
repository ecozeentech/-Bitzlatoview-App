import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../services/cookie_service.dart';

/// Manages authentication session state via secure cookie persistence.
class AuthProvider extends ChangeNotifier {
  AuthProvider({CookieService? cookieService})
      : _cookieService = cookieService ?? CookieService();

  final CookieService _cookieService;
  bool _initialized = false;
  bool _hasSession = false;
  String? _lastUrl;

  bool get isInitialized => _initialized;
  bool get hasSession => _hasSession;
  String? get lastUrl => _lastUrl;
  CookieService get cookieService => _cookieService;

  Future<void> initialize() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _lastUrl = prefs.getString(AppConstants.lastUrlKey);
    await _cookieService.restoreCookies();
    _hasSession = await _cookieService.hasStoredSession();
    _initialized = true;
    notifyListeners();
  }

  Future<void> persistSession() async {
    await _cookieService.persistCookies();
    _hasSession = await _cookieService.hasStoredSession();
    notifyListeners();
  }

  Future<void> saveLastUrl(String url) async {
    _lastUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.lastUrlKey, url);
  }

  Future<void> logout() async {
    await _cookieService.clearCookies();
    _hasSession = false;
    _lastUrl = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.lastUrlKey);
    notifyListeners();
  }
}
