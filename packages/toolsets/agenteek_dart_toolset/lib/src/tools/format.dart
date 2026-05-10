import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';

import '../dart_toolset.dart';
import '_json_arguments.dart';

// format
Tool<Json> formatTool(DartToolSet toolSet) => Tool(
  name: toolSet.buildToolName('format'),
  description: toolSet.buildDescription('Formats a Dart file or a directory'),
  inputSchema: DirectoryOrFileArgs.schema,
  onCall: (args) => _format(toolSet, DirectoryOrFileArgs(args)),
);

Future<ToolSuccess<Json>> _format(
  DartToolSet toolSet,
  DirectoryOrFileArgs args,
) async {
  FileSystemEntity fileOrDir;
  if (args.path.isEmpty) {
    fileOrDir = Directory(toolSet.root);
  } else {
    fileOrDir = await Link(args.path).check(toolSet.root);
    if (!await fileOrDir.exists()) {
      throw 'Not found: ${fileOrDir.getLocalPath(toolSet.root)}';
    }
  }

  return ToolSuccess(await toolSet.exec('format', [fileOrDir.path]));
}
