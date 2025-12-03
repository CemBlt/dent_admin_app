import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../providers/account_settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/image_widget.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState
    extends ConsumerState<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges(AccountSettingsController controller) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final state = ref.read(accountSettingsControllerProvider);
    if (state.user == null) return;

    final result = await controller.saveProfile(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? AppTheme.successGreen : Colors.red,
      ),
    );

    if (result.success) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountSettingsControllerProvider);
    final controller = ref.read(accountSettingsControllerProvider.notifier);

    _syncControllers(state.user);

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
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.user == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: AppTheme.iconGray),
                          const SizedBox(height: 16),
                          Text(
                            'Kullanıcı bilgileri yüklenemedi',
                            style: AppTheme.bodyMedium.copyWith(color: AppTheme.grayText),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                            decoration: BoxDecoration(
                              gradient: AppTheme.accentGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.tealBlue.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Hesap Bilgileri',
                                    style: AppTheme.headingLarge.copyWith(
                                      color: AppTheme.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Profil Fotoğrafı
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppTheme.lightTurquoise,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.tealBlue,
                                width: 3,
                              ),
                            ),
                            child: state.user!.profileImage != null
                                ? ClipOval(
                                    child: buildImage(
                                      state.user!.profileImage!,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                      errorWidget: Icon(
                                        Icons.person,
                                        size: 60,
                                        color: AppTheme.tealBlue,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 60,
                                    color: AppTheme.tealBlue,
                                  ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              // TODO: Profil fotoğrafı değiştirme
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Profil fotoğrafı değiştirme yakında eklenecek')),
                              );
                            },
                            child: Text(
                              'Fotoğrafı Değiştir',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.tealBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Form
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Ad Soyad
                                  _buildTextField(
                                    controller: _nameController,
                                    label: 'Ad Soyad',
                                    icon: Icons.person_outline,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Ad soyad gereklidir';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  // Email
                                  _buildTextField(
                                    controller: _emailController,
                                    label: 'E-posta',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    readOnly: true,
                                    helperText:
                                        'Giriş e-posta adresiniz Supabase Auth tarafından yönetilir ve bu ekrandan değiştirilemez.',
                                    validator: (_) => null,
                                  ),
                                  const SizedBox(height: 20),
                                  // Telefon
                                  _buildTextField(
                                    controller: _phoneController,
                                    label: 'Telefon',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Telefon numarası gereklidir';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 32),
                                  // Kaydet Butonu
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppTheme.tealBlue, AppTheme.deepCyan],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: state.isSaving
                                            ? null
                                            : () => _saveChanges(controller),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          child: state.isSaving
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                )
                                              : Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(Icons.check, color: AppTheme.white, size: 20),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Değişiklikleri Kaydet',
                                                      style: AppTheme.bodyMedium.copyWith(
                                                        color: AppTheme.white,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    String? helperText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        validator: validator,
        style: AppTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTheme.bodySmall.copyWith(color: AppTheme.grayText),
          prefixIcon: Icon(icon, color: AppTheme.tealBlue),
          helperText: helperText,
          helperStyle: AppTheme.bodySmall.copyWith(
            color: AppTheme.grayText,
            height: 1.3,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppTheme.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  void _syncControllers(User? user) {
    if (user == null) return;
    final fullName = user.fullName;
    if (_nameController.text != fullName) {
      _nameController.text = fullName;
    }
    if (_emailController.text != user.email) {
      _emailController.text = user.email;
    }
    if (_phoneController.text != user.phone) {
      _phoneController.text = user.phone;
    }
  }
}

