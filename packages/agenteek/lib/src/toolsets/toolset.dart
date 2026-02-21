import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import '../utils/debug.dart' as dbg;
import '../utils/log.dart';
import '../utils/types.dart';
import 'toolset_base.dart';
import 'toolset_combined.dart';

class ToolSet extends ToolSetBase {
  ToolSet();

  static const ToolSetBase empty = EmptyToolSet._();

  factory ToolSet.combined(Iterable<ToolSet> toolSets) {
    final toolsets = toolSets.toSet();
    final names = toolsets.expand((ts) => ts.names).toList();
    final dedup = names.toSet();
    if (names.length != dedup.length) {
      throw StateError(
        'Cannot combine toolsets containing tools with same names.',
      );
    }
    return CombinedToolSet(toolsets);
  }

  final _tools = <dartantic.Tool>[];

  @override
  List<dartantic.Tool> get tools => _tools;

  @override
  Iterable<String> get names => _tools.map((t) => t.name);

  @override
  dartantic.Tool? getTool(String name) =>
      _tools.where((t) => t.name == name).firstOrNull;

  @override
  void register(dartantic.Tool tool) {
    final existingTool = getTool(tool.name);
    if (existingTool != null) {
      throw StateError('A tool is already registered for ${tool.name}');
    }
    _tools.add(tool);
  }

  @override
  Future<dynamic> invoke(String name, Json args) async {
    if (_disposed) {
      throw StateError('Cannot invoke a tool after the toolset was disposed.');
    }
    final tool = getTool(name);
    if (tool == null) return tool.notFoundError();
    try {
      return await tool.call(args);
    } catch (ex, st) {
      return tool.executionError(ex, st);
    }
  }

  @override
  bool get disposed => _disposed;
  bool _disposed = false;

  @override
  Future<void> dispose() async {
    dbg.trace('Disposing $runtimeType #$hashCode ($_disposed)');
    _disposed = true;
  }
}

class EmptyToolSet extends ToolSetBase {
  const EmptyToolSet._();

  @override
  Future<void> dispose() => Future.value();

  @override
  bool get disposed => false;

  @override
  dartantic.Tool<Object>? getTool(String name) => null;

  @override
  FutureOr<dynamic> invoke(String name, Json args) =>
      throw Exception('Tool "$name" not found.');

  @override
  Iterable<String> get names => const [];

  @override
  void register(dartantic.Tool<Object> tool) {}

  @override
  List<dartantic.Tool<Object>> get tools => const [];
}

extension on dartantic.Tool? {
  static const _unknownToolResult = {'error': 'Unknown tool'};

  Json notFoundError() => _unknownToolResult;

  Json executionError(Object exception, [StackTrace? st]) {
    final message = exception.toString();
    modelLogger.append(
      () =>
          'Exception in tool ${this?.name ?? '???'}: $message, stacktrace=$st',
    );
    return {'error': message, 'stackTrace': ?st?.toString()};
  }
}
