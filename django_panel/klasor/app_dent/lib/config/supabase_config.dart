/// Supabase configuration
///
/// Bu dosyada Supabase URL ve anon key tanımlanır.
/// Production'da bu değerler environment variables veya secure storage'dan okunmalıdır.
class SupabaseConfig {
  // TODO: Kendi Supabase projenizin URL ve anon key'ini buraya ekleyin
  // Supabase Dashboard > Settings > API > Project URL ve anon public key
  static const String supabaseUrl = 'https://lvbtbffqggupxmybozde.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx2YnRiZmZxZ2d1cHhteWJvemRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM1NDA1NTQsImV4cCI6MjA3OTExNjU1NH0.MHlujUrlCKSiVJS87BatJ0d_3PPoImImkOlFWAwSOA4';

  // Örnek:
  // static const String supabaseUrl = 'https://xxxxx.supabase.co';
  // static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
}
