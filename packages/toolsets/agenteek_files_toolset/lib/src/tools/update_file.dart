import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';

import '../file_toolset.dart';
import '_json_arguments.dart';

/// Updates an existing file at the specified path.
///
/// - [args]: A JSON object containing the `path` and `newText` fields.
///   - `path`: The path of the file to update.
///   - `newText`: The new text.
///
/// Returns a `Future<ToolSuccess>` which contains 'OK'.
Tool<String> updateFileTool(FileToolSet toolSet) => Tool(
  name: toolSet.buildToolName('update_file'),
  description: toolSet.buildDescription(
    'Update an existing file'.sideEffect('the line numbers might change'),
  ),
  inputSchema: UpdateFileArgs.schema,
  onCall: (args) => _updateFile(toolSet, UpdateFileArgs(args)),
);

Future<ToolSuccess<String>> _updateFile(
  FileToolSet toolSet,
  UpdateFileArgs args,
) async {
  // check
  final file = await File(args.path).check<File>(toolSet.root);
  if (!toolSet.showHiddenFiles && file.isHidden) throw 'Access denied';

  // proceed
  if (!(await file.exists())) {
    throw 'File does not exists: ${file.getLocalPath(toolSet.root)}';
  }
  if (!toolSet.showHiddenFiles) {
    if (file.isHidden) {
      throw 'File update denied: ${file.getLocalPath(toolSet.root)}';
    }
    var d = Directory(file.getLocalPath(toolSet.root));
    while (d.path != '.') {
      if (d.isHidden) {
        throw 'File update denied: ${file.getLocalPath(toolSet.root)}';
      }
      d = d.parent;
    }
  }
  await file.writeAsString(args.newText);
  return ToolSuccess.ok;
}
