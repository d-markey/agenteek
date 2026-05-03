import 'dart:io';

import 'package:agenteek/agenteek.dart';

import '../file_toolset.dart';
import '../file_reader/helpers.dart';

/// Updates an existing file at the specified path.
///
/// - [args]: A JSON object containing the `path` and `newText` fields.
///   - `path`: The path of the file to update.
///   - `newText`: The new text.
///
/// Returns a `Future<ToolSuccess>` which contains 'OK'.
Tool<String> updateFileTool(FileToolSet toolSet) => Tool(
  name: toolSet.buildToolName('update_file'),
  description: toolSet.buildDescription(
    'Update an existing file'.sideEffect('the line numbers might change'),
  ),
  inputSchema: _inputSchema,
  onCall: (args) => _updateFile(toolSet, args),
);

Future<ToolSuccess<String>> _updateFile(FileToolSet toolSet, Json args) async {
  // load args
  var path = args.getString('path').trim();
  if (path.startsWith('/')) path = path.substring(1);
  final newText = args.getString('newText', defaultValue: '');

  // check
  final file = await File(path).check<File>(toolSet.root);
  if (!toolSet.showHiddenFiles && file.isHidden) throw 'Access denied';

  // proceed
  if (!(await file.exists())) {
    throw 'File does not exists: ${file.getLocalPath(toolSet.root)}';
  }
  if (!toolSet.showHiddenFiles) {
    if (file.isHidden) {
      throw 'File update denied: ${file.getLocalPath(toolSet.root)}';
    }
    var d = Directory(file.getLocalPath(toolSet.root));
    while (d.path != '.') {
      if (d.isHidden) {
        throw 'File update denied: ${file.getLocalPath(toolSet.root)}';
      }
      d = d.parent;
    }
  }
  await file.writeAsString(newText);
  return ToolSuccess.ok;
}

final _inputSchema = z.object(
  {
    'path': z.string('File path'),
    'newText': z.string(
      'New text to write to the file. The full file content will be replaced.',
    ),
  },
  required: ['path', 'newText'],
);
