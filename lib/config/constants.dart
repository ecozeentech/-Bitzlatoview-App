/// Centralized, immutable configuration for the Bitzlatoview mobile app.
///
/// Keeping every URL, key and identifier in one place makes it trivial to
/// point a build at a staging environment or rotate a storage key without
/// hunting through the codebase.
library;

class AppConstants {
  AppConstants._();

  // ---------------------------------------------------------------------
  // Branding
  // ---------------------------------------------------------------------
  static const String appName = 'Bitzlatoview';

  // ---------------------------------------------------------------------
  // Web platform
  // ---------------------------------------------------------------------
  static const String baseUrl = 'https://app.bitzlatoview.com';
  static const String loginPath = '/login';
  static const String dashboardPath = '/dashboard';

  static const String privacyPolicyUrl = '$baseUrl/legal/privacy-policy';
  static const String termsOfServiceUrl = '$baseUrl/legal/terms-of-service';
  static const String riskDisclosureUrl = '$baseUrl/legal/risk-disclosure';
  static const String supportUrl = '$baseUrl/support';
  static const String supportEmail = 'support@bitzlatoview.com';

  /// Domains the in-app WebView is allowed to navigate to without leaving
  /// the app. Anything else (e.g. an external payment provider or a
  /// mailto: link) is handed off to the OS / an external browser.
  static const List<String> allowedNavigationHosts = <String>[
    'app.bitzlatoview.com',
    'bitzlatoview.com',
    'www.bitzlatoview.com',
  ];

  // ---------------------------------------------------------------------
  // Deep linking (Universal Links / App Links)
  // ---------------------------------------------------------------------
  static const String deepLinkHost = 'app.bitzlatoview.com';
  static const List<String> deepLinkSchemes = <String>['https', 'bitzlatoview'];

  // ---------------------------------------------------------------------
  // Secure storage keys
  // ---------------------------------------------------------------------
  static const String secureStorageCookiesKey = 'bzv_session_cookies';
  static const String secureStorageAuthTokenKey = 'bzv_auth_token';
  static const String secureStorageBiometricEnabledKey = 'bzv_biometric_enabled';

  // ---------------------------------------------------------------------
  // Shared preferences keys
  // ---------------------------------------------------------------------
  static const String prefsFirstLaunchKey = 'bzv_first_launch';
  static const String prefsLastUrlKey = 'bzv_last_url';
  static const String prefsPushTokenKey = 'bzv_push_token';
  static const String prefsNotificationsEnabledKey = 'bzv_notifications_enabled';

  // ---------------------------------------------------------------------
  // JavaScript bridge
  // ---------------------------------------------------------------------
  static const String jsBridgeHandlerName = 'BitzlatoviewBridge';

  // ---------------------------------------------------------------------
  // Timeouts
  // ---------------------------------------------------------------------
  static const Duration pageLoadTimeout = Duration(seconds: 30);
  static const Duration splashMinimumDuration = Duration(milliseconds: 1400);
  static const Duration connectivityCheckInterval = Duration(seconds: 5);
}
