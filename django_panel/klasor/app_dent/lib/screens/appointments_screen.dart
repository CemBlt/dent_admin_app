import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/hospital.dart';
import '../models/service.dart';
import '../providers/appointments_provider.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    AppEventService.log('screen_appointments_opened');
  }

  void _cancelAppointment(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Randevuyu İptal Et', style: AppTheme.headingSmall),
        content: Text(
          'Bu randevuyu iptal etmek istediğinize emin misiniz?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hayır',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.grayText),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmCancelAppointment(appointment);
            },
            child: Text(
              'Evet',
              style: AppTheme.bodyMedium.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancelAppointment(Appointment appointment) async {
    final controller = ref.read(appointmentsControllerProvider.notifier);
    final result = await controller.cancelAppointment(appointment);
    if (!mounted) return;
    _showSnackBar(
      result.message,
      result.success ? AppTheme.successGreen : Colors.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appointmentsControllerProvider);
    final controller = ref.read(appointmentsControllerProvider.notifier);
    final upcoming = _upcomingAppointments(state);
    final history = _historyAppointments(state);
    final visibleAppointments =
        state.selectedTab == 0 ? upcoming : history;

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
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.lightTurquoise,
                            AppTheme.mediumTurquoise,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          if (Navigator.canPop(context))
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.arrow_back),
                              color: AppTheme.darkText,
                              onPressed: () => Navigator.pop(context),
                            )
                          else
                            const SizedBox(width: 48),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Randevularım',
                              textAlign: TextAlign.center,
                              style: AppTheme.headingLarge.copyWith(
                                color: AppTheme.darkText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 60), // denge için
                        ],
                      ),
                    ),
                    // Tab Bar
                    Container(
                      color: AppTheme.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTabButton(
                              state,
                              controller,
                              0,
                              'Yaklaşan',
                              upcoming.length,
                            ),
                          ),
                          Expanded(
                            child: _buildTabButton(
                              state,
                              controller,
                              1,
                              'Geçmiş',
                              history.length,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state.errorMessage != null && !state.isLoading)
                      Container(
                        width: double.infinity,
                        color: Colors.red.withOpacity(0.08),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.errorMessage!,
                                style: AppTheme.bodySmall.copyWith(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // List
                    Expanded(
                      child: !AuthService.isAuthenticated
                          ? _buildNotLoggedInView(controller)
                          : RefreshIndicator(
                              onRefresh: controller.refresh,
                              child: _buildAppointmentsList(
                                state,
                                visibleAppointments,
                              ),
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTabButton(
    AppointmentsState state,
    AppointmentsController controller,
    int index,
    String label,
    int count,
  ) {
    final isSelected = state.selectedTab == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.selectTab(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppTheme.tealBlue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.tealBlue : AppTheme.grayText,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.tealBlue.withOpacity(0.1)
                      : AppTheme.iconGray.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: AppTheme.bodySmall.copyWith(
                    color: isSelected ? AppTheme.tealBlue : AppTheme.grayText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotLoggedInView(AppointmentsController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.login,
              size: 64,
              color: AppTheme.iconGray,
            ),
            const SizedBox(height: 16),
            Text(
              'Giriş Yapın',
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Randevularınızı görmek için giriş yapın',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.grayText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      onLoginSuccess: () {
                        Navigator.pop(context);
                        controller.refresh();
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tealBlue,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Giriş Yap',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(
    AppointmentsState state,
    List<Appointment> appointments,
  ) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: AppTheme.iconGray,
            ),
            const SizedBox(height: 16),
            Text(
              'Randevu bulunamadı',
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.grayText),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildAppointmentCard(state, appointment);
      },
    );
  }

  Widget _buildAppointmentCard(
    AppointmentsState state,
    Appointment appointment,
  ) {
    final hospital = _getHospital(state, appointment.hospitalId);
    final doctor = _getDoctor(state, appointment.doctorId);
    final service = _getService(state, appointment.service);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(appointment),
                    style: AppTheme.bodySmall.copyWith(
                      color: _getStatusColor(appointment),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_canManageAppointment(appointment))
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: AppTheme.iconGray),
                    onPressed: () {
                      _showAppointmentOptions(state, appointment);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Tarih ve Saat
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: AppTheme.tealBlue),
                const SizedBox(width: 8),
                Text(
                  _formatDate(appointment.date),
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 18, color: AppTheme.tealBlue),
                const SizedBox(width: 8),
                Text(
                  appointment.time,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Hastane
            if (hospital != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.local_hospital,
                    size: 18,
                    color: AppTheme.iconGray,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(hospital.name, style: AppTheme.bodyMedium),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            // Doktor
            if (doctor != null) ...[
              Row(
                children: [
                  Icon(Icons.person, size: 18, color: AppTheme.iconGray),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      doctor.fullName,
                      style: AppTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            // Hizmet
            if (service != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.medical_services,
                    size: 18,
                    color: AppTheme.iconGray,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(service.name, style: AppTheme.bodyMedium),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            // Notlar
            if (appointment.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: AppTheme.iconGray),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(appointment.notes, style: AppTheme.bodySmall),
                    ),
                  ],
                ),
              ),
            ],
            // Yorum (Sadece geçmiş randevularda)
            if (appointment.status == 'cancelled' ||
                (appointment.status == 'completed' &&
                    !_isFutureAppointment(appointment))) ...[
              const SizedBox(height: 16),
              Divider(color: AppTheme.dividerLight),
              const SizedBox(height: 8),
              // Yorum ekle/düzenle butonu
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showReviewDialog(state, appointment),
                  icon: Icon(Icons.rate_review, size: 18, color: AppTheme.tealBlue),
                  label: Text(
                    'Yorum Ekle / Düzenle',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.tealBlue,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.tealBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAppointmentDetails(state, appointment),
                icon: const Icon(Icons.info_outline, size: 18, color: AppTheme.tealBlue),
                label: Text(
                  'Detayları Gör',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.tealBlue,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.tealBlue.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAppointmentOptions(
    AppointmentsState state,
    Appointment appointment,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.tealBlue),
              title: Text('Düzenle', style: AppTheme.bodyMedium),
              onTap: () {
                Navigator.pop(context);
                // Düzenleme sayfasına yönlendirme
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: Text('İptal Et', style: AppTheme.bodyMedium),
              onTap: () {
                Navigator.pop(context);
                _cancelAppointment(appointment);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAppointmentDetails(
    AppointmentsState state,
    Appointment appointment,
  ) {
    final hospital = _getHospital(state, appointment.hospitalId);
    final doctor = _getDoctor(state, appointment.doctorId);
    final service = _getService(state, appointment.service);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTurquoise,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.event_note, color: AppTheme.tealBlue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Randevu Detayları',
                        style: AppTheme.headingMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDetailRow(
                  icon: Icons.calendar_today,
                  label: 'Tarih',
                  value: _formatDate(appointment.date),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  icon: Icons.access_time,
                  label: 'Saat',
                  value: appointment.time,
                ),
                if (hospital != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.local_hospital,
                    label: 'Hastane',
                    value: hospital.name,
                  ),
                  if (hospital.address.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Adres',
                      value: hospital.address,
                    ),
                  ],
                  if (hospital.phone.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.phone,
                      label: 'Telefon',
                      value: hospital.phone,
                    ),
                  ],
                ],
                if (doctor != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.person_outline,
                    label: 'Doktor',
                    value: doctor.fullName,
                  ),
                ],
                if (service != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.medical_services_outlined,
                    label: 'Hizmet',
                    value: service.name,
                  ),
                ],
                if (appointment.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.notes,
                    label: 'Not',
                    value: appointment.notes,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
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
            color: AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(12),
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

  Future<void> _showReviewDialog(
    AppointmentsState state,
    Appointment appointment,
  ) async {
    final controller = ref.read(appointmentsControllerProvider.notifier);
    final draft = await controller.fetchReviewDraft(appointment);
    if (!mounted) return;

    final reviewController = TextEditingController(text: draft.comment ?? '');
    int hospitalRating = draft.hospitalRating;
    int? doctorRating = draft.doctorRating;

    final hospital = _getHospital(state, appointment.hospitalId);
    final doctor = _getDoctor(state, appointment.doctorId);
    if (!mounted) return;

    final hasExistingReview = (draft.comment?.isNotEmpty ?? false);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            hasExistingReview ? 'Yorumu Düzenle' : 'Yorum Ekle',
            style: AppTheme.headingSmall,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hospital != null) ...[
                  Text(
                    'Hastane Puanı',
                    style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            hospitalRating = index + 1;
                          });
                        },
                        child: Icon(
                          index < hospitalRating ? Icons.star : Icons.star_border,
                          color: index < hospitalRating ? Colors.amber : AppTheme.iconGray,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                ],
                if (doctor != null) ...[
                  Text(
                    'Doktor Puanı',
                    style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            doctorRating = index + 1;
                          });
                        },
                        child: Icon(
                          index < (doctorRating ?? 0) ? Icons.star : Icons.star_border,
                          color: index < (doctorRating ?? 0) ? Colors.amber : AppTheme.iconGray,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Yorum',
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reviewController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Randevunuz hakkında yorumunuzu yazın...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: AppTheme.inputFieldGray,
                  ),
                  style: AppTheme.bodyMedium,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'İptal',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.grayText),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final result = await controller.submitReview(
                  appointment: appointment,
                  review: reviewController.text.trim(),
                  hospitalRating: hospitalRating,
                  doctorRating: doctorRating,
                );
                if (!mounted) return;
                Navigator.pop(context);
                _showSnackBar(
                  result.message,
                  result.success ? AppTheme.successGreen : Colors.red,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tealBlue,
                foregroundColor: AppTheme.white,
              ),
              child: Text(
                'Kaydet',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final dateTime = DateTime.parse(date);
      final months = [
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
      return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
    } catch (e) {
      return date;
    }
  }
}

List<Appointment> _upcomingAppointments(AppointmentsState state) {
  final now = DateTime.now();
  return state.appointments
      .where((apt) {
        if (apt.status == 'cancelled') return false;
        final dateTime = _parseAppointmentDateTime(apt);
        if (dateTime == null) return true;
        return !dateTime.isBefore(now);
      })
      .toList()
    ..sort((a, b) {
      final dateA = _parseAppointmentDateTime(a) ?? DateTime.now();
      final dateB = _parseAppointmentDateTime(b) ?? DateTime.now();
      return dateA.compareTo(dateB);
    });
}

List<Appointment> _historyAppointments(AppointmentsState state) {
  final now = DateTime.now();
  return state.appointments
      .where((apt) {
        if (apt.status == 'cancelled') return true;
        final dateTime = _parseAppointmentDateTime(apt);
        if (dateTime == null) return false;
        return dateTime.isBefore(now);
      })
      .toList()
    ..sort((a, b) {
      final dateA = _parseAppointmentDateTime(a) ?? DateTime.now();
      final dateB = _parseAppointmentDateTime(b) ?? DateTime.now();
      return dateB.compareTo(dateA);
    });
}

Hospital? _getHospital(AppointmentsState state, String hospitalId) {
  try {
    return state.hospitals.firstWhere((h) => h.id == hospitalId);
  } catch (_) {
    return null;
  }
}

Doctor? _getDoctor(AppointmentsState state, String doctorId) {
  try {
    return state.doctors.firstWhere((d) => d.id == doctorId);
  } catch (_) {
    return null;
  }
}

Service? _getService(AppointmentsState state, String serviceId) {
  try {
    return state.services.firstWhere((s) => s.id == serviceId);
  } catch (_) {
    return null;
  }
}

DateTime? _parseAppointmentDateTime(Appointment appointment) {
  if (appointment.date.isEmpty) return null;
  final timeValue = appointment.time.isEmpty ? '00:00' : appointment.time;
  final normalized = timeValue.length == 5 ? '$timeValue:00' : timeValue;
  return DateTime.tryParse('${appointment.date}T$normalized');
}

bool _isFutureAppointment(Appointment appointment) {
  final dateTime = _parseAppointmentDateTime(appointment);
  if (dateTime == null) return false;
  return dateTime.isAfter(DateTime.now());
}

bool _canManageAppointment(Appointment appointment) {
  if (appointment.status == 'cancelled') return false;
  return _isFutureAppointment(appointment);
}

String _getStatusText(Appointment appointment) {
  if (appointment.status == 'cancelled') {
    return 'İptal Edildi';
  }
  return _isFutureAppointment(appointment) ? 'Planlandı' : 'Tamamlandı';
}

Color _getStatusColor(Appointment appointment) {
  if (appointment.status == 'cancelled') {
    return Colors.red;
  }
  return _isFutureAppointment(appointment)
      ? AppTheme.tealBlue
      : AppTheme.successGreen;
}
