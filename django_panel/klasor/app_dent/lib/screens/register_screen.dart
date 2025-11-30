import 'package:flutter/material.dart';
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
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isCheckingPhone = false;
  bool? _phoneIsUnique; // null = kontrol edilmedi, true = unique, false = alınmış
  bool _isCheckingEmail = false;
  bool? _emailIsUnique; // null = kontrol edilmedi, true = unique, false = alınmış

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
      final phone = _phoneController.text.trim();
      final isPhoneTaken = await AuthService.isPhoneNumberTaken(phone);
      
      if (isPhoneTaken) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bu telefon numarası zaten kayıtlı'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Email kontrolü (email girilmişse)
      final email = _emailController.text.trim();
      if (email.isNotEmpty) {
        final isEmailTaken = await AuthService.isEmailTaken(email);
        
        if (isEmailTaken) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Bu email adresi zaten kayıtlı'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      final response = await AuthService.signUp(
        email: email.isEmpty ? null : email,
        password: _passwordController.text,
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
        phone: phone,
      );

      if (response.user != null) {
        // Kayıt başarılı olduğunda, kullanıcının otomatik giriş yapıp yapmadığını kontrol et
        if (!AuthService.isAuthenticated) {
          // Otomatik giriş yapılmamışsa, email ve şifre ile giriş yap
          try {
            // Email boşsa, geçici email ile giriş yap
            final loginEmail = email.isEmpty
                ? 'phone_${phone.replaceAll(RegExp(r'[^0-9]'), '')}@temp.dentapp.com'
                : email;
            
            await AuthService.signInWithEmail(
              email: loginEmail,
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
              content: Text('Kayıt başarılı! Hoş geldiniz.'),
              backgroundColor: AppTheme.successGreen,
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
      if (mounted) {
        String errorMessage = 'Kayıt olurken bir hata oluştu';
        
        if (e.toString().contains('User already registered') || 
            e.toString().contains('already registered')) {
          errorMessage = 'Bu bilgilerle zaten bir kayıt mevcut';
        } else if (e.toString().contains('phone') && e.toString().contains('unique')) {
          errorMessage = 'Bu telefon numarası zaten kayıtlı';
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

  Future<void> _checkPhoneNumber(String phone) async {
    if (phone.trim().isEmpty) {
      setState(() {
        _phoneIsUnique = null;
      });
      return;
    }

    // Telefon formatı kontrolü
    final phoneRegex = RegExp(r'^[0-9\s\+\-\(\)]{10,}$');
    if (!phoneRegex.hasMatch(phone.replaceAll(' ', ''))) {
      setState(() {
        _phoneIsUnique = null;
      });
      return;
    }

    setState(() {
      _isCheckingPhone = true;
      _phoneIsUnique = null;
    });

    try {
      final isTaken = await AuthService.isPhoneNumberTaken(phone);
      if (mounted) {
        setState(() {
          _phoneIsUnique = !isTaken;
        });
        if (isTaken) {
          _formKey.currentState?.validate();
        }
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
      if (mounted) {
        setState(() {
          _phoneIsUnique = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingPhone = false;
        });
      }
    }
  }

  Future<void> _checkEmail(String email) async {
    final trimmedEmail = email.trim();
    
    // Email boşsa veya geçersizse kontrol yapma
    if (trimmedEmail.isEmpty) {
      setState(() {
        _emailIsUnique = null;
      });
      return;
    }

    // Email formatı kontrolü
    if (!trimmedEmail.contains('@') || !trimmedEmail.contains('.')) {
      setState(() {
        _emailIsUnique = null;
      });
      return;
    }

    setState(() {
      _isCheckingEmail = true;
      _emailIsUnique = null;
    });

    try {
      final isTaken = await AuthService.isEmailTaken(trimmedEmail);
      if (mounted) {
        setState(() {
          _emailIsUnique = !isTaken;
        });
        if (isTaken) {
          _formKey.currentState?.validate();
        }
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
      if (mounted) {
        setState(() {
          _emailIsUnique = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingEmail = false;
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
                        // Phone input (ZORUNLU)
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Telefon Numarası *',
                            hintText: '05XX XXX XX XX',
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: AppTheme.cardGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.phone_rounded, color: AppTheme.tealBlue, size: 20),
                            ),
                            suffixIcon: _isCheckingPhone
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.tealBlue),
                                      ),
                                    ),
                                  )
                                : _phoneIsUnique == null
                                    ? null
                                    : Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Icon(
                                          _phoneIsUnique == true
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          color: _phoneIsUnique == true
                                              ? AppTheme.successGreen
                                              : Colors.red,
                                          size: 20,
                                        ),
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
                          onChanged: (value) {
                            setState(() {
                              // Telefon numarası değiştiğinde state'i sıfırla
                              if (value.trim().isEmpty) {
                                _phoneIsUnique = null;
                              }
                            });
                            // Telefon numarası değiştiğinde kontrol et (debounce için)
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (mounted && _phoneController.text == value) {
                                _checkPhoneNumber(value);
                              }
                            });
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Telefon numarası gerekli';
                            }
                            // Basit telefon formatı kontrolü
                            final phoneRegex = RegExp(r'^[0-9\s\+\-\(\)]{10,}$');
                            if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
                              return 'Geçerli bir telefon numarası giriniz';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        // Email input (OPSİYONEL)
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (value) {
                            setState(() {
                              // Email değiştiğinde state'i sıfırla
                              if (value.trim().isEmpty) {
                                _emailIsUnique = null;
                              }
                            });
                            // Email değiştiğinde kontrol et (debounce için)
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (mounted && _emailController.text == value) {
                                _checkEmail(value);
                              }
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Email (Opsiyonel)',
                            hintText: 'ornek@email.com',
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: AppTheme.cardGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.email_rounded, color: AppTheme.tealBlue, size: 20),
                            ),
                            suffixIcon: _isCheckingEmail
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.tealBlue),
                                      ),
                                    ),
                                  )
                                : _emailIsUnique == null
                                    ? null
                                    : Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Icon(
                                          _emailIsUnique == true
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          color: _emailIsUnique == true
                                              ? AppTheme.successGreen
                                              : Colors.red,
                                          size: 20,
                                        ),
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
                            // Email opsiyonel, ama girilmişse geçerli olmalı
                            if (value != null && value.trim().isNotEmpty) {
                              if (!value.contains('@') || !value.contains('.')) {
                                return 'Geçerli bir email adresi giriniz';
                              }
                              // Email unique kontrolü
                              if (_emailIsUnique == false) {
                                return 'Bu email adresi zaten kayıtlı';
                              }
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
