import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:collection/collection.dart';
import 'package:dartantic_interface/dartantic_interface.dart' as ai_;
import 'package:glob/glob.dart';
import 'package:path/path.dart';

import '_helpers.dart' as internal;
import 'file_reader.dart';

/// A `ToolSet` that provides tools for interacting with the file system.
class FileToolSet extends ToolSet {
  /// Initializes a new instance of the `FileToolSet`.
  ///
  /// This constructor sets up the toolset, registering various file-related tools
  /// based on the provided permissions.
  ///
  /// - [prefix]: Used as a namespace for the file-related tools (e.g., `file_list`, `file_search`).
  /// - [scope]: An optional description of the scope covered by this toolset, to help the LLM select the right toolset.
  /// - [root]: The root directory for file operations (optional, defaults to '.').
  /// - [allowCreate]: Flag to allow file/directory creation.
  /// - [allowReplace]: Flag to allow file modification.
  /// - [allowDelete]: Flag to allow file deletion.
  /// - [showHiddenFiles]: Flag to allow listing/showing hidden files (starting with a dot).
  FileToolSet({
    required this.prefix,
    String? scope,
    String root = '.',
    this.displayRoot = '.',
    this.allowCreate = false,
    this.allowReplace = false,
    this.allowDelete = false,
    this.showHiddenFiles = false,
  }) : scope = scope?.trim() ?? '',
       root = internal.canonicalize(root) {
    // register tools
    register(_listFilesSpec);
    register(_locateFileSpec);
    register(_listDirectoriesSpec);
    register(_searchContentsSpec);
    register(_readLinesSpec);
    register(_getLineCountSpec);
    if (allowCreate) register(_createDirectorySpec);
    if (allowCreate) register(_createFileSpec);
    if (allowReplace) register(_replaceLinesSpec);
    if (allowDelete) register(_deleteFileSpec);
  }

  /// The prefix used as a namespace for file-related tools.
  final String prefix;

  /// A description of the scope covered by this toolset.
  final String scope;

  /// The root directory for all file operations performed by this toolset.
  final String root;

  /// The displayed root directory; used in tool descriptions to hidethe physical path of the root.
  final String displayRoot;

  /// A flag indicating whether file and directory creation is allowed.
  final bool allowCreate;

  /// A flag indicating whether file modification (replacing content or lines) is allowed.
  final bool allowReplace;

  /// A flag indicating whether file and directory deletion is allowed.
  final bool allowDelete;

  /// A flag indicating whether hidden files (starting with a dot) should be listed or shown.
  final bool showHiddenFiles;

  /// Lists all files and directories within a specified path.
  ///
  /// - [args]: A JSON object containing the following optional fields:
  ///   - `path`: The directory to list from. Defaults to the root directory.
  ///   - `recursive`: Whether listing should recurse through sub-directories. Defaults to `false`.
  ///   - `includeHidden`: Whether to include hidden files/directories (starting with a dot). Defaults to `false`.
  ///
  /// Returns a `Future<Json>` which resolves to a JSON object with one key:
  /// - `files`: A list of file paths.
  ai_.Tool get _listFilesSpec => ai_.Tool(
    name: '${prefix}_list_files',
    description: _scoped(
      'Use this tool to list files in a given directory or to locate a file',
    ),
    inputSchema: z.object({
      'path': z.string(_optional('Directory to list from', 'root directory')),
      'recursive': z.bool(
        _optional(
          'Whether listing should recurse through sub-directories',
          'false',
        ),
      ),
      'includeHidden': z.bool(
        _optional(
          'Whether to include hidden files and directories (starting with a dot)',
          'false',
        ),
      ),
    }),
    onCall: (args) async {
      args as Json;
      // load args
      var path = (args['path'] as String?)?.trim() ?? '';
      if (path.startsWith('/')) path = path.substring(1);
      final recursive = args['recursive'] as bool? ?? false;
      final includeHidden =
          (args['includeHidden'] as bool? ?? false) && showHiddenFiles;

      // check
      final dir = await Directory(path).check<Directory>(root);
      if (!showHiddenFiles && dir.isHidden) {
        throw 'Access denied: ${dir.getLocalPath(root)}';
      }
      if (!await dir.exists()) {
        throw 'Directory not found: ${dir.getLocalPath(root)}';
      }

      // proceed
      final files = <File>[], pending = <Directory>[];
      if (includeHidden || !dir.isHidden) pending.add(dir);
      var idx = 0;
      while (idx < pending.length) {
        final dir = pending[idx++];
        await for (var e in dir.list(recursive: false, followLinks: false)) {
          if (!includeHidden && e.isHidden) continue;
          if (recursive && e is Directory) {
            pending.add(e);
          } else if (e is File) {
            files.add(e);
          }
        }
      }

      pending.removeAt(0); // do not include starting directory in results

      return {'files': files.map((f) => f.getLocalPath(root)).toList()};
    },
  );

