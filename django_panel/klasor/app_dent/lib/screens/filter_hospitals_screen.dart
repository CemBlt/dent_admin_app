import 'package:flutter/material.dart';
import '../models/hospital.dart';
import '../services/json_service.dart';
import '../theme/app_theme.dart';
import '../widgets/image_widget.dart';
import 'hospital_detail_screen.dart';

class FilterHospitalsScreen extends StatefulWidget {
  const FilterHospitalsScreen({super.key});

  @override
  State<FilterHospitalsScreen> createState() => _FilterHospitalsScreenState();
}

class _FilterHospitalsScreenState extends State<FilterHospitalsScreen> {
  List<Hospital> _allHospitals = [];
  List<Hospital> _filteredHospitals = [];
  List<Hospital> _displayedHospitals = [];
  
  String? _selectedCity;
  String? _selectedDistrict;
  
  final ScrollController _scrollController = ScrollController();
  int _displayedCount = 10; // İlk 10 hastane gösterilecek
  final int _loadMoreCount = 5; // Her seferinde 5 hastane daha yüklenecek
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final hospitals = await JsonService.getHospitals();

    setState(() {
      _allHospitals = hospitals;
      _isLoading = false;
    });
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.tealBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, size: 12, color: Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(
              hoursInfo['text'] as String,
              style: AppTheme.bodySmall.copyWith(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
  }

  // Adres formatından il ve ilçe çıkar (format: "İlçe, İl")
  Map<String, String> _parseAddress(String address) {
    final parts = address.split(',').map((e) => e.trim()).toList();
    if (parts.length >= 2) {
      return {'district': parts[0], 'city': parts[1]};
    }
    return {'district': address, 'city': ''};
  }

  // Tüm illeri getir
  List<String> get _cities {
    final cities = <String>{};
    for (var hospital in _allHospitals) {
      final addressInfo = _parseAddress(hospital.address);
      if (addressInfo['city']!.isNotEmpty) {
        cities.add(addressInfo['city']!);
      }
    }
    return cities.toList()..sort();
  }

  // Seçilen ile göre ilçeleri getir
  List<String> get _districts {
    if (_selectedCity == null) return [];
    
    final districts = <String>{};
    for (var hospital in _allHospitals) {
      final addressInfo = _parseAddress(hospital.address);
      if (addressInfo['city'] == _selectedCity && addressInfo['district']!.isNotEmpty) {
        districts.add(addressInfo['district']!);
      }
    }
    return districts.toList()..sort();
  }

  void _onCitySelected(String? city) {
    setState(() {
      _selectedCity = city;
      _selectedDistrict = null;
      _updateFilteredHospitals();
    });
  }

  void _onDistrictSelected(String? district) {
    setState(() {
      _selectedDistrict = district;
      _updateFilteredHospitals();
    });
  }

  void _updateFilteredHospitals() {
    _filteredHospitals = _allHospitals.where((hospital) {
      final addressInfo = _parseAddress(hospital.address);
      final matchesCity = _selectedCity == null || addressInfo['city'] == _selectedCity;
      final matchesDistrict = _selectedDistrict == null || addressInfo['district'] == _selectedDistrict;
      return matchesCity && matchesDistrict;
    }).toList();
    
    // İsme göre sırala
    _filteredHospitals.sort((a, b) => a.name.compareTo(b.name));
    
    // İlk 10 hastaneyi göster
    _displayedCount = 10;
    _displayedHospitals = _filteredHospitals.take(_displayedCount).toList();
  }

  void _onScroll() {
    // Scroll pozisyonu %80'e ulaştığında daha fazla hastane yükle
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    if (currentScroll >= maxScroll * 0.8) {
      if (_displayedCount < _filteredHospitals.length) {
        setState(() {
          _displayedCount = (_displayedCount + _loadMoreCount)
              .clamp(0, _filteredHospitals.length);
          _displayedHospitals = _filteredHospitals.take(_displayedCount).toList();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Hastane Filtrele'),
        backgroundColor: AppTheme.accentTeal,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filtre Bölümü
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // İl Seçimi
                      DropdownButtonFormField<String>(
                        value: _selectedCity,
                        decoration: InputDecoration(
                          labelText: 'İl Seçiniz',
                          prefixIcon: const Icon(Icons.location_city),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppTheme.inputBackground,
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Tüm İller'),
                          ),
                          ..._cities.map((city) => DropdownMenuItem<String>(
                                value: city,
                                child: Text(city),
                              )),
                        ],
                        onChanged: _onCitySelected,
                      ),
                      if (_selectedCity != null) ...[
                        const SizedBox(height: 16),
                        // İlçe Seçimi
                        DropdownButtonFormField<String>(
                          value: _selectedDistrict,
                          decoration: InputDecoration(
                            labelText: 'İlçe Seçiniz',
                            prefixIcon: const Icon(Icons.location_on),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: AppTheme.inputBackground,
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Tüm İlçeler'),
                            ),
                            ..._districts.map((district) => DropdownMenuItem<String>(
                                  value: district,
                                  child: Text(district),
                                )),
                          ],
                          onChanged: _onDistrictSelected,
                        ),
                      ],
                    ],
                  ),
                ),
                // Sonuç Sayısı
                if (_selectedCity != null || _selectedDistrict != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    color: AppTheme.backgroundSecondary,
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_hospital,
                          size: 18,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_filteredHospitals.length} hastane bulundu',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Hastane Listesi
                Expanded(
                  child: _filteredHospitals.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: AppTheme.iconSecondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedCity == null && _selectedDistrict == null
                                      ? 'Lütfen il veya ilçe seçiniz'
                                      : 'Seçilen kriterlere uygun hastane bulunamadı',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.lightText,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(20),
                          itemCount: _displayedHospitals.length +
                              (_displayedCount < _filteredHospitals.length ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _displayedHospitals.length) {
                              // Loading indicator
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final hospital = _displayedHospitals[index];
                            return _buildHospitalCard(hospital);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildHospitalCard(Hospital hospital) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Hastane Fotoğrafı
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: hospital.image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: buildImage(
                            hospital.image!,
                            fit: BoxFit.cover,
                            errorWidget: Icon(
                              Icons.local_hospital,
                              size: 40,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.local_hospital,
                          size: 40,
                          color: AppTheme.primaryBlue,
                        ),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppTheme.iconSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              hospital.address,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.lightText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildWorkingHoursBadge(hospital),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.iconSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

