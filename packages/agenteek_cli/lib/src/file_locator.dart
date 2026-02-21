import 'dart:io';

import 'package:path/path.dart' as p;

abstract class FileLocator {
  static Future<File?> find(Directory from, String fileName) async {
    var dir = from.absolute;
    if (!await dir.exists()) {
      throw p.PathException('Directory $dir does not exist.');
    }

    while (true) {
      // check from current directory
      final file = File(p.join(dir.path, fileName));
      if (await file.exists()) return file;

      // not found: look one level up
      final parent = dir.parent;
      if (parent.path == dir.path) {
        // reached the root
        return null;
      }

      // continue searching...
      dir = parent;
    }
  }
}
