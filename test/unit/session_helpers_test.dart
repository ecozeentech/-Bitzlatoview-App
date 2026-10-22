import 'package:flutter_test/flutter_test.dart';

import 'package:bitzlatoview_mobile/utils/session_helpers.dart';

void main() {
  group('SessionHelpers', () {
    test('does not persist session on login pages', () {
      expect(
        SessionHelpers.shouldPersistSession('https://bitzlatoview.org/login'),
        isFalse,
      );
      expect(
        SessionHelpers.shouldPersistSession(
          'https://bitzlatoview.org/register',
        ),
        isFalse,
      );
      expect(
        SessionHelpers.shouldPersistSession(
          'https://bitzlatoview.org/forgot-password',
        ),
        isFalse,
      );
    });

    test('persists session on authenticated pages', () {
      expect(
        SessionHelpers.shouldPersistSession(
          'https://bitzlatoview.org/dashboard',
        ),
        isTrue,
      );
      expect(
        SessionHelpers.shouldPersistSession('https://bitzlatoview.org/trade'),
        isTrue,
      );
      expect(
        SessionHelpers.shouldPersistSession('https://bitzlatoview.org/'),
        isTrue,
      );
    });
  });
}
