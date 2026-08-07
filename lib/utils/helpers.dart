import 'dart:convert';

import 'package:flutter/foundation.dart';

/// General-purpose helpers shared across services, providers and screens.
class Helpers {
  Helpers._();

  /// Encodes [value] as JSON, tolerating values that are already Strings.
  static String encodeJson(Object? value) {
    if (value is String) return value;
    return jsonEncode(value);
  }

  /// Safely decodes a JSON string, returning an empty map on failure instead
  /// of throwing - the JS bridge must never crash the app because the web
  /// page sent a malformed payload.
  static Map<String, dynamic> tryDecodeJsonMap(String source) {
    try {
      final Object? decoded = jsonDecode(source);
      if (decoded is Map) return decoded.cast<String, dynamic>();
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// Logs [message] only in debug builds so release binaries never leak
  /// potentially sensitive diagnostic output (see security requirements:
  /// "No sensitive data logging").
  static void debugLog(String message, {String tag = 'Bitzlatoview'}) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  /// Escapes a string for safe interpolation inside a JavaScript template
  /// literal / call, e.g. when injecting data back into the WebView via
  /// `runJavaScript`.
  static String jsStringLiteral(String value) {
    final String escaped = jsonEncode(value);
    return escaped;
  }
}
