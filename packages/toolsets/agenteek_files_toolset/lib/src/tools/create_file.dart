import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';

import '../file_toolset.dart';
import '_json_arguments.dart';

/// Creates a new file at the specified path.
///
/// - [args]: A JSON object containing the `path` field.
///   - `path`: The path of the file to create.
///
/// Returns a `Future<ToolSuccess>` which contains 'OK'.
Tool<String> createFileTool(FileToolSet toolSet) => Tool(
  name: toolSet.buildToolName('create_file'),
  description: toolSet.buildDescription('Create a new file'),
  inputSchema: CreateFileArgs.schema,
  onCall: (args) => _createFile(toolSet, CreateFileArgs(args)),
);

Future<ToolSuccess<String>> _createFile(
  FileToolSet toolSet,
  CreateFileArgs args,
) async {
  // check
  final file = await File(args.path).check<File>(toolSet.root);
  if (!toolSet.showHiddenFiles && file.isHidden) throw 'Access denied';

  // proceed
  if (await file.exists()) {
    throw 'File already exists: ${file.getLocalPath(toolSet.root)}';
  }
  if (!toolSet.showHiddenFiles) {
    if (file.isHidden) {
      throw 'File creation denied: ${file.getLocalPath(toolSet.root)}';
    }
    var d = Directory(file.getLocalPath(toolSet.root));
    while (d.path != '.') {
      if (d.isHidden) {
        throw 'File creation denied: ${file.getLocalPath(toolSet.root)}';
      }
      d = d.parent;
    }
  }
  await file.parent.create(recursive: true);
  await file.writeAsString(args.text);
  return ToolSuccess.ok;
}
