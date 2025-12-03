import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_dent/providers/notification_settings_provider.dart';

Future<void> _waitForAsyncInit() async {
  await Future<void>.delayed(Duration.zero);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationSettingsController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loads saved toggles from preferences', () async {
      SharedPreferences.setMockInitialValues({
        'notif_appointment_reminders': false,
        'notif_appointment_updates': false,
        'notif_promotions': true,
      });

      final controller = NotificationSettingsController();
      await _waitForAsyncInit();

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.appointmentReminders, isFalse);
      expect(controller.state.appointmentUpdates, isFalse);
      expect(controller.state.promotions, isTrue);
    });

    test('toggle methods update state and persist', () async {
      final controller = NotificationSettingsController();
      await _waitForAsyncInit();

      controller.toggleSound(false);
      controller.toggleNews(true);

      expect(controller.state.soundEnabled, isFalse);
      expect(controller.state.news, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notif_sound'), isFalse);
      expect(prefs.getBool('notif_news'), isTrue);
    });
  });
}


