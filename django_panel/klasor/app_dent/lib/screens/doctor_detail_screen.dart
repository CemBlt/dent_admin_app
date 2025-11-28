import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../models/hospital.dart';
import '../models/review.dart';
import '../models/rating.dart';
import '../models/user.dart';
import '../services/json_service.dart';
import '../theme/app_theme.dart';
import '../widgets/image_widget.dart';
import 'create_appointment_screen.dart';
import 'hospital_detail_screen.dart';

class DoctorDetailScreen extends StatefulWidget {
  final Doctor doctor;

  const DoctorDetailScreen({
    super.key,
    required this.doctor,
  });

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen>
    with SingleTickerProviderStateMixin {
  Hospital? _hospital;
  List<Review> _reviews = [];
  List<Rating> _ratings = [];
  double _averageRating = 0.0;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Hastane bilgisini yükle
    final hospitals = await JsonService.getHospitals();
    final hospital = hospitals.firstWhere(
      (h) => h.id == widget.doctor.hospitalId,
      orElse: () => hospitals.first,
    );

    // Yorumları ve puanlamaları yükle
    final reviews = await JsonService.getReviewsByDoctor(widget.doctor.id);
    final ratings = await JsonService.getRatingsByDoctor(widget.doctor.id);
    final averageRating = await JsonService.getDoctorAverageRating(widget.doctor.id);

    setState(() {
      _hospital = hospital;
      _reviews = reviews;
      _ratings = ratings;
      _averageRating = averageRating;
      _isLoading = false;
    });
  }

  String _getDayName(String day) {
    const dayNames = {
      'monday': 'Pazartesi',
      'tuesday': 'Salı',
      'wednesday': 'Çarşamba',
      'thursday': 'Perşembe',
      'friday': 'Cuma',
      'saturday': 'Cumartesi',
      'sunday': 'Pazar',
    };
    return dayNames[day] ?? day;
  }

  String _getDayShortName(String day) {
    const dayNames = {
      'monday': 'Pzt',
      'tuesday': 'Sal',
      'wednesday': 'Çar',
      'thursday': 'Per',
      'friday': 'Cum',
      'saturday': 'Cmt',
      'sunday': 'Paz',
    };
    return dayNames[day] ?? day.substring(0, 3).toUpperCase();
  }

  int _getDayDate(String day) {
    const dayIndexes = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7,
    };

    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1=Pazartesi, 7=Pazar
    final targetWeekday = dayIndexes[day] ?? 1;
    
    // Bu haftanın o gününün tarihini hesapla
    final difference = targetWeekday - currentWeekday;
    final targetDate = now.add(Duration(days: difference));
    
