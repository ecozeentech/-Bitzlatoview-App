import 'package:bitzlatoview_mobile/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Helpers.encodeJson', () {
    test('passes strings through unchanged', () {
      expect(Helpers.encodeJson('already json'), 'already json');
    });

    test('encodes maps/lists to JSON', () {
      expect(Helpers.encodeJson({'a': 1}), '{"a":1}');
      expect(Helpers.encodeJson([1, 2, 3]), '[1,2,3]');
    });
  });

  group('Helpers.tryDecodeJsonMap', () {
    test('decodes a valid JSON object', () {
      expect(Helpers.tryDecodeJsonMap('{"action":"pickFile"}'), {'action': 'pickFile'});
    });

    test('returns an empty map for invalid JSON instead of throwing', () {
      expect(Helpers.tryDecodeJsonMap('not json'), <String, dynamic>{});
      expect(Helpers.tryDecodeJsonMap('[1,2,3]'), <String, dynamic>{});
      expect(Helpers.tryDecodeJsonMap(''), <String, dynamic>{});
    });
  });

  group('Helpers.jsStringLiteral', () {
    test('escapes quotes and special characters', () {
      expect(Helpers.jsStringLiteral('hello "world"'), r'"hello \"world\""');
    });
  });
}
