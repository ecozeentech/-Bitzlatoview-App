import 'package:bitzlatoview_mobile/services/deep_link_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DeepLinkService service;

  setUp(() {
    service = DeepLinkService();
  });

  group('resolveTargetUrl', () {
    test('passes https links through unchanged', () {
      final uri = Uri.parse('https://app.bitzlatoview.com/trade/123');
      expect(service.resolveTargetUrl(uri), 'https://app.bitzlatoview.com/trade/123');
    });

    test('rewrites a custom-scheme link to an absolute web URL', () {
      final uri = Uri.parse('bitzlatoview://trade/123');
      expect(
        service.resolveTargetUrl(uri),
        'https://app.bitzlatoview.com/trade/123',
      );
    });

    test('preserves the query string when rewriting a custom-scheme link', () {
      final uri = Uri.parse('bitzlatoview://p2p/order?ref=push');
      expect(
        service.resolveTargetUrl(uri),
        'https://app.bitzlatoview.com/p2p/order?ref=push',
      );
    });

    test('falls back to / for a bare custom-scheme host with no path', () {
      final uri = Uri.parse('bitzlatoview://dashboard');
      expect(
        service.resolveTargetUrl(uri),
        'https://app.bitzlatoview.com/dashboard',
      );
    });
  });
}
