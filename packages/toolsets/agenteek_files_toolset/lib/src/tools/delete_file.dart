import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';

import '../file_toolset.dart';
import '_json_arguments.dart';

/// Deletes selected lines from a file.
///
/// - [args]: A JSON object containing the `path`.
///   - `path`: The path of the file to delete.
///
/// Returns a `Future<String>` which resolves to a success message.
/// Throws an error if file deletion is not allowed.
Tool<String> deleteFileTool(FileToolSet toolSet) => Tool(
  name: toolSet.buildToolName('delete_file'),
  description: toolSet.buildDescription(
    'Delete a file'.sideEffect('the file will be deleted'),
  ),
  inputSchema: DeleteFileArgs.schema,
  onCall: (args) => _deleteLines(toolSet, DeleteFileArgs(args)),
);

Future<ToolSuccess<String>> _deleteLines(
  FileToolSet toolSet,
  DeleteFileArgs args,
) async {
  // check
  final file = await File(args.path).check<File>(toolSet.root);
  if (!toolSet.showHiddenFiles && file.isHidden) throw 'Access denied';
  if (!await file.exists()) throw 'File not found: ${args.path}.';

  // proceed
  await file.delete();
  return ToolSuccess.ok;
}
