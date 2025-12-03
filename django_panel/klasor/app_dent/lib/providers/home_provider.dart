import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/hospital.dart';
import '../models/tip.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/json_service.dart';
import '../services/location_service.dart';

class HomeState {
  final bool isLoading;
  final List<Hospital> hospitals;
  final List<Doctor> popularDoctors;
  final List<Tip> tips;
  final int currentTipIndex;
  final Appointment? upcomingAppointment;
  final Doctor? upcomingDoctor;
  final User? user;
  final Map<String, Map<String, dynamic>> hospitalRatings;
  final Map<String, Map<String, dynamic>> doctorRatings;
  final Position? userPosition;
  final Map<String, double> hospitalDistances;
  final String? errorMessage;

  const HomeState({
    required this.isLoading,
    required this.hospitals,
    required this.popularDoctors,
    required this.tips,
    required this.currentTipIndex,
    required this.upcomingAppointment,
    required this.upcomingDoctor,
    required this.user,
    required this.hospitalRatings,
    required this.doctorRatings,
    required this.userPosition,
    required this.hospitalDistances,
    required this.errorMessage,
  });

  factory HomeState.initial() => const HomeState(
        isLoading: true,
        hospitals: [],
        popularDoctors: [],
        tips: [],
        currentTipIndex: 0,
        upcomingAppointment: null,
        upcomingDoctor: null,
        user: null,
        hospitalRatings: {},
        doctorRatings: {},
        userPosition: null,
        hospitalDistances: {},
        errorMessage: null,
      );

  HomeState copyWith({
    bool? isLoading,
    List<Hospital>? hospitals,
    List<Doctor>? popularDoctors,
    List<Tip>? tips,
    int? currentTipIndex,
    Appointment? upcomingAppointment,
    Doctor? upcomingDoctor,
    User? user,
    Map<String, Map<String, dynamic>>? hospitalRatings,
    Map<String, Map<String, dynamic>>? doctorRatings,
    Position? userPosition,
    Map<String, double>? hospitalDistances,
    String? errorMessage,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      hospitals: hospitals ?? this.hospitals,
      popularDoctors: popularDoctors ?? this.popularDoctors,
      tips: tips ?? this.tips,
      currentTipIndex: currentTipIndex ?? this.currentTipIndex,
      upcomingAppointment: upcomingAppointment ?? this.upcomingAppointment,
      upcomingDoctor: upcomingDoctor ?? this.upcomingDoctor,
      user: user ?? this.user,
      hospitalRatings: hospitalRatings ?? this.hospitalRatings,
      doctorRatings: doctorRatings ?? this.doctorRatings,
      userPosition: userPosition ?? this.userPosition,
      hospitalDistances: hospitalDistances ?? this.hospitalDistances,
      errorMessage: errorMessage,
    );
  }
}

class HomeController extends StateNotifier<HomeState> {
  HomeController() : super(HomeState.initial());

  Timer? _tipTimer;

  @override
  void dispose() {
    _tipTimer?.cancel();
    super.dispose();
  }

  Future<void> loadInitial({Position? position}) async {
    await _loadData(position: position);
    _startTipCarousel();
  }

  Future<void> refresh() async {
    await _loadData(position: state.userPosition);
  }

  Future<void> _loadData({Position? position}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      List<Hospital> hospitals;
      final distances = <String, double>{};

      if (position != null) {
        hospitals = await JsonService.getNearbyHospitals(
          userLat: position.latitude,
          userLon: position.longitude,
          radiusKm: 50,
        );
        for (final hospital in hospitals) {
          final distance = LocationService.calculateDistance(
            position.latitude,
            position.longitude,
            hospital.latitude,
            hospital.longitude,
          );
          distances[hospital.id] = distance;
        }
      } else {
        hospitals = await JsonService.getHospitals();
        hospitals.sort((a, b) => a.name.compareTo(b.name));
      }

      final doctors = await JsonService.getPopularDoctors();
      final tips = await JsonService.getTips();
      Appointment? upcomingAppointment;
      Doctor? upcomingDoctor;
      User? user;

      if (AuthService.isAuthenticated) {
        final userId = AuthService.currentUserId;
        if (userId != null) {
          user = await JsonService.getUser(userId);
          upcomingAppointment =
              await JsonService.getUpcomingAppointmentForUser(userId);
          if (upcomingAppointment != null) {
            upcomingDoctor =
                await JsonService.getDoctorById(upcomingAppointment.doctorId);
          }
        }
      }

      final hospitalRatingsMap = <String, Map<String, dynamic>>{};
      for (final hospital in hospitals) {
        try {
          final reviews =
              await JsonService.getReviewsByHospital(hospital.id);
          final averageRating =
              await JsonService.getHospitalAverageRating(hospital.id);
          hospitalRatingsMap[hospital.id] = {
            'reviewCount': reviews.length,
            'averageRating': averageRating,
          };
        } catch (_) {
          hospitalRatingsMap[hospital.id] = {
            'reviewCount': 0,
            'averageRating': 0.0,
          };
        }
      }

      final doctorRatingsMap = <String, Map<String, dynamic>>{};
      for (final doctor in doctors) {
        try {
          final reviews = await JsonService.getReviewsByDoctor(doctor.id);
          final averageRating =
              await JsonService.getDoctorAverageRating(doctor.id);
          doctorRatingsMap[doctor.id] = {
            'reviewCount': reviews.length,
            'averageRating': averageRating,
          };
        } catch (_) {
          doctorRatingsMap[doctor.id] = {
            'reviewCount': 0,
            'averageRating': 0.0,
          };
        }
      }

      state = state.copyWith(
        hospitals: hospitals,
        popularDoctors: doctors,
        tips: tips,
        currentTipIndex: tips.isEmpty
            ? 0
            : state.currentTipIndex % tips.length,
        upcomingAppointment: upcomingAppointment,
        upcomingDoctor: upcomingDoctor,
        user: user,
        hospitalRatings: hospitalRatingsMap,
        doctorRatings: doctorRatingsMap,
        userPosition: position ?? state.userPosition,
        hospitalDistances: distances,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void setUserPosition(Position? position) {
    state = state.copyWith(userPosition: position);
  }

  void _startTipCarousel() {
    _tipTimer?.cancel();
    if (state.tips.isEmpty) return;
    _tipTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final nextIndex = (state.currentTipIndex + 1) % state.tips.length;
      state = state.copyWith(currentTipIndex: nextIndex);
    });
  }

  void disposeTimer() {
    _tipTimer?.cancel();
  }
}

final homeControllerProvider =
    StateNotifierProvider<HomeController, HomeState>(
  (ref) => HomeController(),
);

