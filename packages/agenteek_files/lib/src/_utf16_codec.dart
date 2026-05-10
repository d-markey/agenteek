import 'dart:convert';
import 'dart:typed_data';

import '_unicode.dart' as unicode;

const utf16be = Utf16Codec(Endian.big);
const utf16le = Utf16Codec(Endian.little);

class Utf16Codec extends Encoding {
  final Endian endian;

  const Utf16Codec(this.endian, {bool allowMalformed = false})
    : _allowMalformed = allowMalformed;

  final bool _allowMalformed;

  @override
  String get name => (endian == Endian.big) ? 'utf16-be' : 'utf16-le';

  @override
  Utf16Encoder get encoder => (endian == Endian.big)
      ? const Utf16Encoder(Endian.big)
      : const Utf16Encoder(Endian.little);

  @override
  Utf16Decoder get decoder => _allowMalformed
      ? ((endian == Endian.big)
            ? const Utf16Decoder(Endian.big, allowMalformed: true)
            : const Utf16Decoder(Endian.little, allowMalformed: true))
      : ((endian == Endian.big)
            ? const Utf16Decoder(Endian.big, allowMalformed: false)
            : const Utf16Decoder(Endian.little, allowMalformed: false));
}

class Utf16Encoder extends Converter<String, List<int>> {
  final Endian endian;

  const Utf16Encoder(this.endian);

  @override
  List<int> convert(String input) {
    final units = input.codeUnits;
    final buffer = Uint8List(units.length * 2 + 2); // +2 for BOM
    final byteData = ByteData.view(buffer.buffer);
    byteData.setUint16(0, unicode.bom, endian);
    for (var i = 0; i < units.length; i++) {
      byteData.setUint16(i * 2 + 2, units[i], endian);
    }
    return buffer;
  }
}

class Utf16Decoder extends Converter<List<int>, String> {
  const Utf16Decoder(this.endian, {this.allowMalformed = false});

  final Endian endian;
  final bool allowMalformed;

  @override
  String convert(List<int> input) {
    var len = input.length ~/ 2;
    if (input.length != len * 2) {
      throw const FormatException('Inconsistent UTF-16 buffer size.');
    }

    final bytes = Uint8List.fromList(input);
    var view = ByteData.sublistView(bytes);
    var idx = 0;

    if (len >= 1) {
      final bom = view.getUint16(0, endian);
      if (bom == unicode.bom) {
        len--;
        idx = 2;
      } else if (bom == unicode.rbom16) {
        throw const FormatException('Inconsistent UTF-16 BOM vs. endianness.');
      } else {
        // BOM is mandatory for UTF-16
        throw const FormatException('Missing UTF-16 BOM.');
      }
    }

    final buffer = Uint16List(len);

    var h = false;
    if (allowMalformed) {
      for (var i = 0; i < len; i++, idx += 2) {
        var unit = view.getUint16(idx, endian);
        switch (unit) {
          case >= unicode.minHighSurrogate && <= unicode.maxHighSurrogate:
            if (h) buffer[i - 1] = unicode.replacement;
            h = true;
          case >= unicode.minLowSurrogate && <= unicode.maxLowSurrogate:
            if (!h) unit = unicode.replacement;
            h = false;
          default:
            if (h) buffer[i - 1] = unicode.replacement;
            h = false;
        }
        buffer[i] = unit;
      }
      if (h) buffer[len - 1] = unicode.replacement;
    } else {
      for (var i = 0; i < len; i++, idx += 2) {
        final unit = view.getUint16(idx, endian);
        switch (unit) {
          case >= unicode.minHighSurrogate && <= unicode.maxHighSurrogate:
            if (h) throw const FormatException('Invalid UTF-16 surrogate pair');
            h = true;
          case >= unicode.minLowSurrogate && <= unicode.maxLowSurrogate:
            if (!h) throw const FormatException('Unexpected UTF-16 surrogate');
            h = false;
          default:
            if (h) throw const FormatException('Invalid UTF-16 surrogate pair');
        }
        buffer[i] = unit;
      }
      if (h) throw const FormatException('Incomplete UTF-16 surrogate pair');
    }

    return String.fromCharCodes(buffer);
  }
}
