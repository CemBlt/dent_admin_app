import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/hospital.dart';
import '../models/doctor.dart';
import '../models/service.dart';
import '../models/appointment.dart';
import '../services/json_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class CreateAppointmentScreen extends StatefulWidget {
  final String? preselectedHospitalId;
  
  const CreateAppointmentScreen({
    super.key,
    this.preselectedHospitalId,
  });

  @override
  State<CreateAppointmentScreen> createState() => _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  static const int _searchResultsLimit = 10;
  static const int _searchDaysHorizon = 30;

  List<Hospital> _allHospitals = [];
  List<Hospital> _filteredHospitals = [];
  List<Doctor> _allDoctors = [];
  List<Doctor> _filteredDoctors = [];
  List<Service> _services = [];
  List<Appointment> _existingAppointments = [];
  
  String? _selectedCity;
  String? _selectedDistrict;
  Hospital? _selectedHospital;
  Doctor? _selectedDoctor;
  Service? _selectedService;
  DateTime? _selectedDate;
  String? _selectedTime;
  final TextEditingController _notesController = TextEditingController();
  
  bool _isLoading = true;
  List<String> _availableTimes = [];
  bool _isSearchingSlots = false;
  final ScrollController _scrollController = ScrollController();
  bool _showCreateButton = false;

  @override
  void initState() {
    super.initState();
    // Build tamamlandıktan sonra authentication kontrolü yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthenticationAndLoadData();
    });
    _scrollController.addListener(_handleScrollPosition);
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

  Widget _buildSearchButton() {
    final canSearch = _selectedService != null && !_isSearchingSlots;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSearch ? _searchAvailableSlots : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.tealBlue,
          foregroundColor: AppTheme.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isSearchingSlots
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Uygun randevuları ara',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBottomAction() {
    final isActive = _isFormValid();
    return Positioned(
      left: 20,
      right: 20,
      bottom: 24,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isActive ? AppTheme.accentGradient : null,
          color: isActive ? null : AppTheme.iconGray.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.tealBlue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isActive ? _createAppointment : null,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.white,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Randevu Oluştur',
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
    );
  }

  Future<void> _checkAuthenticationAndLoadData() async {
    // Eğer kullanıcı giriş yapmamışsa, login ekranına yönlendir
    if (!AuthService.isAuthenticated) {
      if (!mounted) return;
      
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            onLoginSuccess: () {
              Navigator.pop(context, true);
            },
          ),
        ),
      );
      
      // Kullanıcı login ekranından geri döndüyse ve hala giriş yapmamışsa, bu ekranı kapat
      if (!AuthService.isAuthenticated) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          Navigator.pop(context);
        }
        return;
      }
      
      // Giriş yapıldıysa, verileri yükle
      if (mounted) {
        _loadData();
      }
    } else {
      // Zaten giriş yapılmışsa, verileri yükle
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final hospitals = await JsonService.getHospitals();
    final doctors = await JsonService.getDoctors();
    final services = await JsonService.getServices();
    final appointments = await JsonService.getAppointments();

    setState(() {
      _allHospitals = hospitals;
      _allDoctors = doctors;
      _services = _sortServices(services);
      _existingAppointments = appointments;
      
      // Eğer preselectedHospitalId varsa, hastaneyi seç
      if (widget.preselectedHospitalId != null) {
        try {
          final preselectedHospital = hospitals.firstWhere(
            (h) => h.id == widget.preselectedHospitalId,
          );
          // İl ve ilçe bilgilerini ayarla
          final addressInfo = _getLocationInfo(preselectedHospital);
          _selectedCity = addressInfo['city'];
          _selectedDistrict = addressInfo['district'];
          _selectedHospital = preselectedHospital;
          _updateFilteredHospitals();
          _onHospitalSelected(preselectedHospital);
        } catch (e) {
          // Hastane bulunamadı
        }
      }
      
      _isLoading = false;
    });
  }

  // Adres formatından il ve ilçe çıkar (format: "İlçe, İl")
  Map<String, String> _getLocationInfo(Hospital hospital) {
    final cityFromField = hospital.provinceName?.trim();
    final districtFromField = hospital.districtName?.trim();

    if ((cityFromField?.isNotEmpty ?? false) || (districtFromField?.isNotEmpty ?? false)) {
      return {
        'city': cityFromField ?? '',
        'district': districtFromField ?? '',
      };
    }

    final normalizedAddress = hospital.address.replaceAll('/', ',');
    final parts = normalizedAddress
        .split(',')
        .map((e) => e.trim())
        .where((element) => element.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      final city = parts.last;
      final district = parts.first;
      return {'district': district, 'city': city};
    }

    return {'district': hospital.address.trim(), 'city': ''};
  }

  List<Service> _sortServices(List<Service> services) {
    final sorted = List<Service>.from(services);
    sorted.sort((a, b) {
      final aPriority = _isGeneralService(a) ? 0 : 1;
      final bPriority = _isGeneralService(b) ? 0 : 1;
      if (aPriority != bPriority) {
        return aPriority - bPriority;
      }
      return a.name.compareTo(b.name);
    });
    return sorted;
  }

  bool _isGeneralService(Service service) {
    final normalizedName = service.name.toLowerCase();
    return service.id == '1' || normalizedName.contains('genel');
  }

  List<Doctor> _getDoctorsForSelection({Hospital? hospital, Service? service}) {
    if (hospital == null) return [];

    final doctorsForHospital = _allDoctors
        .where((doctor) => doctor.hospitalId == hospital.id)
        .toList();

    if (service == null) {
      return doctorsForHospital;
    }

    return doctorsForHospital.where((doctor) {
      if (doctor.services.isEmpty) return false;
      return doctor.services.contains(service.id);
    }).toList();
  }

  bool _matchesSelectedLocation(Hospital hospital) {
    final locationInfo = _getLocationInfo(hospital);
    final matchesCity = _selectedCity == null ||
        _selectedCity!.isEmpty ||
        locationInfo['city'] == _selectedCity;
    final matchesDistrict = _selectedDistrict == null ||
        _selectedDistrict!.isEmpty ||
        locationInfo['district'] == _selectedDistrict;

    return matchesCity && matchesDistrict;
  }

  Future<void> _searchAvailableSlots() async {
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lütfen önce hizmet seçiniz'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSearchingSlots = true;
    });

    final Map<String, Hospital> hospitalById = {
      for (final hospital in _allHospitals) hospital.id: hospital,
    };
    final serviceId = _selectedService!.id;

    final candidateDoctors = _allDoctors.where((doctor) {
      if (!doctor.services.contains(serviceId)) return false;
      final hospital = hospitalById[doctor.hospitalId];
      if (hospital == null) return false;
      if (!_matchesSelectedLocation(hospital)) return false;
      if (_selectedHospital != null && doctor.hospitalId != _selectedHospital!.id) return false;
      if (_selectedDoctor != null && doctor.id != _selectedDoctor!.id) return false;
      return true;
    }).toList();

    if (candidateDoctors.isEmpty) {
      setState(() {
        _isSearchingSlots = false;
      });
      _showNoResultMessage();
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime startBase = _selectedDate ?? now;
    final DateTime startDate = DateTime(startBase.year, startBase.month, startBase.day);

    final List<_AvailableSlot> slots = [];
    bool reachedLimit = false;

    for (int dayOffset = 0; dayOffset <= _searchDaysHorizon && !reachedLimit; dayOffset++) {
      final date = startDate.add(Duration(days: dayOffset));
      for (final doctor in candidateDoctors) {
        final hospital = hospitalById[doctor.hospitalId];
        if (hospital == null) continue;

        final times = _getAvailableTimesForDoctor(doctor, date);
        for (final time in times) {
          final slotDateTime = _combineDateAndTime(date, time);
          if (slotDateTime.isBefore(now)) continue;

          slots.add(_AvailableSlot(
            hospital: hospital,
            doctor: doctor,
            date: date,
            time: time,
          ));

          if (slots.length >= _searchResultsLimit) {
            reachedLimit = true;
            break;
          }
        }
        if (reachedLimit) break;
      }
    }

    slots.sort((a, b) => _combineDateAndTime(a.date, a.time).compareTo(
          _combineDateAndTime(b.date, b.time),
        ));

    if (!mounted) return;

    setState(() {
      _isSearchingSlots = false;
    });

    if (slots.isEmpty) {
      _showNoResultMessage();
      return;
    }

    final selectedSlot = await Navigator.push<_AvailableSlot>(
      context,
      MaterialPageRoute(
        builder: (context) => _AvailableSlotsScreen(
          slots: slots,
          service: _selectedService!,
          formatDate: _formatDate,
          selectedCity: _selectedCity,
          selectedDistrict: _selectedDistrict,
          selectedHospital: _selectedHospital,
          selectedDoctor: _selectedDoctor,
        ),
      ),
    );

    if (selectedSlot != null) {
      _applySlotSelection(selectedSlot);
    }
  }

  void _showNoResultMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Seçilen kriterlere uygun randevu bulunamadı.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  DateTime _combineDateAndTime(DateTime date, String time) {
    final parts = time.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  void _applySlotSelection(_AvailableSlot slot) {
    final locationInfo = _getLocationInfo(slot.hospital);
    final filteredDoctors = _getDoctorsForSelection(
      hospital: slot.hospital,
      service: _selectedService,
    );

    setState(() {
      if (locationInfo['city']!.isNotEmpty) {
        _selectedCity = locationInfo['city'];
      }
      if (locationInfo['district']!.isNotEmpty) {
        _selectedDistrict = locationInfo['district'];
      }
      _selectedHospital = slot.hospital;
      _selectedDoctor = slot.doctor;
      _selectedDate = slot.date;
      _selectedTime = slot.time;
      _availableTimes = _getAvailableTimes(slot.date);
      _updateFilteredHospitals();
      _filteredDoctors = filteredDoctors;
    });
  }

  void _handleScrollPosition() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final threshold = 40.0;
    final isNearBottom = position.pixels >= position.maxScrollExtent - threshold;
    if (isNearBottom != _showCreateButton) {
      setState(() {
        _showCreateButton = isNearBottom;
      });
    }
  }

  // Tüm illeri getir
  List<String> get _cities {
    final cities = <String>{};
    for (var hospital in _allHospitals) {
      final addressInfo = _getLocationInfo(hospital);
      if (addressInfo['city']!.isNotEmpty) {
        cities.add(addressInfo['city']!);
      }
    }
    return cities.toList()..sort();
  }

  // Seçilen ile göre ilçeleri getir
  List<String> get _districts {
    if (_selectedCity == null) return [];
    
    final districts = <String>{};
    for (var hospital in _allHospitals) {
      final addressInfo = _getLocationInfo(hospital);
      if (addressInfo['city'] == _selectedCity && addressInfo['district']!.isNotEmpty) {
        districts.add(addressInfo['district']!);
      }
    }
    return districts.toList()..sort();
  }

  void _onCitySelected(String? city) {
    setState(() {
      _selectedCity = city;
      _selectedDistrict = null;
      _selectedHospital = null;
      _selectedDoctor = null;
      _selectedDate = null;
      _selectedTime = null;
      _availableTimes = [];
      _filteredHospitals = [];
      _filteredDoctors = [];
      _isSearchingSlots = false;
      
      if (city != null) {
        _updateFilteredHospitals();
      }
    });
  }

  void _onDistrictSelected(String? district) {
    setState(() {
      _selectedDistrict = district;
      _selectedHospital = null;
      _selectedDoctor = null;
      _selectedDate = null;
      _selectedTime = null;
      _availableTimes = [];
      _filteredDoctors = [];
      _isSearchingSlots = false;
      
      if (district != null) {
        _updateFilteredHospitals();
      }
    });
  }

  void _updateFilteredHospitals() {
    _filteredHospitals = _allHospitals.where((hospital) {
      final addressInfo = _getLocationInfo(hospital);
      final matchesCity = _selectedCity == null || addressInfo['city'] == _selectedCity;
      final matchesDistrict = _selectedDistrict == null || addressInfo['district'] == _selectedDistrict;
      return matchesCity && matchesDistrict;
    }).toList();
  }

  void _onHospitalSelected(Hospital? hospital) {
    final updatedDoctors = _getDoctorsForSelection(
      hospital: hospital,
      service: _selectedService,
    );

    setState(() {
      _selectedHospital = hospital;
      _selectedDoctor = null;
      _selectedDate = null;
      _selectedTime = null;
      _availableTimes = [];
      _filteredDoctors = updatedDoctors;
      _isSearchingSlots = false;
    });
  }

  void _onServiceSelected(Service? service) {
    final updatedDoctors = _getDoctorsForSelection(
      hospital: _selectedHospital,
      service: service,
    );

    setState(() {
      _selectedService = service;
      _selectedDoctor = null;
      _selectedDate = null;
      _selectedTime = null;
      _availableTimes = [];
      _filteredDoctors = updatedDoctors;
      _isSearchingSlots = false;
    });
  }

  void _onDoctorSelected(Doctor? doctor) {
    setState(() {
      _selectedDoctor = doctor;
      _selectedDate = null;
      _selectedTime = null;
      _availableTimes = [];
      _isSearchingSlots = false;
    });
  }

  Future<void> _selectDate() async {
    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Önce doktor seçiniz'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime firstDate = now;
    final DateTime lastDate = now.add(const Duration(days: 90));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.tealBlue,
              onPrimary: AppTheme.white,
              surface: AppTheme.white,
              onSurface: AppTheme.darkText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
        _availableTimes = _getAvailableTimes(picked);
      });
    }
  }

  List<String> _getAvailableTimes(DateTime date) {
    if (_selectedDoctor == null) return [];
    return _getAvailableTimesForDoctor(_selectedDoctor!, date);
  }

  List<String> _getAvailableTimesForDoctor(Doctor doctor, DateTime date) {
    final dayOfWeek = _getDayOfWeek(date.weekday);
    final doctorWorkingHours = doctor.workingHours[dayOfWeek] as Map<String, dynamic>?;
    
    if (doctorWorkingHours == null || doctorWorkingHours['isAvailable'] != true) {
      return [];
    }

    final startTime = doctorWorkingHours['start'] as String?;
    final endTime = doctorWorkingHours['end'] as String?;
    
    if (startTime == null || endTime == null) return [];

    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    
    List<String> times = [];
    DateTime current = start;
    
    while (current.isBefore(end) || current == start) {
      final timeStr = '${current.hour.toString().padLeft(2, '0')}:${current.minute.toString().padLeft(2, '0')}';
      
      if (!_isTimeBooked(doctor, date, timeStr)) {
        times.add(timeStr);
      }
      
      current = current.add(const Duration(minutes: 30));
      if (current.isAfter(end)) break;
    }
    
    return times;
  }

  bool _isTimeBooked(Doctor doctor, DateTime date, String time) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    return _existingAppointments.any((apt) {
      return apt.date == dateStr &&
          apt.time == time &&
          apt.doctorId == doctor.id &&
          apt.status != 'cancelled';
    });
  }

  DateTime _parseTime(String time) {
    final parts = time.split(':');
    return DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  }

  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return 'monday';
    }
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

  bool _isFormValid() {
    return _selectedCity != null &&
        _selectedDistrict != null &&
        _selectedHospital != null &&
        _selectedDoctor != null &&
        _selectedService != null &&
        _selectedDate != null &&
        _selectedTime != null;
  }

  Future<void> _createAppointment() async {
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen tüm alanları doldurunuz'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Giriş kontrolü
    if (!AuthService.isAuthenticated) {
      final result = await Navigator.push(
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

    final userId = AuthService.currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kullanıcı bilgisi alınamadı. Lütfen tekrar giriş yapın.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Loading göster
    setState(() {
      _isLoading = true;
    });

    try {
      // Tarih formatını düzenle (YYYY-MM-DD)
      final dateString = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      
      print('Randevu oluşturuluyor:');
      print('userId: $userId');
      print('hospitalId: ${_selectedHospital!.id}');
      print('doctorId: ${_selectedDoctor!.id}');
      print('date: $dateString');
      print('time: ${_selectedTime!}');
      print('serviceId: ${_selectedService!.id}');
      
      final appointment = await JsonService.createAppointment(
        userId: userId,
        hospitalId: _selectedHospital!.id,
        doctorId: _selectedDoctor!.id,
        date: dateString,
        time: _selectedTime!,
        serviceId: _selectedService!.id,
        notes: _notesController.text.trim(),
      );

      if (appointment != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Randevu başarıyla oluşturuldu'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Randevu oluşturulurken bir hata oluştu. Lütfen tekrar deneyin.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('Randevu oluşturma hatası (catch): $e');
      if (mounted) {
        String errorMessage = 'Randevu oluşturulurken bir hata oluştu';
        
        // Hata mesajını daha anlaşılır hale getir
        if (e.toString().contains('duplicate') || e.toString().contains('unique')) {
          errorMessage = 'Bu saat için zaten bir randevunuz var';
        } else if (e.toString().contains('foreign key') || e.toString().contains('constraint')) {
          errorMessage = 'Seçilen bilgiler geçersiz. Lütfen tekrar seçin.';
        } else if (e.toString().contains('network') || e.toString().contains('connection')) {
          errorMessage = 'İnternet bağlantınızı kontrol edin';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _scrollController.removeListener(_handleScrollPosition);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        _buildHeroHeader(context),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            _buildSection(
                              title: '1. Hizmeti seç',
                              subtitle: 'İhtiyaç duyduğunuz işlemi belirleyin',
                              children: [
                                _buildDropdown<Service>(
                                  value: _selectedService,
                                  items: _services,
                                  onChanged: _onServiceSelected,
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
                                  value: _selectedCity,
                                  items: _cities,
                                  onChanged: _onCitySelected,
                                  hint: 'İl seçiniz',
                                ),
                                const SizedBox(height: 18),
                                _buildFieldLabel('İlçe'),
                                const SizedBox(height: 8),
                                _buildStringDropdown(
                                  value: _selectedDistrict,
                                  items: _districts,
                                  onChanged: _onDistrictSelected,
                                  hint: 'İlçe seçiniz',
                                  enabled: _selectedCity != null,
                                ),
                                const SizedBox(height: 18),
                                _buildFieldLabel('Hastane'),
                                const SizedBox(height: 8),
                                _buildDropdown<Hospital>(
                                  value: _selectedHospital,
                                  items: _filteredHospitals,
                                  onChanged: _onHospitalSelected,
                                  getLabel: (hospital) => hospital.name,
                                  enabled: _selectedDistrict != null,
                                ),
                                const SizedBox(height: 18),
                                _buildFieldLabel('Doktor'),
                                const SizedBox(height: 8),
                                _buildDropdown<Doctor>(
                                  value: _selectedDoctor,
                                  items: _filteredDoctors,
                                  onChanged: _onDoctorSelected,
                                  getLabel: (doctor) => '${doctor.fullName} - ${doctor.specialty}',
                                  enabled: _selectedHospital != null && _filteredDoctors.isNotEmpty,
                                ),
                                const SizedBox(height: 20),
                                _buildSearchButton(),
                              ],
                            ),
                            _buildSection(
                              title: '3. Tarih ve saat',
                              subtitle: 'Müsait olduğunuz zamanı seçin',
                              children: [
                                _buildFieldLabel('Tarih'),
                                const SizedBox(height: 8),
                                _buildDatePicker(),
                                const SizedBox(height: 18),
                                _buildFieldLabel('Saat'),
                                const SizedBox(height: 8),
                                _buildTimeDropdown(),
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
          if (!_isLoading && _showCreateButton) _buildBottomAction(),
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

  Widget _buildDatePicker() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.inputFieldGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerLight),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _selectedDoctor != null ? _selectDate : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: _selectedDoctor != null
                      ? AppTheme.tealBlue
                      : AppTheme.iconGray,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? _formatDate(_selectedDate!)
                        : 'Tarih seçiniz',
                    style: AppTheme.bodyMedium.copyWith(
                      color: _selectedDate != null
                          ? AppTheme.darkText
                          : AppTheme.iconGray,
                    ),
                  ),
                ),
                if (_selectedDate != null)
                  IconButton(
                    icon: Icon(Icons.clear, size: 18, color: AppTheme.iconGray),
                    onPressed: () {
                      setState(() {
                        _selectedDate = null;
                        _selectedTime = null;
                        _availableTimes = [];
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDropdown() {
    // Seçili saatin availableTimes listesinde olup olmadığını kontrol et
    // Eğer yoksa veya duplicate varsa, null yap
    String? validTime;
    if (_selectedTime != null && _availableTimes.isNotEmpty) {
      final matchingTimes = _availableTimes.where((time) => time == _selectedTime).toList();
      if (matchingTimes.length == 1) {
        validTime = _selectedTime;
      } else {
        // Duplicate varsa veya hiç yoksa, null yap
        validTime = null;
      }
    }
    
    return Container(
      decoration: BoxDecoration(
        color: _selectedDate != null && _availableTimes.isNotEmpty
            ? AppTheme.inputFieldGray
            : AppTheme.inputFieldGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedDate != null && _availableTimes.isNotEmpty
              ? AppTheme.dividerLight
              : AppTheme.iconGray.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: validTime,
        items: _availableTimes.map((time) {
          return DropdownMenuItem<String>(
            value: time,
            child: Text(time, style: AppTheme.bodyMedium),
          );
        }).toList(),
        onChanged: _selectedDate != null && _availableTimes.isNotEmpty
            ? (value) {
                setState(() {
                  _selectedTime = value;
                });
              }
            : null,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintText: _selectedDate == null
              ? 'Önce tarih seçiniz'
              : _availableTimes.isEmpty
                  ? 'Uygun saat bulunamadı'
                  : 'Saat seçiniz',
          hintStyle: TextStyle(color: AppTheme.iconGray),
        ),
        style: AppTheme.bodyMedium,
        dropdownColor: AppTheme.white,
        icon: Icon(
          Icons.access_time,
          color: _selectedDate != null && _availableTimes.isNotEmpty
              ? AppTheme.tealBlue
              : AppTheme.iconGray,
        ),
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

class _AvailableSlot {
  final Hospital hospital;
  final Doctor doctor;
  final DateTime date;
  final String time;

  _AvailableSlot({
    required this.hospital,
    required this.doctor,
    required this.date,
    required this.time,
  });
}

class _AvailableSlotsScreen extends StatelessWidget {
  final List<_AvailableSlot> slots;
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

  Widget _buildSlotCard(BuildContext context, _AvailableSlot slot) {
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

