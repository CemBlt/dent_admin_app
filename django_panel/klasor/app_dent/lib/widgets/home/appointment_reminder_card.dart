import 'package:flutter/material.dart';
import '../../models/appointment.dart';
import '../../models/doctor.dart';
import '../../models/hospital.dart';
import '../../theme/app_theme.dart';
import '../../screens/appointments_screen.dart';

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

class AppointmentReminderCard extends StatelessWidget {
  final Appointment? appointment;
  final Hospital? hospital;
  final Doctor? doctor;
  final VoidCallback onOpenAppointments;

  const AppointmentReminderCard({
    super.key,
    this.appointment,
    this.hospital,
    this.doctor,
    required this.onOpenAppointments,
  });

  @override
  Widget build(BuildContext context) {
    if (appointment == null) {
      return const SizedBox.shrink();
    }

    final statusStyle = _getAppointmentStatusStyle(appointment!.status);
    final hospitalAddress = hospital?.address ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: onOpenAppointments,
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
                          _formatAppointmentDateTime(appointment!),
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.grayText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (statusStyle != null &&
                      appointment!.status == 'cancelled')
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
                    ? '${doctor!.name} ${doctor!.surname}'
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
                  onPressed: onOpenAppointments,
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
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
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
}

