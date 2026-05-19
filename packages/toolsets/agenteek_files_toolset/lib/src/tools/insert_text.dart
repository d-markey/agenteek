import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';

import '../file_toolset.dart';
import '_json_arguments.dart';

/// Inserts text into a file.
///
/// - [args]: A JSON object containing the `path`, `startLine`, and `newText` fields.
///   - `path`: The path of the file to modify.
///   - `startLine`: The starting line number (1-based).
///   - `newText`: The new text to insert.
///
/// Returns a `Future<String>` which resolves to a success message.
/// Throws an error if file modification is not allowed or line numbers are invalid.
Tool<String> insertTextTool(FileToolSet toolSet) => Tool(
  name: toolSet.buildToolName('insert_text'),
  description: toolSet.buildDescription(
    'Insert text in a file; use with caution: wrong line numbers will lead to text/code corruption. Always call `read_lines` with `mode=numbered` first'
        .sideEffect('line numbers and file contents will change'),
  ),
  inputSchema: InsertTextArgs.schema,
  onCall: (args) => _insertText(toolSet, InsertTextArgs(args)),
);

Future<ToolSuccess<String>> _insertText(
  FileToolSet toolSet,
  InsertTextArgs args,
) async {
  // check
  final file = await File(
    args.path,
  ).check<File>(toolSet.root, includeHidden: toolSet.showHiddenFiles);
  if (!await file.exists()) {
    throw 'File not found: "${toolSet.getLocalPath(file)}"';
  }
  if (args.line < 1) {
    throw 'Invalid line number: ${args.line}. `line` must be >= 1.';
  }

  // proceed
  final lines = await FileReader.readLines(file);
  if (args.line >= lines.length) {
    lines.add(args.newText);
  } else {
    lines.insert(args.line - 1, args.newText);
  }

  await file.writeAsString(lines.join('\n'));
  return ToolSuccess(
    'New text inserted into file at line ${args.line}: "${file.getLocalPath(toolSet.root)}"',
  );
}
