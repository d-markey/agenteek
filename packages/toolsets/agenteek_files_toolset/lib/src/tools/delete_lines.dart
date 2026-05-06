import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';

import '../../agenteek_files_toolset.dart';

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
    'Deletes lines from file. USE WITH CAUTION: WRONG LINE NUMBERS WILL LEAD TO TEXT/CODE CORRUPTION. ALWAYS CALL `read_lines` WITH mode=`numbered` FIRST'
        .sideEffect('line numbers will change'),
  ),
  inputSchema: _inputSchema,
  onCall: (args) => _deleteLines(toolSet, args),
);

Future<ToolSuccess<String>> _deleteLines(FileToolSet toolSet, Json args) async {
  var path = args.getString('path').trim();
  final startLine = args.getInt('startLine');
  final endLine = args.getInt('endLine');

  // check
  final file = await File(path).check<File>(toolSet.root);
  if (!toolSet.showHiddenFiles && file.isHidden) throw 'Access denied';
  if (!await file.exists()) throw 'File not found: $path.';
  if (startLine < 1 || endLine < 1) {
    throw 'Invalid line number. line must be >= 1.';
  }
  if (endLine < startLine) {
    throw 'Invalid line range. endLine must be >= startLine.';
  }

  // proceed
  final lines = await FileReader.readLines(file);
  lines.removeRange(startLine - 1, endLine);

  await file.writeAsString(lines.join('\n'));
  return ToolSuccess.ok;
}

final _inputSchema = Z.object(
  properties: {
    'path': Z.string(description: 'File path'),
    'startLine': Z.integer(
      description:
          'Line number where deletion starts (1-based, as provided by `read_lines` with mode=`numbered`). Never guess this parameter, call `read_lines` first.',
    ),
    'endLine': Z.integer(
      description:
          'Line number where deletion ends (1-based, inclusive, must be >= `startLine`). Never guess this parameter, call `read_lines` first.',
    ),
  },
  required: ['path', 'startLine', 'endLine'],
);
