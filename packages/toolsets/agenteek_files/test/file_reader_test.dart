import 'dart:convert';
import 'dart:io';

import 'package:agenteek_files/agenteek_files.dart';
import 'package:agenteek_files/src/_utf16_codec.dart';
import 'package:test/test.dart';

void main() {
  group('FileReader', () {
    test('utf16-be with BOM', () async {
      final file = File('./test/assets/utf16be_bom.txt');
      final contents = await file.readAsString(encoding: utf16be);
      final text = await FileReader.readString(file);
      expect(text, contents);
    });

    test('utf16-le with BOM', () async {
      final file = File('./test/assets/utf16le_bom.txt');
      final contents = await file.readAsString(encoding: utf16le);
      final text = await FileReader.readString(file);
      expect(text, contents);
    });

    test('utf8 with BOM', () async {
      final file = File('./test/assets/utf8_bom.txt');
      final contents = await file.readAsString(encoding: utf8);
      final text = await FileReader.readString(file);
      expect(text, contents);
    });

    test('utf8 without BOM', () async {
      final file = File('./test/assets/utf8.txt');
      final contents = await file.readAsString(encoding: utf8);
      final text = await FileReader.readString(file);
      expect(text, contents);
    });

    test('Windows1252', () async {
      final file = File('./test/assets/cp1252.txt');
      final contents = await file.readAsString(encoding: systemEncoding);
      final text = await FileReader.readString(file);
      expect(text, contents);
    });
  });
}
