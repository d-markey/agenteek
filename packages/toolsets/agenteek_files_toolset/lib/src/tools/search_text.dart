import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';
import 'package:collection/collection.dart';
import 'package:glob/glob.dart';

import '../file_toolset.dart';
import '_json_arguments.dart';

/// Searches files for a specific regular expression pattern.
///
/// - [args]: A JSON object containing the following fields:
///   - `pattern`: The search pattern (must be a valid regular expression).
///   - `path`: A Glob pattern to restrict the search to specific files or folders.
///   - `caseSensitive`: Optional. Whether the search is case-sensitive. Defaults to `false`.
///   - `includeHidden`: Optional. Whether to include hidden files (starting with a dot). Defaults to `false`.
///
/// Returns a `Future<ToolSuccess>` which contains the list of matches in a Json map:
/// ```
/// {
///   "<file_name>": [
///     {
///       "beginLine": <number>,
///       "endLine": <number>,
///       "text": "<contents>"
///     }
///   ]
/// }
/// ```
Tool<Json> searchTextTool(FileToolSet toolSet) => Tool(
  name: toolSet.buildToolName('search_text'),
  description: toolSet.buildDescription(
    'Use this tool to search file contents for case-insensitive search and advanced search with a regular expression; '
    'a Glob pattern can be provided as the `path` argument to restrict the search to specific files, e.g. "*.java";'
    'if no `path` is provided, the search will be executed against all files.',
  ),
  inputSchema: SearchTextArgs.schema,
  onCall: (args) => _searchText(toolSet, SearchTextArgs(args)),
);

Future<ToolSuccess<Json>> _searchText(
  FileToolSet toolSet,
  SearchTextArgs args,
) async {
  // check
  final caseSensitive = args.caseSensitive;
  var str = args.pattern;
  Pattern pattern;
  if (str.startsWith('/') && str.endsWith('/')) {
    str = str.substring(1, str.length - 1);
    pattern = RegExp(str, caseSensitive: caseSensitive);
  } else {
    pattern = caseSensitive ? str : str.toLowerCase();
  }
  if (str.isEmpty || (pattern is RegExp && (str == '.*' || str == '.+'))) {
    throw 'Do not use this tool with an empty pattern or a "match all" pattern; '
        'if full content is required, use the `read_lines` tool instead.';
  }
  final path = args.path;
  if (path.startsWith('..')) {
    throw 'Access denied: cannot search outside of the root directory.';
  }

  // proceed
  final bool Function(FileSystemEntity) $include;
  if (path.isNotEmpty) {
    final glob = Glob(path.replaceAll('\\', '/'));
    $include = (e) => (e is File) && glob.matches(e.getLocalPath(toolSet.root));
  } else {
    $include = (e) => (e is File);
  }

  final includeHidden = args.includeHidden && toolSet.showHiddenFiles;

  final allMatches = <String, List<Json>>{};
  final tasks = <Future<void>>[];

  Future<void> $search(File f) async {
    final matches = <Json>[];
    try {
      final text = (await FileReader.readString(f)).normalizeEol();
      final srch = caseSensitive ? text : text.toLowerCase();
      final len = text.length;
      final lines = [0];
      for (var i = 0; i < len; i++) {
        if (text[i] == '\n') {
          lines.add(i + 1);
        }
      }
      if (lines.last < len) lines.add(len);
      for (var match
          in pattern.allMatches(srch).where(($) => $.end > $.start)) {
        // find matched lines
        var beginLine = lowerBound(lines, match.start);
        if (match.start != lines[beginLine]) beginLine -= 1;
        var endLine = lowerBound(lines, match.end - 1);
        if (match.end - 1 != lines[endLine]) endLine -= 1;
        // adjust end of match
        var end = lines[endLine + 1];
        if (end > 0 && text[end - 1] == '\n') end--;
        // add match
        final m = text.substring(lines[beginLine], end).trim();
        if (m.isNotEmpty) {
          matches.add({
            'beginLine': (beginLine + 1).toString(),
            'endLine': (endLine + 1).toString(),
            'text': m,
          });
        }
      }
    } catch (e) {
      matches.add({
        'beginLine': '**ERROR**',
        'endLine': '**ERROR**',
        'text': '**ERROR**: $e',
      });
    }

    if (matches.isNotEmpty) {
      allMatches[f.getLocalPath(toolSet.root)] = matches;
    }
  }

  final directories = [Directory(toolSet.root)];
  while (directories.isNotEmpty) {
    final dir = directories.removeLast();
    await for (var e in dir.list(recursive: false, followLinks: false)) {
      if (!includeHidden && e.isHidden) continue;
      if (e is Directory) {
        directories.add(e);
      } else if ($include(e)) {
        tasks.add($search(e as File));
      }
    }
  }

  await Future.wait(tasks);

  return ToolSuccess(allMatches);
}
