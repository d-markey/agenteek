import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';

import '../file_toolset.dart';
import '_json_arguments.dart';

/// Lists all files and directories within a specified path.
///
/// - [args]: A JSON object containing the following optional fields:
///   - `path`: The directory to list from. Defaults to the root directory.
///   - `recursive`: Whether listing should recurse through sub-directories. Defaults to `false`.
///   - `includeHidden`: Whether to include hidden files/directories (starting with a dot). Defaults to `false`.
///
/// Returns a `Future<ToolSuccess>` which contains the list of files/directories.
Tool<String> listTool(FileToolSet toolSet) => Tool(
  name: toolSet.buildToolName('list'),
  description: toolSet.buildDescription(
    'Use this tool to list files & directories',
  ),
  inputSchema: ListArgs.schema,
  onCall: (args) => _list(toolSet, ListArgs(args)),
);

Future<ToolSuccess<String>> _list(FileToolSet toolSet, ListArgs args) async {
  // check
  Directory dir;
  if (args.path.isEmpty) {
    dir = Directory(toolSet.root);
  } else {
    dir = await Directory(
      args.path,
    ).check<Directory>(toolSet.root, includeHidden: toolSet.showHiddenFiles);
  }
  if (!await dir.exists()) {
    throw 'Directory not found: "${toolSet.getLocalPath(dir)}"';
  }

  // proceed
  final recursive = args.recursive;
  final includeHidden = args.includeHidden && toolSet.showHiddenFiles;
  final results = StringBuffer(), pending = <Directory>[];
  if (includeHidden || !dir.isHidden) pending.add(dir);
  var idx = 0, count = 0;
  while (idx < pending.length) {
    final dir = pending[idx++];
    count = 0;
    results.writeln('Directory: ${toolSet.getLocalPath(dir)}');
    for (var e in dir.listSync(recursive: false, followLinks: false)) {
      if (!includeHidden && e.isHidden) continue;
      if (e is Directory) {
        if (recursive) pending.add(e);
      } else if (e is File) {
        results.writeln('  * ${toolSet.getLocalPath(e)}');
        count++;
      }
    }
    if (count == 0) results.writeln('  (empty)');
  }

  return ToolSuccess(results.toString());
}
