import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/hospital.dart';
import '../services/json_service.dart';

class HospitalsDirectoryState {
  final bool isLoading;
  final List<Hospital> allHospitals;
  final List<Hospital> filteredHospitals;
  final String searchQuery;
  final String sortBy;
  final String? selectedProvince;
  final String? selectedDistrict;
  final int currentPage;
  final bool isLoadingMore;
  final bool hasMoreItems;
  final String? errorMessage;

  const HospitalsDirectoryState({
    required this.isLoading,
    required this.allHospitals,
    required this.filteredHospitals,
    required this.searchQuery,
    required this.sortBy,
    required this.selectedProvince,
    required this.selectedDistrict,
    required this.currentPage,
    required this.isLoadingMore,
    required this.hasMoreItems,
    this.errorMessage,
  });

  factory HospitalsDirectoryState.initial() => const HospitalsDirectoryState(
        isLoading: true,
        allHospitals: [],
        filteredHospitals: [],
        searchQuery: '',
        sortBy: 'name',
        selectedProvince: null,
        selectedDistrict: null,
        currentPage: 0,
        isLoadingMore: false,
        hasMoreItems: true,
      );

  HospitalsDirectoryState copyWith({
    bool? isLoading,
    List<Hospital>? allHospitals,
    List<Hospital>? filteredHospitals,
    String? searchQuery,
    String? sortBy,
    String? selectedProvince,
    String? selectedDistrict,
    int? currentPage,
    bool? isLoadingMore,
    bool? hasMoreItems,
    String? errorMessage,
  }) {
    return HospitalsDirectoryState(
      isLoading: isLoading ?? this.isLoading,
      allHospitals: allHospitals ?? this.allHospitals,
      filteredHospitals: filteredHospitals ?? this.filteredHospitals,
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

class HospitalsDirectoryController
    extends StateNotifier<HospitalsDirectoryState> {
  HospitalsDirectoryController() : super(HospitalsDirectoryState.initial()) {
    loadHospitals();
  }

  static const int itemsPerPage = 20;

  List<Hospital> get displayedHospitals {
    final endIndex =
        ((state.currentPage + 1) * itemsPerPage).clamp(0, state.filteredHospitals.length);
    return state.filteredHospitals.take(endIndex).toList();
  }

  List<String> get provinces {
    final list = state.allHospitals
        .where((h) => (h.provinceName ?? '').isNotEmpty)
        .map((h) => h.provinceName!.trim())
        .toSet()
        .toList();
    list.sort();
    return list;
  }

  List<String> get districts {
    if (state.selectedProvince == null) return const [];
    final list = state.allHospitals
        .where((h) =>
            h.provinceName == state.selectedProvince &&
            (h.districtName ?? '').isNotEmpty)
        .map((h) => h.districtName!.trim())
        .toSet()
        .toList();
    list.sort();
    return list;
  }

  Future<void> loadHospitals() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final hospitals = await JsonService.getHospitals();
      hospitals.sort((a, b) => a.name.compareTo(b.name));
      state = state.copyWith(
        allHospitals: hospitals,
        filteredHospitals: hospitals,
        isLoading: false,
        currentPage: 0,
        hasMoreItems: hospitals.length > itemsPerPage,
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
        (nextPage + 1) * itemsPerPage < state.filteredHospitals.length;

    state = state.copyWith(
      isLoadingMore: true,
    );

    await Future.delayed(const Duration(milliseconds: 200));

    state = state.copyWith(
      currentPage: nextPage,
      isLoadingMore: false,
      hasMoreItems: hasMore,
    );
  }

  void clearFilters() {
    state = state.copyWith(
      selectedProvince: null,
      selectedDistrict: null,
    );
    _applyFilters(resetPage: true);
  }

  void _applyFilters({required bool resetPage}) {
    var filtered = state.allHospitals.where((hospital) {
      if (state.searchQuery.isNotEmpty) {
        final query = state.searchQuery.toLowerCase();
        final matchesSearch =
            hospital.name.toLowerCase().contains(query) ||
            hospital.address.toLowerCase().contains(query);
        if (!matchesSearch) return false;
      }

      if (state.selectedProvince != null &&
          hospital.provinceName != state.selectedProvince) {
        return false;
      }

      if (state.selectedDistrict != null &&
          hospital.districtName != state.selectedDistrict) {
        return false;
      }

      return true;
    }).toList();

    filtered = _sortHospitals(filtered, state.sortBy);

    state = state.copyWith(
      filteredHospitals: filtered,
      currentPage: resetPage ? 0 : state.currentPage,
      hasMoreItems: filtered.length > itemsPerPage,
    );
  }

  void _applySorting() {
    final sorted = _sortHospitals(
      List<Hospital>.from(state.filteredHospitals),
      state.sortBy,
    );
    state = state.copyWith(filteredHospitals: sorted);
  }

  List<Hospital> _sortHospitals(List<Hospital> hospitals, String sortBy) {
    switch (sortBy) {
      case 'distance':
        hospitals.sort(
          (a, b) => _getMockDistance(a).compareTo(_getMockDistance(b)),
        );
        break;
      case 'rating':
        hospitals.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'name':
      default:
        hospitals.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    return hospitals;
  }

  double _getMockDistance(Hospital hospital) {
    final distances = {
      '1': 1.2,
      '2': 0.8,
      '3': 2.5,
    };
    return distances[hospital.id] ?? 1.6;
  }
}

final hospitalsDirectoryProvider = StateNotifierProvider<
    HospitalsDirectoryController, HospitalsDirectoryState>(
  (ref) => HospitalsDirectoryController(),
);

