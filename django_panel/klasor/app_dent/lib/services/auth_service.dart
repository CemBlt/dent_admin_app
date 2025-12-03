import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'package:flutter/foundation.dart';
import '../utils/validators.dart';

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
    Validators.requireEmail(email);
    Validators.requirePassword(password);

    return SupabaseService.supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Email ve şifre ile kayıt olur
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? name,
    String? surname,
    String? phone,
  }) async {
    Validators.requireEmail(email);
    Validators.requirePassword(password);
    Validators.requireNonEmpty(name, 'Ad');
    Validators.requireNonEmpty(surname, 'Soyad');
    Validators.requirePhone(phone);

    final response = await SupabaseService.supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        if (name != null) 'name': name.trim(),
        if (surname != null) 'surname': surname.trim(),
        if (phone != null) 'phone': phone.trim(),
      },
    );

    return response;
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

}

