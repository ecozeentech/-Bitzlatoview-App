import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/constants.dart';
import 'validators.dart';

/// General-purpose helpers.
class Helpers {
  Helpers._();

  /// Returns true if [url] should stay inside the in-app WebView.
  static bool shouldHandleInternally(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (uri.scheme == 'about' || uri.scheme == 'data' || uri.scheme == 'blob') {
      return true;
    }
    return Validators.isAllowedHost(uri.host, AppConstants.allowedHosts);
  }

  /// Opens an external URL in the system browser / handler.
  static Future<bool> openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    try {
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Helpers.openExternal error: $e');
    }
    return false;
  }

  static Future<void> openMailto(String email, {String? subject}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: subject != null ? {'subject': subject} : null,
    );
    await openExternal(uri.toString());
  }

  /// Redacts sensitive values from debug logs.
  static String redact(String? value) {
    if (value == null || value.isEmpty) return '';
    if (value.length <= 8) return '***';
    return '${value.substring(0, 4)}…${value.substring(value.length - 4)}';
  }
}
