import 'package:flutter/material.dart';
import '../../models/doctor.dart';
import '../../models/hospital.dart';
import '../../theme/app_theme.dart';
import '../../screens/doctor_detail_screen.dart';
import '../image_widget.dart';

class DoctorCardHome extends StatelessWidget {
  final Doctor doctor;
  final Hospital? hospital;
  final Map<String, Map<String, dynamic>> doctorRatings;

  const DoctorCardHome({
    super.key,
    required this.doctor,
    this.hospital,
    required this.doctorRatings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
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
              color: AppTheme.tealBlue.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
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
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.cardGradient,
                        ),
                        child: ClipOval(
                          child: doctor.image != null
                              ? buildImage(
                                  doctor.image!,
                                  fit: BoxFit.cover,
                                  width: 72,
                                  height: 72,
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
                      if (doctorRatings.containsKey(doctor.id))
                        Positioned(
                          top: 0,
                          right: 0,
                          child: _buildDoctorRatingOverlay(doctor.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    doctor.fullName,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hospital != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_hospital,
                          size: 11,
                          color: AppTheme.iconGray,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            hospital!.name,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.grayText,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.inputFieldGray,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 10,
                          color: AppTheme.iconGray,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Müsait: Bugün',
                            style: AppTheme.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildDoctorRatingOverlay(String doctorId) {
    final ratingData = doctorRatings[doctorId];
    if (ratingData == null) return const SizedBox.shrink();
    
    final reviewCount = ratingData['reviewCount'] as int;
    final averageRating = ratingData['averageRating'] as double;
    
    // Eğer yorum yoksa gösterme
    if (reviewCount == 0) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 10,
            color: Colors.white,
          ),
          const SizedBox(width: 2),
          Text(
            averageRating > 0 
                ? averageRating.toStringAsFixed(1)
                : '$reviewCount',
            style: AppTheme.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