  /// Locate a file by its base name.
  ///
  /// - [args]: A JSON object containing the following field:
  ///   - `base_name`: The basename of the searched file.
  ///
  /// Returns a `Future<Json>` which resolves to a JSON object with one key:
  /// - `files`: A list of file paths.
  ai_.Tool get _locateFileSpec => ai_.Tool(
    name: '${prefix}_locate_file',
    description: _scoped('Use this tool to locate a file'),
    inputSchema: z.object(
      {'baseName': z.string('The file\'s base file name ')},
      required: ['baseName'],
    ),
    onCall: (args) async {
      args as Json;
      // load args
      var baseName = (args['baseName'] as String?)?.trim() ?? '';

      // check
      if (baseName.isEmpty) {
        throw 'Missing base name';
      }

      // proceed
      final files = <File>[], pending = [Directory(root)];
      var idx = 0;
      while (idx < pending.length) {
        final dir = pending[idx++];
        await for (var e in dir.list(recursive: false, followLinks: false)) {
          if (e is Directory) {
            pending.add(e);
          } else if (e is File) {
            final p = basename(e.path);
            if (p.contains(baseName)) {
              files.add(e);
            }
          }
        }
      }

      return {'files': files.map((f) => f.getLocalPath(root)).toList()};
    },
  );

  /// Lists all directories within a specified path.
  ///
  /// - [args]: A JSON object containing the following optional fields:
  ///   - `path`: The directory to list from. Defaults to the root directory.
  ///   - `recursive`: Whether listing should recurse through sub-directories. Defaults to `false`.
  ///   - `includeHidden`: Whether to include hidden directories (starting with a dot). Defaults to `false`.
  ///
  /// Returns a `Future<Json>` which resolves to a JSON object with one key:
  /// - `directories`: A list of directory paths.
  ai_.Tool get _listDirectoriesSpec => ai_.Tool(
    name: '${prefix}_list_directories',
    description: _scoped(
      'Use this tool to list directories in a given directory or to locate a directory',
    ),
    inputSchema: z.object({
      'path': z.string(_optional('Directory to list from', 'root directory')),
      'recursive': z.bool(
        _optional(
          'Whether listing should recurse through sub-directories',
          'false',
        ),
      ),
      'includeHidden': z.bool(
        _optional(
          'Whether to include hidden directories (starting with a dot)',
          'false',
        ),
      ),
    }),
    onCall: (args) async {
      args as Json;
      // load args
      var path = (args['path'] as String?)?.trim() ?? '';
      if (path.startsWith('/')) path = path.substring(1);
      final recursive = args['recursive'] as bool? ?? false;
      final includeHidden =
          (args['includeHidden'] as bool? ?? false) && showHiddenFiles;

      // check
      final dir = await Directory(path).check<Directory>(root);
      if (!showHiddenFiles && dir.isHidden) {
        throw 'Access denied: ${dir.getLocalPath(root)}';
      }
      if (!await dir.exists()) {
        throw 'Directory not found: ${dir.getLocalPath(root)}';
      }

      // proceed
      final pending = <Directory>[], results = <Directory>[];
      if (includeHidden || !dir.isHidden) pending.add(dir);
      var idx = 0;
      while (idx < pending.length) {
        final dir = pending[idx++];
        await for (var e in dir.list(recursive: false, followLinks: false)) {
          if (!includeHidden && e.isHidden) continue;
          if (e is Directory) {
            results.add(e);
            if (recursive) {
              pending.add(e);
            }
          }
        }
      }

      return {'directories': results.map((d) => d.getLocalPath(root)).toList()};
    },
  );

