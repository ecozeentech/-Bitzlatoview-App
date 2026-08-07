/// Small, dependency-free validation helpers used across the app.
class Validators {
  Validators._();

  static final RegExp _emailRegExp = RegExp(
    r'^[\w\.\-+]+@([\w\-]+\.)+[\w\-]{2,}$',
  );

  /// Whether [value] looks like a syntactically valid email address.
  static bool isValidEmail(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    return _emailRegExp.hasMatch(value.trim());
  }

  /// Whether [url] is an `https` URL, optionally restricted to one of
  /// [allowedHosts]. Used before letting the WebView (or an external
  /// browser) navigate to a URL originating from a deep link or the bridge.
  static bool isSafeHttpsUrl(String? url, {List<String> allowedHosts = const []}) {
    if (url == null || url.isEmpty) return false;
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || !uri.isAbsolute) return false;
    if (uri.scheme != 'https') return false;
    if (allowedHosts.isEmpty) return true;
    return allowedHosts.any(
      (host) => uri.host == host || uri.host.endsWith('.$host'),
    );
  }

  /// Whether [json] parses to a non-null `Map<String, dynamic>`.
  static bool isNonEmptyMap(Object? json) {
    return json is Map && json.isNotEmpty;
  }
}
