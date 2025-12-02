import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'package:flutter/foundation.dart';

/// Authentication service
/// 
/// Kullanıcı giriş, kayıt ve çıkış işlemlerini yönetir.
class AuthService {
  /// Mevcut kullanıcının giriş yapıp yapmadığını kontrol eder
  static bool get isAuthenticated {
    return SupabaseService.supabase.auth.currentUser != null;
  }

  /// Mevcut kullanıcının ID'sini döndürür
  static String? get currentUserId {
    return SupabaseService.supabase.auth.currentUser?.id;
  }

  /// Mevcut kullanıcının email'ini döndürür
  static String? get currentUserEmail {
    return SupabaseService.supabase.auth.currentUser?.email;
  }

  /// Email ve şifre ile giriş yapar
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await SupabaseService.supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Email (zorunlu) ve şifre ile kayıt olur
  /// Telefon numarası zorunludur ve E.164 formatında olmalıdır
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
    String? surname,
    required String phone, // E.164 formatında: +905321234567
  }) async {
    // Email zorunlu, trim yap
    final finalEmail = email.trim();
    
    if (finalEmail.isEmpty) {
      throw Exception('Email adresi gerekli');
    }

    final response = await SupabaseService.supabase.auth.signUp(
      email: finalEmail,
      password: password,
      data: {
        if (name != null && name.isNotEmpty) 'name': name,
        if (surname != null && surname.isNotEmpty) 'surname': surname,
        'phone': phone,
      },
    );

    return response;
  }

  /// Email ve şifre ile kayıt olur (geriye dönük uyumluluk için)
  @Deprecated('Use signUp instead')
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? name,
    String? surname,
    String? phone,
  }) async {
    return signUp(
      email: email,
      password: password,
      name: name,
      surname: surname,
      phone: phone ?? '',
    );
  }

  /// Çıkış yapar
  static Future<void> signOut() async {
    await SupabaseService.supabase.auth.signOut();
  }

  /// Auth state değişikliklerini dinler
  static Stream<AuthState> get authStateChanges {
    return SupabaseService.supabase.auth.onAuthStateChange;
  }

  /// Telefon numarasının daha önce kayıtlı olup olmadığını kontrol eder
  static Future<bool> isPhoneNumberTaken(String phone) async {
    try {
      final response = await SupabaseService.supabase
          .from('user_profiles')
          .select('id')
          .eq('phone', phone.trim())
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      debugPrint('Telefon numarası kontrolü hatası: $e');
      // Hata durumunda güvenli tarafta kal (kayıt yapılmasın)
      return true;
    }
  }

  /// Email'in daha önce kayıtlı olup olmadığını kontrol eder
  /// Sadece user_profiles tablosunda kontrol eder
  /// Not: Supabase Auth kontrolü yapılmıyor çünkü:
  /// 1. signInWithPassword() rate-limit sorunlarına yol açar
  /// 2. Güvenlik loglarında şüpheli aktivite oluşturur
  /// 3. user_profiles tablosu trigger ile auth.users ile senkron kalır
  /// 4. Kayıt sırasında Supabase Auth zaten email uniqueness kontrolü yapar
  static Future<bool> isEmailTaken(String email) async {
    try {
      // Email boşsa veya geçersizse kontrol yapma
      final trimmedEmail = email.trim().toLowerCase();
      if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
        return false; // Geçersiz email, kontrol yapma
      }

      // user_profiles tablosunda kontrol et
      final response = await SupabaseService.supabase
          .from('user_profiles')
          .select('id')
          .eq('email', trimmedEmail)
          .maybeSingle();
      
      // Eğer user_profiles'da bulunduysa, email alınmış demektir
      return response != null;
    } catch (e) {
      debugPrint('Email kontrolü hatası: $e');
      // Hata durumunda false döndür (kayıt denemesi yapılsın,
      // Supabase Auth zaten kontrol edecek)
      return false;
    }
  }
}

