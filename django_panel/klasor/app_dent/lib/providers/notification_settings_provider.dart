import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsState {
  final bool isLoading;
  final bool appointmentReminders;
  final bool appointmentUpdates;
  final bool promotions;
  final bool news;
  final bool soundEnabled;
  final bool vibrationEnabled;

  const NotificationSettingsState({
    required this.isLoading,
    required this.appointmentReminders,
    required this.appointmentUpdates,
    required this.promotions,
    required this.news,
    required this.soundEnabled,
    required this.vibrationEnabled,
  });

  factory NotificationSettingsState.initial() =>
      const NotificationSettingsState(
        isLoading: true,
        appointmentReminders: true,
        appointmentUpdates: true,
        promotions: false,
        news: false,
        soundEnabled: true,
        vibrationEnabled: true,
      );

  NotificationSettingsState copyWith({
    bool? isLoading,
    bool? appointmentReminders,
    bool? appointmentUpdates,
    bool? promotions,
    bool? news,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return NotificationSettingsState(
      isLoading: isLoading ?? this.isLoading,
      appointmentReminders: appointmentReminders ?? this.appointmentReminders,
      appointmentUpdates: appointmentUpdates ?? this.appointmentUpdates,
      promotions: promotions ?? this.promotions,
      news: news ?? this.news,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
}

class NotificationSettingsController
    extends StateNotifier<NotificationSettingsState> {
  NotificationSettingsController()
      : super(NotificationSettingsState.initial()) {
    _loadSettings();
  }

  SharedPreferences? _prefs;

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadSettings() async {
    await _ensurePrefs();
    state = state.copyWith(
      isLoading: false,
      appointmentReminders:
          _prefs?.getBool('notif_appointment_reminders') ?? true,
      appointmentUpdates:
          _prefs?.getBool('notif_appointment_updates') ?? true,
      promotions: _prefs?.getBool('notif_promotions') ?? false,
      news: _prefs?.getBool('notif_news') ?? false,
      soundEnabled: _prefs?.getBool('notif_sound') ?? true,
      vibrationEnabled: _prefs?.getBool('notif_vibration') ?? true,
    );
  }

  Future<void> _updateSetting(String key, bool value) async {
    await _ensurePrefs();
    await _prefs?.setBool(key, value);
  }

  void toggleAppointmentReminders(bool value) {
    state = state.copyWith(appointmentReminders: value);
    _updateSetting('notif_appointment_reminders', value);
  }

  void toggleAppointmentUpdates(bool value) {
    state = state.copyWith(appointmentUpdates: value);
    _updateSetting('notif_appointment_updates', value);
  }

  void togglePromotions(bool value) {
    state = state.copyWith(promotions: value);
    _updateSetting('notif_promotions', value);
  }

  void toggleNews(bool value) {
    state = state.copyWith(news: value);
    _updateSetting('notif_news', value);
  }

  void toggleSound(bool value) {
    state = state.copyWith(soundEnabled: value);
    _updateSetting('notif_sound', value);
  }

  void toggleVibration(bool value) {
    state = state.copyWith(vibrationEnabled: value);
    _updateSetting('notif_vibration', value);
  }
}

final notificationSettingsProvider = StateNotifierProvider<
    NotificationSettingsController, NotificationSettingsState>(
  (ref) => NotificationSettingsController(),
);

