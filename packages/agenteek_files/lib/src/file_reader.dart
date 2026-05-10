import 'dart:convert';
import 'dart:io';

import 'helpers.dart';

class FileReader {
  /// Reads a string from a file, trying different encodings.
  ///
  /// Returns normalized text (\r\n and \r replaced with \n).
  /// Throws an error if the encoding cannot be detected.
  static Future<String> readString(File file) async {
    for (var encoding in encodings) {
      try {
        final text = await file.readAsString(encoding: encoding);
        if (encoding == latin1 && text.isBinary()) {
          return '';
        }
        return text.normalizeEol();
      } catch (ex) {
        // try next encoding
      }
    }
    throw 'Failed to detect encoding for ${file.path}.';
  }

  static Future<List<String>> readLines(File file) async {
    for (var encoding in encodings) {
      try {
        final lines = await file.readAsLines(encoding: encoding);
        if (encoding == latin1 && lines.isBinary()) {
          return const [];
        }
        return lines;
      } catch (_) {
        // try next encoding
      }
    }
    throw 'Failed to detect encoding for ${file.path}.';
  }
}
