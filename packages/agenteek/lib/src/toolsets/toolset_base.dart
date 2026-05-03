import 'dart:async';
import 'dart:convert';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import '../utils/types.dart';
import 'tool.dart';
import 'tool_outcome.dart';
import 'toolset_exception.dart';

abstract class ToolSetBase {
  const ToolSetBase();

  List<Tool> get tools;

  Iterable<String> get names;

  bool get isEmpty => names.isEmpty;
  bool get isNotEmpty => names.isNotEmpty;

  Tool? getTool(String name);

  void register(Tool tool);

  void registerAll(Iterable<Tool> tools) => tools.forEach(register);

  FutureOr<ToolOutcome<T>> invoke<T>(String name, Json args);

  ToolSetException? check(dartantic.ToolPart tool) => tool.isToolNotFoundError
      ? ToolNotFoundException(tool.toolName, tools)
      : null;

  Future<String> checkSideEffects(dartantic.ChatResult result) =>
      Future.value('');

  Future<Map<dartantic.ToolPart, dartantic.ToolPart>> redactObsoleteToolResults(
    List<dartantic.ChatMessage> history,
  ) => Future.value(const {});

  bool get disposed;

  Future<void> dispose();
}

extension on dartantic.ToolPart {
  static final _notFound = RegExp('tool [a-z0-9_.-]+ not found');

  bool get isToolNotFoundError {
    try {
      final json = jsonDecode(result?.toString().toLowerCase() ?? '{}') as Json;
      final error = (json['error'] as String?) ?? '';
      return (json.length == 1) && _notFound.hasMatch(error);
    } catch (_) {
      /* ignored */
    }
    return false;
  }
}
