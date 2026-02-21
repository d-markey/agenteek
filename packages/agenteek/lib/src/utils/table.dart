class Table {
  Table(this.data, {this.headers = const []});

  final List<String> headers;
  final List<List<Object?>> data;

  Iterable<String> get rows sync* {
    var columns = headers.length;
    for (var row in data) {
      if (row.length > columns) {
        columns = row.length;
      }
    }

    final sb = StringBuffer();

    yield _row(sb, columns, headers, _defaultHeader);
    yield _separation(sb, columns);
    yield* data.map((r) => _row(sb, columns, r, _defaultData));
    yield _separation(sb, columns);
  }
}

String _defaultHeader(int i) => 'Column #$i';
String _defaultData(_) => '';

String _row(
  StringBuffer sb,
  int columns,
  List<Object?> data,
  String Function(int) missingData,
) {
  sb.clear();
  for (var i = 0; i < columns; i++) {
    final text = (i < data.length) ? data[i] : missingData(i);
    sb.write('| $text ');
  }
  sb.write('|');
  return sb.toString();
}

String _separation(StringBuffer sb, int columns) {
  sb.clear();
  for (var i = 0; i < columns; i++) {
    sb.write('|---');
  }
  sb.write('|');
  return sb.toString();
}
