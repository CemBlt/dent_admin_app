import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/doctor.dart';
import '../models/hospital.dart';
import '../services/json_service.dart';
import '../widgets/image_widget.dart';
import 'doctor_detail_screen.dart';

class AllDoctorsScreen extends StatefulWidget {
  const AllDoctorsScreen({super.key});

  @override
  State<AllDoctorsScreen> createState() => _AllDoctorsScreenState();
}

class _AllDoctorsScreenState extends State<AllDoctorsScreen> {
  List<Doctor> _allDoctors = [];
  List<Doctor> _filteredDoctors = [];
  List<Hospital> _hospitals = [];
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'name'; // rating, name
  String? _selectedProvince;
  String? _selectedDistrict;
  bool _isLoading = true;
  // Doktor ID -> {reviewCount, averageRating}
  Map<String, Map<String, dynamic>> _doctorRatings = {};
  
  // Pagination
  static const int _itemsPerPage = 20;
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMoreItems = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData();
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
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    if (_isLoadingMore || !_hasMoreItems) return;

    final totalItems = _filteredDoctors.length;
    final displayedItems = (_currentPage + 1) * _itemsPerPage;

    if (displayedItems >= totalItems) {
      setState(() {
        _hasMoreItems = false;
      });
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    // Simüle edilmiş yükleme (gerçek uygulamada API çağrısı yapılabilir)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _currentPage++;
          _isLoadingMore = false;
        });
      }
    });
  }

  List<Doctor> get _displayedDoctors {
    final endIndex = ((_currentPage + 1) * _itemsPerPage).clamp(0, _filteredDoctors.length);
    return _filteredDoctors.take(endIndex).toList();
  }

  Future<void> _loadData() async {
    final doctors = await JsonService.getDoctors();
    final hospitals = await JsonService.getHospitals();

    // Alfabetik sırala
    doctors.sort((a, b) => a.fullName.compareTo(b.fullName));

    // Her doktor için yorum sayısı ve ortalama puanı yükle
    final doctorRatingsMap = <String, Map<String, dynamic>>{};
    for (final doctor in doctors) {
      try {
        final reviews = await JsonService.getReviewsByDoctor(doctor.id);
        final averageRating = await JsonService.getDoctorAverageRating(doctor.id);
        doctorRatingsMap[doctor.id] = {
          'reviewCount': reviews.length,
          'averageRating': averageRating,
        };
      } catch (e) {
        doctorRatingsMap[doctor.id] = {
          'reviewCount': 0,
          'averageRating': 0.0,
        };
      }
    }

    setState(() {
      _allDoctors = doctors;
      _hospitals = hospitals;
      _filteredDoctors = doctors;
      _doctorRatings = doctorRatingsMap;
      _isLoading = false;
    });
    _applyFilters();
  }

  void _onSearchChanged(String query) {
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredDoctors = _allDoctors.where((doctor) {
        // Arama filtresi
        final searchQuery = _searchController.text.toLowerCase();
        if (searchQuery.isNotEmpty) {
          final hospital = _getHospitalByDoctor(doctor);
          final matchesSearch = doctor.fullName.toLowerCase().contains(searchQuery) ||
              (hospital != null && hospital.name.toLowerCase().contains(searchQuery));
          if (!matchesSearch) return false;
        }

        // İl filtresi (doktorun hastanesinin il bilgisine göre)
        if (_selectedProvince != null) {
          final hospital = _getHospitalByDoctor(doctor);
          if (hospital == null || hospital.provinceName != _selectedProvince) {
            return false;
          }
        }

        // İlçe filtresi (doktorun hastanesinin ilçe bilgisine göre)
        if (_selectedDistrict != null) {
          final hospital = _getHospitalByDoctor(doctor);
          if (hospital == null || hospital.districtName != _selectedDistrict) {
            return false;
          }
        }

        return true;
      }).toList();
      _applySorting();
      // Filtre değiştiğinde pagination'ı sıfırla
      _currentPage = 0;
      _hasMoreItems = _filteredDoctors.length > _itemsPerPage;
    });
  }

  Widget _buildDoctorRatingBadge(String doctorId) {
    final ratingData = _doctorRatings[doctorId];
    if (ratingData == null) return const SizedBox.shrink();
    
    final reviewCount = ratingData['reviewCount'] as int;
    final averageRating = ratingData['averageRating'] as double;
    
    // Eğer yorum yoksa gösterme
    if (reviewCount == 0 || averageRating == 0.0) return const SizedBox.shrink();
    
    return Container(
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
            averageRating.toStringAsFixed(1),
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _applySorting() {
    setState(() {
      switch (_sortBy) {
        case 'rating':
          _filteredDoctors.sort((a, b) {
            final ratingA = _doctorRatings[a.id]?['averageRating'] as double? ?? 0.0;
            final ratingB = _doctorRatings[b.id]?['averageRating'] as double? ?? 0.0;
            return ratingB.compareTo(ratingA); // Yüksekten düşüğe
          });
          break;
        case 'name':
          _filteredDoctors.sort((a, b) => a.fullName.compareTo(b.fullName));
          break;
      }
    });
  }

  List<String> _getProvinces() {
    final provinces = _allDoctors
        .map((d) => _getHospitalByDoctor(d))
        .where((h) => h != null && h.provinceName != null)
        .map((h) => h!.provinceName!)
        .toSet()
        .toList();
    provinces.sort();
    return provinces;
  }

  List<String> _getDistricts() {
    if (_selectedProvince == null) return [];
    final districts = _allDoctors
        .map((d) => _getHospitalByDoctor(d))
        .where((h) => h != null && h.provinceName == _selectedProvince && h.districtName != null)
        .map((h) => h!.districtName!)
        .toSet()
        .toList();
    districts.sort();
    return districts;
  }

  void _showProvinceFilter() {
    final provinces = _getProvinces();
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
                  fontWeight: _selectedProvince == null ? FontWeight.bold : FontWeight.normal,
                  color: _selectedProvince == null ? AppTheme.tealBlue : AppTheme.darkText,
                ),
              ),
              trailing: _selectedProvince == null
                  ? Icon(Icons.check, color: AppTheme.tealBlue)
                  : null,
              onTap: () {
                setState(() {
                  _selectedProvince = null;
                  _selectedDistrict = null;
                });
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            ...provinces.map((province) => ListTile(
                  leading: Icon(Icons.location_city, color: AppTheme.iconGray),
                  title: Text(
                    province,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: _selectedProvince == province ? FontWeight.bold : FontWeight.normal,
                      color: _selectedProvince == province ? AppTheme.tealBlue : AppTheme.darkText,
                    ),
                  ),
                  trailing: _selectedProvince == province
                      ? Icon(Icons.check, color: AppTheme.tealBlue)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedProvince = province;
                      _selectedDistrict = null;
                    });
                    _applyFilters();
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showDistrictFilter() {
    final districts = _getDistricts();
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
                  fontWeight: _selectedDistrict == null ? FontWeight.bold : FontWeight.normal,
                  color: _selectedDistrict == null ? AppTheme.tealBlue : AppTheme.darkText,
                ),
              ),
              trailing: _selectedDistrict == null
                  ? Icon(Icons.check, color: AppTheme.tealBlue)
                  : null,
              onTap: () {
                setState(() {
                  _selectedDistrict = null;
                });
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            ...districts.map((district) => ListTile(
                  leading: Icon(Icons.location_on, color: AppTheme.iconGray),
                  title: Text(
                    district,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: _selectedDistrict == district ? FontWeight.bold : FontWeight.normal,
                      color: _selectedDistrict == district ? AppTheme.tealBlue : AppTheme.darkText,
                    ),
                  ),
                  trailing: _selectedDistrict == district
                      ? Icon(Icons.check, color: AppTheme.tealBlue)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedDistrict = district;
                    });
                    _applyFilters();
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showSortOptions() {
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
            _buildSortOption('name', 'Alfabetik', Icons.sort_by_alpha),
            _buildSortOption('rating', 'En Yüksek Puan', Icons.star),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String value, String label, IconData icon) {
    final isSelected = _sortBy == value;
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
        setState(() {
          _sortBy = value;
        });
        _applySorting();
        Navigator.pop(context);
      },
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'rating':
        return 'En Yüksek Puan';
      case 'name':
        return 'Alfabetik';
      default:
        return 'Sırala';
    }
  }

  Hospital? _getHospitalByDoctor(Doctor doctor) {
    try {
      return _hospitals.firstWhere((h) => h.id == doctor.hospitalId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: _isLoading
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
                                  '${_filteredDoctors.length} doktor bulundu',
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
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear_rounded, color: AppTheme.iconGray),
                                        onPressed: () {
                                          setState(() {
                                            _searchController.clear();
                                            _onSearchChanged('');
                                          });
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                              ),
                              onChanged: _onSearchChanged,
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
                                      onTap: _showProvinceFilter,
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
                                                _selectedProvince ?? 'İl',
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
                                      onTap: _showDistrictFilter,
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
                                                _selectedDistrict ?? 'İlçe',
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
                                    onTap: _showSortOptions,
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
                                              _getSortLabel(),
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
                      child: _filteredDoctors.isEmpty
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
                                  if (_searchController.text.isNotEmpty)
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
                              onRefresh: _loadData,
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(20),
                                itemCount: _displayedDoctors.length + (_hasMoreItems ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _displayedDoctors.length) {
                                    // Loading indicator
                                    return Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: AppTheme.tealBlue,
                                        ),
                                      ),
                                    );
                                  }
                                  final doctor = _displayedDoctors[index];
                                  return _buildDoctorCard(doctor);
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

  Widget _buildDoctorCard(Doctor doctor) {
    final hospital = _getHospitalByDoctor(doctor);

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
                            if (_doctorRatings.containsKey(doctor.id))
                              _buildDoctorRatingBadge(doctor.id),
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
}

