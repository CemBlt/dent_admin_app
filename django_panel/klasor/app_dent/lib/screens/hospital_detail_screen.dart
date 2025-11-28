import 'package:flutter/material.dart';

import '../models/doctor.dart';
import '../models/hospital.dart';
import '../models/rating.dart';
import '../models/review.dart';
import '../models/service.dart';
import '../models/user.dart';
import '../services/json_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hospital_logo.dart';
import '../widgets/image_widget.dart';
import 'create_appointment_screen.dart';
import 'doctor_detail_screen.dart';

class HospitalDetailScreen extends StatefulWidget {
  final Hospital hospital;

  const HospitalDetailScreen({super.key, required this.hospital});

  @override
  State<HospitalDetailScreen> createState() => _HospitalDetailScreenState();
}

class _HospitalDetailScreenState extends State<HospitalDetailScreen>
    with SingleTickerProviderStateMixin {
  List<Doctor> _doctors = [];
  List<Service> _services = [];
  List<Review> _reviews = [];
  List<Rating> _ratings = [];
  double _averageRating = 0.0;
  bool _isLoading = true;
  int _currentImageIndex = 0;
  PageController? _pageController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    if (widget.hospital.gallery != null &&
        widget.hospital.gallery!.isNotEmpty) {
      _pageController = PageController();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final doctors = await JsonService.getDoctorsByHospital(widget.hospital.id);

    // Hizmetleri yükle
    final allServices = await JsonService.getServices();
    final hospitalServices = allServices.where((service) {
      return widget.hospital.services.contains(service.id);
    }).toList();

    // Yorumları ve puanlamaları yükle
    final reviews = await JsonService.getReviewsByHospital(widget.hospital.id);
    final ratings = await JsonService.getRatingsByHospital(widget.hospital.id);
    final averageRating = await JsonService.getHospitalAverageRating(
      widget.hospital.id,
    );

    setState(() {
      _doctors = doctors;
      _services = hospitalServices;
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
      if (widget.hospital.workingHours.containsKey(day)) {
        ordered.add(
          MapEntry(
            day,
            widget.hospital.workingHours[day],
          ),
        );
      }
    }
    return ordered;
  }

  String _formatWorkingHours(Map<String, dynamic>? hours) {
    if (hours == null || hours['isAvailable'] == false) {
      return 'Kapalı';
    }
    final start = hours['start'] ?? '';
    final end = hours['end'] ?? '';
    return '$start - $end';
  }

  String _getTodayDayName() {
    final now = DateTime.now();
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[now.weekday - 1];
  }

  Map<String, dynamic> _getTodayWorkingHours() {
    if (widget.hospital.isOpen24Hours) {
      return {
        'isOpen': true,
        'is24Hours': true,
        'text': '7/24 Açık',
      };
    }

    final today = _getTodayDayName();
    final todayHours = widget.hospital.workingHours[today] as Map<String, dynamic>?;
    
    if (todayHours == null || todayHours['isAvailable'] != true) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
      final tomorrowDayName = tomorrowDays[tomorrow.weekday - 1];
      final tomorrowHours = widget.hospital.workingHours[tomorrowDayName] as Map<String, dynamic>?;
      
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

  List<String> _getGalleryImages() {
    final gallery = widget.hospital.gallery ?? [];
    return gallery.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final galleryImages = _getGalleryImages();
    final todayHours = _getTodayWorkingHours();

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
              : NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      // Hero Header
                      SliverAppBar(
                        expandedHeight: 320,
                        pinned: true,
                        backgroundColor: AppTheme.tealBlue,
                        title: Text(
                          widget.hospital.name,
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
                              widget.hospital.image != null
                                  ? buildImage(
                                      widget.hospital.image!,
                                      fit: BoxFit.cover,
                                      errorWidget: Container(
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.accentGradient,
                                        ),
                                        child: const Icon(
                                          Icons.local_hospital_rounded,
                                          size: 80,
                                          color: AppTheme.white,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.accentGradient,
                                      ),
                                      child: const Icon(
                                        Icons.local_hospital_rounded,
                                        size: 80,
                                        color: AppTheme.white,
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
                              // Tıklanabilir alan
                              if (widget.hospital.image != null)
                                Positioned.fill(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _showFullScreenImage(
                                        context,
                                        widget.hospital.image!,
                                      ),
                                      child: Container(),
                                    ),
                                  ),
                                ),
                              // Badge'ler
                              Positioned(
                                bottom: 16,
                                left: 16,
                                right: 16,
                                child: Row(
                                  children: [
                                    _buildStatusBadge(
                                      todayHours['is24Hours'] == true
                                          ? AppTheme.tealBlue
                                          : todayHours['isOpen'] == true
                                              ? Colors.green
                                              : Colors.red,
                                      todayHours['text'] as String,
                                    ),
                                    const SizedBox(width: 8),
                                    if (widget.hospital.provinceName != null &&
                                        widget.hospital.districtName != null)
                                      _buildLocationBadge(),
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
                                      Icon(Icons.people_outline_rounded, size: 22),
                                      const SizedBox(width: 8),
                                      const Text('Doktorlar'),
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
                      _buildInfoTab(galleryImages),
                      _buildDoctorsTab(),
                      _buildReviewsTab(),
                    ],
                  ),
                ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStatusBadge(Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTheme.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            size: 14,
            color: AppTheme.white,
          ),
          const SizedBox(width: 6),
          Text(
            '${widget.hospital.provinceName}/${widget.hospital.districtName}',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.tealBlue.withOpacity(0.4),
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
                builder: (context) => CreateAppointmentScreen(
                  preselectedHospitalId: widget.hospital.id,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: AppTheme.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Randevu Oluştur',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // BİLGİLER SEKME
  Widget _buildInfoTab(List<String> galleryImages) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fotoğraf Galerisi
          if (galleryImages.isNotEmpty) ...[
            _buildGallerySection(galleryImages),
            const SizedBox(height: 24),
          ],
          // İletişim Bilgileri
          _buildContactSection(),
          const SizedBox(height: 20),
          // Çalışma Saatleri
          _buildWorkingHoursSection(),
          const SizedBox(height: 20),
          // Hizmetler
          if (_services.isNotEmpty) ...[
            _buildServicesSection(),
            const SizedBox(height: 20),
          ],
          // Açıklama
          if (widget.hospital.description.isNotEmpty) ...[
            _buildDescriptionSection(),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  // DOKTORLAR SEKME
  Widget _buildDoctorsTab() {
    if (_doctors.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: AppTheme.iconGray,
              ),
              const SizedBox(height: 16),
              Text(
                'Henüz doktor eklenmemiş',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.grayText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _doctors.length,
      itemBuilder: (context, index) {
        return _buildDoctorCard(_doctors[index]);
      },
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
                  appointmentId: review.appointmentId,
                  hospitalRating: 0,
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

  Widget _buildRatingSummary() {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: AppTheme.headingLarge.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < _averageRating.round()
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
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_reviews.length} Değerlendirme',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kullanıcılarımızın görüşleri',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.grayText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGallerySection(List<String> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fotoğraflar',
          style: AppTheme.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController ?? PageController(),
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GestureDetector(
                    onTap: () => _showFullScreenImage(
                      context,
                      images[index],
                      allImages: images,
                      initialIndex: index,
                    ),
                    child: buildImage(
                      images[index],
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        color: AppTheme.inputFieldGray,
                        child: const Icon(
                          Icons.image,
                          size: 60,
                          color: AppTheme.iconGray,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            images.length,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentImageIndex == index
                    ? AppTheme.tealBlue
                    : AppTheme.iconGray.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
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
                Icons.contact_phone_rounded,
                color: AppTheme.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'İletişim Bilgileri',
              style: AppTheme.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildContactCard(
          icon: Icons.location_on_rounded,
          title: 'Adres',
          value: widget.hospital.address,
          color: Colors.red,
          onTap: () {
            // Harita açılabilir
          },
        ),
        const SizedBox(height: 12),
        _buildContactCard(
          icon: Icons.phone_rounded,
          title: 'Telefon',
          value: widget.hospital.phone,
          color: Colors.green,
          onTap: () {
            // Telefon arama
          },
        ),
        const SizedBox(height: 12),
        _buildContactCard(
          icon: Icons.email_rounded,
          title: 'E-posta',
          value: widget.hospital.email,
          color: AppTheme.tealBlue,
          onTap: () {
            // E-posta gönderme
          },
        ),
      ],
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
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
          if (widget.hospital.isOpen24Hours)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.tealBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.tealBlue.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: AppTheme.tealBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '7/24 Açık',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.tealBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
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

  Widget _buildServicesSection() {
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
                  Icons.medical_services_rounded,
                  color: AppTheme.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Hizmetler',
                style: AppTheme.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _services.length,
            itemBuilder: (context, index) {
              final service = _services[index];
              return _buildServiceCard(service);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Service service) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightTurquoise.withOpacity(0.2),
            AppTheme.tealBlue.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.tealBlue.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.tealBlue.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: AppTheme.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              service.name,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.tealBlue,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
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
                  Icons.info_outline_rounded,
                  color: AppTheme.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Hakkında',
                style: AppTheme.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.hospital.description,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.grayText,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorDetailScreen(doctor: doctor),
          ),
        );
      },
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.cardGradient,
              ),
              child: ClipOval(
                child: doctor.image != null
                    ? buildImage(
                        doctor.image!,
                        fit: BoxFit.cover,
                        width: 80,
                        height: 80,
                        errorWidget: Icon(
                          Icons.person,
                          size: 40,
                          color: AppTheme.tealBlue,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 40,
                        color: AppTheme.tealBlue,
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                doctor.fullName,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.cardGradient,
                    ),
                    child: user?.profileImage != null
                        ? ClipOval(
                            child: buildImage(
                              user!.profileImage!,
                              fit: BoxFit.cover,
                              errorWidget: Icon(
                                Icons.person,
                                size: 24,
                                color: AppTheme.white,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 24,
                            color: AppTheme.white,
                          ),
                  ),
                  const SizedBox(width: 12),
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
                        if (rating.hospitalRating > 0)
                          Row(
                            children: List.generate(
                              5,
                              (index) => Icon(
                                index < rating.hospitalRating
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                size: 14,
                                color: AppTheme.accentYellow,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDate(review.createdAt),
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.iconGray,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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

  void _showFullScreenImage(
    BuildContext context,
    String imagePath, {
    List<String>? allImages,
    int initialIndex = 0,
  }) {
    final images = allImages ?? [imagePath];
    final pageController = PageController(initialPage: initialIndex);
    int currentIndex = initialIndex;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return WillPopScope(
            onWillPop: () async {
              pageController.dispose();
              return true;
            },
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.zero,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: pageController,
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setDialogState(() {
                        currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 3.0,
                        child: Center(
                          child: buildImage(
                            images[index],
                            fit: BoxFit.contain,
                            errorWidget: Container(
                              color: AppTheme.inputFieldGray,
                              padding: const EdgeInsets.all(40),
                              child: const Icon(
                                Icons.image,
                                size: 100,
                                color: AppTheme.iconGray,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppTheme.white,
                        size: 30,
                      ),
                      onPressed: () {
                        pageController.dispose();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${currentIndex + 1} / ${images.length}',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      pageController.dispose();
    });
  }
}
