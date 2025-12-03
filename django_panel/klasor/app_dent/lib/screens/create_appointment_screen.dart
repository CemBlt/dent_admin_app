import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../models/hospital.dart';
import '../models/doctor.dart';
import '../models/service.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import 'login_screen.dart';
import '../providers/create_appointment_provider.dart';

class CreateAppointmentScreen extends ConsumerStatefulWidget {
  final String? preselectedHospitalId;
  final String? preselectedDoctorId;
  
  const CreateAppointmentScreen({
    super.key,
    this.preselectedHospitalId,
    this.preselectedDoctorId,
  });

  @override
  ConsumerState<CreateAppointmentScreen> createState() => _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends ConsumerState<CreateAppointmentScreen> {
  final TextEditingController _notesController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  CreateAppointmentController get _controller =>
      ref.read(createAppointmentControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    AppEventService.log('screen_create_appointment_opened', properties: {
      'preselected_hospital': widget.preselectedHospitalId,
      'preselected_doctor': widget.preselectedDoctorId,
    });
    // Build tamamlandıktan sonra authentication kontrolü yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthenticationAndLoadData();
    });
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.accentGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.tealBlue.withOpacity(0.25),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Randevu Oluştur',
                          style: AppTheme.headingLarge.copyWith(
                            color: AppTheme.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dakikalar içinde tamamlayın',
                          style: AppTheme.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timelapse_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '<3 dk',
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _StepChip(label: 'Konum'),
                  _StepChip(label: 'Hizmet'),
                  _StepChip(label: 'Tarih & Saat'),
                  _StepChip(label: 'Onay'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.headingSmall.copyWith(fontSize: 15),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.grayText),
            ),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTheme.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: AppTheme.darkText,
      ),
    );
  }

  Widget _buildBottomAction(CreateAppointmentState state) {
    final isAllFieldsFilled = _isFormComplete(state);
    final isServiceSelected = state.selectedService != null;

    final bool isCreateButton = isAllFieldsFilled;
    final String buttonText =
        isCreateButton ? 'Randevu Oluştur' : 'Uygun randevuları ara';
    final IconData buttonIcon =
        isCreateButton ? Icons.check_circle_outline : Icons.search_rounded;
    final bool isButtonActive = isCreateButton
        ? isAllFieldsFilled
        : (isServiceSelected && !state.isSearchingSlots);
    final VoidCallback? onButtonTap = isButtonActive
        ? (isCreateButton
            ? () => _createAppointment(state)
            : () => _searchAvailableSlots(state))
        : null;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.85),
            ),
            child: SafeArea(
              top: false,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: isButtonActive ? AppTheme.accentGradient : null,
                  color: isButtonActive ? null : AppTheme.iconGray.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isButtonActive
                      ? [
                          BoxShadow(
                            color: AppTheme.tealBlue.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onButtonTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (state.isSearchingSlots && !isCreateButton)
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          else
                            Icon(
                              buttonIcon,
                              color: AppTheme.white,
                            ),
                          const SizedBox(width: 10),
                          Text(
                            buttonText,
                            style: AppTheme.headingSmall.copyWith(
                              color: AppTheme.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkAuthenticationAndLoadData() async {
    if (!AuthService.isAuthenticated) {
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            onLoginSuccess: () {
              Navigator.pop(context, true);
            },
          ),
        ),
      );

      if (!AuthService.isAuthenticated) {
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }
    }

    await _controller.loadData(
      preselectedHospitalId: widget.preselectedHospitalId,
      preselectedDoctorId: widget.preselectedDoctorId,
    );
  }

  Future<void> _searchAvailableSlots(CreateAppointmentState state) async {
    AppEventService.log('appointment_slots_search', properties: {
      'service_id': state.selectedService?.id,
      'hospital_id': state.selectedHospital?.id,
      'doctor_id': state.selectedDoctor?.id,
    });

    if (state.selectedService == null) {
      _showSnackBar('Lütfen önce hizmet seçiniz', Colors.orange);
      return;
    }

    final result = await _controller.searchAvailableSlots();
    if (!mounted) return;

    if (!result.success || result.payload == null) {
      _showSnackBar(result.message, Colors.orange);
      return;
    }

    final slots = (result.payload as List<AvailableSlot>);
    if (slots.isEmpty) {
      _showNoResultMessage();
      return;
    }

    final selectedSlot = await Navigator.push<AvailableSlot>(
      context,
      MaterialPageRoute(
        builder: (context) => _AvailableSlotsScreen(
          slots: slots,
          service: state.selectedService!,
          formatDate: _formatDate,
          selectedCity: state.selectedCity,
          selectedDistrict: state.selectedDistrict,
          selectedHospital: state.selectedHospital,
          selectedDoctor: state.selectedDoctor,
        ),
      ),
    );

    if (selectedSlot != null) {
      AppEventService.log('appointment_slot_selected', properties: {
        'doctor_id': selectedSlot.doctor.id,
        'hospital_id': selectedSlot.hospital.id,
        'date': selectedSlot.date.toIso8601String(),
        'time': selectedSlot.time,
      });
      _controller.applySlotSelection(selectedSlot);
    }
  }

  void _showNoResultMessage() {
    _showSnackBar('Seçilen kriterlere uygun randevu bulunamadı.', Colors.orange);
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

  String _formatDate(DateTime date) {
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
      'Aralık'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  bool _isFormComplete(CreateAppointmentState state) {
    return state.selectedCity != null &&
        state.selectedDistrict != null &&
        state.selectedHospital != null &&
        state.selectedDoctor != null &&
        state.selectedService != null &&
        state.selectedDate != null &&
        state.selectedTime != null;
  }

  Future<void> _createAppointment(CreateAppointmentState state) async {
    if (!_isFormComplete(state)) {
      _showSnackBar('Lütfen tüm alanları doldurunuz', Colors.orange);
      return;
    }

    if (!AuthService.isAuthenticated) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            onLoginSuccess: () {
              Navigator.pop(context, true);
            },
          ),
        ),
      );

      if (!AuthService.isAuthenticated) {
        return;
      }
    }

    final result = await _controller.createAppointment(
      notes: _notesController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (!result.success) {
      _showSnackBar(
        result.message == 'login_required'
            ? 'Lütfen giriş yapınız'
            : result.message,
        Colors.orange,
      );
      return;
    }

    _showSnackBar(result.message, AppTheme.successGreen);
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final state = ref.watch(createAppointmentControllerProvider);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.backgroundLight, AppTheme.lightTurquoise.withOpacity(0.4)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        _buildHeroHeader(context),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSection(
                                  title: '1. Hizmeti seç',
                                  subtitle: 'İhtiyaç duyduğunuz işlemi belirleyin',
                                  children: [
                                _buildDropdown<Service>(
                                  value: state.selectedService,
                                  items: state.services,
                                  onChanged: controller.selectService,
                                  getLabel: (service) => service.name,
                                ),
                                  ],
                                ),
                                _buildSection(
                                  title: '2. Konum ve sağlayıcı',
                                  subtitle: 'Size en uygun klinik ve doktoru seçin',
                                  children: [
                                    _buildFieldLabel('İl'),
                                    const SizedBox(height: 8),
                                _buildStringDropdown(
                                  value: state.selectedCity,
                                  items: controller.cities,
                                  onChanged: controller.selectCity,
                                  hint: 'İl seçiniz',
                                ),
                                    const SizedBox(height: 18),
                                    _buildFieldLabel('İlçe'),
                                    const SizedBox(height: 8),
                                _buildStringDropdown(
                                  value: state.selectedDistrict,
                                  items: controller.districts,
                                  onChanged: controller.selectDistrict,
                                  hint: 'İlçe seçiniz',
                                  enabled: state.selectedCity != null,
                                ),
                                    const SizedBox(height: 18),
                                    _buildFieldLabel('Hastane'),
                                    const SizedBox(height: 8),
                                _buildDropdown<Hospital>(
                                  value: state.selectedHospital,
                                  items: state.filteredHospitals,
                                  onChanged: controller.selectHospital,
                                  getLabel: (hospital) => hospital.name,
                                  enabled: state.selectedDistrict != null,
                                ),
                                    const SizedBox(height: 18),
                                    _buildFieldLabel('Doktor'),
                                    const SizedBox(height: 8),
                                _buildDropdown<Doctor>(
                                  value: state.selectedDoctor,
                                  items: state.filteredDoctors,
                                  onChanged: controller.selectDoctor,
                                  getLabel: (doctor) => doctor.fullName,
                                  enabled: state.selectedHospital != null && state.filteredDoctors.isNotEmpty,
                                ),
                                  ],
                                ),
                                _buildSection(
                                  title: '3. Tarih ve saat',
                                  subtitle: 'Müsait olduğunuz zamanı seçin',
                                  children: [
                                    _buildDateTimePicker(state),
                                  ],
                                ),
                                _buildSection(
                                  title: 'Ek notlar',
                                  subtitle: 'Doktorunuzla paylaşmak istediğiniz ek bilgileri yazabilirsiniz',
                                  children: [
                                    TextField(
                                      controller: _notesController,
                                      maxLines: 4,
                                      decoration: InputDecoration(
                                        hintText: 'Randevu ile ilgili notlarınızı yazabilirsiniz...',
                                        hintStyle: TextStyle(color: AppTheme.iconGray),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(color: AppTheme.dividerLight),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(color: AppTheme.dividerLight),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: AppTheme.tealBlue, width: 1.8),
                                        ),
                                        contentPadding: const EdgeInsets.all(18),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (!state.isLoading) _buildBottomAction(state),
        ],
      ),
    );
  }

  Widget _buildStringDropdown({
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String hint,
    bool enabled = true,
  }) {
    // Duplicate değerleri temizle ve seçili değerin items'da olup olmadığını kontrol et
    final uniqueItems = items.toSet().toList();
    final validValue = value != null && uniqueItems.contains(value) ? value : null;
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.inputFieldGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? AppTheme.dividerLight : AppTheme.iconGray.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: validValue,
        items: uniqueItems.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: AppTheme.bodyMedium,
            ),
          );
        }).toList(),
        onChanged: enabled ? onChanged : null,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.iconGray),
        ),
        style: AppTheme.bodyMedium,
        dropdownColor: AppTheme.white,
        icon: Icon(Icons.arrow_drop_down, color: enabled ? AppTheme.tealBlue : AppTheme.iconGray),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<T> items,
    required Function(T?) onChanged,
    required String Function(T) getLabel,
    bool enabled = true,
  }) {
    // Seçili değerin items listesinde olup olmadığını kontrol et
    // Eğer yoksa veya duplicate varsa, value'yu null yap
    T? validValue;
    if (value != null && items.isNotEmpty) {
      // ID'leri karşılaştırarak kontrol et (Hospital, Doctor, Service için)
      String? valueId;
      if (value is Hospital) {
        valueId = (value as Hospital).id;
      } else if (value is Doctor) {
        valueId = (value as Doctor).id;
      } else if (value is Service) {
        valueId = (value as Service).id;
      }
      
      if (valueId != null) {
        // Items listesinde aynı ID'ye sahip kaç item var kontrol et
        final matchingItems = items.where((item) {
          if (item is Hospital) return (item as Hospital).id == valueId;
          if (item is Doctor) return (item as Doctor).id == valueId;
          if (item is Service) return (item as Service).id == valueId;
          return item == value;
        }).toList();
        
        if (matchingItems.length == 1) {
          validValue = matchingItems.first;
        } else {
          // Duplicate varsa veya hiç yoksa, null yap
          validValue = null;
        }
      } else {
        // ID yoksa, == operatörü ile kontrol et
        final matchingCount = items.where((item) => item == value).length;
        if (matchingCount == 1) {
          try {
            final foundItem = items.firstWhere((item) => item == value);
            validValue = foundItem;
          } catch (e) {
            validValue = null;
          }
        } else {
          validValue = null;
        }
      }
    }
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.inputFieldGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? AppTheme.dividerLight : AppTheme.iconGray.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonFormField<T>(
        value: validValue,
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              getLabel(item),
              style: AppTheme.bodyMedium,
            ),
          );
        }).toList(),
        onChanged: enabled ? onChanged : null,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintText: 'Seçiniz...',
          hintStyle: TextStyle(color: AppTheme.iconGray),
        ),
        style: AppTheme.bodyMedium,
        dropdownColor: AppTheme.white,
        icon: Icon(Icons.arrow_drop_down, color: enabled ? AppTheme.tealBlue : AppTheme.iconGray),
      ),
    );
  }

  Widget _buildDateTimePicker(CreateAppointmentState state) {
    final hasSelection =
        state.selectedDate != null && state.selectedTime != null;
    final dateText = state.selectedDate != null
        ? _formatDate(state.selectedDate!)
        : 'Tarih seçiniz';
    final timeText = state.selectedTime ?? '';
    final displayText = hasSelection 
        ? '$dateText • $timeText'
        : dateText;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.inputFieldGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerLight),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDateTimePickerModal(state),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasSelection 
                        ? AppTheme.tealBlue.withOpacity(0.1)
                        : AppTheme.iconGray.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: hasSelection
                        ? AppTheme.tealBlue
                        : AppTheme.iconGray,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayText,
                        style: AppTheme.bodyMedium.copyWith(
                          color: hasSelection
                              ? AppTheme.darkText
                              : AppTheme.iconGray,
                          fontWeight: hasSelection ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                      if (hasSelection)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Tarih ve saat seçildi',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.tealBlue,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasSelection)
                  IconButton(
                    icon: Icon(Icons.clear, size: 18, color: AppTheme.iconGray),
                    onPressed: () {
                      _controller.setDate(null);
                      _controller.selectTime(null);
                    },
                  ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.iconGray,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDateTimePickerModal(CreateAppointmentState state) async {
    DateTime? tempDate = state.selectedDate;
    String? tempTime = state.selectedTime;
    List<String> tempAvailableTimes = [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Tarih değiştiğinde saatleri güncelle
          if (tempDate != null && tempAvailableTimes.isEmpty) {
            tempAvailableTimes =
                _controller.availableTimesFor(tempDate!);
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppTheme.dividerLight, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tarih ve Saat Seçiniz',
                          style: AppTheme.headingMedium.copyWith(
                            color: AppTheme.darkText,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: AppTheme.iconGray),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tarih Seçimi
                        Text(
                          'Tarih',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 7 günlük tarih butonları
                        Builder(
                          builder: (context) {
                            final now = DateTime.now();
                            final today = DateTime(now.year, now.month, now.day);
                            final weekDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                            final monthNames = [
                              'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
                              'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
                            ];
                            
                            return Row(
                              children: List.generate(7, (index) {
                                final date = today.add(Duration(days: index));
                                final isSelected = tempDate != null &&
                                    tempDate!.year == date.year &&
                                    tempDate!.month == date.month &&
                                    tempDate!.day == date.day;
                                final isToday = index == 0;
                                // DateTime.weekday: 1=Pazartesi, 7=Pazar
                                final dayIndex = date.weekday - 1;
                                
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(right: index < 6 ? 8 : 0),
                                    child: InkWell(
                                      onTap: () {
                                        setModalState(() {
                                          tempDate = date;
                                          tempTime = null; // Tarih değişince saati sıfırla
                                          tempAvailableTimes =
                                              _controller.availableTimesFor(date);
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppTheme.tealBlue
                                              : isToday
                                                  ? AppTheme.tealBlue.withOpacity(0.1)
                                                  : AppTheme.inputFieldGray,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppTheme.tealBlue
                                                : isToday
                                                    ? AppTheme.tealBlue
                                                    : AppTheme.dividerLight,
                                            width: isSelected || isToday ? 2 : 1,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              weekDays[dayIndex],
                                              style: AppTheme.bodySmall.copyWith(
                                                color: isSelected
                                                    ? AppTheme.white
                                                    : AppTheme.iconGray,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              date.day.toString(),
                                              style: AppTheme.bodyLarge.copyWith(
                                                color: isSelected
                                                    ? AppTheme.white
                                                    : AppTheme.darkText,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              monthNames[date.month - 1],
                                              style: AppTheme.bodySmall.copyWith(
                                                color: isSelected
                                                    ? AppTheme.white.withOpacity(0.9)
                                                    : AppTheme.iconGray,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Saat Seçimi
                        Text(
                          'Saat',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (tempDate == null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.inputFieldGray.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.iconGray.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: AppTheme.iconGray, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Önce tarih seçiniz',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.iconGray,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (tempAvailableTimes.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.inputFieldGray.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.iconGray.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: AppTheme.iconGray, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Bu tarihte uygun saat bulunamadı',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.iconGray,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              // Her satırda 3 buton göster (veya ekran genişliğine göre)
                              final crossAxisCount = 3;
                              final spacing = 8.0;
                              final availableWidth = constraints.maxWidth;
                              final itemWidth = (availableWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;
                              
                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: tempAvailableTimes.map((time) {
                                  final isSelected = tempTime == time;
                                  return SizedBox(
                                    width: itemWidth,
                                    child: InkWell(
                                      onTap: () {
                                        setModalState(() {
                                          tempTime = isSelected ? null : time;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppTheme.tealBlue
                                              : AppTheme.inputFieldGray,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppTheme.tealBlue
                                                : AppTheme.dividerLight,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            time,
                                            style: AppTheme.bodyMedium.copyWith(
                                              color: isSelected
                                                  ? AppTheme.white
                                                  : AppTheme.darkText,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Footer Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppTheme.dividerLight, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: AppTheme.dividerLight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'İptal',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.darkText,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: (tempDate != null && tempTime != null)
                              ? () {
                                  Navigator.pop(context);
                                  _controller.setDate(tempDate);
                                  _controller.selectTime(tempTime);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppTheme.tealBlue,
                            disabledBackgroundColor:
                                AppTheme.iconGray.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Seç',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  final String label;
  const _StepChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: Text(
        label,
        style: AppTheme.bodySmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AvailableSlotsScreen extends StatelessWidget {
  final List<AvailableSlot> slots;
  final Service service;
  final String? selectedCity;
  final String? selectedDistrict;
  final Hospital? selectedHospital;
  final Doctor? selectedDoctor;
  final String Function(DateTime) formatDate;

  const _AvailableSlotsScreen({
    required this.slots,
    required this.service,
    required this.formatDate,
    this.selectedCity,
    this.selectedDistrict,
    this.selectedHospital,
    this.selectedDoctor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uygun Randevular'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.backgroundLight, AppTheme.lightTurquoise.withOpacity(0.4)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            physics: const BouncingScrollPhysics(),
            itemCount: slots.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) return _buildSummaryCard();
              final slot = slots[index - 1];
              return _buildSlotCard(context, slot);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final filters = <String>[
      'Hizmet: ${service.name}',
      if ((selectedCity ?? '').isNotEmpty) 'İl: $selectedCity',
      if ((selectedDistrict ?? '').isNotEmpty) 'İlçe: $selectedDistrict',
      if (selectedHospital != null) 'Hastane: ${selectedHospital!.name}',
      if (selectedDoctor != null) 'Doktor: ${selectedDoctor!.fullName}',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtre özeti',
            style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filters
                .map(
                  (label) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.inputFieldGray,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      label,
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.darkText),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCard(BuildContext context, AvailableSlot slot) {
    final dateText = formatDate(slot.date);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_rounded, color: AppTheme.tealBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                '$dateText • ${slot.time}',
                style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            slot.hospital.name,
            style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            slot.doctor.fullName,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.darkText),
          ),
          const SizedBox(height: 4),
          Text(
            slot.hospital.address,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.grayText),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, slot),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: AppTheme.tealBlue),
                foregroundColor: AppTheme.tealBlue,
              ),
              child: const Text('Bu randevuyu seç'),
            ),
          ),
        ],
      ),
    );
  }
}

