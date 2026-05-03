import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/src/file_reader/helpers.dart';

import '../file_toolset.dart';

/// Lists all directories within a specified path.
///
/// - [args]: A JSON object containing the following optional fields:
///   - `path`: The directory to list from. Defaults to the root directory.
///   - `recursive`: Whether listing should recurse through sub-directories. Defaults to `false`.
///   - `includeHidden`: Whether to include hidden directories (starting with a dot). Defaults to `false`.
///
/// Returns a `Future<ToolSuccess>` which contains the list of directory paths.
Tool<String> listDirectoriesTool(FileToolSet toolSet) => Tool(
  name: toolSet.buildToolName('list_directories'),
  description: toolSet.buildDescription(
    'Use this tool to list directories in a given directory, or to locate a directory; this tools lists **directories only**, not files',
  ),
  inputSchema: _inputSchema,
  onCall: (args) => _listDirectories(toolSet, args),
);

Future<ToolSuccess<String>> _listDirectories(
  FileToolSet toolSet,
  Json args,
) async {
  // load args
  var path = args.getString('path', defaultValue: '.').trim();
  if (path.startsWith('/')) path = path.substring(1);
  final recursive = args.getBool('recursive', defaultValue: false);
  final includeHidden =
      args.getBool('includeHidden', defaultValue: false) &&
      toolSet.showHiddenFiles;

  // check
  final dir = await Directory(path).check<Directory>(toolSet.root);
  if (!toolSet.showHiddenFiles && dir.isHidden) throw 'Access denied';
  if (!await dir.exists()) {
    throw 'Directory not found: ${dir.getLocalPath(toolSet.root)}';
  }

  // proceed
  final pending = <Directory>[], results = StringBuffer();
  if (includeHidden || !dir.isHidden) pending.add(dir);
  var idx = 0;
  while (idx < pending.length) {
    final dir = pending[idx++];
    await for (var e in dir.list(recursive: false, followLinks: false)) {
      if (!includeHidden && e.isHidden) continue;
      if (e is Directory) {
        results.writeln(e.getLocalPath(toolSet.root));
        if (recursive) {
          pending.add(e);
        }
      }
    }
  }

  return ToolSuccess(results.toString());
}

final _inputSchema = Z.object(
  properties: {
    'path': Z.string(
      description: 'Directory to list from'.optional('root directory'),
    ),
    'recursive': Z.boolean(
      description: 'Whether listing should recurse through sub-directories'
          .optional('false'),
    ),
    'includeHidden': Z.boolean(
      description: 'Whether to include hidden directories (starting with a dot)'
          .optional('false'),
    ),
  },
);
