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

  /// Email (opsiyonel) ve şifre ile kayıt olur
  /// Telefon numarası zorunludur
  static Future<AuthResponse> signUp({
    String? email,
    required String password,
    String? name,
    String? surname,
    required String phone,
  }) async {
    // Email boşsa, telefon numarasından geçici email oluştur
    // Supabase Auth email zorunlu olduğu için
    final finalEmail = email?.trim().isEmpty ?? true
        ? 'phone_${phone.replaceAll(RegExp(r'[^0-9]'), '')}@temp.dentapp.com'
        : email!.trim();

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
  /// Email boşsa false döner (opsiyonel olduğu için)
  /// Hem user_profiles hem de Supabase Auth'da kontrol eder
  static Future<bool> isEmailTaken(String email) async {
    try {
      // Email boşsa veya geçersizse kontrol yapma
      final trimmedEmail = email.trim();
      if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
        return false;
      }

      // 1. user_profiles tablosunda kontrol et
      final profileResponse = await SupabaseService.supabase
          .from('user_profiles')
          .select('id')
          .eq('email', trimmedEmail)
          .maybeSingle();
      
      if (profileResponse != null) {
        return true; // user_profiles'da bulundu
      }

      // 2. Supabase Auth'da kontrol et
      // Supabase Auth'a direkt erişimimiz olmadığı için,
      // signInWithPassword ile test ediyoruz (yanlış şifre ile)
      // Eğer "Invalid login credentials" hatası alırsak, email var demektir
      // Eğer "User not found" hatası alırsak, email yok demektir
      try {
        await SupabaseService.supabase.auth.signInWithPassword(
          email: trimmedEmail,
          password: r'dummy_check_password_12345!@#$%',
        );
        // Eğer buraya geldiyse (ki gelmemeli), email yok demektir
        return false;
      } catch (authError) {
        final errorString = authError.toString().toLowerCase();
        // Eğer "user not found" veya "email not found" hatası alırsak,
        // email Supabase Auth'da yok demektir
        if (errorString.contains('user not found') ||
            errorString.contains('email not found') ||
            errorString.contains('no user found')) {
          return false; // Email Supabase Auth'da yok
        }
        // "Invalid login credentials" veya "Email not confirmed" gibi hatalar
        // email'in var olduğunu gösterir
        return true; // Email Supabase Auth'da var
      }
    } catch (e) {
      debugPrint('Email kontrolü hatası: $e');
      // Hata durumunda güvenli tarafta kal (kayıt yapılmasın)
      return true;
    }
  }
}

