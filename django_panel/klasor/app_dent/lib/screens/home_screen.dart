import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/hospital.dart';
import '../models/tip.dart';
import '../services/auth_service.dart';
import '../services/json_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/image_widget.dart';
import 'all_doctors_screen.dart';
import 'all_hospitals_screen.dart';
import 'appointments_screen.dart';
import 'create_appointment_screen.dart';
import 'doctor_detail_screen.dart';
import 'hospital_detail_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _AppointmentStatusStyle {
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const _AppointmentStatusStyle({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });
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
  // Hastane ID -> {reviewCount, averageRating}
  Map<String, Map<String, dynamic>> _hospitalRatings = {};
  // Doktor ID -> {reviewCount, averageRating}
  Map<String, Map<String, dynamic>> _doctorRatings = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _startTipCarousel();
  }

  Widget _buildHospitalBadge({
    required IconData icon,
    required String label,
    Color? backgroundColor,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.inputFieldGray,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(icon, size: 14, color: iconColor ?? AppTheme.iconGray),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Çalışma saatleri badge'ini oluşturur
  Widget _buildWorkingHoursBadge(Hospital hospital) {
    final hoursInfo = _getTodayWorkingHours(hospital);
    
    if (hoursInfo['is24Hours'] == true) {
      // 7/24 Açık
      return _buildHospitalBadge(
        icon: Icons.schedule_rounded,
        label: hoursInfo['text'] as String,
        backgroundColor: AppTheme.tealBlue.withOpacity(0.1),
        textColor: AppTheme.tealBlue,
        iconColor: AppTheme.tealBlue,
      );
    } else if (hoursInfo['isOpen'] == true) {
      // Açık - saat'e kadar
      return _buildHospitalBadge(
        icon: Icons.schedule_rounded,
        label: hoursInfo['text'] as String,
        backgroundColor: Colors.green.withOpacity(0.1),
        textColor: Colors.green.shade700,
        iconColor: Colors.green.shade700,
      );
    } else {
      // Kapalı
      return _buildHospitalBadge(
        icon: Icons.schedule_rounded,
        label: hoursInfo['text'] as String,
        backgroundColor: Colors.red.withOpacity(0.1),
        textColor: Colors.red.shade700,
        iconColor: Colors.red.shade700,
      );
    }
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

  Widget _buildDoctorRatingOverlay(String doctorId) {
    final ratingData = _doctorRatings[doctorId];
    if (ratingData == null) return const SizedBox.shrink();
    
    final reviewCount = ratingData['reviewCount'] as int;
    final averageRating = ratingData['averageRating'] as double;
    
    // Eğer yorum yoksa gösterme
    if (reviewCount == 0) return const SizedBox.shrink();
    
    return Positioned(
      top: 6,
      left: 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_rounded,
              size: 12,
              color: Colors.white,
            ),
            const SizedBox(width: 3),
            Text(
              averageRating > 0 
                  ? '${averageRating.toStringAsFixed(1)} ($reviewCount)'
                  : '($reviewCount)',
              style: AppTheme.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalRatingOverlay(String hospitalId) {
    final ratingData = _hospitalRatings[hospitalId];
    if (ratingData == null) return const SizedBox.shrink();
    
    final reviewCount = ratingData['reviewCount'] as int;
    final averageRating = ratingData['averageRating'] as double;
    
    // Eğer yorum yoksa gösterme
    if (reviewCount == 0) return const SizedBox.shrink();
    
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_rounded,
              size: 12,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              averageRating > 0 
                  ? '${averageRating.toStringAsFixed(1)} ($reviewCount)'
                  : '($reviewCount)',
              style: AppTheme.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
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
    Appointment? upcomingAppointment;
    Doctor? upcomingDoctor;

    if (AuthService.isAuthenticated) {
      final userId = AuthService.currentUserId;
      if (userId != null) {
        upcomingAppointment = await JsonService.getUpcomingAppointmentForUser(userId);
        if (upcomingAppointment != null) {
          upcomingDoctor = await JsonService.getDoctorById(upcomingAppointment.doctorId);
        }
      }
    }

    // Hastaneleri uzaklığa göre sırala (en yakından uzağa)
    hospitals.sort((a, b) {
      final distanceA = _getDistanceValue(a);
      final distanceB = _getDistanceValue(b);
      return distanceA.compareTo(distanceB);
    });

    // Her hastane için yorum sayısı ve ortalama puanı yükle
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

  bool get _shouldShowAppointmentReminder =>
      AuthService.isAuthenticated && _upcomingAppointment != null;

  // Doktorun çalıştığı hastaneyi getir
  Hospital? _getHospitalByDoctor(Doctor doctor) {
    try {
      return _hospitals.firstWhere((h) => h.id == doctor.hospitalId);
    } catch (e) {
      return null;
    }
  }

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

  Widget _buildReminderInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.lightTurquoise.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppTheme.tealBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.grayText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatAppointmentDateTime(Appointment appointment) {
    if (appointment.date.isEmpty) {
      return appointment.time;
    }

    var normalizedTime = appointment.time.isEmpty ? '00:00' : appointment.time;
    if (normalizedTime.length == 5) {
      normalizedTime = '$normalizedTime:00';
    }

    final parsed = DateTime.tryParse('${appointment.date}T$normalizedTime');
    if (parsed == null) {
      if (appointment.time.isEmpty) {
        return appointment.date;
      }
      return '${appointment.date} • ${appointment.time}';
    }

    const monthNames = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    const weekdayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    final formattedTime =
        '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    final month = monthNames[parsed.month - 1];
    final weekday = weekdayNames[parsed.weekday - 1];

    return '$weekday, ${parsed.day} $month ${parsed.year} • $formattedTime';
  }

  _AppointmentStatusStyle? _getAppointmentStatusStyle(String status) {
    switch (status) {
      case 'completed':
        return _AppointmentStatusStyle(
          text: 'Tamamlandı',
          backgroundColor: AppTheme.successGreen.withOpacity(0.15),
          textColor: AppTheme.successGreen,
        );
      case 'cancelled':
        return _AppointmentStatusStyle(
          text: 'İptal Edildi',
          backgroundColor: Colors.red.withOpacity(0.12),
          textColor: Colors.red.shade700,
        );
      default:
        return null;
    }
  }

  Widget _buildAppointmentReminderCard() {
    if (!_shouldShowAppointmentReminder) {
      return const SizedBox.shrink();
    }

    final appointment = _upcomingAppointment!;
    final hospital = _getHospitalById(appointment.hospitalId);
    final doctor = _upcomingDoctor;
    final statusStyle = _getAppointmentStatusStyle(appointment.status);
    final hospitalAddress = hospital?.address ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _openAppointments,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.tealBlue.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yaklaşan randevun var',
                          style: AppTheme.headingSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatAppointmentDateTime(appointment),
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.grayText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (statusStyle != null &&
                      appointment.status == 'cancelled')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusStyle.backgroundColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        statusStyle.text,
                        style: AppTheme.bodySmall.copyWith(
                          color: statusStyle.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              _buildReminderInfoRow(
                icon: Icons.local_hospital_rounded,
                label: 'Hastane',
                value: hospital?.name ?? 'Hastane bilgisi yükleniyor',
              ),
              const SizedBox(height: 14),
              _buildReminderInfoRow(
                icon: Icons.person_outline,
                label: 'Doktor',
                value: doctor != null
                    ? '${doctor.name} ${doctor.surname}'
                    : 'Doktor bilgisi yükleniyor',
              ),
              if (hospitalAddress.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: _buildReminderInfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Adres',
                    value: hospitalAddress,
                  ),
                ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.tealBlue,
                    side: const BorderSide(color: AppTheme.tealBlue),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _openAppointments,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Tüm randevuları görüntüle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                        // Header
                        _buildHeader(),
                        const SizedBox(height: 24),
                        if (_shouldShowAppointmentReminder) ...[
                          _buildAppointmentReminderCard(),
                          const SizedBox(height: 16),
                        ],

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
                  const AppLogo(size: 54),
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
            SizedBox(
              width: double.infinity,
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
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.apartment_rounded,
              label: 'Hastaneler',
              color: AppTheme.turquoiseSoft,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllHospitalsScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
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
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
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
                  Stack(
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
                      if (_doctorRatings.containsKey(doctor.id))
                        _buildDoctorRatingOverlay(doctor.id),
                    ],
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
                          ],
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
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.inputFieldGray,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 12,
                                color: AppTheme.iconGray,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Müsait randevu: Bugün',
                                  style: AppTheme.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
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
                    if (_hospitalRatings.containsKey(hospital.id))
                      _buildHospitalRatingOverlay(hospital.id),
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
                            Icons.location_city_rounded,
                            size: 16,
                            color: AppTheme.iconGray,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              hospital.provinceName != null && hospital.districtName != null
                                  ? '${hospital.provinceName}/${hospital.districtName}'
                                  : hospital.address,
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
                          _buildWorkingHoursBadge(hospital),
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
