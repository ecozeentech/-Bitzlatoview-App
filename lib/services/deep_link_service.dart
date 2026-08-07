import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../config/constants.dart';

/// Handles universal links / app links and custom scheme deep links.
class DeepLinkService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  final StreamController<Uri> _linkController =
      StreamController<Uri>.broadcast();

  StreamSubscription<Uri>? _sub;
  bool _initialized = false;

  Stream<Uri> get linkStream => _linkController.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null && isValidDeepLink(initial)) {
        _linkController.add(normalizeUri(initial));
      }
    } catch (e) {
      debugPrint('DeepLinkService initial link error: $e');
    }

    _sub = _appLinks.uriLinkStream.listen(
      (uri) {
        if (isValidDeepLink(uri)) {
          _linkController.add(normalizeUri(uri));
        }
      },
      onError: (Object e) {
        debugPrint('DeepLinkService stream error: $e');
      },
    );
  }

  /// Returns true when the URI targets the Bitzlatoview app.
  bool isValidDeepLink(Uri uri) {
    if (uri.scheme == AppConstants.deepLinkScheme) return true;
    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        AppConstants.allowedHosts.contains(uri.host)) {
      return true;
    }
    return false;
  }

  /// Converts custom-scheme links into https URLs for the WebView.
  Uri normalizeUri(Uri uri) {
    if (uri.scheme == AppConstants.deepLinkScheme) {
      // bitzlatoview://trade/42 → host=trade, path=/42
      final hostPart = uri.host.isNotEmpty ? '/${uri.host}' : '';
      final pathPart = uri.path.isEmpty ? '' : uri.path;
      var combined = '$hostPart$pathPart';
      if (combined.isEmpty) combined = '/';
      final query = uri.hasQuery ? '?${uri.query}' : '';
      final fragment = uri.hasFragment ? '#${uri.fragment}' : '';
      return Uri.parse('${AppConstants.baseUrl}$combined$query$fragment');
    }
    if (uri.scheme == 'http') {
      return uri.replace(scheme: 'https');
    }
    return uri;
  }

  void dispose() {
    _sub?.cancel();
    _linkController.close();
  }
}
