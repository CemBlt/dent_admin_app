import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/hospital.dart';
import '../models/service.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../services/json_service.dart';

class CreateAppointmentState {
  final bool isLoading;
  final bool isSearchingSlots;
  final List<Hospital> allHospitals;
  final List<Hospital> filteredHospitals;
  final List<Doctor> allDoctors;
  final List<Doctor> filteredDoctors;
  final List<Service> services;
  final List<Appointment> existingAppointments;
  final List<String> availableTimes;
  final String? selectedCity;
  final String? selectedDistrict;
  final Hospital? selectedHospital;
  final Doctor? selectedDoctor;
  final Service? selectedService;
  final DateTime? selectedDate;
  final String? selectedTime;
  final String? lastError;

  const CreateAppointmentState({
    required this.isLoading,
    required this.isSearchingSlots,
    required this.allHospitals,
    required this.filteredHospitals,
    required this.allDoctors,
    required this.filteredDoctors,
    required this.services,
    required this.existingAppointments,
    required this.availableTimes,
    required this.selectedCity,
    required this.selectedDistrict,
    required this.selectedHospital,
    required this.selectedDoctor,
    required this.selectedService,
    required this.selectedDate,
    required this.selectedTime,
    required this.lastError,
  });

  factory CreateAppointmentState.initial() => CreateAppointmentState(
        isLoading: true,
        isSearchingSlots: false,
        allHospitals: const [],
        filteredHospitals: const [],
        allDoctors: const [],
        filteredDoctors: const [],
        services: const [],
        existingAppointments: const [],
        availableTimes: const [],
        selectedCity: null,
        selectedDistrict: null,
        selectedHospital: null,
        selectedDoctor: null,
        selectedService: null,
        selectedDate: null,
        selectedTime: null,
        lastError: null,
      );

  CreateAppointmentState copyWith({
    bool? isLoading,
    bool? isSearchingSlots,
    List<Hospital>? allHospitals,
    List<Hospital>? filteredHospitals,
    List<Doctor>? allDoctors,
    List<Doctor>? filteredDoctors,
    List<Service>? services,
    List<Appointment>? existingAppointments,
    List<String>? availableTimes,
    String? selectedCity,
    String? selectedDistrict,
    Hospital? selectedHospital,
    Doctor? selectedDoctor,
    Service? selectedService,
    DateTime? selectedDate,
    String? selectedTime,
    String? lastError,
  }) {
    return CreateAppointmentState(
      isLoading: isLoading ?? this.isLoading,
      isSearchingSlots: isSearchingSlots ?? this.isSearchingSlots,
      allHospitals: allHospitals ?? this.allHospitals,
      filteredHospitals: filteredHospitals ?? this.filteredHospitals,
      allDoctors: allDoctors ?? this.allDoctors,
      filteredDoctors: filteredDoctors ?? this.filteredDoctors,
      services: services ?? this.services,
      existingAppointments: existingAppointments ?? this.existingAppointments,
      availableTimes: availableTimes ?? this.availableTimes,
      selectedCity: selectedCity ?? this.selectedCity,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
      selectedHospital: selectedHospital ?? this.selectedHospital,
      selectedDoctor: selectedDoctor ?? this.selectedDoctor,
      selectedService: selectedService ?? this.selectedService,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      lastError: lastError,
    );
  }
}

class CreateAppointmentResult {
  final bool success;
  final String message;
  final Object? payload;

  const CreateAppointmentResult({
    required this.success,
    required this.message,
    this.payload,
  });
}

