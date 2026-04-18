class JsonToMarkdownConverter {
  /// Recursively flattens a Map by joining nested keys with a dot ('.').
  /// e.g., {'user': {'name': 'Bob'}} becomes {'user.name': 'Bob'}
  static Map<String, dynamic> _flatten(
    Map<String, dynamic> map, [
    String prefix = '',
  ]) {
    Map<String, dynamic> flattened = {};

    for (var entry in map.entries) {
      final String newKey = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';

      switch (entry.value) {
        case Map<String, dynamic> $:
          // Recursive call for nested maps
          flattened.addAll(_flatten($, newKey));
          break;
        case List $:
          // For lists, we convert them to a string representation to avoid
          // creating an infinite number of columns (e.g., list.0, list.1)
          flattened[newKey] = $.join(', ');
          break;
        default:
          flattened[newKey] = entry.value.toString();
          break;
      }
    }

    return flattened;
  }

  static String? convert(List jsonInput) {
    if (jsonInput.isEmpty) return 'List is empty.';

    final allKeys = <String>{};
    final flattenedDataList = <Map<String, dynamic>>[];

    // 1. Flatten every object in the list first
    for (var item in jsonInput) {
      if (item == null) continue;
      if (item is! Map<String, dynamic>) return null;
      final flattenedItem = _flatten(item);
      allKeys.addAll(flattenedItem.keys);
      flattenedDataList.add(flattenedItem);
    }

    final List<String> sortedKeys = allKeys.toList()..sort();

    // 2. Build the Markdown Table
    final buffer = StringBuffer();

    // Header + separator
    buffer.writeln('| ${sortedKeys.join(' | ')} |');
    buffer.writeln('| ${sortedKeys.map((_) => '---').join(' | ')} |');

    // Data Rows
    for (var row in flattenedDataList) {
      final rowValues = sortedKeys.map((key) {
        final value = row[key];
        // Escape pipes to prevent breaking the table
        return (value == null)
            ? ''
            : value.toString().replaceAll('|', '\\|').trim();
      });
      buffer.writeln('| ${rowValues.join(' | ')} |');
    }

    return buffer.toString();
  }
}
