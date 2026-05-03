import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/src/file_reader/helpers.dart';

import '../file_reader/file_reader.dart';
import '../file_toolset.dart';

/// Gets the number of lines in a file.
///
/// - [args]: A JSON object containing the `path` field.
///   - `path`: The path of the file to count lines from.
///
/// Returns a `Future<ToolSuccess>` which contains the total number of lines in the file.
Tool<int> getLineCountTool(FileToolSet toolSet) => Tool(
  name: toolSet.buildToolName('line_count'),
  description: toolSet.buildDescription('Gets the number of lines in a file'),
  inputSchema: _inputSchema,
  onCall: (args) => _getLineCount(toolSet, args),
);

Future<ToolSuccess<int>> _getLineCount(FileToolSet toolSet, Json args) async {
  // load args
  var path = args.getString('path').trim();
  if (path.startsWith('/')) path = path.substring(1);

  // check
  final file = await File(path).check<File>(toolSet.root);
  if (!toolSet.showHiddenFiles && file.isHidden) throw 'Access denied';
  if (!await file.exists()) {
    throw 'File not found: ${file.getLocalPath(toolSet.root)}.';
  }

  // proceed
  final lines = await FileReader.readLines(file);
  return ToolSuccess(lines.length);
}

final _inputSchema = Z.object(
  properties: {'path': Z.string(description: 'File path')},
  required: ['path'],
);