class CreateAppointmentController
    extends StateNotifier<CreateAppointmentState> {
  static const int searchResultsLimit = 10;
  static const int searchDaysHorizon = 30;

  CreateAppointmentController() : super(CreateAppointmentState.initial());

  List<String> get cities {
    final cities = <String>{};
    for (final hospital in state.allHospitals) {
      final info = _getLocationInfo(hospital);
      if ((info['city'] ?? '').isNotEmpty) {
        cities.add(info['city']!);
      }
    }
    final list = cities.toList()..sort();
    return list;
  }

  List<String> get districts {
    if (state.selectedCity == null) return const [];
    final districts = <String>{};
    for (final hospital in state.allHospitals) {
      final info = _getLocationInfo(hospital);
      if (info['city'] == state.selectedCity &&
          (info['district'] ?? '').isNotEmpty) {
        districts.add(info['district']!);
      }
    }
    final list = districts.toList()..sort();
    return list;
  }

  Future<void> loadData({
    String? preselectedHospitalId,
    String? preselectedDoctorId,
  }) async {
    state = state.copyWith(isLoading: true, lastError: null);
    try {
      final hospitals = await JsonService.getHospitals();
      final doctors = await JsonService.getDoctors();
      final services = await JsonService.getServices();
      final availabilityData =
          await JsonService.getAppointmentsForAvailabilityCheck();

      final appointments = availabilityData
          .map(
            (data) => Appointment(
              id: '',
              userId: '',
              hospitalId: '',
              doctorId: data['doctor_id'].toString(),
              date: data['date']?.toString() ?? '',
              time: data['time']?.toString() ?? '',
              status: data['status']?.toString() ?? 'completed',
              service: '',
              notes: '',
              createdAt: '',
            ),
          )
          .toList();

      var selectedCity = state.selectedCity;
      var selectedDistrict = state.selectedDistrict;
      Hospital? selectedHospital = state.selectedHospital;
      Doctor? selectedDoctor = state.selectedDoctor;
      Service? selectedService = state.selectedService;
      var filteredHospitals = <Hospital>[];
      var filteredDoctors = <Doctor>[];

      if (preselectedHospitalId != null) {
        try {
          final hospital = hospitals
              .firstWhere((element) => element.id == preselectedHospitalId);
          final info = _getLocationInfo(hospital);
          selectedCity = info['city'];
          selectedDistrict = info['district'];
          selectedHospital = hospital;
        } catch (_) {}
      }

      filteredHospitals = _filterHospitals(
        hospitals: hospitals,
        city: selectedCity,
        district: selectedDistrict,
      );

      if (preselectedDoctorId != null) {
        try {
          final doctor =
              doctors.firstWhere((element) => element.id == preselectedDoctorId);
          selectedDoctor = doctor;
          if (selectedHospital == null) {
            selectedHospital = hospitals
                .firstWhere((element) => element.id == doctor.hospitalId);
            final info = _getLocationInfo(selectedHospital);
            selectedCity = info['city'];
            selectedDistrict = info['district'];
            filteredHospitals = _filterHospitals(
              hospitals: hospitals,
              city: selectedCity,
              district: selectedDistrict,
            );
          }
          if (doctor.services.isNotEmpty) {
            try {
              selectedService = services.firstWhere(
                (service) => doctor.services.contains(service.id),
              );
            } catch (_) {}
          }
        } catch (_) {}
      }

      filteredDoctors = _filterDoctors(
        doctors: doctors,
        hospital: selectedHospital,
        service: selectedService,
      );

      state = state.copyWith(
        allHospitals: hospitals,
        filteredHospitals: filteredHospitals,
        allDoctors: doctors,
        filteredDoctors: filteredDoctors,
        services: _sortServices(services),
        existingAppointments: appointments,
        selectedCity: selectedCity,
        selectedDistrict: selectedDistrict,
        selectedHospital: selectedHospital,
        selectedDoctor: selectedDoctor,
        selectedService: selectedService,
        isLoading: false,
      );

      if (selectedDoctor != null && selectedService != null) {
        unawaited(searchAvailableSlots());
      }
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        lastError: error.toString(),
      );
    }
  }

  void selectCity(String? city) {
    state = state.copyWith(
      selectedCity: city,
      selectedDistrict: null,
      selectedHospital: null,
      selectedDoctor: null,
      selectedDate: null,
      selectedTime: null,
      availableTimes: const [],
      filteredDoctors: const [],
      isSearchingSlots: false,
      filteredHospitals: _filterHospitals(
        hospitals: state.allHospitals,
        city: city,
        district: null,
      ),
    );
  }

  void selectDistrict(String? district) {
    state = state.copyWith(
      selectedDistrict: district,
      selectedHospital: null,
      selectedDoctor: null,
      selectedDate: null,
      selectedTime: null,
      availableTimes: const [],
      filteredDoctors: const [],
      isSearchingSlots: false,
      filteredHospitals: _filterHospitals(
        hospitals: state.allHospitals,
        city: state.selectedCity,
        district: district,
      ),
    );
  }

  void selectHospital(Hospital? hospital) {
    state = state.copyWith(
      selectedHospital: hospital,
      selectedDoctor: null,
      selectedDate: null,
      selectedTime: null,
      availableTimes: const [],
      isSearchingSlots: false,
      filteredDoctors: _filterDoctors(
        doctors: state.allDoctors,
        hospital: hospital,
        service: state.selectedService,
      ),
    );
  }

  void selectService(Service? service) {
    state = state.copyWith(
      selectedService: service,
      selectedDoctor: null,
      selectedDate: null,
      selectedTime: null,
      availableTimes: const [],
      isSearchingSlots: false,
      filteredDoctors: _filterDoctors(
        doctors: state.allDoctors,
        hospital: state.selectedHospital,
        service: service,
      ),
    );
  }

  void selectDoctor(Doctor? doctor) {
    state = state.copyWith(
      selectedDoctor: doctor,
      selectedDate: null,
      selectedTime: null,
      availableTimes: const [],
      isSearchingSlots: false,
    );
  }

  void setDate(DateTime? date) {
    state = state.copyWith(
      selectedDate: date,
      selectedTime: null,
    );
  }

  void selectTime(String? time) {
    state = state.copyWith(selectedTime: time);
  }

  void hydrateFromLegacy({
    required List<Hospital> hospitals,
    required List<Hospital> filteredHospitals,
    required List<Doctor> doctors,
    required List<Doctor> filteredDoctors,
    required List<Service> services,
    required List<Appointment> existingAppointments,
    required String? selectedCity,
    required String? selectedDistrict,
    required Hospital? selectedHospital,
    required Doctor? selectedDoctor,
    required Service? selectedService,
    required DateTime? selectedDate,
    required String? selectedTime,
    required List<String> availableTimes,
    required bool isLoading,
    bool? isSearchingSlots,
  }) {
    state = state.copyWith(
      allHospitals: hospitals,
      filteredHospitals: filteredHospitals,
      allDoctors: doctors,
      filteredDoctors: filteredDoctors,
      services: services,
      existingAppointments: existingAppointments,
      availableTimes: availableTimes,
      selectedCity: selectedCity,
      selectedDistrict: selectedDistrict,
      selectedHospital: selectedHospital,
      selectedDoctor: selectedDoctor,
      selectedService: selectedService,
      selectedDate: selectedDate,
      selectedTime: selectedTime,
      isLoading: isLoading,
      isSearchingSlots: isSearchingSlots ?? state.isSearchingSlots,
      lastError: null,
    );
  }

  Future<CreateAppointmentResult> searchAvailableSlots() async {
    if (state.selectedService == null) {
      return const CreateAppointmentResult(
        success: false,
        message: 'Lütfen önce hizmet seçiniz',
      );
    }

    state = state.copyWith(isSearchingSlots: true, lastError: null);
    List<Appointment> appointments = state.existingAppointments;

    try {
      final availabilityData =
          await JsonService.getAppointmentsForAvailabilityCheck();
      appointments = availabilityData
          .map(
            (data) => Appointment(
              id: '',
              userId: '',
              hospitalId: '',
              doctorId: data['doctor_id'].toString(),
              date: data['date']?.toString() ?? '',
              time: data['time']?.toString() ?? '',
              status: data['status']?.toString() ?? 'completed',
              service: '',
              notes: '',
              createdAt: '',
            ),
          )
          .toList();
    } catch (error) {
      state = state.copyWith(
        isSearchingSlots: false,
        lastError: error.toString(),
      );
      return CreateAppointmentResult(
        success: false,
        message: 'Randevu kontrolü yapılamadı: $error',
      );
    }

    final hospitalById = {
      for (final hospital in state.allHospitals) hospital.id: hospital,
    };
    final serviceId = state.selectedService!.id;

    final candidateDoctors = state.allDoctors.where((doctor) {
      if (!doctor.services.contains(serviceId)) return false;
      final hospital = hospitalById[doctor.hospitalId];
      if (hospital == null) return false;
      if (!_matchesSelectedLocation(
        hospital,
        state.selectedCity,
        state.selectedDistrict,
      )) return false;
      if (state.selectedHospital != null &&
          doctor.hospitalId != state.selectedHospital!.id) return false;
      if (state.selectedDoctor != null &&
          doctor.id != state.selectedDoctor!.id) return false;
      return true;
    }).toList();

    if (candidateDoctors.isEmpty) {
      state = state.copyWith(isSearchingSlots: false);
      return const CreateAppointmentResult(
        success: false,
        message: 'Filtrelerinize uygun doktor bulunamadı.',
      );
    }

    final now = DateTime.now();
    final startBase = state.selectedDate ?? now;
    final startDate = DateTime(startBase.year, startBase.month, startBase.day);

    final slots = <AvailableSlot>[];
    var reachedLimit = false;

    for (var dayOffset = 0;
        dayOffset <= searchDaysHorizon && !reachedLimit;
        dayOffset++) {
      final date = startDate.add(Duration(days: dayOffset));
      for (final doctor in candidateDoctors) {
        final hospital = hospitalById[doctor.hospitalId];
        if (hospital == null) continue;
        final times = _getAvailableTimesForDoctor(
          doctor: doctor,
          date: date,
        );
        for (final time in times) {
          final slotDateTime = _combineDateAndTime(date, time);
          if (slotDateTime.isBefore(now)) continue;
          if (_isTimeBooked(
            doctor: doctor,
            appointments: appointments,
            date: date,
            time: time,
          )) {
            continue;
          }
          slots.add(
            AvailableSlot(
              hospital: hospital,
              doctor: doctor,
              date: date,
              time: time,
            ),
          );
          if (slots.length >= searchResultsLimit) {
            reachedLimit = true;
            break;
          }
        }
      }
    }

    state = state.copyWith(
      isSearchingSlots: false,
      existingAppointments: appointments,
    );

    if (slots.isEmpty) {
      return const CreateAppointmentResult(
        success: false,
        message: 'Uygun randevu bulunamadı.',
      );
    }

    return CreateAppointmentResult(
      success: true,
      message: 'Slots found',
      payload: slots,
    );
  }

  Future<CreateAppointmentResult> createAppointment({
    required String notes,
  }) async {
    if (!_isFormValid(state)) {
      return const CreateAppointmentResult(
        success: false,
        message: 'Lütfen tüm alanları doldurunuz',
      );
    }

    if (!AuthService.isAuthenticated) {
      return const CreateAppointmentResult(
        success: false,
        message: 'login_required',
      );
    }

    final userId = AuthService.currentUserId;
    if (userId == null) {
      return const CreateAppointmentResult(
        success: false,
        message: 'Kullanıcı bilgisi alınamadı. Lütfen tekrar giriş yapın.',
      );
    }

    AppEventService.log('appointment_submit_attempt', properties: {
      'hospital_id': state.selectedHospital?.id,
      'doctor_id': state.selectedDoctor?.id,
      'service_id': state.selectedService?.id,
      'date_selected': state.selectedDate?.toIso8601String(),
    });

    try {
      final availabilityData =
          await JsonService.getAppointmentsForAvailabilityCheck();
      final appointments = availabilityData
          .map(
            (data) => Appointment(
              id: '',
              userId: '',
              hospitalId: '',
              doctorId: data['doctor_id'].toString(),
              date: data['date']?.toString() ?? '',
              time: data['time']?.toString() ?? '',
              status: data['status']?.toString() ?? 'completed',
              service: '',
              notes: '',
              createdAt: '',
            ),
          )
          .toList();

      if (_isTimeBooked(
        doctor: state.selectedDoctor!,
        appointments: appointments,
        date: state.selectedDate!,
        time: state.selectedTime!,
      )) {
        return const CreateAppointmentResult(
          success: false,
          message: 'Bu tarih ve saatte randevu bulunmakta.',
        );
      }

      state = state.copyWith(
        existingAppointments: appointments,
        isLoading: true,
      );
    } catch (error) {
      debugPrint('Randevu kontrolü yapılamadı: $error');
      state = state.copyWith(isLoading: true);
    }

    try {
      final dateString =
          '${state.selectedDate!.year}-${state.selectedDate!.month.toString().padLeft(2, '0')}-${state.selectedDate!.day.toString().padLeft(2, '0')}';

      final appointment = await JsonService.createAppointment(
        userId: userId,
        hospitalId: state.selectedHospital!.id,
        doctorId: state.selectedDoctor!.id,
        date: dateString,
        time: state.selectedTime!,
        serviceId: state.selectedService!.id,
        notes: notes,
      );

      if (appointment == null) {
        throw Exception('Randevu oluşturulamadı, lütfen tekrar deneyin.');
      }

      AppEventService.log('appointment_submit_success', properties: {
        'appointment_id': appointment.id,
      });

      state = state.copyWith(
        isLoading: false,
        selectedDate: null,
        selectedTime: null,
        availableTimes: const [],
      );

      return const CreateAppointmentResult(
        success: true,
        message: 'Randevunuz oluşturuldu!',
      );
    } catch (error) {
      AppEventService.log('appointment_submit_failed', properties: {
        'error': error.toString(),
      });

      state = state.copyWith(isLoading: false);

      return CreateAppointmentResult(
        success: false,
        message: 'Randevu oluşturulamadı: $error',
      );
    }
  }

  void applySlotSelection(AvailableSlot slot) {
    state = state.copyWith(
      selectedHospital: slot.hospital,
      selectedDoctor: slot.doctor,
      selectedDate: slot.date,
      selectedTime: slot.time,
      availableTimes: _getAvailableTimesForDoctor(
        doctor: slot.doctor,
        date: slot.date,
      ),
      filteredDoctors: _filterDoctors(
        doctors: state.allDoctors,
        hospital: slot.hospital,
        service: state.selectedService,
      ),
      filteredHospitals: _filterHospitals(
        hospitals: state.allHospitals,
        city: _getLocationInfo(slot.hospital)['city'],
        district: _getLocationInfo(slot.hospital)['district'],
      ),
    );
  }

  List<String> availableTimesFor(DateTime date) {
    if (state.selectedDoctor != null) {
      return _getAvailableTimesForDoctor(
        doctor: state.selectedDoctor!,
        date: date,
      );
    }
    return _getGeneralTimeSlots();
  }

  static List<Service> _sortServices(List<Service> services) {
    final sorted = [...services];
    sorted.sort((a, b) => a.name.compareTo(b.name));
    sorted.sort((a, b) {
      final aGeneral = _isGeneralService(a);
      final bGeneral = _isGeneralService(b);
      if (aGeneral == bGeneral) return 0;
      return aGeneral ? -1 : 1;
    });
    return sorted;
  }

  static List<Hospital> _filterHospitals({
    required List<Hospital> hospitals,
    required String? city,
    required String? district,
  }) {
    return hospitals.where((hospital) {
      final info = _getLocationInfo(hospital);
      final matchesCity = city == null || info['city'] == city;
      final matchesDistrict = district == null || info['district'] == district;
      return matchesCity && matchesDistrict;
    }).toList();
  }

  static List<Doctor> _filterDoctors({
    required List<Doctor> doctors,
    required Hospital? hospital,
    required Service? service,
  }) {
    if (hospital == null) return const [];
    final filtered =
        doctors.where((doctor) => doctor.hospitalId == hospital.id).toList();
    if (service == null) return filtered;
    return filtered
        .where(
          (doctor) =>
              doctor.services.isNotEmpty &&
              doctor.services.contains(service.id),
        )
        .toList();
  }

  static Map<String, String?> _getLocationInfo(Hospital hospital) {
    String? city = hospital.provinceName?.trim();
    String? district = hospital.districtName?.trim();

    if ((city?.isNotEmpty ?? false) || (district?.isNotEmpty ?? false)) {
      return {
        'city': (city?.isNotEmpty ?? false) ? city : '',
        'district': (district?.isNotEmpty ?? false) ? district : '',
      };
    }

    if (hospital.address.isNotEmpty) {
      final parts = hospital.address.split(',');
      if (parts.length >= 2) {
        city = parts.last.trim();
        district = parts[parts.length - 2].trim();
      } else if (parts.isNotEmpty) {
        district = parts.first.trim();
      }
    }

    return {
      'city': city ?? '',
      'district': district ?? '',
    };
  }

  static bool _matchesSelectedLocation(
    Hospital hospital,
    String? city,
    String? district,
  ) {
    final info = _getLocationInfo(hospital);
    final matchesCity = city == null || info['city'] == city;
    final matchesDistrict = district == null || info['district'] == district;
    return matchesCity && matchesDistrict;
  }

  static List<String> _getAvailableTimesForDoctor({
    required Doctor doctor,
    required DateTime date,
  }) {
    final dayOfWeek = _getDayOfWeek(date.weekday);
    final dynamic working = doctor.workingHours[dayOfWeek];
    if (working is! Map || working['isAvailable'] != true) {
      return _getGeneralTimeSlots();
    }
    final start = working['start']?.toString() ?? '09:00';
    final end = working['end']?.toString() ?? '17:00';
    final times = <String>[];
    var current = _parseTime(start);
    final endTime = _parseTime(end);
    while (current.compareTo(endTime) <= 0) {
      times.add(_formatTime(current));
      current = current.add(const Duration(minutes: 30));
    }
    return times;
  }

  static List<String> _getGeneralTimeSlots() {
    final times = <String>[];
    for (var hour = 9; hour < 17; hour++) {
      times.add('${hour.toString().padLeft(2, '0')}:00');
      times.add('${hour.toString().padLeft(2, '0')}:30');
    }
    times.add('17:00');
    return times;
  }

  static DateTime _combineDateAndTime(DateTime date, String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts.first) ?? 9;
    final minute = int.tryParse(parts[1]) ?? 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static bool _isTimeBooked({
    required Doctor doctor,
    required List<Appointment> appointments,
    required DateTime date,
    required String time,
  }) {
    final dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return appointments.any(
      (appointment) =>
          appointment.doctorId == doctor.id &&
          appointment.date == dateString &&
          appointment.time == time &&
          appointment.status != 'cancelled',
    );
  }

  static bool _isFormValid(CreateAppointmentState state) {
    return state.selectedCity != null &&
        state.selectedDistrict != null &&
        state.selectedHospital != null &&
        state.selectedDoctor != null &&
        state.selectedService != null &&
        state.selectedDate != null &&
        state.selectedTime != null;
  }

  static bool _isGeneralService(Service service) {
    final normalizedName = service.name.toLowerCase();
    return service.id == '1' || normalizedName.contains('genel');
  }

  static String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
        return 'tuesday';
      case DateTime.wednesday:
        return 'wednesday';
      case DateTime.thursday:
        return 'thursday';
      case DateTime.friday:
        return 'friday';
      case DateTime.saturday:
        return 'saturday';
      case DateTime.sunday:
      default:
        return 'sunday';
    }
  }

  static DateTime _parseTime(String value) {
    final parts = value.split(':');
    final hour = int.tryParse(parts[0]) ?? 9;
    final minute = int.tryParse(parts.elementAtOrNull(1) ?? '0') ?? 0;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class AvailableSlot {
  final Hospital hospital;
  final Doctor doctor;
  final DateTime date;
  final String time;

  const AvailableSlot({
    required this.hospital,
    required this.doctor,
    required this.date,
    required this.time,
  });
}

final createAppointmentControllerProvider = StateNotifierProvider<
    CreateAppointmentController, CreateAppointmentState>(
  (ref) => CreateAppointmentController(),
);

