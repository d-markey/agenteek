import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';

import '../dart_toolset.dart';
import '_json_arguments.dart';

// analyze
Tool<Json> analyzeTool(DartToolSet toolSet) => Tool(
  name: toolSet.buildToolName('analyze'),
  description: toolSet.buildDescription('Analyzes a Dart file or directory'),
  inputSchema: DirectoryOrFileArgs.schema,
  onCall: (args) => _analyze(toolSet, DirectoryOrFileArgs(args)),
);

Future<ToolSuccess<Json>> _analyze(
  DartToolSet toolSet,
  DirectoryOrFileArgs args,
) async {
  FileSystemEntity fileOrDir;
  if (args.path.isEmpty) {
    fileOrDir = Directory(toolSet.root);
  } else {
    fileOrDir = await Link(args.path).check(toolSet.root, includeHidden: false);
    if (!await fileOrDir.exists()) {
      throw 'File or directory not found: "${fileOrDir.getLocalPath(toolSet.root)}"';
    }
  }
  return ToolSuccess(await toolSet.exec('analyze', [fileOrDir.path]));
}
