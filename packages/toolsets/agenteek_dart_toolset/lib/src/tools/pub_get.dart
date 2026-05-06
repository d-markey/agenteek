import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';

import '../dart_toolset.dart';

/// Gets or upgrades packages in a directory
Tool pubGetTool(DartToolSet toolSet) => Tool(
  name: toolSet.buildToolName('pub_get'),
  description: toolSet.buildDescription('Gets or upgrades packages'),
  inputSchema: _inputSchema,
  onCall: (args) => _pubGet(toolSet, args),
);

Future<ToolSuccess<Json>> _pubGet(DartToolSet toolSet, Json args) async {
  var path = args.getString('path', defaultValue: '').trim();
  if (path.startsWith('/')) path = path.substring(1);
  final mode = args.getString('mode', defaultValue: 'get').toLowerCase();

  if (mode != 'get' && mode != 'upgrade') {
    throw 'Invalid mode: $mode';
  }

  Directory dir;
  if (path.isEmpty) {
    dir = Directory(toolSet.root);
  } else {
    dir = await Link(path).check<Directory>(toolSet.root);
    if (!await dir.exists()) {
      throw 'Not found: ${dir.getLocalPath(toolSet.root)}';
    }
  }

  return ToolSuccess(
    await toolSet.exec('dart', ['pub', mode, '--directory=${dir.path}']),
  );
}

final _inputSchema = Z.object(
  properties: {
    'path': Z.string(
      description: 'The path of the directory where to get/update packages'
          .optional('root directory'),
    ),
    'mode': Z.string(description: 'One of `get` or `upgrade`'.optional('get')),
  },
  required: ['path', 'mode'],
);