  /// Searches files for a specific regular expression pattern.
  ///
  /// - [args]: A JSON object containing the following fields:
  ///   - `pattern`: The search pattern (must be a valid regular expression).
  ///   - `path`: A Glob pattern to restrict the search to specific files or folders.
  ///   - `caseSensitive`: Optional. Whether the search is case-sensitive. Defaults to `false`.
  ///   - `includeHidden`: Optional. Whether to include hidden files (starting with a dot). Defaults to `false`.
  ///
  /// Returns a `Future<Json>` which resolves to a JSON object with a `matches` key,
  /// containing a map of matching occurrences. Map keys are files where matches have
  /// been found; map values contains the list of matches in the file (with `beginLine`,
  /// `endLine`,  and the `text` of the match).
  ai_.Tool get _searchContentsSpec => ai_.Tool(
    name: '${prefix}_search_contents',
    description: _scoped(
      'Use this tool to search file contents for a specific regular expression; '
      'a Glob pattern can be provided as the `path` argument to restrict the search to specific files, e.g. "*.java";'
      'if no `path` is provided, the search will be executed against all files.',
    ),
    inputSchema: z.object(
      {
        'pattern': z.string(
          'Search pattern (must be a valid regular expression)',
        ),
        'path': z.string(
          _optional(
            'Path to specific files or folders (must be a valid glob pattern, e.g. `dir/*.txt` to search for text files directly under `dir`, or `dir/**.txt` to search for all text files under `dir`)',
            '',
          ),
        ),
        'caseSensitive': z.bool(
          _optional('Whether the search is case-sensitive', 'false'),
        ),
        'includeHidden': z.bool(
          _optional(
            'Whether to include hidden files (starting with a dot)',
            'false',
          ),
        ),
      },
      required: ['pattern'],
    ),
    onCall: (args) async {
      args as Json;
      // load args
      final pattern = args['pattern'] as String;
      if (pattern == '.*' || pattern == '.+') {
        return {
          'error':
              'Do not use this tool with a "match all" pattern; '
              'if full content is required, use the ${_readLinesSpec.name} tool instead.',
        };
      }
      final path = (args['path'] as String?) ?? '';
      final caseSensitive = args['caseSensitive'] as bool? ?? false;
      final includeHidden =
          (args['includeHidden'] as bool? ?? false) && showHiddenFiles;

      // check
      if (pattern.isEmpty) return const {'matches': []};

      // proceed
      final regexp = RegExp(pattern, caseSensitive: caseSensitive);
      final bool Function(FileSystemEntity) $include;
      if (path.isNotEmpty) {
        final glob = Glob(path.replaceAll('\\', '/'));
        $include = (e) => (e is File) && glob.matches(e.getLocalPath(root));
      } else {
        $include = (e) => (e is File);
      }

      final allMatches = <String, List<Json>>{};
      final tasks = <Future<void>>[];

      Future<void> $search(File f, List<Json> matches) async {
        try {
          final text = await FileReader.readString(f), len = text.length;
          final lines = [0];
          for (var i = 0; i < len; i++) {
            if (text[i] == '\r' && i < len && text[i + 1] != '\n') {
              // \r not followed by \n
              lines.add(i + 1);
            } else if (text[i] == '\n') {
              // \n
              lines.add(i + 1);
            }
          }
          if (lines.last < len) lines.add(len);
          for (var match
              in regexp.allMatches(text).where(($) => $.end > $.start)) {
            // find matched lines
            var beginLine = lowerBound(lines, match.start);
            if (match.start != lines[beginLine]) beginLine -= 1;
            var endLine = lowerBound(lines, match.end - 1);
            if (match.end - 1 != lines[endLine]) endLine -= 1;
            // adjust end of match
            var end = lines[endLine + 1];
            if (end > 0 && text[end - 1] == '\n') end--;
            if (end > 0 && text[end - 1] == '\r') end--;
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
            'text':
                '**ERROR**: ${e.toString().replaceAll('\r', '\\r').replaceAll('\n', '\\n')}',
          });
        }
      }

      final directories = [Directory(root)];
      while (directories.isNotEmpty) {
        final dir = directories.removeLast();
        await for (var e in dir.list(recursive: false, followLinks: false)) {
          if (!includeHidden && e.isHidden) continue;
          if (e is Directory) {
            directories.add(e);
          } else if ($include(e)) {
            final matches = <Json>[];
            tasks.add(
              $search(e as File, matches).then((_) {
                if (matches.isNotEmpty) {
                  allMatches[e.getLocalPath(root)] = matches;
                }
              }),
            );
          }
        }
      }

      await Future.wait(tasks);

      return {'matches': allMatches};
    },
  );

  /// Creates a new directory at the specified path.
  ///
  /// - [args]: A JSON object containing the `path` field.
  ///   - `path`: The path of the directory to create.
  ///
  /// Returns a `Future<String>` which resolves to a success message.
  /// Throws an error if directory creation is not allowed or the path is invalid.
  ai_.Tool get _createDirectorySpec => ai_.Tool(
    name: '${prefix}_create_dir',
    description: _scoped('Create a new directory'),
    inputSchema: z.object(
      {'path': z.string('Directory path')},
      required: ['path'],
    ),
    onCall: (args) async {
      args as Json;
      // load args
      var path = (args['path'] as String).trim();
      if (path.startsWith('/')) path = path.substring(1);

      // check
      final dir = await Directory(path).check<Directory>(root);
      if (!showHiddenFiles && dir.isHidden) throw 'Access denied';

      // proceed
      if (!await dir.exists()) {
        if (!allowCreate) {
          throw 'Directory creation denied: ${dir.getLocalPath(root)}';
        }
        if (!showHiddenFiles) {
          var d = Directory(dir.getLocalPath(root));
          while (d.path != '.') {
            if (d.isHidden) {
              throw 'Directory creation denied: ${dir.getLocalPath(root)}';
            }
            d = d.parent;
          }
        }
        await dir.create(recursive: true);
      }
      return 'Directory ${dir.getLocalPath(root)} created successfully.';
    },
  );

  /// Creates a new file at the specified path.
  ///
  /// - [args]: A JSON object containing the `path` field.
  ///   - `path`: The path of the file to create.
  ///
  /// Returns a `Future<String>` which resolves to a success message.
  /// Throws an error if file creation is not allowed or the path is invalid.
  ai_.Tool get _createFileSpec => ai_.Tool(
    name: '${prefix}_create_file',
    description: _scoped('Create a new file'),
    inputSchema: z.object({'path': z.string('File path')}, required: ['path']),
    onCall: (args) async {
      args as Json;
      // load args
      var path = (args['path'] as String).trim();
      if (path.startsWith('/')) path = path.substring(1);

      // check
      final file = await File(path).check<File>(root);
      if (!showHiddenFiles && file.isHidden) throw 'Access denied';

      // proceed
      if (await file.exists()) {
        throw 'File already exists: ${file.getLocalPath(root)}';
      }
      if (!showHiddenFiles) {
        if (file.isHidden) {
          throw 'File creation denied: ${file.getLocalPath(root)}';
        }
        var d = Directory(file.getLocalPath(root));
        while (d.path != '.') {
          if (d.isHidden) {
            throw 'File creation denied: ${file.getLocalPath(root)}';
          }
          d = d.parent;
        }
      }
      await file.parent.create(recursive: true);
      await file.writeAsString('');
      return 'File ${file.getLocalPath(root)} created successfully.';
    },
  );

  /// Reads a portion of a file, given a start and end line.
  ///
  /// - [args]: A JSON object containing the `path`, `startLine`, and optional `endLine` fields.
  ///   - `path`: The path of the file to read.
  ///   - `startLine`: The starting line number (1-based).
  ///   - `endLine`: Optional. The ending line number (inclusive, 1-based). If provided, must be >= `startLine`. Defaults to the last line in the file.
  ///
  /// Returns a `Future<Json>` which resolves to a JSON object with a `lines` key,
  /// containing a list of objects. Each object has `line` (line number) and `text` (line content).
  ai_.Tool get _readLinesSpec => ai_.Tool(
    name: '${prefix}_read_lines',
    description: _scoped(
      'Reads a chunk from a file, given start and end line numbers',
    ),
    inputSchema: z.object(
      {
        'path': z.string('File path'),
        'startLine': z.int('Starting line number (1-based)'),
        'endLine': z.int(
          _optional(
            'Ending line number (inclusive, 1-based); if provided, must be >= startLine',
            'last line in file',
          ),
        ),
      },
      required: ['path', 'startLine'],
    ),
    onCall: (args) async {
      args as Json;
      // load args
      var path = (args['path'] as String).trim();
      if (path.startsWith('/')) path = path.substring(1);
      var startLine = args['startLine'] as int;
      var endLine = args['endLine'] as int?;

      // check
      final file = await File(path).check<File>(root);
      if (!showHiddenFiles && file.isHidden) throw 'Access denied';
      if (!await file.exists()) throw 'File not found: $path.';
      if (startLine < 1 || (endLine != null && endLine < startLine)) {
        throw 'Invalid line numbers. startLine must be >= 1 and <= endLine.';
      }

      // proceed
      final lines = await FileReader.readLines(file);
      List<String> selectedLines;
      if (lines.isEmpty || startLine > lines.length) {
        selectedLines = const [];
      } else {
        endLine ??= lines.length;
        if (endLine > lines.length) endLine = lines.length;
        selectedLines = lines.sublist(startLine - 1, endLine);
      }
      return {'lines': selectedLines};
    },
  );

  /// Replaces selected lines of a file with new content.
  ///
  /// - [args]: A JSON object containing the `path`, `startLine`, optional `endLine`, and `newContent` fields.
  ///   - `path`: The path of the file to modify.
  ///   - `startLine`: The starting line number (1-based).
  ///   - `endLine`: Optional. The ending line number (inclusive, 1-based). If provided, must be >= `startLine`. Defaults to the last line in the file.
  ///   - `newContent`: The new content to replace the lines with.
  ///
  /// Returns a `Future<String>` which resolves to a success message.
  /// Throws an error if file modification is not allowed or line numbers are invalid.
  ai_.Tool get _replaceLinesSpec => ai_.Tool(
    name: '${prefix}_replace_lines',
    description: _scoped('Replace selected lines of a file with new content'),
    inputSchema: z.object(
      {
        'path': z.string('File path'),
        'startLine': z.int('Starting line number (1-based)'),
        'endLine': z.int(
          _optional(
            'Ending line number (inclusive, 1-based); if provided, must be >= startLine',
            'last line in file',
          ),
        ),
        'newContent': z.string('New content to replace the lines with'),
      },
      required: ['path', 'startLine', 'newContent'],
    ),
    onCall: (args) async {
      args as Json; // load args
      var path = (args['path'] as String).trim();
      if (path.startsWith('/')) path = path.substring(1);
      final startLine = args['startLine'] as int;
      var endLine = args['endLine'] as int?;
      final newContent = args['newContent'] as String;

      // check
      final file = await File(path).check<File>(root);
      if (!showHiddenFiles && file.isHidden) throw 'Access denied';
      if (!await file.exists()) throw 'File not found: $path.';
      if (startLine < 1 || (endLine != null && endLine < startLine)) {
        throw 'Invalid line numbers. startLine must be >= 1 and <= endLine.';
      }

      // proceed
      final lines = await FileReader.readLines(file);
      endLine ??= lines.length;
      if (endLine > lines.length) endLine = lines.length;
      if (startLine > lines.length) {
        lines.add(newContent);
      } else {
        lines.replaceRange(startLine - 1, endLine, [
          if (newContent.isNotEmpty) newContent,
        ]);
      }
      await file.writeAsString(lines.join('\n'));
      return 'Lines $startLine-$endLine in file ${file.getLocalPath(root)} replaced successfully.';
    },
  );

  /// Gets the number of lines in a file.
  ///
  /// - [args]: A JSON object containing the `path` field.
  ///   - `path`: The path of the file to count lines from.
  ///
  /// Returns a `Future<Json>` which resolves to a JSON object with a `lineCount` key,
  /// containing the total number of lines in the file.
  ai_.Tool get _getLineCountSpec => ai_.Tool(
    name: '${prefix}_line_count',
    description: _scoped('Gets the number of lines in a file'),
    inputSchema: z.object({'path': z.string('File path')}, required: ['path']),
    onCall: (args) async {
      args as Json;
      // load args
      var path = (args['path'] as String).trim();
      if (path.startsWith('/')) path = path.substring(1);

      // check
      final file = await File(path).check<File>(root);
      if (!showHiddenFiles && file.isHidden) throw 'Access denied';
      if (!await file.exists()) {
        throw 'File not found: ${file.getLocalPath(root)}.';
      }

      // proceed
      final lines = await FileReader.readLines(file);
      return {'lineCount': lines.length};
    },
  );

  /// Deletes a file or an empty directory.
  ///
  /// - [args]: A JSON object containing the `path` field.
  ///   - `path`: The path of the file or directory to delete.
  ///
  /// Returns a `Future<String>` which resolves to a success message.
  /// Throws an error if deletion is not allowed, the path is invalid, or the directory is not empty.
  ai_.Tool get _deleteFileSpec => ai_.Tool(
    name: '${prefix}_delete',
    description: _scoped('Delete a file or an empty directory'),
    inputSchema: z.object(
      {'path': z.string('File or directory path')},
      required: ['path'],
    ),
    onCall: (args) async {
      args as Json; // load args
      var path = (args['path'] as String).trim();
      if (path.startsWith('/')) path = path.substring(1);

      // check
      final entity = await Link(path).check(root);
      if (!showHiddenFiles && entity.isHidden) throw 'Access denied';
      if (!allowDelete) {
        throw 'File/directory deletion denied: ${entity.getLocalPath(root)}';
      }

      // proceed
      if (await entity.exists()) {
        await entity.delete();
      }
      return 'File/directory ${entity.getLocalPath(root)} deleted successfully.';
    },
  );

  /// A helper method to generate a scoped description for tool functions.
  ///
  /// - [description]: The base description of the tool.
  ///
  /// Returns a string with the description, including the root path and
  /// an optional scope.
  String _scoped(String description) => scope.isEmpty
      ? '$description (root `$displayRoot`).'
      : '$description (root `$displayRoot`); **scope: $scope**. ';

  /// A helper method to generate a description for optional parameters.
  ///
  /// - [description]: The base description of the optional parameter.
  /// - [def]: The default value of the parameter.
  ///
  /// Returns a string indicating that the parameter is optional and its default value.
  String _optional(String description, String def) =>
      '$description; optional, default="$def"';
}
