import 'package:flutter/material.dart';

import '../models/doctor.dart';
import '../models/hospital.dart';
import '../models/rating.dart';
import '../models/review.dart';
import '../models/service.dart';
import '../models/user.dart';
import '../services/json_service.dart';
import '../theme/app_theme.dart';
import '../widgets/image_widget.dart';
import 'create_appointment_screen.dart';

class HospitalDetailScreen extends StatefulWidget {
  final Hospital hospital;

  const HospitalDetailScreen({super.key, required this.hospital});

  @override
  State<HospitalDetailScreen> createState() => _HospitalDetailScreenState();
}

class _HospitalDetailScreenState extends State<HospitalDetailScreen> {
  List<Doctor> _doctors = [];
  List<Service> _services = [];
  List<Review> _reviews = [];
  List<Rating> _ratings = [];
  double _averageRating = 0.0;
  bool _isLoading = true;
  int _currentImageIndex = 0;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.hospital.gallery != null &&
        widget.hospital.gallery!.isNotEmpty) {
      _pageController = PageController();
    }
  }

  @override
  void dispose() {
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

  String _formatWorkingHours(Map<String, dynamic>? hours) {
    if (hours == null || hours['isAvailable'] == false) {
      return 'Kapalı';
    }
    final start = hours['start'] ?? '';
    final end = hours['end'] ?? '';
    return '$start - $end';
  }

  List<String> _getGalleryImages() {
    final gallery = widget.hospital.gallery ?? [];
    // Maksimum 5 fotoğraf göster
    return gallery.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final galleryImages = _getGalleryImages();

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
              : CustomScrollView(
                  slivers: [
                    // Header
                    SliverAppBar(
                      expandedHeight: 250,
                      pinned: true,
                      backgroundColor: AppTheme.tealBlue,
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
                        title: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            widget.hospital.name,
                            style: AppTheme.headingMedium.copyWith(
                              color: AppTheme.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 16),
                        background: widget.hospital.image != null
                            ? GestureDetector(
                                onTap: () => _showFullScreenImage(
                                  context,
                                  widget.hospital.image!,
                                ),
                                child: buildImage(
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
                      ),
                    ),
                    // İçerik
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fotoğraf Galerisi (Eğer varsa)
                            if (galleryImages.isNotEmpty) ...[
                              _buildGallerySection(galleryImages),
                              const SizedBox(height: 24),
                            ],
                            // Hastane Bilgileri
                            _buildInfoSection(),
                            const SizedBox(height: 24),
                            // Çalışma Saatleri
                            _buildWorkingHoursSection(),
                            const SizedBox(height: 24),
                            // Hizmetler
                            if (_services.isNotEmpty) ...[
                              _buildServicesSection(),
                              const SizedBox(height: 24),
                            ],
                            // Doktorlar
                            if (_doctors.isNotEmpty) ...[
                              _buildDoctorsSection(),
                              const SizedBox(height: 24),
                            ],
                            // Yorumlar ve Puanlar
                            _buildReviewsSection(),
                            const SizedBox(height: 24),
                            // Randevu Oluştur Butonu
                            _buildAppointmentButton(),
                            const SizedBox(height: 20),
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
                  // Fullscreen Image Viewer
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
                  // Close Button
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
                  // Image Counter (if multiple images)
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

  Widget _buildGallerySection(List<String> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fotoğraflar', style: AppTheme.headingSmall),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: PageController(),
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
        // Sayfa göstergesi
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

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Text('Hastane Bilgileri', style: AppTheme.headingSmall),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.location_on, widget.hospital.address),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.phone, widget.hospital.phone),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.email, widget.hospital.email),
          if (widget.hospital.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              widget.hospital.description,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.grayText),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.tealBlue, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: AppTheme.bodyMedium)),
      ],
    );
  }

  Widget _buildWorkingHoursSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Text('Çalışma Saatleri', style: AppTheme.headingSmall),
          const SizedBox(height: 16),
          ...widget.hospital.workingHours.entries.map((entry) {
            final day = _getDayName(entry.key);
            final hours = entry.value as Map<String, dynamic>;
            final isAvailable = hours['isAvailable'] == true;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    day,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _formatWorkingHours(hours),
                    style: AppTheme.bodyMedium.copyWith(
                      color: isAvailable
                          ? AppTheme.successGreen
                          : AppTheme.grayText,
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
          Text('Hizmetler', style: AppTheme.headingSmall),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _services.map((service) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.lightTurquoise.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.tealBlue.withOpacity(0.3)),
                ),
                child: Text(
                  service.name,
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.tealBlue),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Doktorlar', style: AppTheme.headingSmall),
              Text(
                '${_doctors.length} doktor',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.grayText),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _doctors.length,
              itemBuilder: (context, index) {
                final doctor = _doctors[index];
                return _buildDoctorCard(doctor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.mediumTurquoise,
              image: doctor.image != null
                  ? DecorationImage(
                      image: AssetImage(doctor.image!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: doctor.image == null
                ? const Icon(Icons.person, size: 40, color: AppTheme.white)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            doctor.name,
            style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            doctor.specialty,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.grayText,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    // Son 2 yorumu al (tarihe göre sıralı)
    final sortedReviews = List<Review>.from(_reviews);
    sortedReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final displayedReviews = sortedReviews.take(2).toList();
    final hasMoreReviews = _reviews.length > 2;

    return Container(
      padding: const EdgeInsets.all(20),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Yorumlar', style: AppTheme.headingSmall),
              if (_averageRating > 0)
                Row(
                  children: [
                    Icon(Icons.star, color: AppTheme.accentYellow, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      _averageRating.toStringAsFixed(1),
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${_reviews.length})',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.grayText,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_reviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      size: 48,
                      color: AppTheme.iconGray,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Henüz yorum yapılmamış',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.grayText,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ...displayedReviews.map((review) {
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
              return _buildReviewCard(review, rating);
            }),
            if (hasMoreReviews) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => _showAllReviewsDialog(),
                  child: Text(
                    'Tümünü Gör',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.tealBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showAllReviewsDialog() {
    // Tarihe göre sıralı yorumlar
    final sortedReviews = List<Review>.from(_reviews);
    sortedReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    showDialog(
      context: context,
      builder: (context) => _AllReviewsDialog(
        reviews: sortedReviews,
        ratings: _ratings,
        averageRating: _averageRating,
        totalCount: _reviews.length,
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
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerLight, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Kullanıcı Avatar
                  Container(
                    width: 40,
                    height: 40,
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
                                Icons.person,
                                size: 20,
                                color: AppTheme.white,
                              ),
                            ),
                          )
                        : Icon(Icons.person, size: 20, color: AppTheme.white),
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
                        if (rating.hospitalRating > 0)
                          Row(
                            children: List.generate(
                              5,
                              (index) => Icon(
                                index < rating.hospitalRating
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 14,
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
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.darkText),
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

  Widget _buildAppointmentButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.tealBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
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
}

// Tüm Yorumlar Dialog Widget'ı
class _AllReviewsDialog extends StatefulWidget {
  final List<Review> reviews;
  final List<Rating> ratings;
  final double averageRating;
  final int totalCount;

  const _AllReviewsDialog({
    required this.reviews,
    required this.ratings,
    required this.averageRating,
    required this.totalCount,
  });

  @override
  State<_AllReviewsDialog> createState() => _AllReviewsDialogState();
}

class _AllReviewsDialogState extends State<_AllReviewsDialog> {
  final ScrollController _scrollController = ScrollController();
  int _displayedCount = 5; // İlk 5 yorum gösterilecek
  final int _loadMoreCount = 5; // Her seferinde 5 yorum daha yüklenecek

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Scroll pozisyonu %80'e ulaştığında daha fazla yorum yükle
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll >= maxScroll * 0.8) {
      if (_displayedCount < widget.reviews.length) {
        setState(() {
          _displayedCount = (_displayedCount + _loadMoreCount).clamp(
            0,
            widget.reviews.length,
          );
        });
      }
    }
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

  Widget _buildReviewCard(Review review, Rating rating) {
    return FutureBuilder<User?>(
      future: JsonService.getUser(review.userId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final userName = user != null
            ? '${user.name} ${user.surname}'
            : 'Kullanıcı';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerLight, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Kullanıcı Avatar
                  Container(
                    width: 40,
                    height: 40,
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
                                Icons.person,
                                size: 20,
                                color: AppTheme.white,
                              ),
                            ),
                          )
                        : Icon(Icons.person, size: 20, color: AppTheme.white),
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
                        if (rating.hospitalRating > 0)
                          Row(
                            children: List.generate(
                              5,
                              (index) => Icon(
                                index < rating.hospitalRating
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 14,
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
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.darkText),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedReviews = widget.reviews.take(_displayedCount).toList();
    final hasMore = _displayedCount < widget.reviews.length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.lightTurquoise, AppTheme.mediumTurquoise],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tüm Yorumlar',
                          style: AppTheme.headingMedium.copyWith(
                            color: AppTheme.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (widget.averageRating > 0)
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: AppTheme.accentYellow,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.averageRating.toStringAsFixed(1)} (${widget.totalCount} yorum)',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.white,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Yorumlar Listesi
            Flexible(
              child: displayedReviews.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              size: 48,
                              color: AppTheme.iconGray,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Henüz yorum yapılmamış',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.grayText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: displayedReviews.length + (hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == displayedReviews.length) {
                          // Loading indicator
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final review = displayedReviews[index];
                        final rating = widget.ratings.firstWhere(
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
                        return _buildReviewCard(review, rating);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
