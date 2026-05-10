import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek/agenteek_dbg.dart' as dbg;
import 'package:agenteek_files_toolset/agenteek_files_toolset.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'workspace_path.dart';

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
        final res = await allFiles.call<String>('list_files');
        expect(res.result.split('\n').where((f) => f.isNotEmpty), hasLength(1));
      });

      test('recursive from root directory', () async {
        final allFiles = FileToolSet(prefix: pfx, root: tempDir.path);
        final args = {'recursive': true};
        final res = await allFiles.call<String>('list_files', args);
        expect(res.result.split('\n').where((f) => f.isNotEmpty), hasLength(2));
      });

      test('from sub directory', () async {
        final allFiles = FileToolSet(prefix: pfx, root: tempDir.path);
        final args = {'path': 'subdir'};
        final res = await allFiles.call<String>('list_files', args);
        expect(res.result.split('\n').where((f) => f.isNotEmpty), hasLength(1));
      });

      test('from root directory parent', () async {
        final allFiles = FileToolSet(prefix: pfx, root: tempDir.path);
        final args = {'path': '..'};
        final res = await allFiles.call<String>('list_files', args);
        expect(res, isA<ToolError>());
        res as ToolError<String>;
        expect(res.error.toString().toLowerCase(), contains('denied'));
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

        final res = await allFiles.call<String>('list_files');
        final files = res.result.split('\n');
        expect(files.where((f) => f.contains('.hidden_file')), isEmpty);
        expect(files.where((f) => f.contains('.file_in_hidden_dir')), isEmpty);
      });

      test('recursive listing', () async {
        final allFiles = FileToolSet(prefix: pfx, root: tempDir.path);
        final args = {'recursive': true};
        final res = await allFiles.call<String>('list_files', args);
        final files = res.result.split('\n');
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
        var result = await allFiles.call<Json>('search_text', args);
        expect(
          result.result,
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
        result = await subdirFiles.call<Json>('search_text', args);
        expect(
          result.result,
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
        final result = await allFiles.call<Json>('search_text', args);
        expect(
          result.result,
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
        var result = await allFiles.call<Json>('search_text', args);
        expect(
          result.result,
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
        result = await subdirFiles.call<Json>('search_text', args);
        expect(
          result.result,
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

        var args = <String, Object?>{'pattern': 'äöüß'};
        var result = await fileToolSet.call<Json>('search_text', args);
        expect(
          result.result,
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
        result = await fileToolSet.call<Json>('search_text', args);
        expect(result.result, isEmpty);
      });

      test('case-insensitive search', () async {
        final fileToolSet = FileToolSet(prefix: pfx, root: tempDir.path);
        final filePath = p.join(tempDir.path, 'test.txt');
        final file = File(filePath);
        await file.writeAsString('THIS IS A TEST FILE');

        final args = {'pattern': 'test file'};
        final result = await fileToolSet.call<Json>('search_text', args);
        expect(
          result.result,
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
        final result = await fileToolSet.call<Json>('search_text', args);
        result as ToolError<Json>;
        expect(result.error.toString().toLowerCase(), contains('match all'));
      });

      test('multiline match', () async {
        final fileToolSet = FileToolSet(prefix: pfx, root: tempDir.path);
        final filePath = p.join(tempDir.path, 'test.txt');
        final file = File(filePath);
        await file.writeAsString(
          '// Some comment\nclass\n   Test\n{\n}\n\nclass Other {\n}\n',
        );

        final args = {'pattern': '/class\\s+[a-z0-9_]+/'};
        final result = await fileToolSet.call<Json>('search_text', args);
        expect(
          result.result,
          equals({
            'test.txt': [
              {'beginLine': '2', 'endLine': '3', 'text': 'class\n   Test'},
              {'beginLine': '7', 'endLine': '7', 'text': 'class Other {'},
            ],
          }),
        );
      });

      test('code search - match all', () async {
        final fileToolSet = FileToolSet(
          prefix: pfx,
          root: await getWorkspacePath('packages/toolsets/agenteek_files'),
        );
        final args = {'pattern': '/.+/', 'path': '**/*.java'};
        final result = await fileToolSet.call<Json>('search_text', args);
        result as ToolError<Json>;
        expect(result.error.toString().toLowerCase(), contains('match all'));
      });

      test('code search - single lines', () async {
        final fileToolSet = FileToolSet(
          prefix: pfx,
          root: await getWorkspacePath('packages/toolsets/agenteek_files/test'),
        );
        final args = {'pattern': 'public', 'path': '**/*.java'};
        final result = await fileToolSet.call<Json>('search_text', args);
        expect(
          result.result,
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
        final fileToolSet = FileToolSet(
          prefix: pfx,
          root: await getWorkspacePath('packages/toolsets/agenteek_files/test'),
        );
        final args = {'pattern': '/;\\s*\\}/', 'path': '**/*.java'};
        final result = await fileToolSet.call<Json>('search_text', args);
        expect(
          result.result,
          equals({
            'assets\\test_code.java': [
              {'beginLine': '8', 'endLine': '9', 'text': 'super();\n\t}'},
              {
                'beginLine': '13',
                'endLine': '14',
                'text': 'this.code = code;\n\t}',
              },
              {'beginLine': '17', 'endLine': '18', 'text': 'return code;\n\t}'},
            ],
          }),
        );
      });

      test('code search - single file', () async {
        final fileToolSet = FileToolSet(
          prefix: pfx,
          root: await getWorkspacePath('packages/toolsets/agenteek_files/test'),
        );
        final args = {'pattern': 'code', 'path': 'assets/test_code.java'};
        final result = await fileToolSet.call<Json>('search_text', args);
        expect(
          result.result,
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
        final result = await fileToolSet.call<String>('create_dir', args);
        expect(result.result.toLowerCase(), contains('ok'));
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
        final result = await fileToolSet.call<String>('create_dir', args);
        expect(result.result.toLowerCase(), contains('ok'));
      });

      test('absolute path creation within root', () async {
        final fileToolSet = FileToolSet(
          prefix: pfx,
          root: tempDir.path,
          allowCreate: true,
        );
        final args = {'path': p.join(tempDir.path, 'new_dir')};
        final result = await fileToolSet.call<String>('create_dir', args);
        expect(result.result.toLowerCase(), contains('ok'));
        expect(Directory(p.join(tempDir.path, 'new_dir')).existsSync(), isTrue);
      });

      test('absolute path creation outside root', () async {
        final fileToolSet = FileToolSet(
          prefix: pfx,
          root: tempDir.path,
          allowCreate: true,
        );
        final args = {'path': p.join(Directory.current.path, 'new_dir')};
        final result = await fileToolSet.call<String>('create_dir', args);
        result as ToolError<String>;
        expect(result.error.toString().toLowerCase(), contains('denied'));
      });

      test('path outside root', () async {
        final fileToolSet = FileToolSet(
          prefix: pfx,
          root: tempDir.path,
          allowCreate: true,
        );
        final args = {'path': '../new_dir'};
        final result = await fileToolSet.call<String>('create_dir', args);
        result as ToolError<String>;
        expect(result.error.toString().toLowerCase(), contains('denied'));
      });
    });

    group('read file lines', () {
      test('valid file path and line numbers', () async {
        final fileToolSet = FileToolSet(prefix: pfx, root: tempDir.path);
        final filePath = p.join(tempDir.path, 'test_file.txt');
        final fileContent = 'line1\nline2\nline3';
        await File(filePath).writeAsString(fileContent);

        final args = {
          'path': 'test_file.txt',
          'startLine': 2,
          'endLine': 3,
          'mode': 'numbered',
        };
        final result = await fileToolSet.call<String>('read_lines', args);
        expect(
          result.result,
          contains(
            '000002| line2\n'
            '000003| line3',
          ),
        );
      });

      test('invalid file path', () async {
        final fileToolSet = FileToolSet(prefix: pfx, root: tempDir.path);
        final args = {'path': 'no_file.txt', 'startLine': 1, 'endLine': 2};
        final result = await fileToolSet.call<String>('read_lines', args);
        result as ToolError<String>;
        expect(result.error.toString().toLowerCase(), contains('not found'));
      });

      test('invalid line numbers (start < 1)', () async {
        final fileToolSet = FileToolSet(prefix: pfx, root: tempDir.path);
        final filePath = p.join(tempDir.path, 'test_file.txt');
        await File(filePath).writeAsString('line1\nline2');

        final args = {'path': 'test_file.txt', 'startLine': 0, 'endLine': 1};
        final result = await fileToolSet.call<String>('read_lines', args);
        result as ToolError<String>;
        expect(result.error.toString().toLowerCase(), contains('invalid'));
      });

      test('end > number of lines', () async {
        final fileToolSet = FileToolSet(prefix: pfx, root: tempDir.path);
        final filePath = p.join(tempDir.path, 'test_file.txt');
        await File(filePath).writeAsString('line1\nline2');

        final args = {
          'path': 'test_file.txt',
          'startLine': 1,
          'endLine': 3,
          'mode': 'numbered',
        };
        final result = await fileToolSet.call<String>('read_lines', args);
        expect(
          result.result,
          contains(
            '000001| line1\n'
            '000002| line2',
          ),
        );
      });

      test('invalid line numbers (start > end)', () async {
        final fileToolSet = FileToolSet(prefix: pfx, root: tempDir.path);
        final filePath = p.join(tempDir.path, 'test_file.txt');
        await File(filePath).writeAsString('line1\nline2');

        final args = {'path': 'test_file.txt', 'startLine': 2, 'endLine': 1};
        final result = await fileToolSet.call<String>('read_lines', args);
        result as ToolError<String>;
        expect(result.error.toString().toLowerCase(), contains('invalid'));
      });

      test('empty file', () async {
        final fileToolSet = FileToolSet(prefix: pfx, root: tempDir.path);
        final filePath = p.join(tempDir.path, 'empty_file.txt');
        await File(filePath).writeAsString('');

        final args = {'path': 'empty_file.txt', 'startLine': 1, 'endLine': 2};
        final result = await fileToolSet.call<String>('read_lines', args);
        expect(result.result.toLowerCase(), contains('is empty'));
      });
    });

    group('replace text in a file', () {
      test('replace text', () async {
        final fileToolSet = FileToolSet(
          prefix: pfx,
          root: tempDir.path,
          allowReplace: true,
        );
        final file = File(p.join(tempDir.path, 'replace_test.txt'));
        await file.writeAsString('line1\nline2\nline3');
        final args = {
          'path': file.path,
          'originalText': 'line2\n',
          'newText': 'new line2a\nnew line2b\n',
        };
        final result = await fileToolSet.call<String>('replace_text', args);
        expect(result.result.toLowerCase(), contains('ok'));
        final newText = await file.readAsString();
        expect(newText, 'line1\nnew line2a\nnew line2b\nline3');
      });

      test('replace text (multi)', () async {
        final fileToolSet = FileToolSet(
          prefix: pfx,
          root: tempDir.path,
          allowReplace: true,
        );
        final file = File(p.join(tempDir.path, 'replace_test.txt'));
        await file.writeAsString('line1\nline2a\nline2b\nline2c\nline3');
        final args = {
          'path': file.path,
          'originalText': 'line2',
          'newText': 'LINE-002-',
          'targetLines': [2, 4],
        };
        final result = await fileToolSet.call<String>('replace_text', args);
        expect(result.result.toLowerCase(), contains('ok'));
        final newText = await file.readAsString();
        expect(newText, 'line1\nLINE-002-a\nline2b\nLINE-002-c\nline3');
      });
    });
  });
}
