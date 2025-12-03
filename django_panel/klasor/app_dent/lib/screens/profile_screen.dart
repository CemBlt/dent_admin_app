import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../providers/profile_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/image_widget.dart';
import 'about_screen.dart';
import 'account_settings_screen.dart';
import 'language_settings_screen.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'notifications_settings_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _showLogoutDialog(ProfileController controller) {
    final state = ref.read(profileControllerProvider);
    if (!state.isAuthenticated) return;

    bool isLoggingOut = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Dialog dışına tıklayınca kapanmasın
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Çıkış Yap', style: AppTheme.headingSmall),
          content: Text(
            'Çıkış yapmak istediğinize emin misiniz?',
            style: AppTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: isLoggingOut
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: Text(
                'İptal',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.grayText),
              ),
            ),
            TextButton(
              onPressed: isLoggingOut
                  ? null
                  : () async {
                      // Çift tıklamayı önle
                      setState(() {
                        isLoggingOut = true;
                      });
                      
                      final result = await controller.logout();
                        
                      Navigator.pop(dialogContext);
                        
                      if (!mounted) return;
                        
                      if (result.success) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const MainScreen()),
                          (route) => false,
                        );
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result.message),
                            backgroundColor:
                                result.success ? AppTheme.successGreen : Colors.red,
                          ),
                        );
                      }
                    },
              child: isLoggingOut
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    )
                  : Text(
                      'Çıkış Yap',
                      style: AppTheme.bodyMedium.copyWith(color: Colors.red),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final controller = ref.read(profileControllerProvider.notifier);

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
              : RefreshIndicator(
                  onRefresh: controller.refreshProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Profil',
                                  style: AppTheme.headingLarge.copyWith(
                                    color: AppTheme.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Profil Bilgileri Kartı
                        if (state.user != null)
                          _buildProfileCard(state.user!, controller)
                        else if (!state.isAuthenticated)
                          _buildNotLoggedInCard(controller),
                        const SizedBox(height: 24),
                        // Menü Seçenekleri
                        _buildMenuSection(state, controller),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(User user, ProfileController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Profil Fotoğrafı
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.lightTurquoise,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.tealBlue,
                    width: 3,
                  ),
                ),
                child: user.profileImage != null
                    ? ClipOval(
                        child: buildImage(
                          user.profileImage!,
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                          errorWidget: Icon(
                            Icons.person,
                            size: 50,
                            color: AppTheme.tealBlue,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 50,
                        color: AppTheme.tealBlue,
                      ),
              ),
              const SizedBox(height: 16),
              // Ad Soyad
              Text(
                user.fullName,
                style: AppTheme.headingMedium,
              ),
              const SizedBox(height: 8),
              // Email
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email, size: 16, color: AppTheme.iconGray),
                  const SizedBox(width: 8),
                  Text(
                    user.email,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.grayText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Telefon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone, size: 16, color: AppTheme.iconGray),
                  const SizedBox(width: 8),
                  Text(
                    user.phone,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.grayText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Düzenle Butonu
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
                    onTap: () {
                      // Profil düzenleme sayfasına yönlendirme
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit, color: AppTheme.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Profili Düzenle',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(
    ProfileState state,
    ProfileController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Hesap Bilgileri - Sadece giriş yapmış kullanıcılar için
            if (state.isAuthenticated && state.user != null) ...[
              _buildMenuItem(
                icon: Icons.person_outline,
                title: 'Hesap Bilgileri',
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountSettingsScreen(),
                    ),
                  );
                  if (result == true) {
                    controller.loadProfile();
                  }
                },
              ),
              _buildDivider(),
            ],
            _buildMenuItem(
              icon: Icons.notifications_outlined,
              title: 'Bildirimler',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsSettingsScreen(),
                  ),
                );
              },
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.language,
              title: 'Dil Ayarları',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LanguageSettingsScreen(),
                  ),
                );
              },
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.info_outline,
              title: 'Hakkında',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutScreen(),
                  ),
                );
              },
            ),
            // Çıkış Yap - Sadece giriş yapmış kullanıcılar için
            if (state.isAuthenticated && state.user != null) ...[
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.logout,
                title: 'Çıkış Yap',
                titleColor: Colors.red,
                onTap: () => _showLogoutDialog(controller),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: titleColor ?? AppTheme.tealBlue,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.bodyMedium.copyWith(
                    color: titleColor ?? AppTheme.darkText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.iconGray,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppTheme.dividerLight,
      indent: 60,
    );
  }

  Widget _buildNotLoggedInCard(ProfileController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.person_outline,
                size: 64,
                color: AppTheme.iconGray,
              ),
              const SizedBox(height: 16),
              Text(
                'Giriş Yapın',
                style: AppTheme.headingMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Randevu oluşturmak ve randevularınızı görmek için giriş yapın',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.grayText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(
                            onLoginSuccess: () {
                              Navigator.pop(context);
                              controller.loadProfile();
                            },
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.login, color: AppTheme.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Giriş Yap',
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
            ],
          ),
        ),
      ),
    );
  }
}

