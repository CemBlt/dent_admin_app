import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase service helper class
/// 
/// Tüm Supabase işlemlerini yöneten merkezi servis sınıfı.
class SupabaseService {
  /// Supabase client instance'ını döndürür
  static SupabaseClient get client => Supabase.instance.client;
  
  /// Supabase client'ına direkt erişim için kısayol
  static SupabaseClient get supabase => client;
}

