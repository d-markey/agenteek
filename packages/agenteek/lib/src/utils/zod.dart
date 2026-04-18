import 'package:dart_mcp/client.dart';
import 'package:dartantic_ai/dartantic_ai.dart' as dartantic show Schema;

// ignore: camel_case_types
abstract class z {
  static dartantic.Schema object(
    Map<String, Object?> properties, {
    String? description,
    List<String>? required,
  }) => dartantic.Schema.fromMap({
    'type': 'object',
    'description': ?description,
    'properties': properties,
    'required': ?required,
  });

  static dartantic.Schema int([String? description]) =>
      dartantic.Schema.fromMap({'type': 'int', 'description': ?description});

  static dartantic.Schema bool([String? description]) =>
      dartantic.Schema.fromMap({'type': 'bool', 'description': ?description});

  static dartantic.Schema string([String? description]) =>
      dartantic.Schema.fromMap({'type': 'string', 'description': ?description});

  static dartantic.Schema of(Tool tool) => dartantic.Schema.fromMap(
    _removeEmptyEnums(tool.inputSchema as Map<String, Object?>),
  );

  static Map<String, Object?> _removeEmptyEnums(Map<String, Object?> schema) {
    var enums = schema['enum'];
    if (enums is List) {
      if (enums.where((e) => e.toString().trim().isEmpty).isNotEmpty) {
        schema['enum'] = enums
            .where((e) => e.toString().trim().isNotEmpty)
            .toList();
      }
    }
    for (var value in schema.values.whereType<Map>()) {
      _removeEmptyEnums(value as Map<String, Object?>);
    }
    return schema;
  }
}
