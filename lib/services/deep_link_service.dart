import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../config/constants.dart';

class DeepLinkService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  final StreamController<Uri> _linkController =
      StreamController<Uri>.broadcast();

  Stream<Uri> get linkStream => _linkController.stream;

  Uri? _initialLink;

  Uri? get initialLink => _initialLink;

  Future<void> initialize() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _initialLink = _normalizeUri(initial);
      }
    } catch (e) {
      debugPrint('DeepLinkService initial link error: $e');
    }

    _appLinks.uriLinkStream.listen(
      (uri) => _linkController.add(_normalizeUri(uri)),
      onError: (Object error) {
        debugPrint('DeepLinkService stream error: $error');
      },
    );
  }

  Uri _normalizeUri(Uri uri) {
    if (uri.host == AppConstants.deepLinkHost ||
        uri.toString().startsWith(AppConstants.baseUrl)) {
      return uri;
    }

    if (uri.scheme == 'bitzlatoview') {
      final path = uri.path.isEmpty ? '/' : uri.path;
      return Uri.parse('${AppConstants.baseUrl}$path')
          .replace(queryParameters: uri.queryParameters);
    }

    return uri;
  }

  String resolveInitialUrl(String? override) {
    if (override != null && override.isNotEmpty) return override;
    if (_initialLink != null) return _initialLink.toString();
    return AppConstants.baseUrl;
  }

  void dispose() {
    _linkController.close();
  }
}
