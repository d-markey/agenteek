import 'dart:io';

import 'package:agenteek/agenteek.dart';

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

  Future<Json> run(String command, {String? workingDir, Duration? timeout});
}
