import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user.dart';
import '../services/json_service.dart';
import '../services/auth_service.dart';
import '../widgets/image_widget.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'account_settings_screen.dart';
import 'notifications_settings_screen.dart';
import 'language_settings_screen.dart';
import 'about_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!AuthService.isAuthenticated) {
      setState(() {
        _user = null;
        _isLoading = false;
      });
      return;
    }

    final userId = AuthService.currentUserId;
    if (userId == null) {
      setState(() {
        _user = null;
        _isLoading = false;
      });
      return;
    }
    
    final user = await JsonService.getUser(userId);
    
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Çıkış Yap', style: AppTheme.headingSmall),
        content: Text(
          'Çıkış yapmak istediğinize emin misiniz?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.grayText),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.signOut();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Çıkış yapıldı'),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
                // Ana sayfaya dön
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(
              'Çıkış Yap',
              style: AppTheme.bodyMedium.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadUserData,
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
                        if (_user != null) 
                          _buildProfileCard(_user!)
                        else if (!_isLoading && !AuthService.isAuthenticated)
                          _buildNotLoggedInCard(),
                        const SizedBox(height: 24),
                        // Menü Seçenekleri
                        _buildMenuSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(User user) {
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

  Widget _buildMenuSection() {
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
                  _loadUserData();
                }
              },
            ),
            _buildDivider(),
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
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.logout,
              title: 'Çıkış Yap',
              titleColor: Colors.red,
              onTap: _showLogoutDialog,
            ),
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

  Widget _buildNotLoggedInCard() {
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
                              _loadUserData();
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

