import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';
import 'package:path/path.dart' as p;

import '../file_toolset.dart';

/// Locate a file by its base name.
///
/// - [args]: A JSON object containing the following field:
///   - `base_name`: The basename of the searched file.
///
/// Returns a `Future<ToolSuccess>` which resolves to the list of file paths.
Tool<String> locateFileTool(FileToolSet toolSet) => Tool(
  name: toolSet.buildToolName('locate_file'),
  description: toolSet.buildDescription('Use this tool to locate a file'),
  inputSchema: _inputSchema,
  onCall: (args) => _locateFile(toolSet, args),
);

Future<ToolSuccess<String>> _locateFile(FileToolSet toolSet, Json args) async {
  // load args
  final baseName = args.getString('baseName', defaultValue: '').trim();

  // check
  if (baseName.isEmpty) throw 'Missing base name';

  // proceed
  final results = StringBuffer(), pending = [Directory(toolSet.root)];
  var idx = 0;
  while (idx < pending.length) {
    final dir = pending[idx++];
    await for (var e in dir.list(recursive: false, followLinks: false)) {
      if (e is Directory) {
        pending.add(e);
      } else if (e is File) {
        final path = p.basename(e.path);
        if (path.contains(baseName)) {
          results.writeln(e.getLocalPath(toolSet.root));
        }
      }
    }
  }

  return ToolSuccess(results.toString());
}

final _inputSchema = Z.object(
  properties: {
    'baseName': Z.string(description: 'The file\'s base file name '),
  },
  required: ['baseName'],
);
