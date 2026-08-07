import 'package:bitzlatoview_mobile/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.isValidEmail', () {
    test('accepts well-formed emails', () {
      expect(Validators.isValidEmail('user@bitzlatoview.com'), isTrue);
      expect(Validators.isValidEmail('first.last+tag@sub.example.co'), isTrue);
    });

    test('rejects malformed or empty input', () {
      expect(Validators.isValidEmail(null), isFalse);
      expect(Validators.isValidEmail(''), isFalse);
      expect(Validators.isValidEmail('not-an-email'), isFalse);
      expect(Validators.isValidEmail('missing@domain'), isFalse);
    });
  });

  group('Validators.isSafeHttpsUrl', () {
    test('rejects non-https schemes', () {
      expect(Validators.isSafeHttpsUrl('http://app.bitzlatoview.com'), isFalse);
      expect(Validators.isSafeHttpsUrl('javascript:alert(1)'), isFalse);
      expect(Validators.isSafeHttpsUrl('ftp://app.bitzlatoview.com'), isFalse);
    });

    test('rejects null/empty/relative input', () {
      expect(Validators.isSafeHttpsUrl(null), isFalse);
      expect(Validators.isSafeHttpsUrl(''), isFalse);
      expect(Validators.isSafeHttpsUrl('/relative/path'), isFalse);
    });

    test('accepts any https url when no host allow-list is given', () {
      expect(Validators.isSafeHttpsUrl('https://example.com'), isTrue);
    });

    test('enforces the allowed host list, including subdomains', () {
      const hosts = ['bitzlatoview.com'];
      expect(
        Validators.isSafeHttpsUrl('https://app.bitzlatoview.com/trade/1', allowedHosts: hosts),
        isTrue,
      );
      expect(
        Validators.isSafeHttpsUrl('https://bitzlatoview.com', allowedHosts: hosts),
        isTrue,
      );
      expect(
        Validators.isSafeHttpsUrl('https://evil.com', allowedHosts: hosts),
        isFalse,
      );
      expect(
        Validators.isSafeHttpsUrl('https://notbitzlatoview.com', allowedHosts: hosts),
        isFalse,
      );
    });
  });

  group('Validators.isNonEmptyMap', () {
    test('true only for non-empty maps', () {
      expect(Validators.isNonEmptyMap({'a': 1}), isTrue);
      expect(Validators.isNonEmptyMap({}), isFalse);
      expect(Validators.isNonEmptyMap(null), isFalse);
      expect(Validators.isNonEmptyMap('not a map'), isFalse);
    });
  });
}
