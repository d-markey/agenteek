import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_file_reader.dart';

import '../../agenteek_dart.dart';

// format
Tool formatTool(DartToolSet toolSet) => Tool(
  name: toolSet.buildToolName('format'),
  description: toolSet.buildDescription('Formats a Dart file or a directory'),
  inputSchema: _inputSchema,
  onCall: (args) => _format(toolSet, args),
);

Future<ToolSuccess<Json>> _format(DartToolSet toolSet, Json args) async {
  var path = args.getString('path', defaultValue: '').trim();
  if (path.startsWith('/')) path = path.substring(1);

  FileSystemEntity fileOrDir;
  if (path.isEmpty) {
    fileOrDir = Directory(toolSet.root);
  } else {
    fileOrDir = await Link(path).check(toolSet.root);
    if (!await fileOrDir.exists()) {
      throw 'Not found: ${fileOrDir.getLocalPath(toolSet.root)}';
    }
  }

  return ToolSuccess(await toolSet.exec('dart', ['format', fileOrDir.path]));
}

final _inputSchema = Z.object(
  properties: {
    'path': Z.string(
      description: 'The path of the file or directory to format'.optional(
        'root directory',
      ),
    ),
  },
  required: ['path'],
);
