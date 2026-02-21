import 'dart:async';

import 'package:agenteek/agenteek.dart';
import 'package:test/test.dart';

void expectError(Json result, Matcher matcher) {
  expect(result['error'], isA<String>());
  expect((result['error'] as String).toLowerCase(), matcher);
}

extension Ext on ToolSet {
  Future<Json> jsonCall(String name, [Json args = const {}]) async =>
      (await invoke(getToolName(name), args)) as Json;

  Future<String> stringCall(String name, [Json args = const {}]) async =>
      (await invoke(getToolName(name), args)) as String;

  String getToolName(String name) =>
      tools.map((s) => s.name).where((n) => n.endsWith(name)).singleOrNull ??
      tools.map((s) => s.name).where((n) => n.contains(name)).singleOrNull ??
      '';
}
