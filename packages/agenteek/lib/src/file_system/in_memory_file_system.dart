import 'file_system.dart';

class MemoryFileSystem implements FileSystem {
  final _files = <String, String>{};

  @override
  String get root => '';

  @override
  Future<bool> exists(String path) {
    final p = FileSystem.normalizePath(path);
    return Future.value(_files.containsKey(p));
  }

  @override
  Stream<String> list() => Stream.fromIterable(_files.keys.toList());

  @override
  Future<void> write(String path, String contents) {
    final p = FileSystem.normalizePath(path);
    _files[p] = contents;
    return Future.value();
  }

  @override
  Future<String> read(String path) {
    final p = FileSystem.normalizePath(path);
    if (!_files.containsKey(p)) {
      throw Exception('File not found: "$path"');
    }
    return Future.value(_files[p]!);
  }

  @override
  Future<void> delete(String path) {
    final p = FileSystem.normalizePath(path);
    _files.remove(p);
    return Future.value();
  }
}
