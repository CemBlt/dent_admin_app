import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/json_service.dart';

class ProfileState {
  final bool isLoading;
  final User? user;
  final bool isAuthenticated;
  final String? errorMessage;

  const ProfileState({
    required this.isLoading,
    required this.user,
    required this.isAuthenticated,
    this.errorMessage,
  });

  factory ProfileState.initial() => const ProfileState(
        isLoading: true,
        user: null,
        isAuthenticated: false,
      );

  ProfileState copyWith({
    bool? isLoading,
    User? user,
    bool updateUser = false,
    bool? isAuthenticated,
    String? errorMessage,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      user: updateUser ? user : this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      errorMessage: errorMessage,
    );
  }
}

class ProfileActionResult {
  final bool success;
  final String message;

  const ProfileActionResult({
    required this.success,
    required this.message,
  });
}

class ProfileController extends StateNotifier<ProfileState> {
  late final StreamSubscription<AuthState> _authSubscription;

  ProfileController() : super(ProfileState.initial()) {
    _authSubscription = AuthService.authStateChanges.listen((_) {
      loadProfile();
    });
    loadProfile();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> loadProfile() async {
    final authenticated = AuthService.isAuthenticated;
    if (!authenticated) {
      state = ProfileState(
        isLoading: false,
        user: null,
        isAuthenticated: false,
      );
      return;
    }

    final userId = AuthService.currentUserId;
    if (userId == null) {
      state = ProfileState(
        isLoading: false,
        user: null,
        isAuthenticated: false,
        errorMessage: 'Kullanıcı bilgisi bulunamadı',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await JsonService.getUser(userId);
      state = state.copyWith(
        isLoading: false,
        user: user,
        updateUser: true,
        isAuthenticated: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> refreshProfile() => loadProfile();

  Future<ProfileActionResult> logout() async {
    try {
      await AuthService.signOut();
      state = state.copyWith(
        user: null,
        updateUser: true,
        isAuthenticated: false,
      );
      return const ProfileActionResult(
        success: true,
        message: 'Çıkış yapıldı',
      );
    } catch (error) {
      return ProfileActionResult(
        success: false,
        message: 'Çıkış yapılırken hata oluştu: $error',
      );
    }
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>(
  (ref) => ProfileController(),
);

