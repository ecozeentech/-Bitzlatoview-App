import 'package:flutter_test/flutter_test.dart';

import 'package:bitzlatoview_mobile/config/constants.dart';
import 'package:bitzlatoview_mobile/models/webview_events.dart';
import 'package:bitzlatoview_mobile/services/deep_link_service.dart';
import 'package:bitzlatoview_mobile/utils/helpers.dart';
import 'package:bitzlatoview_mobile/utils/validators.dart';

void main() {
  group('Validators', () {
    test('isAllowedHost accepts primary and subdomain hosts', () {
      expect(
        Validators.isAllowedHost('app.bitzlatoview.com', AppConstants.allowedHosts),
        isTrue,
      );
      expect(
        Validators.isAllowedHost('bitzlatoview.com', AppConstants.allowedHosts),
        isTrue,
      );
      expect(
        Validators.isAllowedHost('evil.example.com', AppConstants.allowedHosts),
        isFalse,
      );
      expect(
        Validators.isAllowedHost(null, AppConstants.allowedHosts),
        isFalse,
      );
    });

    test('isHttpsUrl validates scheme', () {
      expect(Validators.isHttpsUrl('https://app.bitzlatoview.com'), isTrue);
      expect(Validators.isHttpsUrl('http://app.bitzlatoview.com'), isFalse);
      expect(Validators.isHttpsUrl('not-a-url'), isFalse);
    });

    test('isNonEmpty trims whitespace', () {
      expect(Validators.isNonEmpty('  a '), isTrue);
      expect(Validators.isNonEmpty('   '), isFalse);
      expect(Validators.isNonEmpty(null), isFalse);
    });
  });

  group('Helpers', () {
    test('shouldHandleInternally keeps app domains inside WebView', () {
      expect(
        Helpers.shouldHandleInternally('https://app.bitzlatoview.com/trade/1'),
        isTrue,
      );
      expect(
        Helpers.shouldHandleInternally('https://google.com'),
        isFalse,
      );
      expect(Helpers.shouldHandleInternally('about:blank'), isTrue);
    });

    test('redact masks sensitive strings', () {
      expect(Helpers.redact('abcdefghijklmnop'), 'abcd…mnop');
      expect(Helpers.redact('short'), '***');
      expect(Helpers.redact(null), '');
    });
  });

  group('BridgeMessage', () {
    test('parses known actions and params', () {
      final message = BridgeMessage.fromRaw(
        '{"action":"pickFile","params":{"accept":"image/*"},"requestId":"1"}',
      );
      expect(message.action, BridgeAction.pickFile);
      expect(message.params['accept'], 'image/*');
      expect(message.requestId, '1');
    });

    test('unknown action maps to unknown', () {
      final message = BridgeMessage.fromRaw('{"action":"flyToMoon"}');
      expect(message.action, BridgeAction.unknown);
    });

    test('BridgeResponse serializes to JSON for JS injection', () {
      const response = BridgeResponse(
        success: true,
        data: {'ok': true},
        requestId: 'abc',
      );
      final js = response.toJavaScript();
      expect(js, contains('"success":true'));
      expect(js, contains('"requestId":"abc"'));
    });
  });

  group('DeepLinkService', () {
    late DeepLinkService service;

    setUp(() {
      service = DeepLinkService();
    });

    tearDown(() {
      service.dispose();
    });

    test('accepts https app host and custom scheme', () {
      expect(
        service.isValidDeepLink(Uri.parse('https://app.bitzlatoview.com/p2p/9')),
        isTrue,
      );
      expect(
        service.isValidDeepLink(Uri.parse('bitzlatoview://trade/42')),
        isTrue,
      );
      expect(
        service.isValidDeepLink(Uri.parse('https://example.com')),
        isFalse,
      );
    });

    test('normalizes custom scheme to https base URL', () {
      final normalized = service.normalizeUri(
        Uri.parse('bitzlatoview://trade/42?ref=push'),
      );
      expect(normalized.scheme, 'https');
      expect(normalized.host, 'app.bitzlatoview.com');
      expect(normalized.path, '/trade/42');
      expect(normalized.query, 'ref=push');
    });

    test('upgrades http deep links to https', () {
      final normalized = service.normalizeUri(
        Uri.parse('http://app.bitzlatoview.com/wallet'),
      );
      expect(normalized.scheme, 'https');
    });
  });
}
