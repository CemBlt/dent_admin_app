import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _appointmentReminders = true;
  bool _appointmentUpdates = true;
  bool _promotions = false;
  bool _news = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appointmentReminders = prefs.getBool('notif_appointment_reminders') ?? true;
      _appointmentUpdates = prefs.getBool('notif_appointment_updates') ?? true;
      _promotions = prefs.getBool('notif_promotions') ?? false;
      _news = prefs.getBool('notif_news') ?? false;
      _soundEnabled = prefs.getBool('notif_sound') ?? true;
      _vibrationEnabled = prefs.getBool('notif_vibration') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
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
                          value: _appointmentReminders,
                          onChanged: (value) {
                            setState(() {
                              _appointmentReminders = value;
                            });
                            _saveSetting('notif_appointment_reminders', value);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildNotificationCard(
                          title: 'Randevu Güncellemeleri',
                          subtitle: 'Randevu durumu değişikliklerinde bildirim alın',
                          icon: Icons.update,
                          value: _appointmentUpdates,
                          onChanged: (value) {
                            setState(() {
                              _appointmentUpdates = value;
                            });
                            _saveSetting('notif_appointment_updates', value);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildNotificationCard(
                          title: 'Kampanyalar ve İndirimler',
                          subtitle: 'Özel teklifler ve promosyonlar hakkında bilgi alın',
                          icon: Icons.local_offer,
                          value: _promotions,
                          onChanged: (value) {
                            setState(() {
                              _promotions = value;
                            });
                            _saveSetting('notif_promotions', value);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildNotificationCard(
                          title: 'Haberler ve Güncellemeler',
                          subtitle: 'Uygulama güncellemeleri ve haberler',
                          icon: Icons.newspaper,
                          value: _news,
                          onChanged: (value) {
                            setState(() {
                              _news = value;
                            });
                            _saveSetting('notif_news', value);
                          },
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
                          value: _soundEnabled,
                          onChanged: (value) {
                            setState(() {
                              _soundEnabled = value;
                            });
                            _saveSetting('notif_sound', value);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildSettingCard(
                          title: 'Titreşim',
                          subtitle: 'Bildirim titreşimlerini aç/kapat',
                          icon: Icons.vibration,
                          value: _vibrationEnabled,
                          onChanged: (value) {
                            setState(() {
                              _vibrationEnabled = value;
                            });
                            _saveSetting('notif_vibration', value);
                          },
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

