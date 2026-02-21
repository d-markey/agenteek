import 'dart:io';

import 'package:path/path.dart' as p;

/// appends a trailing '/' or '\' if not present already
String appendPathSeparator(String path) => path.endsWith(Platform.pathSeparator)
    ? path
    : (path + Platform.pathSeparator);

/// canonicalize directory path (with trailing /)
String canonicalize(String root) {
  final dir = Directory(root);
  if (!dir.existsSync()) {
    throw ArgumentError.value(root, 'root', 'Invalid root directory');
  }
  return appendPathSeparator(p.canonicalize(dir.absolute.path));
}

extension FileSystemEntityEx on FileSystemEntity {
  /// checks the entity belongs to the root directory
  Future<T> check<T extends FileSystemEntity>(String root) async {
    var resolvedPath = p.canonicalize(p.join(root, path));

    bool isDirectory;
    if (this is Link) {
      final type = await FileSystemEntity.type(resolvedPath, followLinks: true);
      isDirectory = (type == FileSystemEntityType.directory);
    } else {
      isDirectory = this is Directory;
    }

    final local = isDirectory ? Directory(resolvedPath) : File(resolvedPath);
    if (await local.exists()) {
      resolvedPath = p.canonicalize(await local.resolveSymbolicLinks());
    }
    if (isDirectory) resolvedPath = appendPathSeparator(resolvedPath);
    if (!resolvedPath.startsWith(root)) throw 'Access denied';
    return (isDirectory ? Directory(resolvedPath) : File(resolvedPath)) as T;
  }

  /// gets the local part of the path under root
  String getLocalPath(String root) =>
      p.canonicalize(absolute.path).substring(root.length);

  bool get isHidden => p.basename(path).startsWith('.');
}
