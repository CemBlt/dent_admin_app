import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

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

  /// Email ve şifre ile kayıt olur
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? name,
    String? surname,
    String? phone,
  }) async {
    final response = await SupabaseService.supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        if (name != null) 'name': name,
        if (surname != null) 'surname': surname,
        if (phone != null) 'phone': phone,
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
}

