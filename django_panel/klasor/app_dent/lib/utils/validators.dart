/// Form ve servis düzeyinde tekrar kullanılabilir doğrulamalar.
class Validators {
  Validators._();

  static final _emailRegex = RegExp(r'^.+@.+\..+$');
  static final _phoneRegex = RegExp(r'^(\+?\d{10,15}|0\d{9,10})$');

  static void requireEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      throw const ValidationException('Email adresi gerekli');
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      throw const ValidationException('Geçerli bir email adresi girin');
    }
  }

  static void requirePassword(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) {
      throw const ValidationException('Şifre gerekli');
    }
    if (value.length < minLength) {
      throw ValidationException('Şifre en az $minLength karakter olmalı');
    }
  }

  static void requirePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      throw const ValidationException('Telefon numarası gerekli');
    }
    if (!_phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
      throw const ValidationException('Geçerli bir telefon numarası girin');
    }
  }

  static void requireNonEmpty(String? value, String fieldLabel) {
    if (value == null || value.trim().isEmpty) {
      throw ValidationException('$fieldLabel gerekli');
    }
  }
}

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);

  @override
  String toString() => message;
}


