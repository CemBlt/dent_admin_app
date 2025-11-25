import 'package:flutter/material.dart';

import '../models/doctor.dart';
import '../models/hospital.dart';
import '../models/tip.dart';
import '../services/json_service.dart';
import '../theme/app_theme.dart';
import '../widgets/image_widget.dart';
import 'all_doctors_screen.dart';
import 'all_hospitals_screen.dart';
import 'create_appointment_screen.dart';
import 'doctor_detail_screen.dart';
import 'filter_hospitals_screen.dart';
import 'hospital_detail_screen.dart';
import 'notifications_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Hospital> _hospitals = [];
  List<Doctor> _popularDoctors = [];
  List<Tip> _tips = [];
  List<Tip> _displayedTips = [];
  int _currentTipIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startTipCarousel();
  }

  Widget _buildHospitalBadge({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.inputFieldGray,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(icon, size: 14, color: AppTheme.iconGray),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: IconButton(
        icon: const Icon(Icons.notifications_outlined),
        color: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationsScreen(),
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadData() async {
    final hospitals = await JsonService.getHospitals();
    final doctors = await JsonService.getPopularDoctors();
    final tips = await JsonService.getTips();

    // Hastaneleri uzaklığa göre sırala (en yakından uzağa)
    hospitals.sort((a, b) {
      final distanceA = _getDistanceValue(a);
      final distanceB = _getDistanceValue(b);
      return distanceA.compareTo(distanceB);
    });

    setState(() {
      _hospitals = hospitals;
      _popularDoctors = doctors;
      _tips = tips;
      _displayedTips = tips;
      _isLoading = false;
    });
  }

  void _startTipCarousel() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _tips.isNotEmpty) {
        setState(() {
          _currentTipIndex = (_currentTipIndex + 1) % _tips.length;
        });
        _startTipCarousel();
      }
    });
  }

  // Uzaklık değerini sayısal olarak döndür
  double _getDistanceValue(Hospital hospital) {
    // Gerçek konum bilgisi olmadığı için hastane ID'sine göre sabit değer
    final distances = {'1': 1.2, '2': 0.8, '3': 2.5};
    return distances[hospital.id] ?? 1.6;
  }

  // Uzaklık hesaplama (string formatında)
  String _getDistance(Hospital hospital) {
    final distance = _getDistanceValue(hospital);
    return '${distance.toStringAsFixed(1)} km';
  }

  // Doktorun çalıştığı hastaneyi getir
  Hospital? _getHospitalByDoctor(Doctor doctor) {
    try {
      return _hospitals.firstWhere((h) => h.id == doctor.hospitalId);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
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
              AppTheme.lightTurquoise.withOpacity(0.5),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header ve Arama
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildSearchBar(),
                        const SizedBox(height: 24),

                        // Randevu Oluştur Butonu
                        _buildCreateAppointmentButton(),
                        const SizedBox(height: 16),
                        _buildQuickActions(),
                        const SizedBox(height: 24),

                        // Yakınımdaki Hastaneler
                        _buildNearbyHospitals(),
                        const SizedBox(height: 24),

                        // Popüler Doktorlar
                        _buildPopularDoctors(),
                        const SizedBox(height: 24),

                        // İpuçları
                        _buildTipsSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.accentGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.tealBlue.withOpacity(0.25),
              blurRadius: 30,
              spreadRadius: -5,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.health_and_safety_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Merhaba, Cem!',
                          style: AppTheme.headingLarge.copyWith(
                            color: AppTheme.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sağlığın için yanındayız',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildNotificationButton(),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Bugün nasıl yardımcı olabiliriz?',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.tealBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateAppointmentScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Hemen Randevu Oluştur',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.tealBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SearchScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppTheme.tealBlue.withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.tealBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Doktor, klinik veya hizmet ara',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.grayText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.inputFieldGray,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: AppTheme.iconGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateAppointmentButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.white,
              AppTheme.lightTurquoise.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.white.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.tealBlue.withOpacity(0.08),
              blurRadius: 22,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dakikalar içinde randevunu oluştur',
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ücretsiz ipuçları ve doktor önerileri',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.grayText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      backgroundColor: AppTheme.tealBlue,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateAppointmentScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text('Randevu Oluştur'),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FilterHospitalsScreen(),
                      ),
                    );
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.white,
                    foregroundColor: AppTheme.tealBlue,
                    minimumSize: const Size(54, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.filter_list_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildStatChip(Icons.local_hospital_outlined, '35+ Klinik'),
                const SizedBox(width: 12),
                _buildStatChip(Icons.verified_rounded, 'Onaylı Doktor'),
                const SizedBox(width: 12),
                _buildStatChip(Icons.timer_rounded, '<2 dk'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.inputFieldGray),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppTheme.tealBlue),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildQuickActionCard(
              icon: Icons.apartment_rounded,
              label: 'Hastaneler',
              color: AppTheme.lightTurquoise,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllHospitalsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            _buildQuickActionCard(
              icon: Icons.people_alt_rounded,
              label: 'Doktorlar',
              color: AppTheme.turquoiseSoft,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllDoctorsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            _buildQuickActionCard(
              icon: Icons.filter_alt_rounded,
              label: 'Filtrele',
              color: AppTheme.lightTurquoise.withOpacity(0.8),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FilterHospitalsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 120,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 18,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: AppTheme.tealBlue,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularDoctors() {
    if (_popularDoctors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Popüler Doktorlar',
                  style: AppTheme.headingMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllDoctorsScreen(),
                    ),
                  );
                },
                child: Text(
                  'Tümünü Gör',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.tealBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _popularDoctors.length,
            itemBuilder: (context, index) {
              final doctor = _popularDoctors[index];
              return _buildDoctorCard(doctor);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    final hospital = _getHospitalByDoctor(doctor);

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
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
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DoctorDetailScreen(doctor: doctor),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: AppTheme.cardGradient,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: doctor.image != null
                          ? buildImage(
                              doctor.image!,
                              fit: BoxFit.cover,
                              width: 76,
                              height: 76,
                              errorWidget: Icon(
                                Icons.person,
                                size: 36,
                                color: AppTheme.tealBlue,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 36,
                              color: AppTheme.tealBlue,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.lightTurquoise,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: AppTheme.accentYellow,
                                  ),
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
                        const SizedBox(height: 4),
                        Text(
                          doctor.specialty,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.grayText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (hospital != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.local_hospital,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.inputFieldGray,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: AppTheme.iconGray,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Müsait randevu: Bugün',
                                  style: AppTheme.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNearbyHospitals() {
    if (_hospitals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Yakınımdaki Hastaneler',
                  style: AppTheme.headingMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllHospitalsScreen(),
                    ),
                  );
                },
                child: Text(
                  'Tümünü Gör',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.tealBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _hospitals.length > 3 ? 3 : _hospitals.length,
          itemBuilder: (context, index) {
            final hospital = _hospitals[index];
            return _buildHospitalCard(hospital);
          },
        ),
      ],
    );
  }

  Widget _buildHospitalCard(Hospital hospital) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HospitalDetailScreen(hospital: hospital),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 25,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: SizedBox(
                        width: 110,
                        height: 110,
                        child: hospital.image != null
                            ? buildImage(
                                hospital.image!,
                                fit: BoxFit.cover,
                                errorWidget: Icon(
                                  Icons.local_hospital,
                                  size: 40,
                                  color: AppTheme.tealBlue,
                                ),
                              )
                            : Container(
                                color: AppTheme.lightTurquoise,
                                child: Icon(
                                  Icons.local_hospital,
                                  size: 40,
                                  color: AppTheme.tealBlue,
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '4.6',
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
                const SizedBox(width: 18),
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
                            Icons.location_on,
                            size: 16,
                            color: AppTheme.iconGray,
                          ),
                          const SizedBox(width: 6),
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
                        runSpacing: 8,
                        children: [
                          _buildHospitalBadge(
                            icon: Icons.location_on,
                            label: _getDistance(hospital),
                          ),
                          _buildHospitalBadge(
                            icon: Icons.schedule_rounded,
                            label: '7/24 Açık',
                          ),
                          _buildHospitalBadge(
                            icon: Icons.verified_user,
                            label: 'Onaylı',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
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

  Widget _buildTipsSection() {
    if (_displayedTips.isEmpty) return const SizedBox.shrink();

    final currentTip = _displayedTips[_currentTipIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.accentGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.tealBlue.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Diş Sağlığı İpuçları',
                    style: AppTheme.headingSmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Column(
                  key: ValueKey(currentTip.id),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentTip.title,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentTip.content,
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildTipIndicators(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipIndicators() {
    return Row(
      children: List.generate(
        _displayedTips.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(right: 6),
          height: 6,
          width: index == _currentTipIndex ? 32 : 12,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(index == _currentTipIndex ? 0.9 : 0.4),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
