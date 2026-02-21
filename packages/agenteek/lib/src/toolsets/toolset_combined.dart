import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import 'toolset.dart';

class CombinedToolSet extends ToolSet {
  CombinedToolSet(this._toolsets);

  final Set<ToolSet> _toolsets;

  @override
  void register(dartantic.Tool tool) {
    throw UnsupportedError(
      'A combined toolset cannot have tools outside of children toolsets',
    );
  }

  @override
  List<dartantic.Tool> get tools => _toolsets.expand((ts) => ts.tools).toList();

  @override
  List<String> get names => _toolsets.expand((ts) => ts.names).toList();

  @override
  dartantic.Tool? getTool(String name) =>
      _toolsets.map((ts) => ts.getTool(name)).nonNulls.firstOrNull;

  @override
  bool get disposed => super.disposed && _toolsets.every((ts) => ts.disposed);

  @override
  Future<void> dispose() => Future.wait([
    super.dispose().onError((_, _) => null),
    ..._toolsets.map((ts) => ts.dispose().onError((_, _) => null)),
  ]);
}
