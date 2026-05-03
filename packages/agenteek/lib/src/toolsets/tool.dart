import 'dart:async';
import 'dart:convert';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import '../utils/types.dart';
import 'tool_outcome.dart';

class Tool<T> implements dartantic.Tool<Json> {
  Tool({
    required String name,
    required String description,
    dartantic.Schema? inputSchema,
    required FutureOr<ToolOutcome<T>> Function(Json) onCall,
  }) : _tool = dartantic.Tool(
         name: name,
         description: description,
         inputSchema: inputSchema,
         onCall: onCall,
       );

  final dartantic.Tool<Json> _tool;

  @override
  String get description => _tool.description;

  @override
  dartantic.Schema get inputSchema => _tool.inputSchema;

  @override
  String get name => _tool.name;

  @override
  FutureOr<ToolOutcome<T>> Function(Json) get onCall =>
      _tool.onCall as FutureOr<ToolOutcome<T>> Function(Json);

  @override
  Map<String, Object?> toJson() => _tool.toJson();

  Future<ToolOutcome<V>> invoke<V>(Json arguments) async {
    try {
      return (await _tool.call(arguments)) as ToolOutcome<V>;
    } catch (ex, st) {
      return ToolError<V>(ex.toString(), st);
    }
  }

  @override
  Future<String> call(Json arguments) async {
    try {
      final result = (await invoke<T>(arguments)).result;
      if (result is String || result is num || result is bool) {
        return result.toString();
      } else if (result is List<String>) {
        return result.join('\n');
      } else if (result is List<num>) {
        return result.join(' ');
      } else {
        return jsonEncode(result);
      }
    } catch (ex) {
      return "**ERROR:** $ex";
    }
  }
}
