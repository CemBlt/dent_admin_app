import 'package:flutter/material.dart';
import '../../models/doctor.dart';
import '../../models/hospital.dart';
import '../../theme/app_theme.dart';
import '../../screens/all_doctors_screen.dart';
import 'doctor_card_home.dart';

class PopularDoctorsSection extends StatelessWidget {
  final List<Doctor> popularDoctors;
  final List<Hospital> hospitals;
  final Map<String, Map<String, dynamic>> doctorRatings;

  const PopularDoctorsSection({
    super.key,
    required this.popularDoctors,
    required this.hospitals,
    required this.doctorRatings,
  });

  @override
  Widget build(BuildContext context) {
    if (popularDoctors.isEmpty) return const SizedBox.shrink();

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
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: popularDoctors.length,
            itemBuilder: (context, index) {
              final doctor = popularDoctors[index];
              return DoctorCardHome(
                doctor: doctor,
                hospital: _getHospitalByDoctor(doctor),
                doctorRatings: doctorRatings,
              );
            },
          ),
        ),
      ],
    );
  }

  Hospital? _getHospitalByDoctor(Doctor doctor) {
    try {
      return hospitals.firstWhere((h) => h.id == doctor.hospitalId);
    } catch (e) {
      return null;
    }
  }
}

