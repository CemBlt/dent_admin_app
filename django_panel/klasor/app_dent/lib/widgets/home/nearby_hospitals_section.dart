import 'package:flutter/material.dart';
import '../../models/hospital.dart';
import '../../theme/app_theme.dart';
import '../../screens/all_hospitals_screen.dart';
import 'hospital_card_home.dart';
import 'package:geolocator/geolocator.dart';

class NearbyHospitalsSection extends StatelessWidget {
  final List<Hospital> hospitals;
  final Position? userPosition;
  final Map<String, double> hospitalDistances;
  final Map<String, Map<String, dynamic>> hospitalRatings;
  final VoidCallback onRequestLocationPermission;

  const NearbyHospitalsSection({
    super.key,
    required this.hospitals,
    this.userPosition,
    required this.hospitalDistances,
    required this.hospitalRatings,
    required this.onRequestLocationPermission,
  });

  @override
  Widget build(BuildContext context) {
    if (hospitals.isEmpty) return const SizedBox.shrink();

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
                  userPosition != null 
                      ? 'Yakınımdaki Hastaneler'
                      : 'Hastaneler',
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
        if (userPosition == null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.inputFieldGray,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.dividerLight),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_off_rounded,
                    color: AppTheme.iconGray,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yakındaki hastaneleri görmek için konum izni gerekli',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Konum izni vererek size en yakın hastaneleri görebilirsiniz.',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.grayText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onRequestLocationPermission,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text(
                      'İzin Ver',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.tealBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: hospitals.length > 3 ? 3 : hospitals.length,
          itemBuilder: (context, index) {
            final hospital = hospitals[index];
            return HospitalCardHome(
              hospital: hospital,
              userPosition: userPosition,
              distance: hospitalDistances[hospital.id],
              hospitalRatings: hospitalRatings,
            );
          },
        ),
      ],
    );
  }
}

