import 'dart:async';

import 'package:agenteek/agenteek.dart';
import 'package:test/test.dart';

void expectError(Json result, Matcher matcher) {
  expect(result['error'], isA<String>());
  expect((result['error'] as String).toLowerCase(), matcher);
}

extension Ext on ToolSet {
  Future<Json> jsonCall(String name, [Json args = const {}]) async =>
      (await invoke(name, args)) as Json;

  Future<String> stringCall(String name, [Json args = const {}]) async =>
      (await invoke(name, args)) as String;
}
