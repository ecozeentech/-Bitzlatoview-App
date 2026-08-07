import 'dart:async';

import 'package:app_links/app_links.dart';

import '../config/constants.dart';
import '../utils/helpers.dart';
import '../utils/validators.dart';

/// Wraps `app_links` to surface Universal Links (iOS) / App Links (Android)
/// as validated `Uri`s the app can hand off to the WebView.
///
/// Only links pointing at [AppConstants.allowedNavigationHosts] are ever
/// forwarded - anything else is dropped, since the deep link target
/// ultimately becomes a URL the WebView will load.
class DeepLinkService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;
  final StreamController<Uri> _linkController = StreamController<Uri>.broadcast();

  /// Emits every valid deep link received while the app is running.
  Stream<Uri> get onLink => _linkController.stream;

  /// Initializes the listener and, if the app was cold-started from a link,
  /// emits that link too.
  Future<void> initialize() async {
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handleUri(initialUri);
    } catch (e) {
      Helpers.debugLog('Failed to read initial deep link: $e');
    }

    _subscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object e) => Helpers.debugLog('Deep link stream error: $e'),
    );
  }

  void _handleUri(Uri uri) {
    if (!_isAllowed(uri)) {
      Helpers.debugLog('Ignoring deep link to disallowed host: $uri');
      return;
    }
    Helpers.debugLog('Received deep link: $uri');
    _linkController.add(uri);
  }

  bool _isAllowed(Uri uri) {
    // Custom scheme links (bitzlatoview://trade/123) are always allowed;
    // https links are restricted to the platform's own domains.
    if (AppConstants.deepLinkSchemes.contains(uri.scheme) && uri.scheme != 'https') {
      return true;
    }
    return Validators.isSafeHttpsUrl(
      uri.toString(),
      allowedHosts: AppConstants.allowedNavigationHosts,
    );
  }

  /// Converts an incoming deep link into the absolute web URL the WebView
  /// should load, e.g. `bitzlatoview://trade/123` -> `https://app.bitzlatoview.com/trade/123`.
  String resolveTargetUrl(Uri uri) {
    if (uri.scheme == 'https') return uri.toString();
    final String path = uri.host.isNotEmpty
        ? '/${uri.host}${uri.path}'
        : uri.path;
    return Uri.parse(AppConstants.baseUrl)
        .replace(path: path.isEmpty ? '/' : path, query: uri.query.isEmpty ? null : uri.query)
        .toString();
  }

  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_linkController.close());
  }
}
