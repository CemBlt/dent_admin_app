import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_dent/providers/language_settings_provider.dart';

Future<void> _waitForAsyncInit() async {
  // Let the asynchronous constructor work finish.
  await Future<void>.delayed(Duration.zero);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LanguageSettingsController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loads saved language from preferences', () async {
      SharedPreferences.setMockInitialValues({'app_language': 'en'});

      final controller = LanguageSettingsController();
      await _waitForAsyncInit();

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.selectedLanguage, 'en');
    });

    test('changeLanguage updates state and persists selection', () async {
      final controller = LanguageSettingsController();
      await _waitForAsyncInit();

      String? message;
      await controller.changeLanguage(
        languageCode: 'en',
        showMessage: (value) => message = value,
      );

      expect(controller.state.selectedLanguage, 'en');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_language'), 'en');
      expect(message, isNotNull);
    });
  });
}


