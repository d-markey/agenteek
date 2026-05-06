import 'dart:typed_data';

import 'package:agenteek_files/src/_utf16_codec.dart';
import 'package:test/test.dart';

final throwsFormatException = throwsA(isA<FormatException>());

void main() {
  group('Utf16Codec', () {
    group('utf16-be', () {
      final codec = utf16be;
      final allowMalformedCodec = Utf16Codec(Endian.big, allowMalformed: true);

      test('Valid encoding and decoding', () {
        final original = 'Hello, world! 😀';
        final decoded = codec.decode(codec.encode(original));
        expect(decoded, original);
      });

      test('Decode with BOM', () {
        final bytes = Uint8List.fromList([
          0xFE,
          0xFF,
          0x00,
          0x41,
          0x00,
          0x42,
        ]); // BOM + "AB"
        expect(codec.decode(bytes), 'AB');
      });

      test('Decode without BOM fails', () {
        final bytes = Uint8List.fromList([
          0x00,
          0x41,
          0x00,
          0x42,
        ]); // BOM + "AB"
        expect(() => codec.decode(bytes), throwsFormatException);
      });

      test('Do not decode with invalid BOM', () {
        final bytes = Uint8List.fromList([
          0xFF,
          0xFE,
          0x41,
          0x00,
          0x42,
          0x00,
        ]); // BOM + "AB" (little endian)
        expect(() => codec.decode(bytes), throwsFormatException);
      });

      test('Encode with BOM', () {
        expect(codec.encode('AB'), [0xFE, 0xFF, 0x00, 0x41, 0x00, 0x42]);
      });

      test('Handle invalid sequence', () {
        final bytesBE = Uint8List.fromList([
          0xFE,
          0xFF,
          0x00,
          0x41,
          0xD8,
          0x00,
        ]); // Incomplete surrogate pair
        expect(
          allowMalformedCodec.decode(bytesBE),
          String.fromCharCodes([0x0041, 0xFFFD]),
        );
        expect(() => codec.decode(bytesBE), throwsFormatException);
      });

      test('Empty input', () {
        expect(codec.decode(Uint8List.fromList([])), '');
      });

      test('Long string', () {
        final longString = 'a' * 1024;
        final encoded = codec.encode(longString);
        expect(codec.decode(encoded), longString);
      });

      test('String with special characters', () {
        final specialChars = '~!@#\$%^&*()_+`-= []\\{}|;\':",./<>?';
        final encoded = codec.encode(specialChars);
        expect(codec.decode(encoded), specialChars);
      });
    });

    group('utf16-le', () {
      final codec = utf16le;
      final allowMalformedCodec = Utf16Codec(
        Endian.little,
        allowMalformed: true,
      );

      test('Valid encoding and decoding', () {
        final original = 'Hello, world! 😀';
        final decoded = codec.decode(codec.encode(original));
        expect(decoded, original);
      });

      test('Decode with BOM', () {
        final bytes = Uint8List.fromList([
          0xFF,
          0xFE,
          0x41,
          0x00,
          0x42,
          0x00,
        ]); // BOM + "AB"
        expect(codec.decode(bytes), 'AB');
      });

      test('Decode without BOM fails', () {
        final bytes = Uint8List.fromList([
          0x41,
          0x00,
          0x42,
          0x00,
        ]); // BOM + "AB"
        expect(() => codec.decode(bytes), throwsFormatException);
      });

      test('Do not decode with invalid BOM', () {
        final bytes = Uint8List.fromList([
          0xFE,
          0xFF,
          0x00,
          0x41,
          0x00,
          0x42,
        ]); // BOM + "AB" (little-endian)
        expect(() => codec.decode(bytes), throwsFormatException);
      });

      test('Encode with BOM', () {
        expect(codec.encode('AB'), [0xFF, 0xFE, 0x41, 0x00, 0x42, 0x00]);
      });

      test('Handle invalid sequence', () {
        final bytesLE = Uint8List.fromList([
          0xFF,
          0xFE,
          0x41,
          0x00,
          0x00,
          0xD8,
        ]); // Incomplete surrogate pair
        expect(
          allowMalformedCodec.decode(bytesLE),
          String.fromCharCodes([0x0041, 0xFFFD]),
        );
        expect(() => codec.decode(bytesLE), throwsFormatException);
      });

      test('Empty input', () {
        expect(codec.decode(Uint8List.fromList([])), '');
      });

      test('Long string', () {
        final longString = 'a' * 1024;
        final encoded = codec.encode(longString);
        expect(codec.decode(encoded), longString);
      });

      test('String with special characters', () {
        final specialChars = '~!@#\$%^&*()_+`-= []\\{}|;\':",./<>?';
        final encoded = codec.encode(specialChars);
        expect(codec.decode(encoded), specialChars);
      });
    });
  });
}
