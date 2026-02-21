import 'package:meta/meta.dart';

import '../../utils/debug.dart' as dbg;
import '../../utils/types.dart';

@internal
extension JsonPatchExt on Map {
  Json patchSchema() {
    List $patch(List array) {
      final types = array
          .map(
            (v) => switch (v) {
              null => 'null',
              String() => 'string',
              int() => 'int',
              double() => 'double',
              bool() => 'bool',
              Map() => 'object',
              List() => 'array',
              _ => v.runtimeType.toString(),
            },
          )
          .toSet();
      final nullable = types.remove('null');
      if (types.length == 1) {
        switch (types.first) {
          case 'string':
            return nullable ? array.cast<String?>() : array.cast<String>();
          case 'int':
            return nullable ? array.cast<int?>() : array.cast<int>();
          case 'double':
            return nullable ? array.cast<double?>() : array.cast<double>();
          case 'bool':
            return nullable ? array.cast<bool?>() : array.cast<bool>();
          case 'object':
            return nullable
                ? array
                      .cast<Map?>()
                      .map((m) => m?.patchSchema())
                      .cast<Json?>()
                      .toList()
                : array
                      .cast<Map>()
                      .map((m) => m.patchSchema())
                      .cast<Json>()
                      .toList();
          case 'array':
            return nullable
                ? array
                      .cast<List?>()
                      .map((a) => (a == null) ? null : $patch(a))
                      .toList()
                : array.cast<List>().map($patch).toList();
          default:
            dbg.trace('UNKNOWN TYPE: ${types.first}');
        }
      } else {
        dbg.trace('MIXED TYPES: $types');
      }

      return array;
    }

    Json $process(Map object) {
      for (var e in object.entries) {
        switch (e.value) {
          case final Map map:
            if (map['type'] == 'array' && !map.containsKey('items')) {
              map['items'] = <String, Object?>{
                'type': 'object',
                'properties': <String, Object?>{},
              };
            }
            if (map['type'] == 'object' && !map.containsKey('properties')) {
              map['properties'] = <String, Object?>{};
            }
            object[e.key] = $process(map);
          case final List list:
            object[e.key] = $patch(list);
          default:
          // nothing to do
        }
      }
      return object.cast<String, Object?>();
    }

    return $process(this);
  }
}
