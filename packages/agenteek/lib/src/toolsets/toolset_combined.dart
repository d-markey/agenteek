import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import 'tool.dart';
import 'toolset.dart';

class CombinedToolSet extends ToolSet {
  CombinedToolSet(this._toolsets);

  final Set<ToolSet> _toolsets;

  @override
  void register(Tool tool) {
    throw UnsupportedError(
      'A combined toolset cannot have tools outside of children toolsets',
    );
  }

  @override
  List<Tool> get tools => _toolsets.expand((ts) => ts.tools).toList();

  @override
  List<String> get names => _toolsets.expand((ts) => ts.names).toList();

  @override
  Tool? getTool(String name) =>
      _toolsets.map((ts) => ts.getTool(name)).nonNulls.firstOrNull;

  @override
  Future<String> checkSideEffects(dartantic.ChatResult result) async {
    StringBuffer? sideEffects;
    for (var toolset in _toolsets) {
      final message = await toolset.checkSideEffects(result);
      if (message.isNotEmpty) {
        sideEffects ??= StringBuffer();
        sideEffects.writeln(message);
      }
    }
    return (sideEffects == null) ? '' : sideEffects.toString().trim();
  }

  @override
  Future<Map<dartantic.ToolPart, dartantic.ToolPart>> redactObsoleteToolResults(
    List<dartantic.ChatMessage> history,
  ) async {
    final results = <dartantic.ToolPart, dartantic.ToolPart>{};
    for (var toolset in _toolsets) {
      final subResults = await toolset.redactObsoleteToolResults(history);
      if (results.keys.any(subResults.containsKey)) {
        throw StateError(
          'Multiple toolsets tried to redact the same tool call',
        );
      }
      results.addAll(subResults);
    }
    return results;
  }

  @override
  bool get disposed => super.disposed && _toolsets.every((ts) => ts.disposed);

  @override
  Future<void> dispose() => Future.wait([
    super.dispose().onError((_, _) => null),
    ..._toolsets.map((ts) => ts.dispose().onError((_, _) => null)),
  ]);
}
