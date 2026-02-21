enum FileMode {
  none,
  readOnly,
  readWrite;

  static FileMode parse(String value) => switch (value.trim()) {
    '' || 'none' => none,
    'read' || 'read-only' => readOnly,
    'read-write' => readWrite,
    _ => throw UnsupportedError('Unsupported mode: $value'),
  };
}
