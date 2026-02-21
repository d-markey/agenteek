import 'dart:io';

import 'package:path/path.dart' as p;

import 'file_system.dart';

class PersistentFileSystem implements FileSystem {
  PersistentFileSystem(String root)
    : _rootDir = Directory(root),
      root =
          '${p.canonicalize(Directory(root).absolute.path).toLowerCase()}${p.separator}';

  final Directory _rootDir;

  @override
  final String root;

  File _getFile(String path) => File(
    p.join(root, FileSystem.normalizePath(path).replaceAll('/', p.separator)),
  );

  @override
  Future<bool> exists(String path) => _getFile(path).exists();

  @override
  Stream<String> list() => _rootDir.existsSync()
      ? _rootDir
            .list(recursive: true, followLinks: false)
            .where((f) => f is File)
            .map((f) {
              final fp = p.canonicalize(f.absolute.path);
              return fp.toLowerCase().startsWith(root)
                  ? fp.substring(root.length).replaceAll(p.separator, '/')
                  : '';
            })
            .where((p) => p.isNotEmpty)
      : Stream.fromIterable(const []);

  @override
  Future<void> write(String path, String contents) {
    final file = _getFile(path);
    return file.parent
        .create(recursive: true)
        .then((_) => file.writeAsString(contents));
  }

  @override
  Future<String> read(String path) {
    final file = _getFile(path);
    return file.existsSync()
        ? file.readAsString()
        : throw Exception('File not found: "$path"');
  }

  @override
  Future<void> delete(String path) async {
    final file = _getFile(path);
    await file.delete();
  }
}
