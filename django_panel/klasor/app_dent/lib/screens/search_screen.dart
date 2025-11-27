import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/doctor.dart';
import '../models/hospital.dart';
import '../services/json_service.dart';
import '../widgets/image_widget.dart';
import 'hospital_detail_screen.dart';
import 'doctor_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Doctor> _allDoctors = [];
  List<Hospital> _allHospitals = [];
  List<Doctor> _filteredDoctors = [];
  List<Hospital> _filteredHospitals = [];
  bool _isLoading = true;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final doctors = await JsonService.getDoctors();
    final hospitals = await JsonService.getHospitals();

    setState(() {
      _allDoctors = doctors;
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.tealBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, size: 10, color: AppTheme.tealBlue),
            const SizedBox(width: 3),
            Text(
              hoursInfo['text'] as String,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.tealBlue,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    } else if (hoursInfo['isOpen'] == true) {
      // Açık - saat'e kadar
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, size: 10, color: Colors.green.shade700),
            const SizedBox(width: 3),
            Text(
              hoursInfo['text'] as String,
              style: AppTheme.bodySmall.copyWith(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    } else {
      // Kapalı
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, size: 10, color: Colors.red.shade700),
            const SizedBox(width: 3),
            Text(
              hoursInfo['text'] as String,
              style: AppTheme.bodySmall.copyWith(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _currentQuery = query;
      
      if (query.isEmpty) {
        _filteredDoctors = [];
        _filteredHospitals = [];
      } else {
        final lowerQuery = query.toLowerCase();
        
        // Doktorları filtrele
        _filteredDoctors = _allDoctors.where((doctor) {
          return doctor.fullName.toLowerCase().contains(lowerQuery);
        }).toList();
        
        // Hastaneleri filtrele
        _filteredHospitals = _allHospitals.where((hospital) {
          return hospital.name.toLowerCase().contains(lowerQuery) ||
              hospital.address.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  Hospital? _getHospitalByDoctor(Doctor doctor) {
    try {
      return _allHospitals.firstWhere((h) => h.id == doctor.hospitalId);
    } catch (e) {
      return null;
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
                    // Header ve Arama
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.lightTurquoise,
                            AppTheme.mediumTurquoise,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: AppTheme.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: 'Doktor veya klinik ara...',
                                  hintStyle: TextStyle(color: AppTheme.iconGray),
                                  prefixIcon: Icon(Icons.search, color: AppTheme.iconGray),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.clear, color: AppTheme.iconGray),
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
                                    vertical: 12,
                                  ),
                                ),
                                onChanged: _onSearchChanged,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Sonuçlar
                    Expanded(
                      child: _currentQuery.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search,
                                    size: 64,
                                    color: AppTheme.iconGray,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Doktor veya klinik arayın',
                                    style: AppTheme.bodyLarge.copyWith(
                                      color: AppTheme.grayText,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _filteredDoctors.isEmpty && _filteredHospitals.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64,
                                        color: AppTheme.iconGray,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Sonuç bulunamadı',
                                        style: AppTheme.bodyLarge.copyWith(
                                          color: AppTheme.grayText,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Arama kriterlerinizi değiştirmeyi deneyin',
                                        style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.grayText,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Doktorlar
                                      if (_filteredDoctors.isNotEmpty) ...[
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.person,
                                              size: 20,
                                              color: AppTheme.tealBlue,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Doktorlar (${_filteredDoctors.length})',
                                              style: AppTheme.headingSmall,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        ..._filteredDoctors.map((doctor) => _buildDoctorCard(doctor)),
                                        const SizedBox(height: 24),
                                      ],
                                      // Hastaneler
                                      if (_filteredHospitals.isNotEmpty) ...[
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.local_hospital,
                                              size: 20,
                                              color: AppTheme.tealBlue,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Hastaneler (${_filteredHospitals.length})',
                                              style: AppTheme.headingSmall,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        ..._filteredHospitals.map((hospital) => _buildHospitalCard(hospital)),
                                      ],
                                    ],
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                builder: (context) => DoctorDetailScreen(
                  doctor: doctor,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Doktor Fotoğrafı
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTurquoise,
                    shape: BoxShape.circle,
                  ),
                  child: doctor.image != null
                      ? ClipOval(
                          child: buildImage(
                            doctor.image!,
                            fit: BoxFit.cover,
                            width: 60,
                            height: 60,
                            errorWidget: Icon(
                              Icons.person,
                              size: 30,
                              color: AppTheme.tealBlue,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 30,
                          color: AppTheme.tealBlue,
                        ),
                ),
                const SizedBox(width: 12),
                // Doktor Bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        doctor.fullName,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hospital != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.local_hospital,
                              size: 12,
                              color: AppTheme.iconGray,
                            ),
                            const SizedBox(width: 4),
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
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.iconGray,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalCard(Hospital hospital) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                // Hastane Görseli
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTurquoise,
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
                              size: 30,
                              color: AppTheme.tealBlue,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.local_hospital,
                          size: 30,
                          color: AppTheme.tealBlue,
                        ),
                ),
                const SizedBox(width: 12),
                // Hastane Bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hospital.name,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: AppTheme.iconGray,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              hospital.address,
                              style: AppTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildWorkingHoursBadge(hospital),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.iconGray,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

