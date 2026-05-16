import 'dart:convert';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import '../toolsets/tool_outcome.dart';
import '../toolsets/toolset.dart';
import 'types.dart';

extension ObjectDbgExt on Object? {
  String getHexHashCode(int width) =>
      hashCode.toRadixString(16).padLeft(width, '0');
}

String dump(dynamic args, {int maxLen = 40}) {
  final str = args.toString();
  return (str.length > maxLen) ? '${str.substring(0, maxLen)}...' : str;
}

extension ChatMessageDbgExt on dartantic.ChatMessage {
  static final _indent = JsonEncoder.withIndent('  ');

  String dump() =>
      '[${role.name}]:\n\n${parts.map((p) => '* part ${p.runtimeType}\n```\n${_indent.convert(p.toJson()).replaceAll('```', '`')}\n```').join('\n')}\n';
}

extension ToolSetDbgExt on ToolSet {
  Future<ToolOutcome<T>> call<T>(String name, [Json args = const {}]) =>
      invoke<T>(getToolName(name), args);

  String getToolName(String name) {
    final uname = '.$name';
    return tools
            .map((s) => s.name)
            .where((n) => n == name || n.endsWith(uname))
            .singleOrNull ??
        name;
  }
}

extension MapDbgExt<K, V> on Map<K, V> {
  Map<K, V> without(String key) => deepClone().._detach(key);

  Map<K, V> deepClone() {
    Map<K, V> newMap = {};

    for (var e in entries) {
      final v = e.value;
      if (v is Map && v.isEmpty) continue;
      if (v is List && v.isEmpty) continue;
      newMap[e.key] = switch (v) {
        Map() => v.deepClone() as V,
        List() => v.deepClone() as V,
        _ => v,
      };
    }

    return newMap;
  }

  void _detach(String key) {
    final stack = <Map>[this];
    if (key.isEmpty) {
      while (stack.isNotEmpty) {
        final m = stack.removeLast();
        for (var v in m.values) {
          if (v is Map) {
            stack.add(v);
          } else if (v is List) {
            stack.addAll(v.whereType<Map>());
          }
        }
      }
    } else {
      while (stack.isNotEmpty) {
        final m = stack.removeLast();
        m.remove(key);
        for (var v in m.values) {
          if (v is Map) {
            stack.add(v);
          } else if (v is List) {
            stack.addAll(v.whereType<Map>());
          }
        }
      }
    }
  }
}

extension on List<Object?> {
  List<Object?> deepClone() {
    List<Object?> newList = [];

    for (var v in this) {
      newList.add(switch (v) {
        Map() => v.deepClone(),
        List() => v.deepClone(),
        _ => v,
      });
    }

    return newList;
  }
}
