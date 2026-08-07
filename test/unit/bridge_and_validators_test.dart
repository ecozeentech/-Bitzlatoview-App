import 'package:flutter_test/flutter_test.dart';

import 'package:bitzlatoview_mobile/models/webview_events.dart';
import 'package:bitzlatoview_mobile/utils/validators.dart';

void main() {
  group('BridgeAction', () {
    test('parses action from JSON', () {
      final action = BridgeAction.fromJson({
        'action': 'pickFile',
        'params': {'accept': 'image/*'},
        'callbackId': 'cb-1',
      });

      expect(action.action, 'pickFile');
      expect(action.params['accept'], 'image/*');
      expect(action.callbackId, 'cb-1');
    });
  });

  group('BridgeResponse', () {
    test('serializes to JSON', () {
      const response = BridgeResponse(
        callbackId: 'cb-1',
        success: true,
        data: {'copied': true},
      );

      expect(response.toJson(), {
        'callbackId': 'cb-1',
        'success': true,
        'data': {'copied': true},
        'error': null,
      });
    });
  });

  group('Validators', () {
    test('validates Bitzlatoview URLs', () {
      expect(
        Validators.isBitzlatoviewUrl('https://app.bitzlatoview.com/trade'),
        isTrue,
      );
      expect(Validators.isBitzlatoviewUrl('https://example.com'), isFalse);
    });

    test('validates email format', () {
      expect(Validators.validateEmail('user@bitzlatoview.com'), isNull);
      expect(Validators.validateEmail('invalid'), isNotNull);
    });
  });
}
