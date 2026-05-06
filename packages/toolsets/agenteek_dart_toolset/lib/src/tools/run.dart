import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';

import '../dart_toolset.dart';

// run
Tool runTool(DartToolSet toolSet) => Tool(
  name: toolSet.buildToolName('run'),
  description: toolSet.buildDescription('Runs a Dart script'),
  inputSchema: _inputSchema,
  onCall: (args) => _run(toolSet, args),
);

Future<ToolSuccess<Json>> _run(DartToolSet toolSet, Json args) async {
  var path = args.getString('path');
  if (path.startsWith('/')) path = path.substring(1);

  final script = await File(path).check(toolSet.root);
  if (!await script.exists()) {
    throw 'Not found: ${script.getLocalPath(toolSet.root)}';
  }

  return ToolSuccess(await toolSet.exec('dart', ['run', script.path]));
}

final _inputSchema = Z.object(
  properties: {'path': Z.string(description: 'The path to the Dart script.')},
  required: ['path'],
);
