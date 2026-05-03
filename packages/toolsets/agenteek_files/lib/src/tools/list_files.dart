import 'dart:io';

import 'package:agenteek/agenteek.dart';

import '../file_toolset.dart';
import '../file_reader/helpers.dart';

/// Lists all files and directories within a specified path.
///
/// - [args]: A JSON object containing the following optional fields:
///   - `path`: The directory to list from. Defaults to the root directory.
///   - `recursive`: Whether listing should recurse through sub-directories. Defaults to `false`.
///   - `includeHidden`: Whether to include hidden files/directories (starting with a dot). Defaults to `false`.
///
/// Returns a `Future<ToolSuccess>` which contains the list of file paths.
Tool<String> listFilesTool(FileToolSet toolSet) => Tool(
  name: toolSet.buildToolName('list_files'),
  description: toolSet.buildDescription(
    'Use this tool to list files in a given directory, or to locate a file; this tools lists **files only**, not directories',
  ),
  inputSchema: _inputSchema,
  onCall: (args) => _listFiles(toolSet, args),
);

Future<ToolSuccess<String>> _listFiles(FileToolSet toolSet, Json args) async {
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
  final results = StringBuffer(), pending = <Directory>[];
  if (includeHidden || !dir.isHidden) pending.add(dir);
  var idx = 0;
  while (idx < pending.length) {
    final dir = pending[idx++];
    await for (var e in dir.list(recursive: false, followLinks: false)) {
      if (!includeHidden && e.isHidden) continue;
      if (recursive && e is Directory) {
        pending.add(e);
      } else if (e is File) {
        results.writeln(e.getLocalPath(toolSet.root));
      }
    }
  }

  pending.removeAt(0); // do not include starting directory in results
  return ToolSuccess(results.toString());
}

final _inputSchema = z.object({
  'path': z.string('Directory to list from'.optional('root directory')),
  'recursive': z.bool(
    'Whether listing should recurse through sub-directories'.optional('false'),
  ),
  'includeHidden': z.bool(
    'Whether to include hidden files and directories (starting with a dot)'
        .optional('false'),
  ),
});
