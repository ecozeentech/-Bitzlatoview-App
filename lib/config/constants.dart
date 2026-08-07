/// Application-wide constants for Bitzlatoview Mobile.
class AppConstants {
  AppConstants._();

  static const String appName = 'Bitzlatoview';
  static const String appPackage = 'com.bitzlatoview.bitzlatoview_mobile';

  /// Primary web platform URL rendered inside the WebView.
  static const String baseUrl = 'https://app.bitzlatoview.com';

  /// Legal / compliance pages (served by the web platform).
  static const String privacyPolicyUrl = '$baseUrl/privacy';
  static const String termsOfServiceUrl = '$baseUrl/terms';
  static const String riskDisclosureUrl = '$baseUrl/risk-disclosure';
  static const String supportUrl = '$baseUrl/support';
  static const String supportEmail = 'support@bitzlatoview.com';

  /// Domains allowed to load inside the WebView.
  static const List<String> allowedHosts = [
    'app.bitzlatoview.com',
    'bitzlatoview.com',
    'www.bitzlatoview.com',
  ];

  /// JavaScript bridge channel name expected by the web platform.
  static const String jsBridgeChannel = 'BitzlatoviewBridge';

  /// Secure storage keys.
  static const String cookiesStorageKey = 'bv_session_cookies';
  static const String fcmTokenStorageKey = 'bv_fcm_token';
  static const String biometricEnabledKey = 'bv_biometric_enabled';

  /// Shared preferences keys.
  static const String firstLaunchKey = 'bv_first_launch';
  static const String lastUrlKey = 'bv_last_url';

  /// Deep link schemes / hosts.
  static const String deepLinkHost = 'app.bitzlatoview.com';
  static const String deepLinkScheme = 'bitzlatoview';

  /// Splash minimum display duration.
  static const Duration splashMinDuration = Duration(milliseconds: 1200);

  /// Connectivity / reload debounce.
  static const Duration connectivityDebounce = Duration(milliseconds: 800);
}
