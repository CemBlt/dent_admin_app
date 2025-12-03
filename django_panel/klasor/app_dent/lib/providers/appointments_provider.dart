import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/hospital.dart';
import '../models/service.dart';
import '../services/auth_service.dart';
import '../services/json_service.dart';

class AppointmentsState {
  final bool isLoading;
  final List<Appointment> appointments;
  final List<Hospital> hospitals;
  final List<Doctor> doctors;
  final List<Service> services;
  final int selectedTab;
  final String? errorMessage;

  const AppointmentsState({
    required this.isLoading,
    required this.appointments,
    required this.hospitals,
    required this.doctors,
    required this.services,
    required this.selectedTab,
    this.errorMessage,
  });

  factory AppointmentsState.initial() => const AppointmentsState(
        isLoading: true,
        appointments: [],
        hospitals: [],
        doctors: [],
        services: [],
        selectedTab: 0,
      );

  AppointmentsState copyWith({
    bool? isLoading,
    List<Appointment>? appointments,
    List<Hospital>? hospitals,
    List<Doctor>? doctors,
    List<Service>? services,
    int? selectedTab,
    String? errorMessage,
  }) {
    return AppointmentsState(
      isLoading: isLoading ?? this.isLoading,
      appointments: appointments ?? this.appointments,
      hospitals: hospitals ?? this.hospitals,
      doctors: doctors ?? this.doctors,
      services: services ?? this.services,
      selectedTab: selectedTab ?? this.selectedTab,
      errorMessage: errorMessage,
    );
  }
}

class AppointmentActionResult {
  final bool success;
  final String message;

  const AppointmentActionResult({
    required this.success,
    required this.message,
  });
}

class AppointmentReviewDraft {
  final String? comment;
  final int hospitalRating;
  final int? doctorRating;

  const AppointmentReviewDraft({
    this.comment,
    this.hospitalRating = 0,
    this.doctorRating,
  });
}

class AppointmentsController extends StateNotifier<AppointmentsState> {
  AppointmentsController() : super(AppointmentsState.initial()) {
    _loadAppointments();
  }

  Future<void> refresh() async => _loadAppointments();

  Future<void> _loadAppointments() async {
    if (!AuthService.isAuthenticated) {
      state = state.copyWith(
        isLoading: false,
        appointments: [],
        hospitals: [],
        doctors: [],
        services: [],
        errorMessage: null,
      );
      return;
    }

    final userId = AuthService.currentUserId;
    if (userId == null) {
      state = state.copyWith(
        isLoading: false,
        appointments: [],
        hospitals: [],
        doctors: [],
        services: [],
        errorMessage: 'Kullanıcı bilgisi eksik',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final appointments = await JsonService.getUserAppointments(userId);
      final hospitals = await JsonService.getHospitals();
      final doctors = await JsonService.getDoctors();
      final services = await JsonService.getServices();

      state = state.copyWith(
        appointments: appointments,
        hospitals: hospitals,
        doctors: doctors,
        services: services,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<AppointmentActionResult> cancelAppointment(
    Appointment appointment,
  ) async {
    final success = await JsonService.cancelAppointment(appointment.id);
    if (success) {
      await _loadAppointments();
      return const AppointmentActionResult(
        success: true,
        message: 'Randevu iptal edildi',
      );
    }
    return const AppointmentActionResult(
      success: false,
      message: 'Randevu iptal edilirken bir hata oluştu',
    );
  }

  void selectTab(int index) {
    state = state.copyWith(selectedTab: index);
  }

  Future<AppointmentReviewDraft> fetchReviewDraft(
    Appointment appointment,
  ) async {
    try {
      final review = await JsonService.getReviewByAppointmentId(appointment.id);
      final rating = await JsonService.getRatingByAppointmentId(appointment.id);
      return AppointmentReviewDraft(
        comment: review?.comment,
        hospitalRating: rating?.hospitalRating ?? 0,
        doctorRating: rating?.doctorRating,
      );
    } catch (_) {
      return const AppointmentReviewDraft();
    }
  }

  Future<AppointmentActionResult> submitReview({
    required Appointment appointment,
    required String review,
    required int hospitalRating,
    int? doctorRating,
  }) async {
    final userId = AuthService.currentUserId;
    if (userId == null) {
      return const AppointmentActionResult(
        success: false,
        message: 'Kullanıcı bilgisi alınamadı',
      );
    }

    try {
      final reviewSaved =
          await JsonService.updateAppointmentReview(appointment.id, review);
      if (!reviewSaved) {
        return const AppointmentActionResult(
          success: false,
          message: 'Yorum kaydedilemedi. Lütfen tekrar deneyin.',
        );
      }

      if (hospitalRating > 0) {
        final rating = await JsonService.updateOrCreateRating(
          userId: userId,
          hospitalId: appointment.hospitalId,
          doctorId: appointment.doctorId,
          appointmentId: appointment.id,
          hospitalRating: hospitalRating,
          doctorRating: doctorRating,
        );

        if (rating == null) {
          return const AppointmentActionResult(
            success: false,
            message: 'Puanlama kaydedilemedi. Lütfen tekrar deneyin.',
          );
        }
      }

      await _loadAppointments();
      return const AppointmentActionResult(
        success: true,
        message: 'Yorum ve puanlama kaydedildi',
      );
    } catch (error) {
      return AppointmentActionResult(
        success: false,
        message: 'İşlem sırasında bir hata oluştu: $error',
      );
    }
  }
}

final appointmentsControllerProvider =
    StateNotifierProvider<AppointmentsController, AppointmentsState>(
  (ref) => AppointmentsController(),
);


