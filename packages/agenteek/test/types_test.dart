import 'package:agenteek/agenteek.dart';
import 'package:test/test.dart';

void main() {
  group('JsonExtension', () {
    group('getInt', () {
      test('Successful retrieval of existing value', () {
        final json = {'age': 25};
        expect(json.getInt('age'), equals(25));
      });

      test('Successful retrieval of existing value as string', () {
        final json = {'age': '25'};
        expect(json.getInt('age'), equals(25));
      });

      test('Successful retrieval of default value when key is missing', () {
        final json = <String, Object?>{};
        expect(json.getInt('age', defaultValue: 30), equals(30));
      });

      test('MissingArgumentException when required key is missing', () {
        final json = <String, Object?>{};
        expect(
          () => json.getInt('age'),
          throwsA(isA<MissingArgumentException>()),
        );
      });

      test(
        'InvalidArgumentException when value is present but unparseable',
        () {
          final json = {'age': 'not_an_int'};
          expect(
            () => json.getInt('age'),
            throwsA(isA<InvalidArgumentException>()),
          );
        },
      );
    });

    group('getString', () {
      test('Successful retrieval of existing value', () {
        final json = {'name': 'John'};
        expect(json.getString('name'), equals('John'));
      });

      test('Successful retrieval of existing value as int', () {
        final json = {'name': 123};
        expect(json.getString('name'), equals('123'));
      });

      test(
        'Successful retrieval of default value when key is missing, null or empty',
        () {
          final json = <String, Object?>{};
          expect(
            json.getString('name', defaultValue: 'Guest'),
            equals('Guest'),
          );
          json['name'] = null;
          expect(
            json.getString('name', defaultValue: 'Guest'),
            equals('Guest'),
          );
          json['name'] = '';
          expect(
            json.getString('name', defaultValue: 'Guest'),
            equals('Guest'),
          );
        },
      );

      test('MissingArgumentException when required key is missing or null', () {
        final json = <String, Object?>{};
        expect(
          () => json.getString('name'),
          throwsA(isA<MissingArgumentException>()),
        );
        json['name'] = null;
        expect(
          () => json.getString('name'),
          throwsA(isA<MissingArgumentException>()),
        );
      });
    });

    group('getBool', () {
      test('Successful retrieval of existing value', () {
        final json = {'isActive': true};
        expect(json.getBool('isActive'), isTrue);
      });

      test('Successful retrieval of existing value as string', () {
        final json = {'isActive': 'true'};
        expect(json.getBool('isActive'), isTrue);
      });

      test('Successful retrieval of existing value as string (false)', () {
        final json = {'isActive': 'false'};
        expect(json.getBool('isActive'), isFalse);
      });

      test('Successful retrieval of default value when key is missing', () {
        final json = <String, Object?>{};
        expect(json.getBool('isActive', defaultValue: true), isTrue);
      });

      test('MissingArgumentException when required key is missing', () {
        final json = <String, Object?>{};
        expect(
          () => json.getBool('isActive'),
          throwsA(isA<MissingArgumentException>()),
        );
      });

      test(
        'InvalidArgumentException when value is present but unparseable',
        () {
          final json = {'isActive': 'not_a_bool'};
          expect(
            () => json.getBool('isActive'),
            throwsA(isA<InvalidArgumentException>()),
          );
        },
      );
    });
  });
}
