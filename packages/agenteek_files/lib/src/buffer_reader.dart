import 'dart:convert';

import 'helpers.dart';

class BufferReader {
  /// Reads a string from a list of bytes, trying different encodings.
  ///
  /// Returns normalized text (\r\n and \r replaced with \n).
  /// Throws an error if the encoding cannot be detected.
  static String readString(List<int> bytes) {
    for (var encoding in encodings) {
      try {
        final text = encoding.decode(bytes);
        return (encoding == latin1 && text.isBinary())
            ? ''
            : text.normalizeEol();
      } catch (ex) {
        // try next encoding
      }
    }
    throw 'Failed to detect encoding.';
  }

  static List<String> readLines(List<int> bytes) =>
      readString(bytes).split('\n');
}
