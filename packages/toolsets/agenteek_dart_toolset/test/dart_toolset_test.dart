import 'package:agenteek/agenteek.dart';
import 'package:agenteek/agenteek_dbg.dart' as dbg;
import 'package:agenteek_dart_toolset/dart_toolset.dart';
import 'package:test/test.dart';

import 'workspace_path.dart';

void main() {
  group('DartToolSet', () {
    test('analyze', () async {
      final dartToolset = DartToolSet(
        prefix: 'agenteek_team',
        root: await getWorkspacePath('packages/agenteek_team'),
        scope: 'agenteek_team',
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
        root: await getWorkspacePath('packages/toolsets/agenteek_dart_toolset'),
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
