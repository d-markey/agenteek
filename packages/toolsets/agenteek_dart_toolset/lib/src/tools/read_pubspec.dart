import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';
import 'package:path/path.dart' as p;

import '../dart_toolset.dart';

/// reads the pubspec.yaml file in a directory
Tool readPubspecTool(DartToolSet toolSet) => Tool(
  name: toolSet.buildToolName('read_pubspec'),
  description: toolSet.buildDescription('Reads the `pubspec.yaml` file'),
  inputSchema: _inputSchema,
  onCall: (args) => _readPubSpec(toolSet, args),
);

Future<ToolSuccess<String>> _readPubSpec(DartToolSet toolSet, Json args) async {
  var path = (args['path'] as String?)?.trim() ?? '';
  if (path.startsWith('/')) path = path.substring(1);

  if (path.isEmpty) path = toolSet.root;
  final file = await File(
    p.join(path, 'pubspec.yaml'),
  ).check<File>(toolSet.root);
  if (!await file.exists()) {
    throw 'Not found: ${file.getLocalPath(toolSet.root)}';
  }

  return ToolSuccess(await FileReader.readString(file));
}

final _inputSchema = Z.object(
  properties: {
    'path': Z.string(
      description: 'The path of the directory where "pubspec.yaml" is located'
          .optional('root directory'),
    ),
  },
  required: ['path'],
);
