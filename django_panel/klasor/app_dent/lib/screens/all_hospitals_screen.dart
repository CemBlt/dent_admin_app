import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/hospital.dart';
import '../providers/hospitals_directory_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/hospital_logo.dart';
import 'hospital_detail_screen.dart';

class AllHospitalsScreen extends ConsumerStatefulWidget {
  const AllHospitalsScreen({super.key});

  @override
  ConsumerState<AllHospitalsScreen> createState() => _AllHospitalsScreenState();
}

class _AllHospitalsScreenState extends ConsumerState<AllHospitalsScreen> {
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
      ref.read(hospitalsDirectoryProvider.notifier).loadMore();
    }
  }

  // Uzaklık değerini sayısal olarak döndür
  double _getDistanceValue(Hospital hospital) {
    final distances = {
      '1': 1.2,
      '2': 0.8,
      '3': 2.5,
    };
    return distances[hospital.id] ?? 1.6;
  }

  // Uzaklık hesaplama (string formatında)
  String _getDistance(Hospital hospital) {
    final distance = _getDistanceValue(hospital);
    return '${distance.toStringAsFixed(1)} km';
  }

  /// Bugünün gününü İngilizce gün adına çevirir (monday, tuesday, vb.)
  String _getTodayDayName() {
    final now = DateTime.now();
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    // DateTime.now().weekday: 1=Pazartesi, 7=Pazar
    return days[now.weekday - 1];
  }

  /// Hastane için bugünün çalışma saatlerini ve durumunu döndürür
  Map<String, dynamic> _getTodayWorkingHours(Hospital hospital) {
    if (hospital.isOpen24Hours) {
      return {
        'isOpen': true,
        'is24Hours': true,
        'text': '7/24 Açık',
      };
    }

    final today = _getTodayDayName();
    final todayHours = hospital.workingHours[today] as Map<String, dynamic>?;
    
    if (todayHours == null || todayHours['isAvailable'] != true) {
      // Bugün kapalı, yarın açık mı kontrol et
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
      final tomorrowDayName = tomorrowDays[tomorrow.weekday - 1];
      final tomorrowHours = hospital.workingHours[tomorrowDayName] as Map<String, dynamic>?;
      
      if (tomorrowHours != null && tomorrowHours['isAvailable'] == true) {
        final start = tomorrowHours['start'] as String?;
        if (start != null) {
          return {
            'isOpen': false,
            'is24Hours': false,
            'text': 'Kapalı - Yarın $start',
          };
        }
      }
      
      return {
        'isOpen': false,
        'is24Hours': false,
        'text': 'Kapalı',
      };
    }

    final start = todayHours['start'] as String?;
    final end = todayHours['end'] as String?;
    
    if (start == null || end == null) {
      return {
        'isOpen': false,
        'is24Hours': false,
        'text': 'Kapalı',
      };
    }

    // Şu an açık mı kontrol et
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final isCurrentlyOpen = currentTime.compareTo(start) >= 0 && currentTime.compareTo(end) < 0;

    if (isCurrentlyOpen) {
      return {
        'isOpen': true,
        'is24Hours': false,
        'text': 'Açık - $end\'e kadar',
      };
    } else {
      // Bugün açık ama şu an kapalı (henüz açılmadı veya kapandı)
      if (currentTime.compareTo(start) < 0) {
        return {
          'isOpen': false,
          'is24Hours': false,
          'text': 'Kapalı - $start\'da açılır',
        };
      } else {
        return {
          'isOpen': false,
          'is24Hours': false,
          'text': 'Kapalı - Yarın $start',
        };
      }
    }
  }

  /// Çalışma saatleri badge'ini oluşturur
  Widget _buildWorkingHoursBadge(Hospital hospital) {
    final hoursInfo = _getTodayWorkingHours(hospital);
    
    if (hoursInfo['is24Hours'] == true) {
      // 7/24 Açık
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.tealBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, size: 12, color: AppTheme.tealBlue),
            const SizedBox(width: 4),
            Text(
              hoursInfo['text'] as String,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.tealBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else if (hoursInfo['isOpen'] == true) {
      // Açık - saat'e kadar
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, size: 12, color: Colors.green.shade700),
            const SizedBox(width: 4),
            Text(
              hoursInfo['text'] as String,
              style: AppTheme.bodySmall.copyWith(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else {
      // Kapalı
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, size: 12, color: Colors.red.shade700),
            const SizedBox(width: 4),
            Text(
              hoursInfo['text'] as String,
              style: AppTheme.bodySmall.copyWith(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showProvinceFilter(
    HospitalsDirectoryController controller,
    HospitalsDirectoryState state,
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
    HospitalsDirectoryController controller,
    HospitalsDirectoryState state,
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
    HospitalsDirectoryController controller,
    HospitalsDirectoryState state,
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
            _buildSortOption(state, controller, 'distance', 'En Yakın', Icons.near_me),
            _buildSortOption(state, controller, 'rating', 'En Yüksek Puan', Icons.star),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(
    HospitalsDirectoryState state,
    HospitalsDirectoryController controller,
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
      case 'distance':
        return 'En Yakın';
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
    final state = ref.watch(hospitalsDirectoryProvider);
    final controller = ref.read(hospitalsDirectoryProvider.notifier);
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
                                  'Tüm Hastaneler',
                                  style: AppTheme.headingLarge.copyWith(
                                    color: AppTheme.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${state.filteredHospitals.length} hastane bulundu',
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
                                hintText: 'Hastane ara...',
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
                    // Hastane Listesi
                    Expanded(
                      child: state.filteredHospitals.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.local_hospital_outlined,
                                    size: 64,
                                    color: AppTheme.iconGray,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Hastane bulunamadı',
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
                              onRefresh: controller.loadHospitals,
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(20),
                                itemCount: controller.displayedHospitals.length +
                                    (state.hasMoreItems ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == controller.displayedHospitals.length) {
                                    return Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: AppTheme.tealBlue,
                                        ),
                                      ),
                                    );
                                  }
                                  final hospital = controller.displayedHospitals[index];
                                  return _buildHospitalCard(hospital);
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

  Widget _buildHospitalCard(Hospital hospital) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                builder: (context) => HospitalDetailScreen(
                  hospital: hospital,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Hastane Görseli
                Stack(
                  children: [
                    HospitalLogo(imageUrl: hospital.image, size: 84),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 12, color: Colors.white),
                            const SizedBox(width: 2),
                            Text(
                              '4.5',
                              style: AppTheme.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Hastane Bilgileri
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hospital.name,
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: AppTheme.iconGray,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      hospital.address,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.grayText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTurquoise,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.near_me_rounded, size: 12, color: AppTheme.tealBlue),
                        const SizedBox(width: 4),
                        Text(
                          _getDistance(hospital),
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.tealBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildWorkingHoursBadge(hospital),
                ],
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

