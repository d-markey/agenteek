import 'dart:math';

import 'types.dart';

class MarkdownTable {
  /// Recursively flattens a Map by joining nested keys with a dot ('.').
  /// e.g., {'user': {'name': 'Bob'}} becomes {'user.name': 'Bob'}
  static Json _flatten(Json json, [String prefix = '']) {
    final flattened = Json();

    for (final entry in json.entries) {
      final newKey = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';

      final _ = switch (entry.value) {
        // Recursive call for nested maps
        Json $ => flattened.addAll(_flatten($, newKey)),
        // For lists, we convert them to a string representation to avoid
        // creating an infinite number of columns (e.g., list.0, list.1)
        List $ => flattened[newKey] = $.join(', '),
        _ => flattened[newKey] = entry.value.toString(),
      };
    }

    return flattened;
  }

  static String fromJsonList(
    Iterable<Json> jsonInput, {
    Map<String, String> headers = const {},
    bool sortKeys = false,
  }) {
    if (jsonInput.isEmpty) return 'List is empty.';

    final allKeys = <String>{}, flatData = <Json>[];

    // 1. Flatten every object in the list first
    for (var item in jsonInput) {
      final flatItem = _flatten(item);
      allKeys.addAll(flatItem.keys);
      flatData.add(flatItem);
    }

    final flatKeys = allKeys.toList();
    if (sortKeys) flatKeys.sort();

    // 2. Build the Markdown Table
    final buffer = StringBuffer();

    // Header + separator
    String $hdr(String key) => headers[key] ?? key;
    buffer.writeln('| ${flatKeys.map($hdr).join(' | ')} |');
    buffer.writeln('| ${flatKeys.map(_sep).join(' | ')} |');

    // Data Rows
    for (var row in flatData) {
      // Escape pipes & CRLF/CR/LF to prevent breaking the table
      final rowValues = flatKeys.map((key) => _esc(row[key]));
      buffer.writeln('| ${rowValues.join(' | ')} |');
    }

    return buffer.toString();
  }

  static String fromList(
    Iterable<List> items, {
    List<String> headers = const [],
  }) {
    if (items.isEmpty) return 'List is empty.';

    final maxLen = items.map((e) => e.length).reduce(max);
    final maxItems = Iterable<int>.generate(maxLen);

    // 2. Build the Markdown Table
    final buffer = StringBuffer();

    // Header + separator
    String $hdr(int idx) => headers.safeGet(idx) ?? 'Column #$idx';
    buffer.writeln('| ${maxItems.map($hdr).join(' | ')} |');
    buffer.writeln('| ${maxItems.map(_sep).join(' | ')} |');

    // Data Rows
    for (var row in items) {
      // Escape pipes & CRLF/CR/LF to prevent breaking the table
      final rowValues = maxItems.map((idx) => _esc(row.safeGet(idx)));
      buffer.writeln('| ${rowValues.join(' | ')} |');
    }

    return buffer.toString();
  }

  static String _sep(_) => '---';

  static String _esc(dynamic value) =>
      value
          ?.toString()
          .trim()
          .replaceAll('|', '\\|')
          .replaceAll('\\r\\n', '\n')
          .replaceAll('\\r', '\n')
          .replaceAll('\\r', '<br />') ??
      '';
}

extension<T> on List<T> {
  T? safeGet(int idx) => (idx < length) ? this[idx] : null;
}
