import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/doctor.dart';
import '../models/hospital.dart';
import '../services/json_service.dart';

class DoctorsDirectoryState {
  final bool isLoading;
  final List<Doctor> allDoctors;
  final List<Doctor> filteredDoctors;
  final List<Hospital> hospitals;
  final String searchQuery;
  final String sortBy;
  final String? selectedProvince;
  final String? selectedDistrict;
  final int currentPage;
  final bool isLoadingMore;
  final bool hasMoreItems;
  final String? errorMessage;

  const DoctorsDirectoryState({
    required this.isLoading,
    required this.allDoctors,
    required this.filteredDoctors,
    required this.hospitals,
    required this.searchQuery,
    required this.sortBy,
    required this.selectedProvince,
    required this.selectedDistrict,
    required this.currentPage,
    required this.isLoadingMore,
    required this.hasMoreItems,
    this.errorMessage,
  });

  factory DoctorsDirectoryState.initial() => const DoctorsDirectoryState(
        isLoading: true,
        allDoctors: [],
        filteredDoctors: [],
        hospitals: [],
        searchQuery: '',
        sortBy: 'name',
        selectedProvince: null,
        selectedDistrict: null,
        currentPage: 0,
        isLoadingMore: false,
        hasMoreItems: true,
      );

  DoctorsDirectoryState copyWith({
    bool? isLoading,
    List<Doctor>? allDoctors,
    List<Doctor>? filteredDoctors,
    List<Hospital>? hospitals,
    String? searchQuery,
    String? sortBy,
    String? selectedProvince,
    String? selectedDistrict,
    int? currentPage,
    bool? isLoadingMore,
    bool? hasMoreItems,
    String? errorMessage,
  }) {
    return DoctorsDirectoryState(
      isLoading: isLoading ?? this.isLoading,
      allDoctors: allDoctors ?? this.allDoctors,
      filteredDoctors: filteredDoctors ?? this.filteredDoctors,
      hospitals: hospitals ?? this.hospitals,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      selectedProvince: selectedProvince ?? this.selectedProvince,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreItems: hasMoreItems ?? this.hasMoreItems,
      errorMessage: errorMessage,
    );
  }
}

class DoctorsDirectoryController
    extends StateNotifier<DoctorsDirectoryState> {
  DoctorsDirectoryController() : super(DoctorsDirectoryState.initial()) {
    loadDoctors();
  }

  static const int itemsPerPage = 20;

  List<Doctor> get displayedDoctors {
    final endIndex =
        ((state.currentPage + 1) * itemsPerPage).clamp(0, state.filteredDoctors.length);
    return state.filteredDoctors.take(endIndex).toList();
  }

  List<String> get provinces {
    final list = state.hospitals
        .where((h) => (h.provinceName ?? '').isNotEmpty)
        .map((h) => h.provinceName!.trim())
        .toSet()
        .toList();
    list.sort();
    return list;
  }

  List<String> get districts {
    if (state.selectedProvince == null) return const [];
    final list = state.hospitals
        .where((h) =>
            h.provinceName == state.selectedProvince &&
            (h.districtName ?? '').isNotEmpty)
        .map((h) => h.districtName!.trim())
        .toSet()
        .toList();
    list.sort();
    return list;
  }

  Future<void> loadDoctors() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final doctors = await JsonService.getDoctors();
      final hospitals = await JsonService.getHospitals();
      doctors.sort((a, b) => a.fullName.compareTo(b.fullName));

      state = state.copyWith(
        allDoctors: doctors,
        hospitals: hospitals,
        filteredDoctors: doctors,
        isLoading: false,
        currentPage: 0,
        hasMoreItems: doctors.length > itemsPerPage,
      );
      _applyFilters(resetPage: true);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  void updateSearch(String query) {
    if (query == state.searchQuery) return;
    state = state.copyWith(searchQuery: query);
    _applyFilters(resetPage: true);
  }

  void selectProvince(String? province) {
    state = state.copyWith(
      selectedProvince: province,
      selectedDistrict: null,
    );
    _applyFilters(resetPage: true);
  }

  void selectDistrict(String? district) {
    state = state.copyWith(selectedDistrict: district);
    _applyFilters(resetPage: true);
  }

  void updateSort(String sortBy) {
    if (sortBy == state.sortBy) return;
    state = state.copyWith(sortBy: sortBy);
    _applySorting();
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMoreItems || state.isLoading) return;
    final nextPage = state.currentPage + 1;
    final hasMore =
        (nextPage + 1) * itemsPerPage < state.filteredDoctors.length;

    state = state.copyWith(isLoadingMore: true);

    await Future.delayed(const Duration(milliseconds: 200));

    state = state.copyWith(
      currentPage: nextPage,
      isLoadingMore: false,
      hasMoreItems: hasMore,
    );
  }

  Hospital? hospitalFor(String hospitalId) {
    try {
      return state.hospitals.firstWhere((h) => h.id == hospitalId);
    } catch (_) {
      return null;
    }
  }

  void _applyFilters({required bool resetPage}) {
    var filtered = state.allDoctors.where((doctor) {
      if (state.searchQuery.isNotEmpty) {
        final query = state.searchQuery.toLowerCase();
        final hospital = hospitalFor(doctor.hospitalId);
        final matchesSearch = doctor.fullName.toLowerCase().contains(query) ||
            (hospital != null &&
                hospital.name.toLowerCase().contains(query));
        if (!matchesSearch) return false;
      }

      if (state.selectedProvince != null) {
        final hospital = hospitalFor(doctor.hospitalId);
        if (hospital == null ||
            hospital.provinceName != state.selectedProvince) {
          return false;
        }
      }

      if (state.selectedDistrict != null) {
        final hospital = hospitalFor(doctor.hospitalId);
        if (hospital == null ||
            hospital.districtName != state.selectedDistrict) {
          return false;
        }
      }

      return true;
    }).toList();

    filtered = _sortDoctors(filtered, state.sortBy);

    state = state.copyWith(
      filteredDoctors: filtered,
      currentPage: resetPage ? 0 : state.currentPage,
      hasMoreItems: filtered.length > itemsPerPage,
    );
  }

  void _applySorting() {
    final sorted = _sortDoctors(
      List<Doctor>.from(state.filteredDoctors),
      state.sortBy,
    );
    state = state.copyWith(filteredDoctors: sorted);
  }

  List<Doctor> _sortDoctors(List<Doctor> doctors, String sortBy) {
    switch (sortBy) {
      case 'rating':
        doctors.sort((a, b) => b.fullName.compareTo(a.fullName));
        break;
      case 'name':
      default:
        doctors.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
    }
    return doctors;
  }
}

final doctorsDirectoryProvider =
    StateNotifierProvider<DoctorsDirectoryController, DoctorsDirectoryState>(
  (ref) => DoctorsDirectoryController(),
);

