import 'file_system.dart';

class PersistentFileSystem implements FileSystem {
  PersistentFileSystem(String root);

  @override
  String get root => throw UnsupportedError('Unsupported platform.');

  @override
  Future<bool> exists(String path) =>
      throw UnsupportedError('Unsupported platform.');

  @override
  Stream<String> list() => throw UnsupportedError('Unsupported platform.');

  @override
  Future<void> write(String path, String contents) =>
      throw UnsupportedError('Unsupported platform.');

  @override
  Future<String> read(String path) =>
      throw UnsupportedError('Unsupported platform.');

  @override
  Future<void> delete(String path) =>
      throw UnsupportedError('Unsupported platform.');
}
