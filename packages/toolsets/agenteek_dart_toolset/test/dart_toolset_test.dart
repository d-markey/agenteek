import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek/agenteek_dbg.dart' as dbg;
import 'package:agenteek_dart_toolset/dart_toolset.dart';
import 'package:test/test.dart';

import 'workspace_path.dart';

void main() {
  group('DartToolSet', () {
    dbg.enableTrace = false;

    test('pubspec', () async {
      final dartToolset = DartToolSet(
        prefix: 'agenteek',
        root: await getWorkspacePath(''),
        scope: 'root',
      );
      var result = await dartToolset.call<String>('read_pubspec');
      var pubspec = await File(
        await getWorkspacePath('pubspec.yaml'),
      ).readAsString();
      expect(result.result, equals(pubspec));

      result = await dartToolset.call<String>('read_pubspec', {
        'path': 'packages/toolsets/agenteek_dart',
      });
      pubspec = await File(
        await getWorkspacePath('packages/toolsets/agenteek_dart/pubspec.yaml'),
      ).readAsString();
      expect(result.result, equals(pubspec));
    });

    test('analyze', () async {
      final dartToolset = DartToolSet(
        prefix: 'agenteek_cli',
        root: await getWorkspacePath('packages/agenteek_cli'),
        scope: 'agenteek_cli',
      );
      final args = {'path': 'bin/calc'};
      final result = await dartToolset.call<Json>('analyze', args);
      expect(
        (result.result['stdout'] as String).toLowerCase(),
        contains('no issues'),
      );
    });

    test('analyze', () async {
      final dartToolset = DartToolSet(
        prefix: 'agenteek_dart',
        root: await getWorkspacePath('packages/toolsets/agenteek_dart'),
        scope: 'agenteek_dart',
      );
      final args = {'path': 'test/assets/invalid.dart'};
      final result = await dartToolset.call<Json>('analyze', args);
      expect(
        (result.result['stdout'] as String).toLowerCase(),
        allOf(
          contains('await_in_wrong_context'),
          contains('undefined_function'),
        ),
      );
    });
  });
}
