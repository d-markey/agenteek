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
  description: toolSet.buildDescription(
    'Create a new **file** at `path`. Directories will be created as needed.',
  ),
  inputSchema: CreateFileArgs.schema,
  onCall: (args) => _createFile(toolSet, CreateFileArgs(args)),
);

Future<ToolSuccess<String>> _createFile(
  FileToolSet toolSet,
  CreateFileArgs args,
) async {
  // check
  final file = await File(
    args.path,
  ).check<File>(toolSet.root, includeHidden: toolSet.showHiddenFiles);
  if (await file.exists()) {
    throw 'File already exists: "${toolSet.getLocalPath(file)}"';
  }

  // proceed
  await file.parent.create(recursive: true);
  await file.writeAsString(args.text);
  return ToolSuccess('File created: "${toolSet.getLocalPath(file)}"');
}
