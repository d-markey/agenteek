import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import '../utils/types.dart';
import 'tool.dart';
import 'tool_outcome.dart';

abstract class ToolSetBase {
  const ToolSetBase();

  List<Tool> get tools;

  Iterable<String> get names;

  bool get isEmpty => names.isEmpty;
  bool get isNotEmpty => names.isNotEmpty;

  Tool? getTool(String name);

  void register(Tool tool);

  void registerAll(Iterable<Tool> tools) => tools.forEach(register);

  FutureOr<ToolOutcome<T>> invoke<T>(String name, [Json? args]);

  Future<Map<dartantic.ToolPart, dartantic.ToolPart>> redactObsoleteToolResults(
    List<dartantic.ChatMessage> history,
  ) => Future.value(const {});

  bool get disposed;

  Future<void> dispose();
}
