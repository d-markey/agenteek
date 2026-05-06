import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';

import '../dart_toolset.dart';

// analyze
Tool analyzeTool(DartToolSet toolSet) => Tool(
  name: toolSet.buildToolName('analyze'),
  description: toolSet.buildDescription('Analyzes a Dart file or directory'),
  inputSchema: _inputSchema,
  onCall: (args) => _analyze(toolSet, args),
);

Future<ToolSuccess<Json>> _analyze(DartToolSet toolSet, Json args) async {
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
  return ToolSuccess(await toolSet.exec('dart', ['analyze', fileOrDir.path]));
}

final _inputSchema = Z.object(
  properties: {
    'path': Z.string(
      description: 'The path of the file or directory to analyze'.optional(
        'root directory',
      ),
    ),
  },
  required: ['path'],
);
