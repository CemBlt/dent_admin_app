import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/hospital.dart';
import '../models/tip.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/json_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'appointments_screen.dart';
import 'notifications_screen.dart';

// Widgets
import '../widgets/home/home_header.dart';
import '../widgets/home/appointment_reminder_card.dart';
import '../widgets/home/create_appointment_card.dart';
import '../widgets/home/quick_actions.dart';
import '../widgets/home/nearby_hospitals_section.dart';
import '../widgets/home/popular_doctors_section.dart';
import '../widgets/home/tips_section.dart';

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
  Appointment? _upcomingAppointment;
  Doctor? _upcomingDoctor;
  
  // Kullanıcı bilgisi
  User? _user;
  
  // Hastane ID -> {reviewCount, averageRating}
  Map<String, Map<String, dynamic>> _hospitalRatings = {};
  // Doktor ID -> {reviewCount, averageRating}
  Map<String, Map<String, dynamic>> _doctorRatings = {};
  
  // Kullanıcı konumu
  Position? _userPosition;
  // Mesafe bilgisi (hastane ID -> mesafe km)
  Map<String, double> _hospitalDistances = {};

  @override
  void initState() {
    super.initState();
    _checkLocationAndLoadData();
    _startTipCarousel();
  }

  /// Konum kontrolü yap ve verileri yükle
  Future<void> _checkLocationAndLoadData() async {
    final hasRequested = await LocationService.hasRequestedPermission();
    
    if (!hasRequested) {
      final shouldRequest = await _showLocationPermissionDialog();
      if (shouldRequest) {
        await _requestLocationPermission();
      }
    } else {
      await _loadUserLocation();
    }
    
    await _loadData();
  }

  /// İlk açılış konum izni dialogu
  Future<bool> _showLocationPermissionDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Konum İzni',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: const Text(
          'Yakınındaki hastaneleri görmek için konum bilgisine ihtiyacımız var. '
          'Konumunuz sadece bu amaç için kullanılacak ve saklanmayacaktır.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Şimdi Değil'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tealBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('İzin Ver'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Konum izni iste
  Future<void> _requestLocationPermission() async {
    final permission = await LocationService.requestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      await _loadUserLocation();
      await _loadData();
    }
  }

  /// Kullanıcı konumunu yükle
  Future<void> _loadUserLocation() async {
    final position = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _userPosition = position;
      });
      if (position != null) {
        debugPrint('✅ Konum alındı: ${position.latitude}, ${position.longitude}');
      } else {
        debugPrint('❌ Konum alınamadı');
      }
    }
  }

  /// Konum izni yoksa tekrar iste
  Future<void> _requestLocationPermissionAgain() async {
    final permission = await LocationService.requestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      await _loadUserLocation();
      await _loadData();
    } else if (permission == LocationPermission.deniedForever) {
      await _showOpenSettingsDialog();
    }
  }

  /// Ayarlara git dialogu
  Future<void> _showOpenSettingsDialog() async {
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Konum İzni Gerekli'),
        content: const Text(
          'Yakınındaki hastaneleri görmek için konum izni gereklidir. '
          'Lütfen ayarlardan konum iznini açın.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tealBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ayarlara Git'),
          ),
        ],
      ),
    );

    if (shouldOpen == true) {
      await LocationService.openAppSettings();
    }
  }

  Future<void> _loadData() async {
    List<Hospital> hospitals;
    Map<String, double> hospitalDistances = {};

    if (_userPosition != null) {
      debugPrint('📍 Konum var, yakındaki hastaneler getiriliyor...');
      hospitals = await JsonService.getNearbyHospitals(
        userLat: _userPosition!.latitude,
        userLon: _userPosition!.longitude,
        radiusKm: 50,
      );
      debugPrint('✅ ${hospitals.length} yakındaki hastane bulundu');
      
      for (final hospital in hospitals) {
        final distance = LocationService.calculateDistance(
          _userPosition!.latitude,
          _userPosition!.longitude,
          hospital.latitude,
          hospital.longitude,
        );
        hospitalDistances[hospital.id] = distance;
      }
    } else {
      debugPrint('📍 Konum yok, tüm hastaneler getiriliyor...');
      hospitals = await JsonService.getHospitals();
      hospitals.sort((a, b) => a.name.compareTo(b.name));
      debugPrint('✅ ${hospitals.length} hastane bulundu');
    }

    final doctors = await JsonService.getPopularDoctors();
    final tips = await JsonService.getTips();
    Appointment? upcomingAppointment;
    Doctor? upcomingDoctor;

    User? user;
    if (AuthService.isAuthenticated) {
      final userId = AuthService.currentUserId;
      if (userId != null) {
        user = await JsonService.getUser(userId);
        
        upcomingAppointment = await JsonService.getUpcomingAppointmentForUser(userId);
        if (upcomingAppointment != null) {
          upcomingDoctor = await JsonService.getDoctorById(upcomingAppointment.doctorId);
        }
      }
    }

    final hospitalRatingsMap = <String, Map<String, dynamic>>{};
    for (final hospital in hospitals) {
      try {
        final reviews = await JsonService.getReviewsByHospital(hospital.id);
        final averageRating = await JsonService.getHospitalAverageRating(hospital.id);
        hospitalRatingsMap[hospital.id] = {
          'reviewCount': reviews.length,
          'averageRating': averageRating,
        };
      } catch (e) {
        hospitalRatingsMap[hospital.id] = {
          'reviewCount': 0,
          'averageRating': 0.0,
        };
      }
    }

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

    if (!mounted) return;
    setState(() {
      _hospitals = hospitals;
      _popularDoctors = doctors;
      _tips = tips;
      _displayedTips = tips;
      _hospitalRatings = hospitalRatingsMap;
      _doctorRatings = doctorRatingsMap;
      _upcomingAppointment = upcomingAppointment;
      _upcomingDoctor = upcomingDoctor;
      _hospitalDistances = hospitalDistances;
      _user = user;
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

  bool get _shouldShowAppointmentReminder =>
      AuthService.isAuthenticated && _upcomingAppointment != null;

  Hospital? _getHospitalById(String hospitalId) {
    try {
      return _hospitals.firstWhere((h) => h.id == hospitalId);
    } catch (e) {
      return null;
    }
  }

  Future<void> _openAppointments() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AppointmentsScreen(),
      ),
    );
    if (!mounted) return;
    await _loadData();
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
                        HomeHeader(
                          user: _user,
                          onNotificationPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationsScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        if (_shouldShowAppointmentReminder) ...[
                          AppointmentReminderCard(
                            appointment: _upcomingAppointment,
                            hospital: _getHospitalById(_upcomingAppointment!.hospitalId),
                            doctor: _upcomingDoctor,
                            onOpenAppointments: _openAppointments,
                          ),
                          const SizedBox(height: 16),
                        ],

                        const CreateAppointmentCard(),
                        const SizedBox(height: 16),
                        
                        const QuickActions(),
                        const SizedBox(height: 24),

                        NearbyHospitalsSection(
                          hospitals: _hospitals,
                          userPosition: _userPosition,
                          hospitalDistances: _hospitalDistances,
                          hospitalRatings: _hospitalRatings,
                          onRequestLocationPermission: _requestLocationPermissionAgain,
                        ),
                        const SizedBox(height: 24),

                        PopularDoctorsSection(
                          popularDoctors: _popularDoctors,
                          hospitals: _hospitals,
                          doctorRatings: _doctorRatings,
                        ),
                        const SizedBox(height: 24),

                        TipsSection(
                          displayedTips: _displayedTips,
                          currentTipIndex: _currentTipIndex,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
