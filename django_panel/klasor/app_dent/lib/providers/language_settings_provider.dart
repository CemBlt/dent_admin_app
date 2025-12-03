import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageSettingsState {
  final bool isLoading;
  final String selectedLanguage;

  const LanguageSettingsState({
    required this.isLoading,
    required this.selectedLanguage,
  });

  factory LanguageSettingsState.initial() =>
      const LanguageSettingsState(isLoading: true, selectedLanguage: 'tr');

  LanguageSettingsState copyWith({
    bool? isLoading,
    String? selectedLanguage,
  }) {
    return LanguageSettingsState(
      isLoading: isLoading ?? this.isLoading,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
    );
  }
}

class LanguageSettingsController
    extends StateNotifier<LanguageSettingsState> {
  LanguageSettingsController() : super(LanguageSettingsState.initial()) {
    _loadLanguage();
  }

  SharedPreferences? _prefs;

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadLanguage() async {
    await _ensurePrefs();
    final language = _prefs?.getString('app_language') ?? 'tr';
    state = state.copyWith(
      selectedLanguage: language,
      isLoading: false,
    );
  }

  Future<void> changeLanguage({
    required String languageCode,
    required void Function(String message) showMessage,
  }) async {
    if (state.selectedLanguage == languageCode) {
      showMessage('Seçili dil zaten aktif.');
      return;
    }

    state = state.copyWith(selectedLanguage: languageCode);
    await _ensurePrefs();
    await _prefs?.setString('app_language', languageCode);
    showMessage(
      'Dil değişikliği kaydedildi. Uygulamayı yeniden başlatırken aktif olur.',
    );
  }
}

final languageSettingsProvider =
    StateNotifierProvider<LanguageSettingsController, LanguageSettingsState>(
  (ref) => LanguageSettingsController(),
);

