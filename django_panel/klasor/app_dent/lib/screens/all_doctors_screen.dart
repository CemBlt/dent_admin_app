import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/doctor.dart';
import '../models/hospital.dart';
import '../providers/doctors_directory_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/image_widget.dart';
import 'doctor_detail_screen.dart';

class AllDoctorsScreen extends ConsumerStatefulWidget {
  const AllDoctorsScreen({super.key});

  @override
  ConsumerState<AllDoctorsScreen> createState() => _AllDoctorsScreenState();
}

class _AllDoctorsScreenState extends ConsumerState<AllDoctorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(doctorsDirectoryProvider.notifier).loadMore();
    }
  }

  void _showProvinceFilter(
    DoctorsDirectoryController controller,
    DoctorsDirectoryState state,
  ) {
    final provinces = controller.provinces;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'İl Seçiniz',
              style: AppTheme.headingSmall,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.clear, color: AppTheme.iconGray),
              title: Text(
                'Tümü',
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: state.selectedProvince == null ? FontWeight.bold : FontWeight.normal,
                  color: state.selectedProvince == null ? AppTheme.tealBlue : AppTheme.darkText,
                ),
              ),
              trailing: state.selectedProvince == null
                  ? Icon(Icons.check, color: AppTheme.tealBlue)
                  : null,
              onTap: () {
                controller.selectProvince(null);
                Navigator.pop(context);
              },
            ),
            ...provinces.map((province) => ListTile(
                  leading: Icon(Icons.location_city, color: AppTheme.iconGray),
                  title: Text(
                    province,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: state.selectedProvince == province ? FontWeight.bold : FontWeight.normal,
                      color: state.selectedProvince == province ? AppTheme.tealBlue : AppTheme.darkText,
                    ),
                  ),
                  trailing: state.selectedProvince == province
                      ? Icon(Icons.check, color: AppTheme.tealBlue)
                      : null,
                  onTap: () {
                    controller.selectProvince(province);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showDistrictFilter(
    DoctorsDirectoryController controller,
    DoctorsDirectoryState state,
  ) {
    final districts = controller.districts;
    if (districts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce bir il seçiniz')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'İlçe Seçiniz',
              style: AppTheme.headingSmall,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.clear, color: AppTheme.iconGray),
              title: Text(
                'Tümü',
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: state.selectedDistrict == null ? FontWeight.bold : FontWeight.normal,
                  color: state.selectedDistrict == null ? AppTheme.tealBlue : AppTheme.darkText,
                ),
              ),
              trailing: state.selectedDistrict == null
                  ? Icon(Icons.check, color: AppTheme.tealBlue)
                  : null,
              onTap: () {
                controller.selectDistrict(null);
                Navigator.pop(context);
              },
            ),
            ...districts.map((district) => ListTile(
                  leading: Icon(Icons.location_on, color: AppTheme.iconGray),
                  title: Text(
                    district,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: state.selectedDistrict == district ? FontWeight.bold : FontWeight.normal,
                      color: state.selectedDistrict == district ? AppTheme.tealBlue : AppTheme.darkText,
                    ),
                  ),
                  trailing: state.selectedDistrict == district
                      ? Icon(Icons.check, color: AppTheme.tealBlue)
                      : null,
                  onTap: () {
                    controller.selectDistrict(district);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showSortOptions(
    DoctorsDirectoryController controller,
    DoctorsDirectoryState state,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sıralama',
              style: AppTheme.headingSmall,
            ),
            const SizedBox(height: 20),
            _buildSortOption(state, controller, 'name', 'Alfabetik', Icons.sort_by_alpha),
            _buildSortOption(state, controller, 'rating', 'En Yüksek Puan', Icons.star),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(
    DoctorsDirectoryState state,
    DoctorsDirectoryController controller,
    String value,
    String label,
    IconData icon,
  ) {
    final isSelected = state.sortBy == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.tealBlue : AppTheme.iconGray),
      title: Text(
        label,
        style: AppTheme.bodyMedium.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.tealBlue : AppTheme.darkText,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: AppTheme.tealBlue)
          : null,
      onTap: () {
        controller.updateSort(value);
        Navigator.pop(context);
      },
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'rating':
        return 'En Yüksek Puan';
      case 'name':
        return 'Alfabetik';
      default:
        return 'Sırala';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(doctorsDirectoryProvider);
    final controller = ref.read(doctorsDirectoryProvider.notifier);
    _syncSearchField(state.searchQuery);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundLight,
              AppTheme.lightTurquoise.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.tealBlue.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tüm Doktorlar',
                                  style: AppTheme.headingLarge.copyWith(
                                    color: AppTheme.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${state.filteredDoctors.length} doktor bulundu',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Arama ve Sıralama
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Arama Kutusu
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.tealBlue.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Doktor ara...',
                                hintStyle: TextStyle(color: AppTheme.iconGray),
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.cardGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.search_rounded, color: AppTheme.tealBlue, size: 20),
                                ),
                                suffixIcon: state.searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear_rounded, color: AppTheme.iconGray),
                                        onPressed: () {
                                          controller.updateSearch('');
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                              ),
                              onChanged: controller.updateSearch,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Filtre ve Sıralama Butonları
                          Row(
                            children: [
                              // İl Filtresi
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppTheme.dividerLight,
                                      width: 1,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () =>
                                          _showProvinceFilter(controller, state),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.location_city_rounded,
                                              color: AppTheme.darkText,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                state.selectedProvince ?? 'İl',
                                                style: AppTheme.bodySmall.copyWith(
                                                  color: AppTheme.darkText,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            Icon(
                                              Icons.arrow_drop_down_rounded,
                                              color: AppTheme.darkText,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // İlçe Filtresi
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppTheme.dividerLight,
                                      width: 1,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () =>
                                          _showDistrictFilter(controller, state),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.location_on_rounded,
                                              color: AppTheme.darkText,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                state.selectedDistrict ?? 'İlçe',
                                                style: AppTheme.bodySmall.copyWith(
                                                  color: AppTheme.darkText,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            Icon(
                                              Icons.arrow_drop_down_rounded,
                                              color: AppTheme.darkText,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Sıralama Butonu
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.lightTurquoise.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () =>
                                        _showSortOptions(controller, state),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.tune_rounded,
                                            color: AppTheme.darkText,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              _getSortLabel(state.sortBy),
                                              style: AppTheme.bodySmall.copyWith(
                                                color: AppTheme.darkText,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          Icon(
                                            Icons.arrow_drop_down_rounded,
                                            color: AppTheme.darkText,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Doktor Listesi
                    Expanded(
                      child: state.filteredDoctors.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 64,
                                    color: AppTheme.iconGray,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Doktor bulunamadı',
                                    style: AppTheme.bodyLarge.copyWith(
                                      color: AppTheme.grayText,
                                    ),
                                  ),
                                  if (state.searchQuery.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Arama kriterlerinizi değiştirmeyi deneyin',
                                        style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.grayText,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: controller.loadDoctors,
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(20),
                                itemCount: controller.displayedDoctors.length +
                                    (state.hasMoreItems ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == controller.displayedDoctors.length) {
                                    return Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: AppTheme.tealBlue,
                                        ),
                                      ),
                                    );
                                  }
                                  final doctor = controller.displayedDoctors[index];
                                  final hospital =
                                      controller.hospitalFor(doctor.hospitalId);
                                  return _buildDoctorCard(doctor, hospital);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor, Hospital? hospital) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.tealBlue.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DoctorDetailScreen(
                    doctor: doctor,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  // Doktor Fotoğrafı
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: AppTheme.cardGradient,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: doctor.image != null
                          ? buildImage(
                              doctor.image!,
                              fit: BoxFit.cover,
                              width: 76,
                              height: 76,
                              errorWidget: Icon(
                                Icons.person_rounded,
                                size: 36,
                                color: AppTheme.tealBlue,
                              ),
                            )
                          : Icon(
                              Icons.person_rounded,
                              size: 36,
                              color: AppTheme.tealBlue,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Doktor Bilgileri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                doctor.fullName,
                                style: AppTheme.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.lightTurquoise,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, size: 14, color: AppTheme.accentYellow),
                                  const SizedBox(width: 2),
                                  Text(
                                    '4.8',
                                    style: AppTheme.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (hospital != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.local_hospital_rounded,
                                size: 14,
                                color: AppTheme.iconGray,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  hospital.name,
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.grayText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.inputFieldGray,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule_rounded, size: 12, color: AppTheme.iconGray),
                              const SizedBox(width: 6),
                              Text(
                                'Müsait randevu: Bugün',
                                style: AppTheme.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.iconGray,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _syncSearchField(String value) {
    if (_searchController.text == value) return;
    _searchController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}

