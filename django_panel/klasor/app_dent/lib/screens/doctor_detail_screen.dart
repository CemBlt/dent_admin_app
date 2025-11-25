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

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  Hospital? _hospital;
  List<Review> _reviews = [];
  List<Rating> _ratings = [];
  double _averageRating = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // AppBar
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: AppTheme.tealBlue,
                  leading: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.white),
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
                        widget.doctor.fullName,
                        style: AppTheme.headingSmall.copyWith(
                          color: AppTheme.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    centerTitle: false,
                    titlePadding: const EdgeInsets.only(
                      left: 56,
                      bottom: 16,
                      right: 16,
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                      ),
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 4),
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
                                ? buildImage(
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
                        // Doktor Bilgileri
                        _buildInfoSection(),
                        const SizedBox(height: 24),
                        // Çalıştığı Hastane
                        if (_hospital != null) ...[
                          _buildHospitalSection(),
                          const SizedBox(height: 24),
                        ],
                        // Çalışma Saatleri
                        _buildWorkingHoursSection(),
                        const SizedBox(height: 24),
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.doctor.fullName,
                      style: AppTheme.headingMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTurquoise,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.doctor.specialty,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.tealBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_averageRating > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentYellow.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.star,
                        color: AppTheme.accentYellow,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _averageRating.toStringAsFixed(1),
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (widget.doctor.bio.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: AppTheme.dividerLight),
            const SizedBox(height: 16),
            Text(
              'Hakkında',
              style: AppTheme.headingSmall,
            ),
            const SizedBox(height: 8),
            Text(
              widget.doctor.bio,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.grayText,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHospitalSection() {
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
          Text(
            'Çalıştığı Hastane',
            style: AppTheme.headingSmall,
          ),
          const SizedBox(height: 16),
          InkWell(
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
                            Icons.location_on,
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
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.iconGray,
                ),
              ],
            ),
          ),
        ],
      ),
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
          Text(
            'Çalışma Saatleri',
            style: AppTheme.headingSmall,
          ),
          const SizedBox(height: 16),
          ...widget.doctor.workingHours.entries.map((entry) {
            final day = entry.key;
            final hours = entry.value as Map<String, dynamic>;
            final isAvailable = hours['isAvailable'] as bool;
            final start = hours['start'] as String?;
            final end = hours['end'] as String?;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getDayName(day),
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isAvailable && start != null && end != null)
                    Text(
                      '$start - $end',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.tealBlue,
                      ),
                    )
                  else
                    Text(
                      'Kapalı',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.iconGray,
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
              Text(
                'Yorumlar',
                style: AppTheme.headingSmall,
              ),
              if (_averageRating > 0)
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: AppTheme.accentYellow,
                      size: 20,
                    ),
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
                  doctorId: review.doctorId,
                  appointmentId: review.appointmentId,
                  hospitalRating: 0,
                  doctorRating: 0,
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
            border: Border.all(
              color: AppTheme.dividerLight,
              width: 1,
            ),
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
                        : Icon(
                            Icons.person,
                            size: 20,
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
                        if (rating.doctorRating != null && rating.doctorRating! > 0)
                          Row(
                            children: List.generate(
                              5,
                              (index) => Icon(
                                index < (rating.doctorRating ?? 0)
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
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.darkText,
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
                  preselectedHospitalId: widget.doctor.hospitalId,
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
          _displayedCount = (_displayedCount + _loadMoreCount)
              .clamp(0, widget.reviews.length);
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
            border: Border.all(
              color: AppTheme.dividerLight,
              width: 1,
            ),
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
                        : Icon(
                            Icons.person,
                            size: 20,
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
                        if (rating.doctorRating != null && rating.doctorRating! > 0)
                          Row(
                            children: List.generate(
                              5,
                              (index) => Icon(
                                index < (rating.doctorRating ?? 0)
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
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.darkText,
                ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
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
                  colors: [
                    AppTheme.lightTurquoise,
                    AppTheme.mediumTurquoise,
                  ],
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
                            doctorId: review.doctorId,
                            appointmentId: review.appointmentId,
                            hospitalRating: 0,
                            doctorRating: 0,
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

