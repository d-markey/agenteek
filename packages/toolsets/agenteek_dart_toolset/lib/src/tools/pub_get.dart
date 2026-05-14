import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';

import '../dart_toolset.dart';
import '_json_arguments.dart';

/// Gets or upgrades packages in a directory
Tool<Json> pubGetTool(DartToolSet toolSet) => Tool(
  name: toolSet.buildToolName('pub_get'),
  description: toolSet.buildDescription('Gets or upgrades packages'),
  inputSchema: PubGetArgs.schema,
  onCall: (args) => _pubGet(toolSet, PubGetArgs(args)),
);

Future<ToolSuccess<Json>> _pubGet(DartToolSet toolSet, PubGetArgs args) async {
  Directory dir;
  if (args.path.isEmpty) {
    dir = Directory(toolSet.root);
  } else {
    dir = await Link(args.path).check<Directory>(toolSet.root);
    if (!await dir.exists()) {
      throw 'Not found: ${dir.getLocalPath(toolSet.root)}';
    }
  }

  return ToolSuccess(
    await toolSet.exec('pub', [args.mode, '--directory=${dir.path}']),
  );
}
