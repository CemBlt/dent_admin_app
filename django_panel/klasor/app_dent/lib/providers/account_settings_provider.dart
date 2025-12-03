import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/json_service.dart';

class AccountSettingsState {
  final bool isLoading;
  final bool isSaving;
  final User? user;
  final String? errorMessage;

  const AccountSettingsState({
    required this.isLoading,
    required this.isSaving,
    required this.user,
    this.errorMessage,
  });

  factory AccountSettingsState.initial() => const AccountSettingsState(
        isLoading: true,
        isSaving: false,
        user: null,
      );

  AccountSettingsState copyWith({
    bool? isLoading,
    bool? isSaving,
    User? user,
    String? errorMessage,
  }) {
    return AccountSettingsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AccountActionResult {
  final bool success;
  final String message;

  const AccountActionResult({
    required this.success,
    required this.message,
  });
}

class AccountSettingsController
    extends StateNotifier<AccountSettingsState> {
  AccountSettingsController() : super(AccountSettingsState.initial()) {
    loadUser();
  }

  Future<void> loadUser() async {
    if (!AuthService.isAuthenticated) {
      state = AccountSettingsState(
        isLoading: false,
        isSaving: false,
        user: null,
      );
      return;
    }

    final userId = AuthService.currentUserId;
    if (userId == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Kullanıcı bilgisi bulunamadı',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await JsonService.getUser(userId);
      state = state.copyWith(
        user: user,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<AccountActionResult> saveProfile({
    required String fullName,
    required String email,
    required String phone,
  }) async {
    if (state.user == null) {
      return const AccountActionResult(
        success: false,
        message: 'Kullanıcı bilgisi bulunamadı',
      );
    }

    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      // TODO: JsonService.updateUser eklendiğinde burada kullanılacak.
      await Future.delayed(const Duration(milliseconds: 200));

      state = state.copyWith(isSaving: false);
      return const AccountActionResult(
        success: true,
        message: 'Bilgiler güncellendi',
      );
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: error.toString(),
      );
      return AccountActionResult(
        success: false,
        message: 'Güncelleme başarısız: $error',
      );
    }
  }
}

final accountSettingsControllerProvider = StateNotifierProvider<
    AccountSettingsController, AccountSettingsState>(
  (ref) => AccountSettingsController(),
);

