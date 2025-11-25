import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/hospital.dart';
import '../services/json_service.dart';
import '../widgets/image_widget.dart';
import 'hospital_detail_screen.dart';

class AllHospitalsScreen extends StatefulWidget {
  const AllHospitalsScreen({super.key});

  @override
  State<AllHospitalsScreen> createState() => _AllHospitalsScreenState();
}

class _AllHospitalsScreenState extends State<AllHospitalsScreen> {
  List<Hospital> _allHospitals = [];
  List<Hospital> _filteredHospitals = [];
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'distance'; // distance, rating, name
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final hospitals = await JsonService.getHospitals();

    // Maksimum 10km uzaklıktaki hastaneleri filtrele
    final nearbyHospitals = hospitals.where((hospital) {
      final distance = _getDistanceValue(hospital);
      return distance <= 10.0;
    }).toList();

    // Uzaklığa göre sırala
    nearbyHospitals.sort((a, b) {
      final distanceA = _getDistanceValue(a);
      final distanceB = _getDistanceValue(b);
      return distanceA.compareTo(distanceB);
    });

    setState(() {
      _allHospitals = nearbyHospitals;
      _filteredHospitals = nearbyHospitals;
      _isLoading = false;
    });
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

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredHospitals = _allHospitals;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredHospitals = _allHospitals.where((hospital) {
          return hospital.name.toLowerCase().contains(lowerQuery) ||
              hospital.address.toLowerCase().contains(lowerQuery);
        }).toList();
      }
      _applySorting();
    });
  }

  void _applySorting() {
    setState(() {
      switch (_sortBy) {
        case 'distance':
          _filteredHospitals.sort((a, b) {
            final distanceA = _getDistanceValue(a);
            final distanceB = _getDistanceValue(b);
            return distanceA.compareTo(distanceB);
          });
          break;
        case 'rating':
          // Şimdilik sabit puan kullanıyoruz, gerçek puan sistemi eklendiğinde güncellenir
          _filteredHospitals.sort((a, b) => b.name.compareTo(a.name));
          break;
        case 'name':
          _filteredHospitals.sort((a, b) => a.name.compareTo(b.name));
          break;
      }
    });
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
            _buildSortOption('distance', 'En Yakın', Icons.near_me),
            _buildSortOption('rating', 'En Yüksek Puan', Icons.star),
            _buildSortOption('name', 'Alfabetik', Icons.sort_by_alpha),
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                                  'Yakınımdaki Hastaneler',
                                  style: AppTheme.headingLarge.copyWith(
                                    color: AppTheme.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_filteredHospitals.length} hastane bulundu',
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
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.tune_rounded,
                                        color: AppTheme.tealBlue,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _getSortLabel(),
                                        style: AppTheme.bodyMedium.copyWith(
                                          color: AppTheme.tealBlue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        Icons.arrow_drop_down_rounded,
                                        color: AppTheme.tealBlue,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Hastane Listesi
                    Expanded(
                      child: _filteredHospitals.isEmpty
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
                                padding: const EdgeInsets.all(20),
                                itemCount: _filteredHospitals.length,
                                itemBuilder: (context, index) {
                                  final hospital = _filteredHospitals[index];
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
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: AppTheme.cardGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: hospital.image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: buildImage(
                                hospital.image!,
                                fit: BoxFit.cover,
                                errorWidget: Icon(
                                  Icons.local_hospital_rounded,
                                  size: 40,
                                  color: AppTheme.tealBlue,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.local_hospital_rounded,
                              size: 40,
                              color: AppTheme.tealBlue,
                            ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.turquoiseSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.schedule_rounded, size: 12, color: AppTheme.mintBlue),
                                const SizedBox(width: 4),
                                Text(
                                  '7/24',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.mintBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
}

