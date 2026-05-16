import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files.dart';

extension type DeleteFileArgs(Json _json) {
  String get path => _normalizePath(_json.getString('path'));

  static final schema = S.object(
    properties: {'path': S.string(description: 'Path of the file to delete')},
    required: ['path'],
  );
}

extension type CreateFileArgs(Json _json) {
  String get path => _normalizePath(_json.getString('path'));

  String get text => _json.getString('text', defaultValue: '');

  static final schema = S.object(
    properties: {
      'path': S.string(description: 'File path'),
      'text': S.string(description: 'Text to write to the file'.optional('')),
    },
    required: ['path'],
  );
}

extension type DeleteLinesArgs(Json _json) {
  String get path => _normalizePath(_json.getString('path'));

  int get startLine => _json.getInt('startLine');

  int get endLine => _json.getInt('endLine');

  static final schema = S.object(
    properties: {
      'path': S.string(description: 'File path'),
      'startLine': S.integer(
        description:
            'Line number where deletion starts (1-based, as provided by `read_lines` with mode=`numbered`). Never guess this parameter, call `read_lines` first.',
      ),
      'endLine': S.integer(
        description:
            'Line number where deletion ends (1-based, inclusive, must be >= `startLine`). Never guess this parameter, call `read_lines` first.',
      ),
    },
    required: ['path', 'startLine', 'endLine'],
  );
}

extension type InsertTextArgs(Json _json) {
  String get path => _normalizePath(_json.getString('path'));

  int get line => _json.getInt('line');

  String get newText => _json.getString('newText').normalizeEol();

  static final schema = S.object(
    properties: {
      'path': S.string(description: 'File path'),
      'line': S.integer(
        description:
            'Line number where insertion starts (1-based, as provided by `read_lines` with mode=`numbered`). Never guess this parameter, call `read_lines` first.',
      ),
      'newText': S.string(description: 'Text to insert.'),
    },
    required: ['path', 'line', 'newText'],
  );
}

extension type ReadLinesArgs(Json _json) {
  String get path => _normalizePath(_json.getString('path'));

  int get startLine => _json.getInt('startLine', defaultValue: 1);

  int get endLine => _json.getInt('endLine', defaultValue: 0);

  String get mode {
    final mode = _json.getString('mode', defaultValue: 'raw').toLowerCase();
    return (mode == 'raw' || mode == 'numbered')
        ? mode
        : throw 'Invalid mode: $mode';
  }

  static final schema = S.object(
    properties: {
      'path': S.string(description: 'File path'),
      'startLine': S.integer(
        description: 'Starting line number (1-based)'.optional('1'),
      ),
      'endLine': S.integer(
        description:
            'Ending line number (inclusive, 1-based); if provided, must be >= startLine'
                .optional('last line in file'),
      ),
      'mode': S.string(
        description:
            'One of `raw` (lines are dumped as is) or `numbered` (line numbers are shown before each line).'
                .optional('raw'),
      ),
    },
    required: ['path'],
  );
}

extension type ReplaceTextArgs(Json _json) {
  String get path => _normalizePath(_json.getString('path'));

  String get originalText => _json.getString('originalText').normalizeEol();

  String get newText => _json.getString('newText').normalizeEol();

  List<int> get targetLines =>
      _json.getList<int>('targetLines', defaultValue: const []);

  static final schema = S.object(
    properties: {
      'path': S.string(description: 'File path'),
      'originalText': S.string(description: 'Original text'),
      'newText': S.string(description: 'New text'),
      'targetLines': S.list(
        items: S.integer(),
        description:
            'Line numbers where replacement is expected; when missing or empty, the original text will be replaced if and only if there is exactly one occurence'
                .optional('empty list'),
      ),
    },
    required: ['path', 'originalText', 'newText'],
  );
}

extension type SearchTextArgs(Json _json) {
  String get path => _normalizePath(_json.getString('path', defaultValue: ''));

  String get pattern => _json.getString('pattern');

  bool get caseSensitive => _json.getBool('caseSensitive', defaultValue: false);

  bool get includeHidden => _json.getBool('includeHidden', defaultValue: false);

  static final schema = S.object(
    properties: {
      'pattern': S.string(
        description:
            'Search pattern: raw string OR regular expression. To active a "RegExp" search, the pattern **MUST** be provided between slashes (`/`, eg: `/\\.java\$/`) otherwise it will be interpreted as a raw string. Case-sensitivity can be controlled via the `caseSensitive` argument.',
      ),
      'path': S.string(
        description:
            'Path to specific files or folders (must be a valid glob pattern, e.g. `dir/*.txt` to search for text files directly under `dir`, or `dir/**.txt` to search for all text files under `dir`)'
                .optional('root directory'),
      ),
      'caseSensitive': S.boolean(
        description: 'Whether the search is case-sensitive'.optional('false'),
      ),
      'includeHidden': S.boolean(
        description: 'Whether to include hidden files (starting with a dot)'
            .optional('false'),
      ),
    },
    required: ['pattern'],
  );
}

extension type UpdateFileArgs(Json _json) {
  String get path => _normalizePath(_json.getString('path'));

  String get newText => _json.getString('newText').normalizeEol();

  static final schema = S.object(
    properties: {
      'path': S.string(description: 'File path'),
      'newText': S.string(
        description:
            'New text to write to the file. The full file content will be replaced.',
      ),
    },
    required: ['path', 'newText'],
  );
}

extension type ListDirectoriesArgs(Json _json) {
  String get path => _normalizePath(_json.getString('path', defaultValue: ''));

  bool get recursive => _json.getBool('recursive', defaultValue: true);

  bool get includeHidden => _json.getBool('includeHidden', defaultValue: false);

  static final schema = S.object(
    properties: {
      'path': S.string(
        description: 'Directory to list from'.optional('root directory'),
      ),
      'recursive': S.boolean(
        description: 'Whether listing should recurse through sub-directories'
            .optional('true'),
      ),
      'includeHidden': S.boolean(
        description:
            'Whether to include hidden directories (starting with a dot)'
                .optional('false'),
      ),
    },
  );
}

extension type ListFilesArgs(Json _json) {
  String get path => _normalizePath(_json.getString('path', defaultValue: ''));

  bool get recursive => _json.getBool('recursive', defaultValue: false);

  bool get includeHidden => _json.getBool('includeHidden', defaultValue: false);

  static final schema = S.object(
    properties: {
      'path': S.string(
        description: 'Directory to list from'.optional('root directory'),
      ),
      'recursive': S.boolean(
        description: 'Whether listing should recurse through sub-directories'
            .optional('false'),
      ),
      'includeHidden': S.boolean(
        description:
            'Whether to include hidden files and directories (starting with a dot)'
                .optional('false'),
      ),
    },
  );
}

extension type LocateFileArgs(Json _json) {
  String get baseName => _json.getString('baseName');

  static final schema = S.object(
    properties: {
      'baseName': S.string(description: 'The file\'s base file name '),
    },
    required: ['baseName'],
  );
}

extension type GetLineCountArgs(Json _json) {
  String get path => _normalizePath(_json.getString('path'));

  static final schema = S.object(
    properties: {'path': S.string(description: 'File path')},
    required: ['path'],
  );
}

String _normalizePath(String path) {
  path = path.trim();
  if (path == '.') return '';
  return path.startsWith('/') ? path.substring(1) : path;
}
