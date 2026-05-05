import 'dart:io';

abstract class Container {
  String get image;
  String get name;
  String get id;

  Future<bool?> isRunning();

  Future<void> create();
  Future<void> delete();

  Future<void> start();
  Future<void> stop();

  Future<void> cpdir(Directory source, String dest);
  Future<void> rmdir(String dest);

  Future<Map<String, Object?>> run(String command, {String? workingDir});
}
