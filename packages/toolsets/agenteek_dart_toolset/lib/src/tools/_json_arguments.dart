import 'package:agenteek/agenteek.dart';

extension type DirectoryOrFileArgs(Json _json) {
  String get path {
    final p = _json.getString('path', defaultValue: '');
    return p.startsWith('/') ? p.substring(1) : p;
  }

  static final schema = S.object(
    properties: {
      'path': S.string(
        description: 'Path to the directory or file.'.optional(
          'root directory',
        ),
      ),
    },
  );
}

extension type TestArgs(Json _json) {
  String get path {
    final p = _json.getString('path', defaultValue: '');
    return p.startsWith('/') ? p.substring(1) : p;
  }

  String get nameFilter => _json.getString('nameFilter', defaultValue: '');

  int get concurrency => _json.getInt('concurrency', defaultValue: 2);

  int get timeout => _json.getInt('timeout', defaultValue: 300);

  static final schema = S.object(
    properties: {
      'path': S.string(
        description: 'Path to the directory or file.'.optional(
          'root directory',
        ),
      ),
      'nameFilter': S.string(
        description:
            'Plain name filter to run only matching tests (the "--plain-name" argument). '
                    'When empty, all tests are run.'
                .optional(''),
      ),
      'concurrency': S.integer(
        description:
            'The number of concurrent test suites (the "--concurrency" argument). '
                    'When provided, must be positive and non-zero.'
                .optional('4'),
      ),
      'timeout': S.integer(
        description:
            'An optional timeout in seconds for the full test process (not per test case).'
                .optional('300'),
      ),
    },
  );
}

extension type RunArgs(Json _json) {
  String get scriptPath {
    final p = _json.getString('scriptPath');
    return p.startsWith('/') ? p.substring(1) : p;
  }

  int get timeout => _json.getInt('timeout', defaultValue: 180);

  static final schema = S.object(
    properties: {
      'scriptPath': S.string(description: 'The path to the Dart script.'),
      'timeout': S.integer(
        description: 'An optional timeout in seconds.'.optional('180'),
      ),
    },
    required: ['scriptPath'],
  );
}

extension type PubGetArgs(Json _json) {
  String get path {
    final path = _json.getString('path', defaultValue: '');
    return path.startsWith('/') ? path.substring(1) : path;
  }

  String get mode {
    final mode = _json.getString('mode', defaultValue: 'get').toLowerCase();
    return (mode == 'get' || mode == 'upgrade')
        ? mode
        : throw 'Invalid mode: $mode';
  }

  static final schema = S.object(
    properties: {
      'path': S.string(
        description: 'The path of the directory where to get/update packages'
            .optional('root directory'),
      ),
      'mode': S.string(
        description: 'One of `get` or `upgrade`'.optional('get'),
      ),
    },
    required: ['path', 'mode'],
  );
}
