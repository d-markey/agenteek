import 'dart:convert';
import 'dart:typed_data';

import '_unicode.dart' as unicode;

const utf32be = Utf32Codec(Endian.big);
const utf32le = Utf32Codec(Endian.little);

class Utf32Codec extends Encoding {
  const Utf32Codec(this.endian, {bool allowMalformed = false})
    : _allowMalformed = allowMalformed;

  final Endian endian;
  final bool _allowMalformed;

  @override
  String get name => (endian == Endian.big) ? 'utf32-be' : 'utf32-le';

  @override
  Utf32Encoder get encoder => (endian == Endian.big)
      ? const Utf32Encoder(Endian.big)
      : const Utf32Encoder(Endian.little);

  @override
  Utf32Decoder get decoder => _allowMalformed
      ? ((endian == Endian.big)
            ? const Utf32Decoder(Endian.big, allowMalformed: true)
            : const Utf32Decoder(Endian.little, allowMalformed: true))
      : ((endian == Endian.big)
            ? const Utf32Decoder(Endian.big, allowMalformed: false)
            : const Utf32Decoder(Endian.little, allowMalformed: false));
}

class Utf32Encoder extends Converter<String, Uint8List> {
  final Endian endian;

  const Utf32Encoder(this.endian);

  @override
  Uint8List convert(String input) {
    final runes = input.runes.toList();
    final bytes = Uint8List(runes.length * 4 + 4); // +4 for BOM
    final byteData = ByteData.sublistView(bytes);
    byteData.setUint32(0, unicode.bom, endian);
    for (int i = 0; i < runes.length; i++) {
      byteData.setUint32(i * 4 + 4, runes[i], endian);
    }
    return bytes;
  }
}

class Utf32Decoder extends Converter<List<int>, String> {
  const Utf32Decoder(this.endian, {this.allowMalformed = false});

  final Endian endian;
  final bool allowMalformed;

  @override
  String convert(List<int> input) {
    var len = input.length ~/ 4;
    if (input.length != len * 4) {
      throw const FormatException('Inconsistent UTF-32 buffer size.');
    }

    final bytes = Uint8List.fromList(input);
    var view = ByteData.sublistView(bytes);
    var idx = 0;

    if (len >= 1) {
      final bom = view.getUint32(0, endian);
      if (bom == unicode.bom) {
        len--;
        idx = 4;
      } else if (bom == unicode.rbom32) {
        throw const FormatException('Inconsistent UTF-32 BOM vs. endianness.');
      } else {
        // BOM is optional for UTF-32
      }
    }

    final buffer = Uint32List(len);

    if (allowMalformed) {
      for (int i = 0; i < len; i++, idx += 4) {
        final rune = view.getUint32(idx, endian);
        buffer[i] = (rune < unicode.maxCodepoint) ? rune : unicode.replacement;
      }
    } else {
      for (int i = 0; i < len; i++, idx += 4) {
        final rune = view.getUint32(idx, endian);
        buffer[i] = (rune < unicode.maxCodepoint)
            ? rune
            : throw const FormatException('Invalid UTF-32 character');
      }
    }

    return String.fromCharCodes(buffer);
  }
}
