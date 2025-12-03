import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppEventService {
  AppEventService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> log(
    String eventName, {
    Map<String, dynamic>? properties,
  }) async {
    try {
      final sessionUserId = _client.auth.currentUser?.id;
      final Map<String, dynamic> payload = {
        'event_name': eventName,
        'user_id': sessionUserId,
        'event_props': <String, dynamic>{
          'platform': defaultTargetPlatform.name,
          if (properties != null) ...properties,
        },
      };
      await _client.from('app_events').insert(payload);
    } catch (error) {
      debugPrint('AppEventService log failed: $error');
    }
  }
}

