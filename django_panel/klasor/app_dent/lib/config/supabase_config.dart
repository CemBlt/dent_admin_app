import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase configuration
/// Supabase yapılandırması
///
/// Bu dosyada Supabase URL ve anon key tanımlanır.
/// Production'da bu değerler environment variables veya secure storage'dan okunmalıdır.
/// Production veya CI ortamlarında değerleri `--dart-define` ile geçmeniz beklenir.
/// Örnek: `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
class SupabaseConfig {
  // TODO: Kendi Supabase projenizin URL ve anon key'ini buraya ekleyin
  // Supabase Dashboard > Settings > API > Project URL ve anon public key

  /// `flutter run --dart-define=SUPABASE_URL=...`
  static String get supabaseUrl {
    const value = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    if (value.isNotEmpty) return value;
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  /// `flutter run --dart-define=SUPABASE_ANON_KEY=...`
  static String get supabaseAnonKey {
    const value = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    if (value.isNotEmpty) return value;
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  // Örnek:
  // static const String supabaseUrl = 'https://xxxxx.supabase.co';
  // static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';

  /// Çevre değişkenleri eksikse erken uyarı verir.
  static void ensureConfigured() {
    final missing = <String>[];
    if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
    if (supabaseAnonKey.isEmpty) missing.add('SUPABASE_ANON_KEY');
    if (missing.isNotEmpty) {
      throw StateError(
        'Supabase yapılandırması eksik: ${missing.join(', ')}.\n'
        'Değerleri `--dart-define` ile sağlayın veya CI/CD ortamınıza ekleyin.',
      );
    }
  }
}
