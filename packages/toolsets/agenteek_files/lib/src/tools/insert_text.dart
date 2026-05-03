import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/src/file_reader/helpers.dart';

import '../file_reader/file_reader.dart';
import '../file_toolset.dart';

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
    'Insert text in a file. USE WITH CAUTION: WRONG LINE NUMBERS WILL LEAD TO TEXT/CODE CORRUPTION. ALWAYS CALL `read_lines` WITH mode=`numbered` FIRST'
        .sideEffect('line numbers will change'),
  ),
  inputSchema: _inputSchema,
  onCall: (args) => _insertText(toolSet, args),
);

Future<ToolSuccess<String>> _insertText(FileToolSet toolSet, Json args) async {
  var path = args.getString('path').trim();
  if (path.startsWith('/')) path = path.substring(1);
  final line = args.getInt('line');
  final newText = args.getString('newText');

  // check
  final file = await File(path).check<File>(toolSet.root);
  if (!toolSet.showHiddenFiles && file.isHidden) throw 'Access denied';
  if (!await file.exists()) throw 'File not found: $path.';
  if (line < 1) {
    throw 'Invalid line number. line must be >= 1.';
  }

  // proceed
  final lines = await FileReader.readLines(file);
  if (line >= lines.length) {
    lines.add(newText);
  } else {
    lines.insert(line - 1, newText);
  }

  await file.writeAsString(lines.join('\n'));
  return ToolSuccess.ok;
}

final _inputSchema = z.object(
  {
    'path': z.string('File path'),
    'line': z.int(
      'Line number where insertion starts (1-based, as provided by `read_lines` with mode=`numbered`). Never guess this parameter, call `read_lines` first.',
    ),
    'newText': z.string('Text to insert.'),
  },
  required: ['path', 'line', 'newText'],
);
