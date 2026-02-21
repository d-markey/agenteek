import 'dart:io';

import 'package:agenteek_dart/agenteek_dart.dart';
import 'package:test/test.dart';

import 'extensions.dart';

void main() {
  group('DartToolSet', () {
    test('pubspec', () async {
      final dartToolset = DartToolSet(prefix: 'agenteek', root: '.');
      final result = await dartToolset.jsonCall('agenteek_get_pubspec');
      expect(result['error'], isNull);
      expect(
        result['content'],
        equals(await File('pubspec.yaml').readAsString()),
      );
    });

    test('analyze', () async {
      final dartToolset = DartToolSet(prefix: 'agenteek', root: '.');
      final args = {'path': './bin/calc'};
      final result = await dartToolset.jsonCall('agenteek_analyze', args);
      expect(result['error'], isNull);
      expect((result['output'] as String).toLowerCase(), contains('no issues'));
    });

    test('analyze', () async {
      final dartToolset = DartToolSet(prefix: 'agenteek', root: '.');
      final args = {'path': './test/assets/invalid.dart'};
      final result = await dartToolset.jsonCall('agenteek_analyze', args);
      expect(result['error'], isNull);
      expect(
        (result['output'] as String).toLowerCase(),
        allOf(
          contains('await_in_wrong_context'),
          contains('undefined_function'),
        ),
      );
    });
  });
}
