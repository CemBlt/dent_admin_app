import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/phone_number.dart';

import '../services/auth_service.dart';
import '../utils/validators.dart';

class LoginState {
  final bool isLoading;
  final bool obscurePassword;
  final String? errorMessage;

  const LoginState({
    required this.isLoading,
    required this.obscurePassword,
    this.errorMessage,
  });

  factory LoginState.initial() => const LoginState(
        isLoading: false,
        obscurePassword: true,
      );

  LoginState copyWith({
    bool? isLoading,
    bool? obscurePassword,
    String? errorMessage,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      errorMessage: errorMessage,
    );
  }
}

class RegisterState {
  final bool isLoading;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool? isPhoneUnique;
  final bool? isEmailUnique;
  final String? phoneError;

  const RegisterState({
    required this.isLoading,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    this.isPhoneUnique,
    this.isEmailUnique,
    this.phoneError,
  });

  factory RegisterState.initial() => const RegisterState(
        isLoading: false,
        obscurePassword: true,
        obscureConfirmPassword: true,
      );

  RegisterState copyWith({
    bool? isLoading,
    bool? obscurePassword,
    bool? obscureConfirmPassword,
    bool? isPhoneUnique,
    bool? isEmailUnique,
    String? phoneError,
  }) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword: obscureConfirmPassword ?? this.obscureConfirmPassword,
      isPhoneUnique: isPhoneUnique,
      isEmailUnique: isEmailUnique,
      phoneError: phoneError,
    );
  }
}

class LoginController extends StateNotifier<LoginState> {
  LoginController() : super(LoginState.initial());

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  Future<bool> login({
    required String email,
    required String password,
    required void Function(String message) showMessage,
  }) async {
    if (state.isLoading) return false;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      Validators.requireEmail(email);
      Validators.requirePassword(password);

      final response = await AuthService.signInWithEmail(
        email: email.trim(),
        password: password,
      );

      return response.user != null;
    } on ValidationException catch (e) {
      showMessage(e.message);
    } catch (e) {
      showMessage(
        e.toString().contains('Invalid login credentials')
            ? 'Email veya şifre hatalı'
            : 'Giriş yapılırken bir hata oluştu',
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
    return false;
  }
}

class RegisterController extends StateNotifier<RegisterState> {
  RegisterController() : super(RegisterState.initial());

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void toggleConfirmPasswordVisibility() {
    state =
        state.copyWith(obscureConfirmPassword: !state.obscureConfirmPassword);
  }

  void clearEmailError() {
    state = state.copyWith(isEmailUnique: null);
  }

  void clearPhoneError() {
    state = state.copyWith(
      isPhoneUnique: null,
      phoneError: null,
    );
  }

  void setPhoneError(String message) {
    state = state.copyWith(
      phoneError: message,
      isPhoneUnique: false,
    );
  }

  Map<String, bool> passwordRules(String password) {
    return {
      'length': password.length >= 8,
      'upperCase': password.contains(RegExp(r'[A-Z]')),
      'lowerCase': password.contains(RegExp(r'[a-z]')),
      'digit': password.contains(RegExp(r'[0-9]')),
    };
  }

  Future<bool> register({
    required String name,
    required String surname,
    required String email,
    required String password,
    required String confirmPassword,
    required PhoneNumber? phone,
    required void Function(String message, {bool success}) showMessage,
  }) async {
    if (state.isLoading) return false;

    if (phone == null) {
      setPhoneError('Telefon numarası gerekli');
      return false;
    }

    if (phone.number.startsWith('0')) {
      setPhoneError(
        'Telefon numarası 0 ile başlayamaz. Ülke kodu otomatik eklenir.',
      );
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      phoneError: null,
      isEmailUnique: null,
    );

    try {
      Validators.requireNonEmpty(name, 'Ad');
      Validators.requireNonEmpty(surname, 'Soyad');
      Validators.requireEmail(email);
      Validators.requirePassword(password);

      final rules = passwordRules(password);
      if (!rules['upperCase']! ||
          !rules['lowerCase']! ||
          !rules['digit']!) {
        throw ValidationException('Şifre gereksinimleri karşılanmıyor');
      }

      if (password != confirmPassword) {
        throw ValidationException('Şifreler eşleşmiyor');
      }

      final phoneE164 = phone.completeNumber;

      final isPhoneTaken =
          await AuthService.isPhoneNumberTaken(phoneE164);
      if (isPhoneTaken) {
        setPhoneError('Bu telefon numarası zaten kayıtlı');
        return false;
      }

      state = state.copyWith(isPhoneUnique: true);

      final response = await AuthService.signUpWithEmail(
        email: email.trim(),
        password: password,
        name: name.trim(),
        surname: surname.trim(),
        phone: phoneE164,
      );

      if (response.user == null) {
        showMessage('Kayıt olurken bir hata oluştu', success: false);
        return false;
      }

      if (!AuthService.isAuthenticated) {
        await AuthService.signInWithEmail(
          email: email.trim(),
          password: password,
        );
      }

      state = state.copyWith(isEmailUnique: null);
      showMessage('Kayıt başarılı!', success: true);
      return true;
    } on ValidationException catch (e) {
      showMessage(e.message, success: false);
    } catch (error) {
      final message = error.toString().toLowerCase();
      if (message.contains('already registered') ||
          message.contains('unique constraint')) {
        state = state.copyWith(isEmailUnique: false);
        showMessage('Bu email adresi zaten kayıtlı', success: false);
      } else if (message.contains('phone')) {
        setPhoneError('Bu telefon numarası zaten kayıtlı');
        showMessage('Bu telefon numarası zaten kayıtlı', success: false);
      } else {
        showMessage('Kayıt olurken bir hata oluştu', success: false);
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
    return false;
  }
}

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>(
  (ref) => LoginController(),
);

final registerControllerProvider =
    StateNotifierProvider<RegisterController, RegisterState>(
  (ref) => RegisterController(),
);

