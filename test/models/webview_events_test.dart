import 'package:bitzlatoview_mobile/models/webview_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BridgeAction', () {
    test('round-trips known actions through their wire names', () {
      for (final action in BridgeAction.values) {
        if (action == BridgeAction.unknown) continue;
        expect(BridgeAction.fromWire(action.wireName), action);
      }
    });

    test('unrecognized wire names map to unknown', () {
      expect(BridgeAction.fromWire('doSomethingDangerous'), BridgeAction.unknown);
      expect(BridgeAction.fromWire(''), BridgeAction.unknown);
    });
  });

  group('BridgeRequest.fromJson', () {
    test('parses action, params and requestId', () {
      final request = BridgeRequest.fromJson({
        'action': 'pickFile',
        'params': {'accept': 'image/*'},
        'requestId': 'req_1',
      });
      expect(request.action, BridgeAction.pickFile);
      expect(request.params, {'accept': 'image/*'});
      expect(request.requestId, 'req_1');
    });

    test('defaults params to an empty map when absent', () {
      final request = BridgeRequest.fromJson({'action': 'getLocation'});
      expect(request.params, isEmpty);
      expect(request.requestId, isNull);
    });
  });

  group('BridgeResponse.toJson', () {
    test('a success response omits the error field', () {
      const response = BridgeResponse(requestId: 'r1', data: {'ok': true});
      final json = response.toJson();
      expect(json['success'], isTrue);
      expect(json['data'], {'ok': true});
      expect(json.containsKey('error'), isFalse);
    });

    test('a failure response carries the error and omits data', () {
      const response = BridgeResponse(requestId: 'r1', success: false, error: 'boom');
      final json = response.toJson();
      expect(json['success'], isFalse);
      expect(json['error'], 'boom');
      expect(json.containsKey('data'), isFalse);
    });
  });

  group('PushNotificationPayload.fromRemoteMessageData', () {
    test('prefers explicit title/body over data fields', () {
      final payload = PushNotificationPayload.fromRemoteMessageData(
        {'title': 'from data', 'deep_link': 'https://app.bitzlatoview.com/trade/1'},
        title: 'from notification',
        body: 'body text',
      );
      expect(payload.title, 'from notification');
      expect(payload.body, 'body text');
      expect(payload.deepLink, 'https://app.bitzlatoview.com/trade/1');
    });

    test('falls back to the url field when deep_link is absent', () {
      final payload = PushNotificationPayload.fromRemoteMessageData(
        {'url': 'https://app.bitzlatoview.com/p2p/9'},
      );
      expect(payload.deepLink, 'https://app.bitzlatoview.com/p2p/9');
    });
  });
}
