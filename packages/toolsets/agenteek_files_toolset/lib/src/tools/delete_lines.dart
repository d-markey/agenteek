import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';

import '../../files_toolset.dart';
import '_json_arguments.dart';

/// Deletes selected lines from a file.
///
/// - [args]: A JSON object containing the `path`, `startLine`, and `endLine`.
///   - `path`: The path of the file to modify.
///   - `startLine`: The starting line number (1-based).
///   - `endLine`: The ending line number (inclusive, 1-based).
///
/// Returns a `Future<String>` which resolves to a success message.
/// Throws an error if file modification is not allowed or line numbers are invalid.
Tool<String> deleteLinesTool(FileToolSet toolSet) => Tool(
  name: toolSet.buildToolName('delete_lines'),
  description: toolSet.buildDescription(
    'Deletes lines between `startLine` and `endLine` (inclusive, 1-based) from file at `path`; '
            'use with caution: wrong line numbers will lead to text/code corruption. Always call `read_lines` with `mode=numbered` first'
        .sideEffect('line numbers and file contents will change'),
  ),
  inputSchema: DeleteLinesArgs.schema,
  onCall: (args) => _deleteLines(toolSet, DeleteLinesArgs(args)),
);

Future<ToolSuccess<String>> _deleteLines(
  FileToolSet toolSet,
  DeleteLinesArgs args,
) async {
  // check
  final file = await File(
    args.path,
  ).check<File>(toolSet.root, includeHidden: toolSet.showHiddenFiles);
  if (!await file.exists()) {
    throw 'File not found: "${toolSet.getLocalPath(file)}".';
  }
  final startLine = args.startLine, endLine = args.endLine;
  if (startLine < 1 || endLine < 1) {
    throw 'Invalid line range: $startLine-$endLine. Lines must be >= 1.';
  }
  if (endLine < startLine) {
    throw 'Invalid line range: $startLine-$endLine. `endLine` must be >= `startLine`.';
  }

  // proceed
  final lines = await FileReader.readLines(file);
  lines.removeRange(startLine - 1, endLine);
  await file.writeAsString(lines.join('\n'));
  return ToolSuccess(
    'Lines $startLine-$endLine deleted from file: "${toolSet.getLocalPath(file)}"',
  );
}
