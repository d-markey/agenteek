import '_file_system_stub.dart'
    if (dart.library.io) '_file_system_io.dart'
    if (dart.library.js_interop) '_file_system_web.dart'
    as impl;

typedef PersistentFileSystem = impl.PersistentFileSystem;

abstract class FileSystem {
  String get root;

  Future<bool> exists(String path);
  Stream<String> list();
  Future<void> write(String path, String contents);
  Future<String> read(String path);
  Future<void> delete(String path);

  static final _sep = RegExp('[\\\\/]');

  static String normalizePath(String path) {
    final segments = path.split(_sep).where((s) => s.isNotEmpty).toList();
    var idx = 0;
    while (idx < segments.length) {
      if (segments[idx] == '.') {
        //       2
        // a  b  .  c  d
        segments.removeAt(idx);
        //       2
        // a  b  c  d
      } else if (segments[idx] == '..') {
        //       2           OR    0
        // a  b  ..  c  d          ..  a  b
        segments.removeAt(idx);
        //       2       OR    0
        // a  b  c  d          a  b
        if (idx > 0) {
          idx--;
          segments.removeAt(idx);
          //    1
          // a  c  d
        }
      } else {
        idx++;
      }
    }
    return segments.join('/');
  }
}
