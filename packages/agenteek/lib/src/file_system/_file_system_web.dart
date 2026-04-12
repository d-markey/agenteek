import 'package:web/web.dart' as web;

import 'file_system.dart';

class PersistentFileSystem implements FileSystem {
  PersistentFileSystem(this.root);

  @override
  final String root;

  String _getKey(String path) {
    final p = FileSystem.normalizePath(path);
    return 'agenteek:$root:$p';
  }

  @override
  Future<bool> exists(String path) {
    final key = _getKey(path);
    return Future.value(web.window.localStorage.getItem(key) != null);
  }

  @override
  Stream<String> list() {
    final prefix = 'agenteek:$root:';
    final results = <String>[];
    final storage = web.window.localStorage;
    for (var i = 0; i < storage.length; i++) {
      final key = storage.key(i);
      if (key != null && key.startsWith(prefix)) {
        results.add(key.substring(prefix.length));
      }
    }
    return Stream.fromIterable(results);
  }

  @override
  Future<void> write(String path, String contents) {
    final key = _getKey(path);
    web.window.localStorage.setItem(key, contents);
    return Future.value();
  }

  @override
  Future<String> read(String path) {
    final key = _getKey(path);
    final contents = web.window.localStorage.getItem(key);
    if (contents == null) {
      throw Exception('File not found: "$path"');
    }
    return Future.value(contents);
  }

  @override
  Future<void> delete(String path) {
    final key = _getKey(path);
    web.window.localStorage.removeItem(key);
    return Future.value();
  }
}
