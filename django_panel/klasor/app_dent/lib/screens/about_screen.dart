import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _packageInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _packageInfo = packageInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
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
                        'Hakkında',
                        style: AppTheme.headingLarge.copyWith(
                          color: AppTheme.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Logo/Icon
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.accentGradient,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.tealBlue.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: AppLogo(
                                    size: 90,
                                    withBackground: false,
                                    fallbackIconColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Uygulama Adı
                              Text(
                                'Dişçi Bul',
                                style: AppTheme.headingLarge.copyWith(
                                  color: AppTheme.darkText,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Versiyon
                              if (_packageInfo != null)
                                Text(
                                  'Versiyon ${_packageInfo!.version} (${_packageInfo!.buildNumber})',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.grayText,
                                  ),
                                ),
                              const SizedBox(height: 32),
                              // Açıklama
                              Container(
                                padding: const EdgeInsets.all(20),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hakkında',
                                      style: AppTheme.headingSmall.copyWith(
                                        color: AppTheme.darkText,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Dişçi Bul, diş hekimi randevu yönetimi için geliştirilmiş modern bir mobil uygulamadır. '
                                      'Hastalar kolayca randevu oluşturabilir, doktor ve klinik bilgilerine erişebilir, '
                                      'randevularını yönetebilir ve değerlendirmeler yapabilir.',
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: AppTheme.grayText,
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Bilgiler
                              _buildInfoCard(
                                icon: Icons.email,
                                title: 'E-posta',
                                subtitle: 'info@bumel.com.tr',
                                onTap: () {
                                  // TODO: E-posta açma
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildInfoCard(
                                icon: Icons.phone,
                                title: 'Telefon',
                                subtitle: '+90 (537) 224 71 06',
                                onTap: () {
                                  // TODO: Telefon arama
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildInfoCard(
                                icon: Icons.language,
                                title: 'Web Sitesi',
                                subtitle: 'bumel.com.tr',
                                onTap: () {
                                  // TODO: Web sitesi açma
                                },
                              ),
                              const SizedBox(height: 32),
                              // Telif Hakkı
                              Text(
                                '© 2025 Dişçi Bul. Tüm hakları saklıdır.',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.grayText,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.grayText,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
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

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.tealBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppTheme.tealBlue, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.grayText,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppTheme.iconGray),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
