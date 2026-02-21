import 'dart:typed_data';

import 'package:agenteek_files/src/_utf32_codec.dart';
import 'package:test/test.dart';

final throwsFormatException = throwsA(isA<FormatException>());

void main() {
  group('Utf32Codec', () {
    group('utf32-be', () {
      final codec = utf32be;
      final allowMalformedCodec = Utf32Codec(Endian.big, allowMalformed: true);

      test('Valid encoding and decoding', () {
        final original = 'Hello, world! 😀';
        final decoded = codec.decode(codec.encode(original));
        expect(decoded, original);
      });

      test('Invalid UTF-32 sequence - allowMalformed=false', () {
        final invalidData = Uint8List.fromList([0x12, 0x34, 0x56, 0x78]);
        expect(() => codec.decode(invalidData), throwsFormatException);
      });

      test('Invalid UTF-32 sequence - allowMalformed=true', () {
        final invalidData = Uint8List.fromList([0x12, 0x34, 0x56, 0x78]);
        expect(allowMalformedCodec.decode(invalidData), contains('\uFFFD'));
      });

      test('BOM detection', () {
        final dataWithBom = Uint8List.fromList([
          0x00,
          0x00,
          0xFE,
          0xFF,
          0x00,
          0x00,
          0x00,
          0x48,
          0x00,
          0x00,
          0x00,
          0x65,
        ]); // BOM + "He"
        expect(codec.decode(dataWithBom), 'He');
      });

      test('Do not decode with invalid BOM', () {
        final dataWithBom = Uint8List.fromList([
          0xFF,
          0xFE,
          0x00,
          0x00,
          0x48,
          0x00,
          0x00,
          0x00,
          0x65,
          0x00,
          0x00,
          0x00,
        ]); // BOM + "He" (little-endian)
        expect(() => codec.decode(dataWithBom), throwsFormatException);
      });

      test('Missing BOM', () {
        final dataWithoutBom = Uint8List.fromList([
          0x00,
          0x00,
          0x00,
          0x48,
          0x00,
          0x00,
          0x00,
          0x65,
        ]); // "He" without BOM
        expect(codec.decode(dataWithoutBom), equals('He'));
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

    group('utf32-le', () {
      final codec = utf32le;
      final allowMalformedCodec = Utf32Codec(
        Endian.little,
        allowMalformed: true,
      );

      test('Valid encoding and decoding', () {
        final original = 'Hello, world! 😀';
        final decoded = codec.decode(codec.encode(original));
        expect(decoded, original);
      });

      test('Invalid UTF-32 sequence - allowMalformed=false', () {
        final invalidData = Uint8List.fromList([0x12, 0x34, 0x56, 0x78]);
        expect(() => codec.decode(invalidData), throwsFormatException);
      });

      test('Invalid UTF-32 sequence - allowMalformed=true', () {
        final invalidData = Uint8List.fromList([0x12, 0x34, 0x56, 0x78]);
        expect(allowMalformedCodec.decode(invalidData), contains('\uFFFD'));
      });

      test('BOM detection', () {
        final dataWithBom = Uint8List.fromList([
          0xFF,
          0xFE,
          0x00,
          0x00,
          0x48,
          0x00,
          0x00,
          0x00,
          0x65,
          0x00,
          0x00,
          0x00,
        ]); // BOM + "He"
        expect(codec.decode(dataWithBom), 'He');
      });

      test('Do not decode with invalid BOM', () {
        final dataWithBom = Uint8List.fromList([
          0x00,
          0x00,
          0xFE,
          0xFF,
          0x00,
          0x00,
          0x00,
          0x48,
          0x00,
          0x00,
          0x00,
          0x65,
        ]); // BOM + "He" (big-endian)
        expect(() => codec.decode(dataWithBom), throwsFormatException);
      });

      test('Missing BOM', () {
        final dataWithoutBom = Uint8List.fromList([
          0x48,
          0x00,
          0x00,
          0x00,
          0x65,
          0x00,
          0x00,
          0x00,
        ]); // "He" without BOM
        expect(codec.decode(dataWithoutBom), equals('He'));
      });

      test('Empty input', () {
        expect(utf32le.decode(Uint8List.fromList([])), '');
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
