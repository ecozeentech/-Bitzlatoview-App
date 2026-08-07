/// Shared validators for URLs and bridge payloads.
class Validators {
  Validators._();

  static bool isAllowedHost(String? host, List<String> allowedHosts) {
    if (host == null || host.isEmpty) return false;
    final lower = host.toLowerCase();
    return allowedHosts.any(
      (allowed) => lower == allowed || lower.endsWith('.$allowed'),
    );
  }

  static bool isHttpsUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.scheme == 'https';
  }

  static bool isNonEmpty(String? value) =>
      value != null && value.trim().isNotEmpty;
}
