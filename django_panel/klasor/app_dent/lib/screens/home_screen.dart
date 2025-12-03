import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../models/hospital.dart';
import '../providers/home_provider.dart';
import '../services/auth_service.dart';
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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationAndLoadData();
    });
  }

  Future<void> _checkLocationAndLoadData() async {
    final controller = ref.read(homeControllerProvider.notifier);
    final hasRequested = await LocationService.hasRequestedPermission();

    Position? position;
    if (!hasRequested) {
      final shouldRequest = await _showLocationPermissionDialog();
      if (shouldRequest) {
        position = await _requestLocationPermission();
      }
    } else {
      position = await _loadUserLocation();
    }

    if (!mounted) return;

    await controller.loadInitial(position: position);
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
  Future<Position?> _requestLocationPermission() async {
    final permission = await LocationService.requestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return await _loadUserLocation();
    }
    return null;
  }

  /// Kullanıcı konumunu yükle
  Future<Position?> _loadUserLocation() async {
    final position = await LocationService.getCurrentLocation();
    if (!mounted) return position;

    if (position != null) {
      ref.read(homeControllerProvider.notifier).setUserPosition(position);
      debugPrint('✅ Konum alındı: ${position.latitude}, ${position.longitude}');
    } else {
      debugPrint('❌ Konum alınamadı');
    }
    return position;
  }

  /// Konum izni yoksa tekrar iste
  Future<void> _requestLocationPermissionAgain() async {
    final permission = await LocationService.requestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      await _loadUserLocation();
      if (!mounted) return;
      await ref.read(homeControllerProvider.notifier).refresh();
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


  bool _shouldShowAppointmentReminder(HomeState state) =>
      AuthService.isAuthenticated && state.upcomingAppointment != null;

  Future<void> _openAppointments(HomeState state, HomeController controller) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AppointmentsScreen(),
      ),
    );
    if (!mounted) return;
    await controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);

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
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: controller.refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HomeHeader(
                          user: state.user,
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
                        
                        if (state.errorMessage != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      state.errorMessage!,
                                      style: AppTheme.bodySmall.copyWith(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (_shouldShowAppointmentReminder(state)) ...[
                          AppointmentReminderCard(
                            appointment: state.upcomingAppointment,
                            hospital: _getHospitalById(state, state.upcomingAppointment!.hospitalId),
                            doctor: state.upcomingDoctor,
                            onOpenAppointments: () => _openAppointments(state, controller),
                          ),
                          const SizedBox(height: 16),
                        ],

                        const CreateAppointmentCard(),
                        const SizedBox(height: 16),
                        
                        const QuickActions(),
                        const SizedBox(height: 24),

                        NearbyHospitalsSection(
                          hospitals: state.hospitals,
                          userPosition: state.userPosition,
                          hospitalDistances: state.hospitalDistances,
                          hospitalRatings: state.hospitalRatings,
                          onRequestLocationPermission: _requestLocationPermissionAgain,
                        ),
                        const SizedBox(height: 24),

                        PopularDoctorsSection(
                          popularDoctors: state.popularDoctors,
                          hospitals: state.hospitals,
                          doctorRatings: state.doctorRatings,
                        ),
                        const SizedBox(height: 24),

                        TipsSection(
                          displayedTips: state.tips,
                          currentTipIndex: state.currentTipIndex,
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

  Hospital? _getHospitalById(HomeState state, String hospitalId) {
    try {
      return state.hospitals.firstWhere((h) => h.id == hospitalId);
    } catch (_) {
      return null;
    }
  }

}
