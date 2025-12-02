import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback? onRegisterSuccess;
  
  const RegisterScreen({
    super.key,
    this.onRegisterSuccess,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool? _phoneIsUnique; // null = kontrol edilmedi, true = unique, false = alınmış
  bool? _emailIsUnique; // null = kontrol edilmedi, true = unique, false = alınmış
  PhoneNumber? _phoneNumber; // Country picker'dan gelen telefon numarası
  String? _phoneNumberError; // Telefon numarası hata mesajı

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Telefon numarası kontrolü
      if (_phoneNumber == null) {
        setState(() {
          _phoneNumberError = 'Telefon numarası gerekli';
          _isLoading = false;
        });
        return;
      }

      // E.164 formatında telefon numarası (boşluksuz)
      final phoneE164 = _phoneNumber!.completeNumber; // +905321234567 formatında
      
      // "0" ile başlayan numaraları kontrol et
      final localNumber = _phoneNumber!.number;
      if (localNumber.startsWith('0')) {
        setState(() {
          _phoneNumberError = 'Telefon numarası 0 ile başlayamaz. Ülke kodu kullanın (+90 gibi)';
          _isLoading = false;
        });
        return;
      }

      final isPhoneTaken = await AuthService.isPhoneNumberTaken(phoneE164);
      
      if (isPhoneTaken) {
        setState(() {
          _phoneIsUnique = false;
          _phoneNumberError = 'Bu telefon numarası zaten kayıtlı';
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.cancel, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text('Bu telefon numarası zaten kayıtlı'),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          // Form validasyonunu tetikle
          _formKey.currentState?.validate();
        }
        return;
      }
      
      // Telefon numarası unique
      setState(() {
        _phoneIsUnique = true;
        _phoneNumberError = null;
      });

      // Email kontrolü (email artık zorunlu)
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Email adresi gerekli'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Email format kontrolü
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(email)) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Geçerli bir email adresi giriniz'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Email kontrolü (kayıt öncesi)
      final isEmailTaken = await AuthService.isEmailTaken(email);
      if (isEmailTaken) {
        setState(() {
          _emailIsUnique = false;
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.cancel, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text('Bu email adresi zaten kayıtlı'),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          // Form validasyonunu tetikle
          _formKey.currentState?.validate();
        }
        return;
      }

      // Kayıt işlemini dene
      AuthResponse? response;
      try {
        response = await AuthService.signUp(
          email: email,
          password: _passwordController.text,
          name: _nameController.text.trim(),
          surname: _surnameController.text.trim(),
          phone: phoneE164, // E.164 formatında kaydet
        );
      } catch (signUpError) {
        // Kayıt hatası - email zaten kayıtlı olabilir
        final errorString = signUpError.toString().toLowerCase();
        
        // Email zaten kayıtlı hatası
        if (errorString.contains('user already registered') || 
            errorString.contains('already registered') ||
            errorString.contains('email already registered') ||
            errorString.contains('email address is already registered') ||
            errorString.contains('user with this email already exists') ||
            errorString.contains('email already exists') ||
            errorString.contains('duplicate key value') ||
            errorString.contains('unique constraint')) {
          setState(() {
            _emailIsUnique = false;
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.cancel, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text('Bu email adresi zaten kayıtlı'),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
            // Form validasyonunu tetikle
            _formKey.currentState?.validate();
          }
          return;
        }
        
        // Diğer hatalar için genel hata mesajı göster
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kayıt olurken bir hata oluştu: ${signUpError.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      if (response != null && response.user != null) {
        // Email kontrolünü sıfırla (kayıt başarılı)
        setState(() {
          _emailIsUnique = null;
        });
        
        // Kayıt başarılı olduğunda, kullanıcının otomatik giriş yapıp yapmadığını kontrol et
        if (!AuthService.isAuthenticated) {
          // Otomatik giriş yapılmamışsa, email ve şifre ile giriş yap
          try {
            await AuthService.signInWithEmail(
              email: email,
              password: _passwordController.text,
            );
          } catch (e) {
            // Giriş yapılamazsa, kullanıcıya bilgi ver
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Kayıt başarılı! Lütfen giriş yapın.'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            }
            if (mounted) {
              Navigator.pop(context, false);
            }
            return;
          }
        }
        
        // Kullanıcı giriş yapmış durumda
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text('Kayıt başarılı!'),
                ],
              ),
              backgroundColor: AppTheme.successGreen,
              duration: const Duration(seconds: 3),
            ),
          );
          
          if (widget.onRegisterSuccess != null) {
            widget.onRegisterSuccess!();
          } else {
            Navigator.pop(context, true);
          }
        }
      }
    } catch (e) {
      // Bu catch bloğu sadece beklenmeyen hatalar için (signUp zaten kendi try-catch'inde)
      if (mounted) {
        String errorMessage = 'Kayıt olurken bir hata oluştu';
        final errorString = e.toString().toLowerCase();
        
        // Telefon numarası zaten kayıtlı hatası
        if (errorString.contains('phone') && errorString.contains('unique')) {
          errorMessage = 'Bu telefon numarası zaten kayıtlı';
          setState(() {
            _phoneIsUnique = false;
            _phoneNumberError = 'Bu telefon numarası zaten kayıtlı';
          });
          // Form validasyonunu tetikle
          _formKey.currentState?.validate();
        }
        // Diğer hatalar
        else if (errorString.contains('invalid email')) {
          errorMessage = 'Geçerli bir email adresi giriniz';
        } else if (errorString.contains('password')) {
          errorMessage = 'Şifre gereksinimlerini karşılamıyor';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  /// Şifre kurallarını kontrol eder
  Map<String, bool> _checkPasswordRules(String password) {
    return {
      'length': password.length >= 6,
      'upperCase': password.contains(RegExp(r'[A-Z]')),
      'lowerCase': password.contains(RegExp(r'[a-z]')),
      'digit': password.contains(RegExp(r'[0-9]')),
    };
  }

  /// Şifre kuralları widget'ı
  Widget _buildPasswordStrengthMeter(String password) {
    if (password.isEmpty) return const SizedBox.shrink();
    
    final rules = _checkPasswordRules(password);
    
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
              _buildRuleItem('En az 6 karakter', rules['length'] ?? false),
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
                            if (value == null || value.trim().isEmpty) {
                              return 'Ad gerekli';
                            }
                            return null;
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
                            if (value == null || value.trim().isEmpty) {
                              return 'Soyad gerekli';
                            }
                            return null;
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
                                errorText: _phoneNumberError,
                                // suffixIcon yok - kontrol sadece kayıt butonuna basıldığında yapılacak
                              ),
                              initialCountryCode: 'TR', // Türkiye varsayılan
                              onChanged: (phone) {
                                setState(() {
                                  _phoneNumber = phone;
                                  _phoneNumberError = null;
                                  _phoneIsUnique = null;
                                  
                                  // "0" ile başlayan numaraları kontrol et
                                  if (phone.number.startsWith('0')) {
                                    _phoneNumberError = 'Telefon numarası 0 ile başlayamaz. Ülke kodu otomatik eklenir.';
                                  }
                                });
                                // Real-time kontrol yok, sadece kayıt butonuna basıldığında kontrol edilecek
                              },
                              validator: (phone) {
                                if (phone == null || phone.completeNumber.isEmpty) {
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
                                
                                if (_phoneNumberError != null) {
                                  return _phoneNumberError;
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
                            // Email değiştiğinde önceki hata durumunu temizle
                            setState(() {
                              _emailIsUnique = null;
                            });
                            // Real-time kontrol yok, sadece kayıt butonuna basıldığında kontrol edilecek
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
                            // Email artık zorunlu
                            if (value == null || value.trim().isEmpty) {
                              return 'Email adresi gerekli';
                            }
                            
                            // Email format kontrolü
                            final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                            if (!emailRegex.hasMatch(value.trim())) {
                              return 'Geçerli bir email adresi giriniz';
                            }
                            
                            // Email unique kontrolü (real-time kontrol sonucu)
                            if (_emailIsUnique == false) {
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
                              obscureText: _obscurePassword,
                              onChanged: (value) {
                                setState(() {
                                  // Sadece state'i güncelle, güç hesaplaması yok
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Şifre *',
                                hintText: 'En az 6 karakter',
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
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: AppTheme.iconGray,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
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
                                if (value == null || value.isEmpty) {
                                  return 'Şifre gerekli';
                                }
                                if (value.length < 6) {
                                  return 'Şifre en az 6 karakter olmalıdır';
                                }
                                final rules = _checkPasswordRules(value);
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
                            _buildPasswordStrengthMeter(_passwordController.text),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Confirm password input
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
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
                                    _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: AppTheme.iconGray,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
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
                              onTap: _isLoading ? null : _handleRegister,
                              borderRadius: BorderRadius.circular(18),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_isLoading)
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
