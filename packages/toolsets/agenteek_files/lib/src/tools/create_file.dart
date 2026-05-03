import 'dart:io';

import 'package:agenteek/agenteek.dart';

import '../file_toolset.dart';
import '../file_reader/helpers.dart';

/// Creates a new file at the specified path.
///
/// - [args]: A JSON object containing the `path` field.
///   - `path`: The path of the file to create.
///
/// Returns a `Future<ToolSuccess>` which contains 'OK'.
Tool<String> createFileTool(FileToolSet toolSet) => Tool(
  name: toolSet.buildToolName('create_file'),
  description: toolSet.buildDescription('Create a new file'),
  inputSchema: _inputSchema,
  onCall: (args) => _createFile(toolSet, args),
);

Future<ToolSuccess<String>> _createFile(FileToolSet toolSet, Json args) async {
  // load args
  var path = args.getString('path').trim();
  if (path.startsWith('/')) path = path.substring(1);
  final text = args.getString('text', defaultValue: '');

  // check
  final file = await File(path).check<File>(toolSet.root);
  if (!toolSet.showHiddenFiles && file.isHidden) throw 'Access denied';

  // proceed
  if (await file.exists()) {
    throw 'File already exists: ${file.getLocalPath(toolSet.root)}';
  }
  if (!toolSet.showHiddenFiles) {
    if (file.isHidden) {
      throw 'File creation denied: ${file.getLocalPath(toolSet.root)}';
    }
    var d = Directory(file.getLocalPath(toolSet.root));
    while (d.path != '.') {
      if (d.isHidden) {
        throw 'File creation denied: ${file.getLocalPath(toolSet.root)}';
      }
      d = d.parent;
    }
  }
  await file.parent.create(recursive: true);
  await file.writeAsString(text);
  return ToolSuccess.ok;
}

final _inputSchema = Z.object(
  properties: {
    'path': Z.string(description: 'File path'),
    'text': Z.string(description: 'Text to write to the file'.optional()),
  },
  required: ['path'],
);
