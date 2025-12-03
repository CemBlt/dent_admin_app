import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final VoidCallback? onRegisterSuccess;
  
  const RegisterScreen({
    super.key,
    this.onRegisterSuccess,
  });

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  PhoneNumber? _phoneNumber;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister(RegisterController controller) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await controller.register(
      name: _nameController.text,
      surname: _surnameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      phone: _phoneNumber,
      showMessage: (message, {bool success = false}) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: success ? AppTheme.successGreen : Colors.red,
          ),
        );
      },
    );

    if (success && mounted) {
      if (widget.onRegisterSuccess != null) {
        widget.onRegisterSuccess!();
      } else {
        Navigator.pop(context, true);
      }
    }
  }


  /// Şifre kurallarını kontrol eder
  Map<String, bool> _checkPasswordRules(String password) {
    return {
      'length': password.length >= 8,
      'upperCase': password.contains(RegExp(r'[A-Z]')),
      'lowerCase': password.contains(RegExp(r'[a-z]')),
      'digit': password.contains(RegExp(r'[0-9]')),
    };
  }

  /// Şifre kuralları widget'ı
  Widget _buildPasswordStrengthMeter(Map<String, bool> rules) {
    if (_passwordController.text.isEmpty) return const SizedBox.shrink();

    // Tüm kurallar sağlandı mı?
    final allRulesMet = (rules['length'] ?? false) &&
                        (rules['upperCase'] ?? false) &&
                        (rules['lowerCase'] ?? false) &&
                        (rules['digit'] ?? false);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Tüm kurallar sağlandıysa sadece "Güvenli şifre" göster
        if (allRulesMet)
          Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 16,
                color: AppTheme.successGreen,
              ),
              const SizedBox(width: 4),
              Text(
                'Güvenli şifre',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.successGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        else
          // Kurallar listesi
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _buildRuleItem('En az 8 karakter', rules['length'] ?? false),
              _buildRuleItem('1 büyük harf', rules['upperCase'] ?? false),
              _buildRuleItem('1 küçük harf', rules['lowerCase'] ?? false),
              _buildRuleItem('1 rakam', rules['digit'] ?? false),
            ],
          ),
      ],
    );
  }

  Widget _buildRuleItem(String text, bool isValid) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.cancel,
          size: 16,
          color: isValid ? AppTheme.successGreen : Colors.red,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTheme.bodySmall.copyWith(
            color: isValid ? AppTheme.successGreen : Colors.red,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerControllerProvider);
    final controller = ref.read(registerControllerProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundLight,
              AppTheme.lightTurquoise.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_rounded, color: AppTheme.tealBlue),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Title Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.tealBlue.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.person_add_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Kayıt Ol',
                          style: AppTheme.headingLarge.copyWith(
                            color: AppTheme.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Yeni hesap oluşturun',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.tealBlue.withOpacity(0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Name input
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Ad *',
                            hintText: 'Adınızı giriniz',
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: AppTheme.cardGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.person_rounded, color: AppTheme.tealBlue, size: 20),
                            ),
                            filled: true,
                            fillColor: AppTheme.inputFieldGray,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppTheme.tealBlue, width: 2),
                            ),
                          ),
                          style: AppTheme.bodyMedium,
                          validator: (value) {
                            try {
                              Validators.requireNonEmpty(value, 'Ad');
                              return null;
                            } on ValidationException catch (e) {
                              return e.message;
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        // Surname input
                        TextFormField(
                          controller: _surnameController,
                          decoration: InputDecoration(
                            labelText: 'Soyad *',
                            hintText: 'Soyadınızı giriniz',
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: AppTheme.cardGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.person_rounded, color: AppTheme.tealBlue, size: 20),
                            ),
                            filled: true,
                            fillColor: AppTheme.inputFieldGray,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppTheme.tealBlue, width: 2),
                            ),
                          ),
                          style: AppTheme.bodyMedium,
                          validator: (value) {
                            try {
                              Validators.requireNonEmpty(value, 'Soyad');
                              return null;
                            } on ValidationException catch (e) {
                              return e.message;
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        // Phone input (ZORUNLU - Country Picker ile)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IntlPhoneField(
                              decoration: InputDecoration(
                                labelText: 'Telefon Numarası *',
                                hintText: '532 123 45 67',
                                filled: true,
                                fillColor: AppTheme.inputFieldGray,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppTheme.tealBlue, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.red, width: 2),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.red, width: 2),
                                ),
                                errorText: state.phoneError,
                                // suffixIcon yok - kontrol sadece kayıt butonuna basıldığında yapılacak
                              ),
                              initialCountryCode: 'TR', // Türkiye varsayılan
                              onChanged: (phone) {
                                setState(() {
                                  _phoneNumber = phone;
                                });
                                controller.clearPhoneError();
                              },
                              validator: (phone) {
                                final completeNumber = phone?.completeNumber;
                                try {
                                  Validators.requirePhone(completeNumber);
                                } on ValidationException catch (e) {
                                  return e.message;
                                }

                                if (phone == null) {
                                  return 'Telefon numarası gerekli';
                                }

                                // "0" ile başlayan numaraları reddet
                                if (phone.number.startsWith('0')) {
                                  return 'Telefon numarası 0 ile başlayamaz. Ülke kodu otomatik eklenir.';
                                }

                                // E.164 format kontrolü
                                if (!phone.completeNumber.startsWith('+')) {
                                  return 'Ülke kodu gerekli';
                                }

                        if (state.phoneError != null) {
                          return state.phoneError;
                        }

                                return null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Email input (ZORUNLU)
                            TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (value) {
                            controller.clearEmailError();
                          },
                          decoration: InputDecoration(
                            labelText: 'Email *',
                            hintText: 'ornek@email.com',
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: AppTheme.cardGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.email_rounded, color: AppTheme.tealBlue, size: 20),
                            ),
                            // suffixIcon yok - kontrol sadece kayıt butonuna basıldığında yapılacak
                            filled: true,
                            fillColor: AppTheme.inputFieldGray,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppTheme.tealBlue, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                          ),
                          style: AppTheme.bodyMedium,
                          validator: (value) {
                            try {
                              Validators.requireEmail(value);
                            } on ValidationException catch (e) {
                              return e.message;
                            }

                            if (state.isEmailUnique == false) {
                              return 'Bu email adresi zaten kayıtlı';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        // Password input
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _passwordController,
                              obscureText: state.obscurePassword,
                              onChanged: (value) {
                                setState(() {
                                  // Sadece state'i güncelle, güç hesaplaması yok
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Şifre *',
                                hintText: 'En az 8 karakter',
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.cardGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.lock_rounded, color: AppTheme.tealBlue, size: 20),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    state.obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppTheme.iconGray,
                                  ),
                                  onPressed: () {
                                    controller.togglePasswordVisibility();
                                  },
                                ),
                                filled: true,
                                fillColor: AppTheme.inputFieldGray,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppTheme.tealBlue, width: 2),
                                ),
                              ),
                              style: AppTheme.bodyMedium,
                              validator: (value) {
                                try {
                                  Validators.requirePassword(value);
                                } on ValidationException catch (e) {
                                  return e.message;
                                }
                                final rules = _checkPasswordRules(value ?? '');
                                if (!rules['upperCase']!) {
                                  return 'Şifre en az 1 büyük harf içermelidir';
                                }
                                if (!rules['lowerCase']!) {
                                  return 'Şifre en az 1 küçük harf içermelidir';
                                }
                                if (!rules['digit']!) {
                                  return 'Şifre en az 1 rakam içermelidir';
                                }
                                return null;
                              },
                            ),
                            _buildPasswordStrengthMeter(
                              controller.passwordRules(_passwordController.text),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Confirm password input
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: state.obscureConfirmPassword,
                          onChanged: (value) {
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            labelText: 'Şifre Tekrar *',
                            hintText: 'Şifrenizi tekrar giriniz',
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: AppTheme.cardGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.lock_rounded, color: AppTheme.tealBlue, size: 20),
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_confirmPasswordController.text.isNotEmpty &&
                                    _passwordController.text.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Icon(
                                      _confirmPasswordController.text == _passwordController.text
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: _confirmPasswordController.text == _passwordController.text
                                          ? AppTheme.successGreen
                                          : Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                IconButton(
                                  icon: Icon(
                                    state.obscureConfirmPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppTheme.iconGray,
                                  ),
                                  onPressed: () {
                                    controller.toggleConfirmPasswordVisibility();
                                  },
                                ),
                              ],
                            ),
                            filled: true,
                            fillColor: AppTheme.inputFieldGray,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppTheme.tealBlue, width: 2),
                            ),
                          ),
                          style: AppTheme.bodyMedium,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Şifre tekrarı gerekli';
                            }
                            if (value != _passwordController.text) {
                              return 'Şifreler eşleşmiyor';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        // Register button
                        Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.accentGradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.tealBlue.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: state.isLoading
                                  ? null
                                  : () => _handleRegister(controller),
                              borderRadius: BorderRadius.circular(18),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (state.isLoading)
                                      const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    else ...[
                                      const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Kayıt Ol',
                                        style: AppTheme.bodyMedium.copyWith(
                                          color: AppTheme.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
