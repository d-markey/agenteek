import 'dart:convert';
import 'dart:io';

import '_utf16_codec.dart';
import '_utf32_codec.dart';

const encodings = [
  utf32be,
  utf32le,
  utf16be,
  utf16le,
  utf8,
  systemEncoding,
  latin1,
];

class FileReader {
  static Future<String> readString(File file) async {
    for (var encoding in encodings) {
      try {
        final text = await file.readAsString(encoding: encoding);
        if ((encoding == systemEncoding || encoding == latin1) &&
            text.isBinary()) {
          return '';
        }
        return text;
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
        if ((encoding == systemEncoding || encoding == latin1) &&
            lines.isBinary()) {
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

extension TextBinaryCheckExt on String {
  bool isBinary({int maxCheck = 2048}) {
    int /*zero = 0, ctrl = 0,*/ ws = 0, ascii = 0, other = 0, len = 0;
    for (var rune in runes) {
      len++;
      if (rune == 0x00) {
        //zero++;
      } else if ((0x09 <= rune && rune <= 0x0D) || (rune == 0x20)) {
        ws++;
      } else if (rune < 0x20 || rune == 0x7F) {
        //ctrl++;
      } else if (rune < 0x7F) {
        ascii++;
      } else {
        other++;
      }
      if (len > maxCheck) break;
    }
    // binary if less than 98% printable characters / whitespaces
    return (100 * (ascii + ws + other) < (98 * len));
  }
}

extension LinesBinaryCheck on Iterable<String> {
  bool isBinary({int maxCheck = 2048}) {
    int /*zero = 0, ctrl = 0,*/ ws = 0, ascii = 0, other = 0, len = 0;
    for (var line in this) {
      for (var rune in line.runes) {
        len++;
        if (rune == 0x00) {
          // zero++;
        } else if ((0x09 <= rune && rune <= 0x0D) || (rune == 0x20)) {
          ws++;
        } else if (rune < 0x20 || rune == 0x7F) {
          // ctrl++;
        } else if (rune < 0x7F) {
          ascii++;
        } else {
          other++;
        }
        if (len > maxCheck) break;
      }
      if (len > maxCheck) break;
    }
    // binary if less than 98% printable characters / whitespaces
    return (100 * (ascii + ws + other) < (98 * len));
  }
}
