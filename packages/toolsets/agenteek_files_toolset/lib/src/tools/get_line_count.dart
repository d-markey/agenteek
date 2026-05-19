import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';

import '../file_toolset.dart';
import '_json_arguments.dart';

/// Gets the number of lines in a file.
///
/// - [args]: A JSON object containing the `path` field.
///   - `path`: The path of the file to count lines from.
///
/// Returns a `Future<ToolSuccess>` which contains the total number of lines in the file.
Tool<int> getLineCountTool(FileToolSet toolSet) => Tool(
  name: toolSet.buildToolName('line_count'),
  description: toolSet.buildDescription('Gets the number of lines in a file'),
  inputSchema: GetLineCountArgs.schema,
  onCall: (args) => _getLineCount(toolSet, GetLineCountArgs(args)),
);

Future<ToolSuccess<int>> _getLineCount(
  FileToolSet toolSet,
  GetLineCountArgs args,
) async {
  // check
  final file = await File(
    args.path,
  ).check<File>(toolSet.root, includeHidden: toolSet.showHiddenFiles);
  if (!await file.exists()) {
    throw 'File not found: "${toolSet.getLocalPath(file)}"';
  }

  // proceed
  final lines = await FileReader.readLines(file);
  return ToolSuccess(lines.length);
}
