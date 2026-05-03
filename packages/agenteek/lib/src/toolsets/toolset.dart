import 'dart:async';

import '../utils/debug.dart' as dbg;
import '../utils/types.dart';
import 'tool.dart';
import 'tool_outcome.dart';
import 'toolset_base.dart';
import 'toolset_combined.dart';
import 'toolset_exception.dart';

class ToolSet extends ToolSetBase {
  ToolSet();

  static const ToolSet empty = _EmptyToolSet._();

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

  final _tools = <Tool>[];

  @override
  List<Tool> get tools => _tools;

  @override
  Iterable<String> get names => _tools.map((t) => t.name);

  @override
  Tool? getTool(String name) => _tools.where((t) => t.name == name).firstOrNull;

  @override
  void register(Tool tool) {
    final existingTool = getTool(tool.name);
    if (existingTool != null) {
      throw StateError('A tool is already registered for ${tool.name}');
    }
    _tools.add(tool);
  }

  @override
  Future<ToolOutcome<T>> invoke<T>(String name, Json args) async {
    if (_disposed) {
      throw StateError('Cannot invoke a tool after the toolset was disposed.');
    }
    final tool = getTool(name);
    if (tool == null) {
      return ToolError<T>(ToolNotFoundException(name, tools));
    }
    try {
      return await tool.invoke<T>(args);
    } catch (ex, st) {
      return ToolError<T>(ex, st);
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

class _EmptyToolSet extends ToolSetBase implements ToolSet {
  const _EmptyToolSet._();

  @override
  Future<void> dispose() => Future.value();

  @override
  bool get disposed => false;

  @override
  Tool? getTool(String name) => null;

  @override
  Future<ToolOutcome<T>> invoke<T>(String name, Json args) => Future.value(
    ToolError<T>('Tool not found: "$name".', StackTrace.current),
  );

  @override
  Iterable<String> get names => const [];

  @override
  void register(Tool tool) {}

  @override
  final _tools = const <Tool>[];

  @override
  List<Tool> get tools => _tools;

  @override
  bool get _disposed => false;

  @override
  set _disposed(bool value) {}
}