    return targetDate.day;
  }

  String _getTodayDayName() {
    final now = DateTime.now();
    final weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return weekdays[now.weekday - 1];
  }

  List<MapEntry<String, dynamic>> _getOrderedWorkingHours() {
    const dayOrder = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    final ordered = <MapEntry<String, dynamic>>[];
    for (final day in dayOrder) {
      if (widget.doctor.workingHours.containsKey(day)) {
        ordered.add(
          MapEntry(
            day,
            widget.doctor.workingHours[day],
          ),
        );
      }
    }
    return ordered;
  }

  String _formatWorkingHours(Map<String, dynamic> hours) {
    final isAvailable = hours['isAvailable'] == true;
    if (!isAvailable) return 'Kapalı';
    
    final start = hours['start'] as String?;
    final end = hours['end'] as String?;
    
    if (start != null && end != null) {
      return '$start - $end';
    }
    return 'Kapalı';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
                : NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [
                        // Hero Header
                        SliverAppBar(
                          expandedHeight: 320,
                          pinned: true,
                          backgroundColor: AppTheme.tealBlue,
                          title: Text(
                            widget.doctor.fullName,
                            style: AppTheme.headingSmall.copyWith(
                              color: AppTheme.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          leading: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: AppTheme.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          flexibleSpace: FlexibleSpaceBar(
                            titlePadding: EdgeInsets.zero,
                            centerTitle: false,
                            background: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Gradient Background
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.accentGradient,
                                  ),
                                ),
                                // Doktor Fotoğrafı
                                Center(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: widget.doctor.image != null
                                          ? GestureDetector(
                                              onTap: () => _showFullScreenImage(
                                                context,
                                                widget.doctor.image!,
                                              ),
                                              child: buildImage(
                                                widget.doctor.image!,
                                                width: 160,
                                                height: 160,
                                                fit: BoxFit.cover,
                                                errorWidget: Container(
                                                  width: 160,
                                                  height: 160,
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.white.withOpacity(0.3),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.person_rounded,
                                                    size: 80,
                                                    color: AppTheme.white,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Container(
                                              width: 160,
                                              height: 160,
                                              decoration: BoxDecoration(
                                                color: AppTheme.white.withOpacity(0.3),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.person_rounded,
                                                size: 80,
                                                color: AppTheme.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                // Gradient Overlay
                                IgnorePointer(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.6),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Rating ve Badge'ler
                                Positioned(
                                  bottom: 16,
                                  left: 16,
                                  right: 16,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (_averageRating > 0) ...[
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.star_rounded,
                                              color: AppTheme.accentYellow,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _averageRating.toStringAsFixed(1),
                                              style: AppTheme.bodyLarge.copyWith(
                                                color: AppTheme.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '(${_reviews.length})',
                                              style: AppTheme.bodyMedium.copyWith(
                                                color: AppTheme.white.withOpacity(0.9),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      if (_hospital != null &&
                                          _hospital!.provinceName != null &&
                                          _hospital!.districtName != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.location_on_rounded,
                                                size: 14,
                                                color: AppTheme.white,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${_hospital!.provinceName} / ${_hospital!.districtName}',
                                                style: AppTheme.bodySmall.copyWith(
                                                  color: AppTheme.white,
                                                  fontWeight: FontWeight.w600,
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
                          bottom: PreferredSize(
                            preferredSize: const Size.fromHeight(56),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, -2),
                                  ),
                                ],
                              ),
                              child: TabBar(
                                controller: _tabController,
                                labelColor: AppTheme.tealBlue,
                                unselectedLabelColor: AppTheme.grayText.withOpacity(0.6),
                                indicator: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.tealBlue.withOpacity(0.15),
                                      AppTheme.lightTurquoise.withOpacity(0.08),
                                    ],
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicatorWeight: 0,
                                labelStyle: AppTheme.headingSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  letterSpacing: 0.3,
                                ),
                                unselectedLabelStyle: AppTheme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                tabs: [
                                  Tab(
                                    height: 56,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.info_outline_rounded, size: 22),
                                        const SizedBox(width: 8),
                                        const Text('Bilgiler'),
                                      ],
                                    ),
                                  ),
                                  Tab(
                                    height: 56,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.rate_review_outlined, size: 22),
                                        const SizedBox(width: 8),
                                        const Text('Yorumlar'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ];
                    },
                    body: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildInfoTab(),
                        _buildReviewsTab(),
                      ],
                    ),
                  ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateAppointmentScreen(
                  preselectedHospitalId: widget.doctor.hospitalId,
                  preselectedDoctorId: widget.doctor.id,
                ),
              ),
            );
          },
          backgroundColor: AppTheme.tealBlue,
          icon: const Icon(Icons.calendar_month_rounded, color: AppTheme.white),
          label: Text(
            'Randevu Oluştur',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // BİLGİLER SEKME
  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hakkında
          if (widget.doctor.bio.isNotEmpty) ...[
            _buildSection(
              icon: Icons.person_outline_rounded,
              title: 'Hakkında',
              child: Text(
                widget.doctor.bio,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.grayText,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          // Çalıştığı Hastane
          if (_hospital != null) ...[
            _buildSection(
              icon: Icons.local_hospital_rounded,
              title: 'Çalıştığı Hastane',
              child: _buildHospitalCard(),
            ),
            const SizedBox(height: 20),
          ],
          // Çalışma Saatleri
          _buildWorkingHoursSection(),
        ],
      ),
    );
  }

  // YORUMLAR SEKME
  Widget _buildReviewsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Özeti
          if (_averageRating > 0) _buildRatingSummary(),
          const SizedBox(height: 20),
          // Yorumlar
          if (_reviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      size: 64,
                      color: AppTheme.iconGray,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz yorum yapılmamış',
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.grayText,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._reviews.map((review) {
              final rating = _ratings.firstWhere(
                (r) => r.appointmentId == review.appointmentId,
                orElse: () => Rating(
                  id: '',
                  userId: review.userId,
                  hospitalId: review.hospitalId,
                  doctorId: review.doctorId,
                  appointmentId: review.appointmentId,
                  hospitalRating: 0,
                  doctorRating: 0,
                  createdAt: review.createdAt,
                ),
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildReviewCard(review, rating),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTheme.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildHospitalCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HospitalDetailScreen(
                hospital: _hospital!,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.tealBlue.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.lightTurquoise,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _hospital!.image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: buildImage(
                          _hospital!.image!,
                          fit: BoxFit.cover,
                          errorWidget: Icon(
                            Icons.local_hospital_rounded,
                            size: 30,
                            color: AppTheme.tealBlue,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.local_hospital_rounded,
                        size: 30,
                        color: AppTheme.tealBlue,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hospital!.name,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                            _hospital!.address,
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
    );
  }

  Widget _buildWorkingHoursSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: AppTheme.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Çalışma Saatleri',
                style: AppTheme.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._getOrderedWorkingHours().map((entry) {
            final day = _getDayName(entry.key);
            final hours = entry.value as Map<String, dynamic>;
            final isAvailable = hours['isAvailable'] == true;
            final isToday = entry.key == _getTodayDayName();

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isToday
                    ? AppTheme.tealBlue.withOpacity(0.1)
                    : AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isToday
                      ? AppTheme.tealBlue.withOpacity(0.4)
                      : AppTheme.dividerLight,
                  width: isToday ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppTheme.tealBlue
                              : AppTheme.inputFieldGray,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${_getDayDate(entry.key)}',
                            style: AppTheme.bodyMedium.copyWith(
                              color: isToday
                                  ? AppTheme.white
                                  : AppTheme.grayText,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                day,
                                style: AppTheme.bodyMedium.copyWith(
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isToday
                                      ? AppTheme.tealBlue
                                      : AppTheme.darkText,
                                ),
                              ),
                              if (isToday) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.tealBlue,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Bugün',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? (isToday
                              ? AppTheme.tealBlue.withOpacity(0.15)
                              : Colors.green.withOpacity(0.1))
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _formatWorkingHours(hours),
                      style: AppTheme.bodyMedium.copyWith(
                        color: isAvailable
                            ? (isToday
                                ? AppTheme.tealBlue
                                : Colors.green.shade700)
                            : Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.tealBlue.withOpacity(0.1),
            AppTheme.lightTurquoise.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.tealBlue.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                _averageRating.toStringAsFixed(1),
                style: AppTheme.headingLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.tealBlue,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < _averageRating.round()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: AppTheme.accentYellow,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_reviews.length} yorum',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.grayText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review, Rating rating) {
    return FutureBuilder<User?>(
      future: JsonService.getUser(review.userId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final userName = user != null
            ? '${user.name} ${user.surname}'
            : 'Kullanıcı';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Kullanıcı Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.mediumTurquoise,
                    ),
                    child: user?.profileImage != null
                        ? ClipOval(
                            child: buildImage(
                              user!.profileImage!,
                              fit: BoxFit.cover,
                              errorWidget: Icon(
                                Icons.person_rounded,
                                size: 24,
                                color: AppTheme.white,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.person_rounded,
                            size: 24,
                            color: AppTheme.white,
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Kullanıcı Adı ve Puan
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (rating.doctorRating != null && rating.doctorRating! > 0)
                          Row(
                            children: List.generate(
                              5,
                              (index) => Icon(
                                index < (rating.doctorRating ?? 0)
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                size: 16,
                                color: AppTheme.accentYellow,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Tarih
                  Text(
                    _formatDate(review.createdAt),
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.iconGray,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Yorum Metni
              Text(
                review.comment,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.darkText,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Bugün';
      } else if (difference.inDays == 1) {
        return 'Dün';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} gün önce';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks hafta önce';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months ay önce';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years yıl önce';
      }
    } catch (e) {
      return dateString;
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: buildImage(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
