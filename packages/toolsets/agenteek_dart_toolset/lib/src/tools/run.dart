import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';

import '../dart_toolset.dart';
import '_json_arguments.dart';

// run
Tool<Json> runTool(DartToolSet toolSet) => Tool(
  name: toolSet.buildToolName('run'),
  description: toolSet.buildDescription('Runs a Dart script'),
  inputSchema: RunArgs.schema,
  onCall: (args) => _run(toolSet, RunArgs(args)),
);

Future<ToolSuccess<Json>> _run(DartToolSet toolSet, RunArgs args) async {
  final script = await File(args.scriptPath).check(toolSet.root);
  if (!await script.exists()) {
    throw 'Not found: ${script.getLocalPath(toolSet.root)}';
  }

  final result = await toolSet.execInPodman(
    'dart run ${script.getLocalPath(toolSet.root).replaceAll('\\', '/')}',
  );
  return ToolSuccess(result);
}
