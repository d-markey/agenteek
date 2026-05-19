import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';

import '../dart_toolset.dart';
import '_json_arguments.dart';

// run
Tool<Json> runTool(DartToolSet toolSet) => Tool(
  name: toolSet.buildToolName('run'),
  description: toolSet.buildDescription(
    'Runs a Dart script/program in a sandbox. Program output is only accessible via `stdout` and `stderr`. '
    'Programs that create files are not recommended.',
  ),
  inputSchema: RunArgs.schema,
  onCall: (args) => _run(toolSet, RunArgs(args)),
);

Future<ToolSuccess<Json>> _run(DartToolSet toolSet, RunArgs args) async {
  final script = await File(
    args.scriptPath,
  ).check<File>(toolSet.root, includeHidden: false);
  if (!await script.exists()) {
    throw 'Script not found: "${script.getLocalPath(toolSet.root)}"';
  }

  toolSet.logger.info('Runing script: $args');

  final result = await toolSet.execInPodman(
    'dart run ${script.getLocalPath(toolSet.root).replaceAll('\\', '/')}',
    timeout: Duration(seconds: args.timeout),
  );
  return ToolSuccess(result);
}
