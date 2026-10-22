import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../config/constants.dart';
import '../models/webview_events.dart';

class Helpers {
  static String encodeBridgeResponse(BridgeResponse response) {
    return jsonEncode(response.toJson());
  }

  static String getBridgeInjectionScript() {
    return '''
      (function() {
        if (window.${AppConstants.jsBridgeName}) return;
        window.${AppConstants.jsBridgeName} = {
          postMessage: function(message) {
            if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
              window.flutter_inappwebview.callHandler('${AppConstants.jsBridgeName}', message);
            }
          }
        };
        window.handleNativeBridgeResponse = function(response) {
          if (window.onBitzlatoviewBridgeResponse) {
            window.onBitzlatoviewBridgeResponse(response);
          }
        };
      })();
    ''';
  }

  static NavigationActionPolicy shouldAllowNavigation(Uri? uri) {
    if (uri == null) return NavigationActionPolicy.CANCEL;
    if (uri.scheme == 'https' && Helpers.isAllowedHost(uri.host)) {
      return NavigationActionPolicy.ALLOW;
    }
    if (uri.scheme == 'mailto' || uri.scheme == 'tel') {
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.CANCEL;
  }

  static bool isAllowedHost(String host) {
    return host == AppConstants.deepLinkHost ||
        host.endsWith('.bitzlatoview.org');
  }
}
