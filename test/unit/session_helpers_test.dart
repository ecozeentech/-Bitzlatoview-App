import 'package:flutter_test/flutter_test.dart';

import 'package:bitzlatoview_mobile/utils/session_helpers.dart';

void main() {
  group('SessionHelpers', () {
    test('does not persist session on login pages', () {
      expect(
        SessionHelpers.shouldPersistSession('https://app.bitzlatoview.com/login'),
        isFalse,
      );
      expect(
        SessionHelpers.shouldPersistSession(
          'https://app.bitzlatoview.com/register',
        ),
        isFalse,
      );
      expect(
        SessionHelpers.shouldPersistSession(
          'https://app.bitzlatoview.com/forgot-password',
        ),
        isFalse,
      );
    });

    test('persists session on authenticated pages', () {
      expect(
        SessionHelpers.shouldPersistSession(
          'https://app.bitzlatoview.com/dashboard',
        ),
        isTrue,
      );
      expect(
        SessionHelpers.shouldPersistSession('https://app.bitzlatoview.com/trade'),
        isTrue,
      );
      expect(
        SessionHelpers.shouldPersistSession('https://app.bitzlatoview.com/'),
        isTrue,
      );
    });
  });
}
