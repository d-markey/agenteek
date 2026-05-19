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
Tool<String> copyFileTool(FileToolSet toolSet) => Tool(
  name: toolSet.buildToolName('copy_file'),
  description: toolSet.buildDescription(
    'Copy an existing file to a new path. Directories in the new path will be created if needed. This tool can be used in conjunction with `delete_file` to move or rename a file.',
  ),
  inputSchema: CopyFileArgs.schema,
  onCall: (args) => _copyFile(toolSet, CopyFileArgs(args)),
);

Future<ToolSuccess<String>> _copyFile(
  FileToolSet toolSet,
  CopyFileArgs args,
) async {
  // check
  final file = await File(
    args.sourcePath,
  ).check<File>(toolSet.root, includeHidden: toolSet.showHiddenFiles);
  if (!await file.exists()) {
    throw 'Source file not found: "${toolSet.getLocalPath(file)}"';
  }
  final target = await File(
    args.targetPath,
  ).check<File>(toolSet.root, includeHidden: toolSet.showHiddenFiles);
  if (await target.exists()) {
    throw 'Target file already exists: "${toolSet.getLocalPath(target)}"';
  }

  // proceed
  await target.parent.create(recursive: true);
  await file.copy(target.path);
  return ToolSuccess(
    'File copied from "${toolSet.getLocalPath(file)}" to "${toolSet.getLocalPath(target)}"',
  );
}
