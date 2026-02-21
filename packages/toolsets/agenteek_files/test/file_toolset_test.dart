import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'extensions.dart';

void main() {
  group('FileToolSet', () {
    late Directory tempDir;
    final pfx = 'fs';

    setUp(() async {
      tempDir = (await Directory.systemTemp.createTemp(
        'file_tool_set_test',
      )).absolute;
      final subdir = await Directory(p.join(tempDir.path, 'subdir')).create();
      await File(p.join(tempDir.path, 'test.dart')).writeAsString(
        '// IN ROOT\n'
        'import \'dart:io\';',
      );
      await File(p.join(subdir.path, 'test.dart')).writeAsString(
        '// IN SUBDIR\n'
        'import \'dart:io\';',
      );
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    group('list files', () {
      test('from root directory', () async {
        final allFiles = FileToolSet(prefix: pfx, root: tempDir.path);
        final res = await allFiles.jsonCall('list_files');
        expect(res['error'], isNull);
        expect(res['files'], isA<List>());
        expect(res['files'] as List, hasLength(1));
      });

      test('recursive from root directory', () async {
        final allFiles = FileToolSet(prefix: pfx, root: tempDir.path);
        final args = {'recursive': true};
        final res = await allFiles.jsonCall('list_files', args);
        expect(res['error'], isNull);
        expect(res['files'], isA<List>());
        expect(res['files'] as List, hasLength(2));
      });

      test('from sub directory', () async {
        final allFiles = FileToolSet(prefix: pfx, root: tempDir.path);
        final args = {'path': 'subdir'};
        final res = await allFiles.jsonCall('list_files', args);
        expect(res['error'], isNull);
        expect(res['files'], isA<List>());
        expect(res['files'] as List, hasLength(1));
      });

      test('from root directory parent', () async {
        final allFiles = FileToolSet(prefix: pfx, root: tempDir.path);
        final args = {'path': '..'};
        final res = await allFiles.jsonCall('list_files', args);
        expectError(res, contains('denied'));
        expect(res['files'], isNull);
      });

      test('from root directory exclude hidden files', () async {
        final allFiles = FileToolSet(prefix: pfx, root: tempDir.path);
        await File(
          p.join(tempDir.path, '.hidden_file.txt'),
        ).writeAsString('hidden file');
        await Directory(p.join(tempDir.path, '.hidden_dir')).create();
        await File(
          p.join(tempDir.path, '.hidden_dir', 'file_in_hidden_dir.txt'),
        ).writeAsString('visible file in hidden dir');

        final res = await allFiles.jsonCall('list_files');
        expect(res['error'], isNull);
        expect(res['files'], isA<List>());

        final files = (res['files'] as List).cast<String>();

        expect(files.any((f) => f.contains('.hidden_file')), isFalse);
        expect(files.any((f) => f.contains('.file_in_hidden_dir')), isFalse);
      });

      test('recursive listing', () async {
        final allFiles = FileToolSet(prefix: pfx, root: tempDir.path);
        final args = {'recursive': true};
        final res = await allFiles.jsonCall('list_files', args);
        expect(res['error'], isNull);
        expect(res['files'], isA<List>());

        final files = (res['files'] as List).cast<String>();

        expect(
          files.where((f) => f.contains('test.dart')),
          hasLength(greaterThanOrEqualTo(2)),
        ); // test.dart in root and subdir
      });
    });

    group('search in files', () {
      test('in root', () async {
        final allFiles = FileToolSet(prefix: pfx, root: tempDir.path);
        final args = {'pattern': '\'dart:io\''};
        var result = await allFiles.jsonCall('search_contents', args);
        expect(result['error'], isNull);
        expect(
          result['matches'] as Map,
          equals({
            'test.dart': [
              {'beginLine': '2', 'endLine': '2', 'text': 'import \'dart:io\';'},
            ],
            'subdir\\test.dart': [
              {'beginLine': '2', 'endLine': '2', 'text': 'import \'dart:io\';'},
            ],
          }),
        );

        final subdirFiles = FileToolSet(
          prefix: 'subdir',
          root: p.join(tempDir.path, 'subdir'),
        );
        result = await subdirFiles.jsonCall('search_contents', args);
        expect(result['error'], isNull);
        expect(
          result['matches'] as Map,
          equals({
            'test.dart': [
              {'beginLine': '2', 'endLine': '2', 'text': 'import \'dart:io\';'},
            ],
          }),
        );
      });

      test('with extension', () async {
        final allFiles = FileToolSet(prefix: pfx, root: tempDir.path);
        final args = {'pattern': '\'dart:io\'', 'path': '**.dart'};
        var result = await allFiles.jsonCall('search_contents', args);
        expect(result['error'], isNull);
        expect(
          result['matches'] as Map,
          equals({
            'test.dart': [
              {'beginLine': '2', 'endLine': '2', 'text': 'import \'dart:io\';'},
            ],
            'subdir\\test.dart': [
              {'beginLine': '2', 'endLine': '2', 'text': 'import \'dart:io\';'},
            ],
          }),
        );
      });

      test('in specific subdirectory', () async {
        final allFiles = FileToolSet(prefix: pfx, root: tempDir.path);

        var args = {'pattern': '\'dart:io\'', 'path': 'subdir/**'};
        var result = await allFiles.jsonCall('search_contents', args);
        expect(result['error'], isNull);
        expect(
          result['matches'] as Map,
          equals({
            'subdir\\test.dart': [
              {'beginLine': '2', 'endLine': '2', 'text': 'import \'dart:io\';'},
            ],
          }),
        );

        final subdirFiles = FileToolSet(
          prefix: 'subdir',
          root: p.join(tempDir.path, 'subdir'),
        );
        args = {'pattern': '\'dart:io\''};
        result = await subdirFiles.jsonCall('search_contents', args);
        expect(result['error'], isNull);
        expect(
          result['matches'] as Map,
          equals({
            'test.dart': [
              {'beginLine': '2', 'endLine': '2', 'text': 'import \'dart:io\';'},
            ],
          }),
        );
      });

      test('search with different encodings', () async {
        final fileToolSet = FileToolSet(prefix: pfx, root: tempDir.path);
        final filePath = p.join(tempDir.path, 'test.txt');
        final file = File(filePath);
        await file.writeAsString(
          'test with special chars: äöüß',
          encoding: systemEncoding,
        );

        Json args = {'pattern': 'äöüß'};
        var result = await fileToolSet.jsonCall('search_contents', args);
        expect(result['error'], isNull);
        expect(
          result['matches'] as Map,
          equals({
            'test.txt': [
              {
                'beginLine': '1',
                'endLine': '1',
                'text': 'test with special chars: äöüß',
              },
            ],
          }),
        );

        args = {'pattern': 'ÄÖÜ', 'caseSensitive': true};
        result = await fileToolSet.jsonCall('search_contents', args);
        expect(result['error'], isNull);
        expect(result['matches'] as Map, isEmpty);
      });

      test('case-insensitive search', () async {
        final fileToolSet = FileToolSet(prefix: pfx, root: tempDir.path);
        final filePath = p.join(tempDir.path, 'test.txt');
        final file = File(filePath);
        await file.writeAsString('THIS IS A TEST FILE');

        final args = {'pattern': 'test file', 'caseSensitive': false};
        final result = await fileToolSet.jsonCall('search_contents', args);
        expect(result['error'], isNull);
        expect(
          result['matches'] as Map,
          equals({
            'test.txt': [
              {'beginLine': '1', 'endLine': '1', 'text': 'THIS IS A TEST FILE'},
            ],
          }),
        );
      });

      test('empty pattern', () async {
        final fileToolSet = FileToolSet(prefix: pfx, root: tempDir.path);
        final filePath = p.join(tempDir.path, 'test.txt');
        final file = File(filePath);
        await file.writeAsString('test content');

        final args = {'pattern': ''};
        final result = await fileToolSet.jsonCall('search_contents', args);
        expect(result['error'], isNull);
        expect(result['matches'] as List, isEmpty);
      });

      test('multiline match', () async {
        final fileToolSet = FileToolSet(prefix: pfx, root: tempDir.path);
        final filePath = p.join(tempDir.path, 'test.txt');
        final file = File(filePath);
        await file.writeAsString(
          '// Some comment\nclass\n   Test\n{\n}\n\nclass Other {\n}\n',
        );

        final args = {'pattern': 'class\\s+[a-z0-9_]+'};
        final result = await fileToolSet.jsonCall('search_contents', args);
        expect(result['error'], isNull);
        expect(
          result['matches'] as Map,
          equals({
            'test.txt': [
              {'beginLine': '2', 'endLine': '3', 'text': 'class\n   Test'},
              {'beginLine': '7', 'endLine': '7', 'text': 'class Other {'},
            ],
          }),
        );
      });

      test('code search - match all', () async {
        final fileToolSet = FileToolSet(prefix: pfx, root: './test');
        final args = {'pattern': '.*', 'path': '**/*.java'};
        final matches = await fileToolSet.jsonCall('search_contents', args);

        // construct matched lines from original file
        // each non-empty line will be a match
        final lines = await File(
          './test/assets/test_code.java',
        ).readAsLines(encoding: systemEncoding);

        final expectedMatches = <Map<String, String>>[];
        for (var i = 1; i <= lines.length; i++) {
          final code = lines[i - 1].trim();
          if (code.isNotEmpty) {
            expectedMatches.add({
              'beginLine': '$i',
              'endLine': '$i',
              'text': code,
            });
          }
        }

        expect(
          matches['matches'] as Map,
          equals({'assets\\test_code.java': expectedMatches}),
        );
      });

      test('code search - single lines', () async {
        final fileToolSet = FileToolSet(prefix: pfx, root: './test');
        final args = {'pattern': 'public', 'path': '**/*.java'};
        final matches = await fileToolSet.jsonCall('search_contents', args);

        expect(
          matches['matches'] as Map,
          equals({
            'assets\\test_code.java': [
              {
                'beginLine': '3',
                'endLine': '3',
                'text': 'public class CoreException extends Exception {',
              },
              {
                'beginLine': '7',
                'endLine': '7',
                'text': 'public CoreException() {',
              },
              {
                'beginLine': '11',
                'endLine': '11',
                'text': 'public CoreException(String code) {',
              },
              {
                'beginLine': '16',
                'endLine': '16',
                'text': 'public String getCode() {',
              },
            ],
          }),
        );
      });

      test('code search - multiline', () async {
        final fileToolSet = FileToolSet(prefix: pfx, root: './test');
        final args = {'pattern': ';\\s*\\}', 'path': '**/*.java'};
        final matches = await fileToolSet.jsonCall('search_contents', args);

        expect(
          matches['matches'] as Map,
          equals({
            'assets\\test_code.java': [
              {'beginLine': '8', 'endLine': '9', 'text': 'super();\r\n\t}'},
              {
                'beginLine': '13',
                'endLine': '14',
                'text': 'this.code = code;\r\n\t}',
              },
              {
                'beginLine': '17',
                'endLine': '18',
                'text': 'return code;\r\n\t}',
              },
            ],
          }),
        );
      });

      test('code search - single file', () async {
        final fileToolSet = FileToolSet(prefix: pfx, root: './test');
        final args = {'pattern': 'code', 'path': 'assets\\test_code.java'};
        final matches = await fileToolSet.jsonCall('search_contents', args);

        expect(
          matches['matches'] as Map,
          equals({
            'assets\\test_code.java': [
              {
                'beginLine': '5',
                'endLine': '5',
                'text': 'private String code = "non-initialisé";',
              },
              {
                'beginLine': '11',
                'endLine': '11',
                'text': 'public CoreException(String code) {',
              },
              {'beginLine': '13', 'endLine': '13', 'text': 'this.code = code;'},
              {'beginLine': '13', 'endLine': '13', 'text': 'this.code = code;'},
              {
                'beginLine': '16',
                'endLine': '16',
                'text': 'public String getCode() {',
              },
              {'beginLine': '17', 'endLine': '17', 'text': 'return code;'},
            ],
          }),
        );
      });
    });

    group('create directory', () {
      test('successful directory creation', () async {
        final fileToolSet = FileToolSet(
          prefix: pfx,
          root: tempDir.path,
          allowCreate: true,
        );
        final args = {'path': 'new_dir'};
        final result = await fileToolSet.stringCall('create_dir', args);
        expect(result, contains('success'));
        expect(Directory(p.join(tempDir.path, 'new_dir')).existsSync(), isTrue);
      });

      test('directory already exists', () async {
        final fileToolSet = FileToolSet(
          prefix: pfx,
          root: tempDir.path,
          allowCreate: true,
        );
        final newDirPath = p.join(tempDir.path, 'existing_dir');
        await Directory(newDirPath).create();
        final args = {'path': 'existing_dir'};
        final result = await fileToolSet.stringCall('create_dir', args);
        expect(result, contains('success'));
      });

      test('absolute path creation within root', () async {
        final fileToolSet = FileToolSet(
          prefix: pfx,
          root: tempDir.path,
          allowCreate: true,
        );
        final args = {'path': p.join(tempDir.path, 'new_dir')};
        final result = await fileToolSet.stringCall('create_dir', args);
        expect(result, contains('success'));
        expect(Directory(p.join(tempDir.path, 'new_dir')).existsSync(), isTrue);
      });

      test('absolute path creation outside root', () async {
        final fileToolSet = FileToolSet(
          prefix: pfx,
          root: tempDir.path,
          allowCreate: true,
        );
        final args = {'path': p.join(Directory.current.path, 'new_dir')};
        final result = await fileToolSet.jsonCall('create_dir', args);
        expect(result, isA<Json>());
        expectError(result, contains('denied'));
      });

      test('path outside root', () async {
        final fileToolSet = FileToolSet(
          prefix: pfx,
          root: tempDir.path,
          allowCreate: true,
        );
        final args = {'path': '../new_dir'};
        final result = await fileToolSet.jsonCall('create_dir', args);
        expect(result, isA<Json>());
        expectError(result, contains('denied'));
      });
    });

    group('read file lines', () {
      test('valid file path and line numbers', () async {
        final fileToolSet = FileToolSet(prefix: pfx, root: tempDir.path);
        final filePath = p.join(tempDir.path, 'test_file.txt');
        final fileContent = 'line1\nline2\nline3';
        await File(filePath).writeAsString(fileContent);

        final args = {'path': 'test_file.txt', 'startLine': 2, 'endLine': 3};
        final result = await fileToolSet.jsonCall('read_lines', args);
        expect(result['error'], isNull);
        expect(result['lines'] as List, equals(['line2', 'line3']));
      });

      test('invalid file path', () async {
        final fileToolSet = FileToolSet(prefix: pfx, root: tempDir.path);
        final args = {'path': 'no_file.txt', 'startLine': 1, 'endLine': 2};
        final result = await fileToolSet.jsonCall('read_lines', args);
        expectError(result, contains('not found'));
      });

      test('invalid line numbers (start < 1)', () async {
        final fileToolSet = FileToolSet(prefix: pfx, root: tempDir.path);
        final filePath = p.join(tempDir.path, 'test_file.txt');
        await File(filePath).writeAsString('line1\nline2');

        final args = {'path': 'test_file.txt', 'startLine': 0, 'endLine': 1};
        final result = await fileToolSet.jsonCall('read_lines', args);
        expectError(result, contains('invalid'));
      });

      test('end > number of lines', () async {
        final fileToolSet = FileToolSet(prefix: pfx, root: tempDir.path);
        final filePath = p.join(tempDir.path, 'test_file.txt');
        await File(filePath).writeAsString('line1\nline2');

        final args = {'path': 'test_file.txt', 'startLine': 1, 'endLine': 3};
        final result = await fileToolSet.jsonCall('read_lines', args);
        expect(result['error'], isNull);
        expect(result['lines'] as List, equals(['line1', 'line2']));
      });

      test('invalid line numbers (start > end)', () async {
        final fileToolSet = FileToolSet(prefix: pfx, root: tempDir.path);
        final filePath = p.join(tempDir.path, 'test_file.txt');
        await File(filePath).writeAsString('line1\nline2');

        final args = {'path': 'test_file.txt', 'startLine': 2, 'endLine': 1};
        final result = await fileToolSet.jsonCall('read_lines', args);
        expectError(result, contains('invalid'));
      });

      test('empty file', () async {
        final fileToolSet = FileToolSet(prefix: pfx, root: tempDir.path);
        final filePath = p.join(tempDir.path, 'empty_file.txt');
        await File(filePath).writeAsString('');

        final args = {'path': 'empty_file.txt', 'startLine': 1, 'endLine': 2};
        final result = await fileToolSet.jsonCall('read_lines', args);
        expect(result['error'], isNull);
        expect(result['lines'] as List, isEmpty);
      });
    });

    group('replace lines in a file', () {
      test('only one line', () async {
        final fileToolSet = FileToolSet(
          prefix: pfx,
          root: tempDir.path,
          allowReplace: true,
        );
        final file = File(p.join(tempDir.path, 'replace_test.txt'));
        await file.writeAsString('line1\nline2\nline3');
        final args = {
          'path': 'replace_test.txt',
          'startLine': 2,
          'endLine': 2,
          'newContent': 'new line2',
        };
        final result = await fileToolSet.stringCall('replace_lines', args);
        expect(result, contains('success'));
        final newContent = await file.readAsString();
        expect(newContent, 'line1\nnew line2\nline3');
      });

      test('multiple lines', () async {
        final fileToolSet = FileToolSet(
          prefix: pfx,
          root: tempDir.path,
          allowReplace: true,
        );
        final file = File(p.join(tempDir.path, 'replace_test.txt'));
        await file.writeAsString('line1\nline2\nline3\nline4\nline5');
        final args = {
          'path': file.path,
          'startLine': 2,
          'endLine': 4,
          'newContent': 'new line2\nnew line3\nnew line4',
        };
        final result = await fileToolSet.stringCall('replace_lines', args);
        expect(result, contains('success'));
        final newContent = await file.readAsString();
        expect(newContent, 'line1\nnew line2\nnew line3\nnew line4\nline5');
      });

      test('delete lines (= replace with empty string)', () async {
        final fileToolSet = FileToolSet(
          prefix: pfx,
          root: tempDir.path,
          allowReplace: true,
        );
        final file = File(p.join(tempDir.path, 'replace_test.txt'));
        await file.writeAsString('line1\nline2\nline3');
        final args = {
          'path': file.path,
          'startLine': 2,
          'endLine': 2,
          'newContent': '',
        };
        final result = await fileToolSet.stringCall('replace_lines', args);
        expect(result, contains('success'));
        final newContent = await file.readAsString();
        expect(newContent, 'line1\nline3');
      });

      test('beginning of the file', () async {
        final fileToolSet = FileToolSet(
          prefix: pfx,
          root: tempDir.path,
          allowReplace: true,
        );
        final file = File(p.join(tempDir.path, 'replace_test.txt'));
        await file.writeAsString('line1\nline2\nline3');
        final args = {
          'path': file.path,
          'startLine': 1,
          'endLine': 1,
          'newContent': 'new line1',
        };
        final result = await fileToolSet.stringCall('replace_lines', args);
        expect(result, contains('success'));
        final newContent = await file.readAsString();
        expect(newContent, 'new line1\nline2\nline3');
      });

      test('end of the file', () async {
        final fileToolSet = FileToolSet(
          prefix: pfx,
          root: tempDir.path,
          allowReplace: true,
        );
        final file = File(p.join(tempDir.path, 'replace_test.txt'));
        await file.writeAsString('line1\nline2\nline3');
        final args = {
          'path': file.path,
          'startLine': 3,
          'endLine': 3,
          'newContent': 'new line3',
        };
        final result = await fileToolSet.stringCall('replace_lines', args);
        expect(result, contains('success'));
        final newContent = await file.readAsString();
        expect(newContent, 'line1\nline2\nnew line3');
      });

      test('one line with multiple new lines', () async {
        final fileToolSet = FileToolSet(
          prefix: pfx,
          root: tempDir.path,
          allowReplace: true,
        );
        final file = File(p.join(tempDir.path, 'replace_test.txt'));
        await file.writeAsString('line1\nline2\nline3');
        final args = {
          'path': file.path,
          'startLine': 2,
          'endLine': 2,
          'newContent': 'new line2a\nnew line2b',
        };
        final result = await fileToolSet.stringCall('replace_lines', args);
        expect(result, contains('success'));
        final newContent = await file.readAsString();
        expect(newContent, 'line1\nnew line2a\nnew line2b\nline3');
      });

      test('empty file', () async {
        final fileToolSet = FileToolSet(
          prefix: pfx,
          root: tempDir.path,
          allowReplace: true,
        );
        final file = File(p.join(tempDir.path, 'replace_test.txt'));
        await file.writeAsString('');
        final args = {
          'path': file.path,
          'startLine': 1,
          'endLine': 1,
          'newContent': 'new line1',
        };
        final result = await fileToolSet.stringCall('replace_lines', args);
        expect(result, contains('success'));
        final newContent = await file.readAsString();
        expect(newContent, 'new line1');
      });
    });
  });
}
