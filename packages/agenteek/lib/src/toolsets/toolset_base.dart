import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import '../utils/types.dart';

abstract class ToolSetBase {
  const ToolSetBase();

  List<dartantic.Tool> get tools;

  Iterable<String> get names;

  bool get isEmpty => names.isEmpty;
  bool get isNotEmpty => names.isNotEmpty;

  dartantic.Tool? getTool(String name);

  void register(dartantic.Tool tool);

  void registerAll(Iterable<dartantic.Tool> tools) => tools.forEach(register);

  FutureOr<dynamic> invoke(String name, Json args);

  bool get disposed;

  Future<void> dispose();
}
