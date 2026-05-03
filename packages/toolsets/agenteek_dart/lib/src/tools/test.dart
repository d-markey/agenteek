import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_file_reader.dart';

import '../../agenteek_dart.dart';

// test
Tool testTool(DartToolSet toolSet) => Tool(
  name: toolSet.buildToolName('test'),
  description: toolSet.buildDescription('Runs unit tests'),
  inputSchema: _inputSchema,
  onCall: (args) => _test(toolSet, args),
);

Future<ToolOutcome<Json>> _test(DartToolSet toolSet, Json args) async {
  var path = args.getString('path', defaultValue: '').trim();
  if (path.startsWith('/')) path = path.substring(1);

  FileSystemEntity fileOrDir;
  if (path.isEmpty) {
    fileOrDir = Directory(toolSet.root);
  } else {
    fileOrDir = await Link(path).check(toolSet.root);
    if (!await fileOrDir.exists()) {
      throw 'Not found: ${fileOrDir.getLocalPath(toolSet.root)}';
    }
  }

  return ToolSuccess(
    await toolSet.exec('dart', ['test', '--reporter=expanded', fileOrDir.path]),
  );
}

final _inputSchema = z.object({
  'path': z.string(
    'The path to the test directory (or to a specific test file to only run tests in that file)'
        .optional('root directory'),
  ),
});
