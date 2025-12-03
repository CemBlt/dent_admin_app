import 'package:flutter_test/flutter_test.dart';
import 'package:app_dent/utils/validators.dart';

void main() {
  group('Validators', () {
    test('email doğrulama geçerli adresi kabul eder', () {
      expect(() => Validators.requireEmail('test@example.com'), returnsNormally);
    });

    test('email doğrulama hatalı adresi reddeder', () {
      expect(
        () => Validators.requireEmail('invalid'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('şifre en az 8 karakter olmalı', () {
      expect(() => Validators.requirePassword('12345678'), returnsNormally);
      expect(
        () => Validators.requirePassword('123'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('telefon doğrulaması boş ve hatalı formatları reddeder', () {
      expect(
        () => Validators.requirePhone(''),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => Validators.requirePhone('123'),
        throwsA(isA<ValidationException>()),
      );
      expect(() => Validators.requirePhone('+905551112233'), returnsNormally);
    });
  });
}

