import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notification_settings_provider.dart';
import '../theme/app_theme.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationSettingsProvider);
    final controller = ref.read(notificationSettingsProvider.notifier);

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
                        'Bildirimler',
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
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bildirim Türleri
                        Text(
                          'Bildirim Türleri',
                          style: AppTheme.headingSmall.copyWith(
                            color: AppTheme.darkText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildNotificationCard(
                          title: 'Randevu Hatırlatıcıları',
                          subtitle: 'Randevunuzdan önce bildirim alın',
                          icon: Icons.calendar_today,
                          value: state.appointmentReminders,
                          onChanged: controller.toggleAppointmentReminders,
                        ),
                        const SizedBox(height: 12),
                        _buildNotificationCard(
                          title: 'Randevu Güncellemeleri',
                          subtitle: 'Randevu durumu değişikliklerinde bildirim alın',
                          icon: Icons.update,
                          value: state.appointmentUpdates,
                          onChanged: controller.toggleAppointmentUpdates,
                        ),
                        const SizedBox(height: 12),
                        _buildNotificationCard(
                          title: 'Kampanyalar ve İndirimler',
                          subtitle: 'Özel teklifler ve promosyonlar hakkında bilgi alın',
                          icon: Icons.local_offer,
                          value: state.promotions,
                          onChanged: controller.togglePromotions,
                        ),
                        const SizedBox(height: 12),
                        _buildNotificationCard(
                          title: 'Haberler ve Güncellemeler',
                          subtitle: 'Uygulama güncellemeleri ve haberler',
                          icon: Icons.newspaper,
                          value: state.news,
                          onChanged: controller.toggleNews,
                        ),
                        const SizedBox(height: 32),
                        // Bildirim Ayarları
                        Text(
                          'Bildirim Ayarları',
                          style: AppTheme.headingSmall.copyWith(
                            color: AppTheme.darkText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSettingCard(
                          title: 'Ses',
                          subtitle: 'Bildirim seslerini aç/kapat',
                          icon: Icons.volume_up,
                          value: state.soundEnabled,
                          onChanged: controller.toggleSound,
                        ),
                        const SizedBox(height: 12),
                        _buildSettingCard(
                          title: 'Titreşim',
                          subtitle: 'Bildirim titreşimlerini aç/kapat',
                          icon: Icons.vibration,
                          value: state.vibrationEnabled,
                          onChanged: controller.toggleVibration,
                        ),
                        const SizedBox(height: 24),
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

  Widget _buildNotificationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
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
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.tealBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.deepCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.deepCyan, size: 24),
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
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.deepCyan,
            ),
          ],
        ),
      ),
    );
  }
}

