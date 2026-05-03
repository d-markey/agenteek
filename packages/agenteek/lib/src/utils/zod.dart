import 'package:dart_mcp/client.dart';
import 'package:dartantic_ai/dartantic_ai.dart' as dartantic show Schema;

typedef Z = dartantic.Schema;

extension SchemaExt on Tool {
  dartantic.Schema getSchema() =>
      .fromMap(_removeEmptyEnums(inputSchema as Map<String, Object?>));

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

extension DescriptionExt on String {
  String optional([String defaultValue = '']) => defaultValue.isEmpty
      ? '${toString()} (optional)'
      : '${toString()} (optional; defaults to "$defaultValue")';

  String sideEffect(String sideEffect) => sideEffect.isEmpty
      ? '${toString()}; **WARNING: this tool has side effects**'
      : '${toString()}; **WARNING: this tool has side effects** $sideEffect';
}
