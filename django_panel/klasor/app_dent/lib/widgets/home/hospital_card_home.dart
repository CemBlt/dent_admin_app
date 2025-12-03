import 'package:flutter/material.dart';
import '../../models/hospital.dart';
import '../../theme/app_theme.dart';
import '../../screens/hospital_detail_screen.dart';
import '../hospital_logo.dart';
import 'package:geolocator/geolocator.dart';

class HospitalCardHome extends StatelessWidget {
  final Hospital hospital;
  final Position? userPosition;
  final double? distance;
  final Map<String, Map<String, dynamic>> hospitalRatings;

  const HospitalCardHome({
    super.key,
    required this.hospital,
    this.userPosition,
    this.distance,
    required this.hospitalRatings,
  });

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    HospitalLogo(
                      imageUrl: hospital.image,
                      size: 80,
                    ),
                    if (hospitalRatings.containsKey(hospital.id))
                      Positioned(
                        top: 4,
                        left: 4,
                        child: _buildHospitalRatingOverlay(hospital.id),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_city_rounded,
                            size: 16,
                            color: AppTheme.iconGray,
                          ),
                          const SizedBox(width: 5),
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
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (userPosition != null && distance != null)
                            _buildHospitalBadge(
                              icon: Icons.location_on,
                              label: _getDistanceText(distance!),
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

  Widget _buildHospitalBadge({
    required IconData icon,
    required String label,
    Color? backgroundColor,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.inputFieldGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(icon, size: 12, color: iconColor ?? AppTheme.iconGray),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: textColor,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getDistanceText(double distance) {
    if (distance < 0) {
      return 'Mesafe bilgisi yok';
    }
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }

  Widget _buildHospitalRatingOverlay(String hospitalId) {
    final ratingData = hospitalRatings[hospitalId];
    if (ratingData == null) return const SizedBox.shrink();
    
    final reviewCount = ratingData['reviewCount'] as int;
    final averageRating = ratingData['averageRating'] as double;
    
    if (reviewCount == 0) return const SizedBox.shrink();
    
    return Container(
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
    );
  }

  Widget _buildWorkingHoursBadge(Hospital hospital) {
    final hoursInfo = _getTodayWorkingHours(hospital);
    
    if (hoursInfo['is24Hours'] == true) {
      return _buildHospitalBadge(
        icon: Icons.schedule_rounded,
        label: hoursInfo['text'] as String,
        backgroundColor: AppTheme.tealBlue.withOpacity(0.1),
        textColor: AppTheme.tealBlue,
        iconColor: AppTheme.tealBlue,
      );
    } else if (hoursInfo['isOpen'] == true) {
      return _buildHospitalBadge(
        icon: Icons.schedule_rounded,
        label: hoursInfo['text'] as String,
        backgroundColor: Colors.green.withOpacity(0.1),
        textColor: Colors.green.shade700,
        iconColor: Colors.green.shade700,
      );
    } else {
      return _buildHospitalBadge(
        icon: Icons.schedule_rounded,
        label: hoursInfo['text'] as String,
        backgroundColor: Colors.red.withOpacity(0.1),
        textColor: Colors.red.shade700,
        iconColor: Colors.red.shade700,
      );
    }
  }

  String _getTodayDayName() {
    final now = DateTime.now();
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[now.weekday - 1];
  }

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
}

