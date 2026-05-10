import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';

import '../file_toolset.dart';
import '_json_arguments.dart';

/// Reads a portion of a file, given a start and end line.
///
/// - [args]: A JSON object containing the `path`, `startLine`, and optional `endLine` fields.
///   - `path`: The path of the file to read.
///   - `startLine`: The starting line number (1-based).
///   - `endLine`: Optional. The ending line number (inclusive, 1-based). If provided, must be >= `startLine`. Defaults to the last line in the file.
///
/// Returns a `Future<Json>` which contains the file contents.
Tool<String> readLinesTool(FileToolSet toolSet) => Tool(
  name: toolSet.buildToolName('read_lines'),
  description: toolSet.buildDescription(
    'Reads a chunk from a file, given start and end line numbers',
  ),
  inputSchema: ReadLinesArgs.schema,
  onCall: (args) => _readLines(toolSet, ReadLinesArgs(args)),
);

Future<ToolSuccess<String>> _readLines(
  FileToolSet toolSet,
  ReadLinesArgs args,
) async {
  // check
  final file = await File(args.path).check<File>(toolSet.root);
  if (!toolSet.showHiddenFiles && file.isHidden) throw 'Access denied';
  if (!await file.exists()) throw 'File not found: ${args.path}.';
  final startLine = args.startLine;
  var endLine = args.endLine;
  if (startLine < 1 || endLine < 0 || (endLine > 0 && endLine < startLine)) {
    throw 'Invalid line numbers. startLine must be >= 1, and if endLine is provided: endLine >= 1 && startLine <= endLine.';
  }

  // proceed
  final lines = await FileReader.readLines(file);
  if (lines.isEmpty || startLine > lines.length) {
    return ToolSuccess(
      '**INFO**: file "${file.getLocalPath(toolSet.root)}" is empty after line $startLine.',
    );
  } else {
    if (endLine == 0) endLine = lines.length;
    if (endLine > lines.length) endLine = lines.length;
    final selectedLines = lines.sublist(startLine - 1, endLine);
    return ToolSuccess(
      ((args.mode == 'raw')
              ? selectedLines
              : selectedLines.indexed.map(
                  (e) =>
                      '${(startLine + e.$1).toString().padLeft(6, '0')}| ${e.$2}',
                ))
          .join('\n'),
    );
  }
}
