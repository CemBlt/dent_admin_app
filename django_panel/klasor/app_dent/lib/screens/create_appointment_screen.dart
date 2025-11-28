import 'dart:ui';
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
  final String? preselectedDoctorId;
  
  const CreateAppointmentScreen({
    super.key,
    this.preselectedHospitalId,
    this.preselectedDoctorId,
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

  @override
  void initState() {
    super.initState();
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

  Widget _buildBottomAction() {
    // Tüm alanlar dolu mu kontrol et
    final isAllFieldsFilled = _isFormValid();
    // Hizmet seçilmiş mi kontrol et (arama butonu için)
    final isServiceSelected = _selectedService != null;
    
    // Buton metni ve fonksiyonu belirle
    final bool isCreateButton = isAllFieldsFilled;
    final String buttonText = isCreateButton ? 'Randevu Oluştur' : 'Uygun randevuları ara';
    final IconData buttonIcon = isCreateButton ? Icons.check_circle_outline : Icons.search_rounded;
    final bool isButtonActive = isCreateButton 
        ? isAllFieldsFilled 
        : (isServiceSelected && !_isSearchingSlots);
    final VoidCallback? onButtonTap = isButtonActive
        ? (isCreateButton ? _createAppointment : _searchAvailableSlots)
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
                          if (_isSearchingSlots && !isCreateButton)
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
    
    // Müsaitlik kontrolü için optimize edilmiş sorguyu kullan
    final availabilityData = await JsonService.getAppointmentsForAvailabilityCheck();
    final appointments = availabilityData.map((data) {
      return Appointment(
        id: '',
        userId: '',
        hospitalId: '',
        doctorId: data['doctor_id'].toString(),
        date: data['date']?.toString() ?? '',
        time: data['time']?.toString() ?? '',
        status: data['status']?.toString() ?? 'completed',
        service: '',
        notes: '',
        review: null,
        createdAt: '',
      );
    }).toList();

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
      
      // Eğer preselectedDoctorId varsa, doktoru seç ve randevuları göster
      if (widget.preselectedDoctorId != null) {
        try {
          final preselectedDoctor = doctors.firstWhere(
            (d) => d.id == widget.preselectedDoctorId,
          );
          
          // Doktorun hastanesini seç
          if (_selectedHospital == null) {
            try {
              final doctorHospital = hospitals.firstWhere(
                (h) => h.id == preselectedDoctor.hospitalId,
              );
              final addressInfo = _getLocationInfo(doctorHospital);
              _selectedCity = addressInfo['city'];
              _selectedDistrict = addressInfo['district'];
              _selectedHospital = doctorHospital;
              _updateFilteredHospitals();
            } catch (e) {
              // Hastane bulunamadı
            }
          }
          
          // Doktoru seç
          _selectedDoctor = preselectedDoctor;
          
          // Doktorun hizmetlerinden birini otomatik seç (varsa)
          if (preselectedDoctor.services.isNotEmpty) {
            final doctorServiceId = preselectedDoctor.services.first;
            try {
              _selectedService = services.firstWhere(
                (s) => s.id == doctorServiceId,
              );
            } catch (e) {
              // Hizmet bulunamadı
            }
          }
          
          // Filtrelenmiş doktorları güncelle
          _filteredDoctors = _getDoctorsForSelection(
            hospital: _selectedHospital,
            service: _selectedService,
          );
          
          // Randevuları otomatik göster
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedService != null) {
              _searchAvailableSlots();
            }
          });
        } catch (e) {
          // Doktor bulunamadı
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

    // Randevu listesini güncelle (alınmış randevuları görmemek için)
    try {
      final availabilityData = await JsonService.getAppointmentsForAvailabilityCheck();
      
      // Availability data'yı Appointment listesine çevir (sadece kontrol için gerekli alanlar)
      final appointments = availabilityData.map((data) {
        return Appointment(
          id: '',
          userId: '',
          hospitalId: '',
          doctorId: data['doctor_id'].toString(),
          date: data['date']?.toString() ?? '',
          time: data['time']?.toString() ?? '',
          status: data['status']?.toString() ?? 'completed',
          service: '',
          notes: '',
          review: null,
          createdAt: '',
        );
      }).toList();
      
      if (mounted) {
        setState(() {
          _existingAppointments = appointments;
        });
      }
    } catch (e) {
      print('Randevu listesi güncellenirken hata: $e');
      if (mounted) {
        setState(() {
          _isSearchingSlots = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Randevu kontrolü yapılamadı: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

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
      if (mounted) {
        setState(() {
          _isSearchingSlots = false;
        });
      }
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

          // Ekstra güvenlik: Her slot için tekrar kontrol et
          if (!_isTimeBooked(doctor, date, time)) {
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


  List<String> _getAvailableTimes(DateTime date) {
    // Eğer doktor seçilmişse, o doktorun müsait saatlerini göster
    if (_selectedDoctor != null) {
      return _getAvailableTimesForDoctor(_selectedDoctor!, date);
    }
    
    // Doktor seçilmemişse, genel saatleri göster (09:00 - 17:00 arası, 30 dakikalık aralıklarla)
    return _getGeneralTimeSlots();
  }

  List<String> _getGeneralTimeSlots() {
    // Genel saat aralıkları: 09:00 - 17:00, 30 dakikalık aralıklarla
    final List<String> times = [];
    for (int hour = 9; hour < 17; hour++) {
      times.add('${hour.toString().padLeft(2, '0')}:00');
      times.add('${hour.toString().padLeft(2, '0')}:30');
    }
    // Son saat: 17:00
    times.add('17:00');
    return times;
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

  /// Saat formatını normalize eder (HH:MM formatına çevirir)
  /// Örnek: "9:00" -> "09:00", "09:00:00" -> "09:00", "9:30" -> "09:30"
  String _normalizeTime(String time) {
    if (time.isEmpty) return time;
    
    // Boşlukları temizle
    time = time.trim();
    
    // HH:MM:SS formatından HH:MM formatına çevir
    if (time.length >= 8 && time.contains(':')) {
      final parts = time.split(':');
      if (parts.length >= 2) {
        final hour = parts[0].padLeft(2, '0');
        final minute = parts[1].padLeft(2, '0');
        return '$hour:$minute';
      }
    }
    
    // HH:MM formatını kontrol et ve normalize et
    if (time.length == 5 && time.contains(':')) {
      final parts = time.split(':');
      if (parts.length == 2) {
        final hour = parts[0].padLeft(2, '0');
        final minute = parts[1].padLeft(2, '0');
        return '$hour:$minute';
      }
    }
    
    // H:MM formatını HH:MM formatına çevir
    if (time.length == 4 && time.contains(':')) {
      final parts = time.split(':');
      if (parts.length == 2) {
        final hour = parts[0].padLeft(2, '0');
        final minute = parts[1].padLeft(2, '0');
        return '$hour:$minute';
      }
    }
    
    return time;
  }

  bool _isTimeBooked(Doctor doctor, DateTime date, String time) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final normalizedTime = _normalizeTime(time);
    
    return _existingAppointments.any((apt) {
      final aptDate = apt.date.trim();
      final aptTime = _normalizeTime(apt.time);
      final doctorIdMatch = apt.doctorId.toString() == doctor.id.toString();
      final dateMatch = aptDate == dateStr;
      final timeMatch = aptTime == normalizedTime;
      final statusMatch = apt.status != 'cancelled';
      
      return dateMatch && timeMatch && doctorIdMatch && statusMatch;
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

    // Randevu çakışması kontrolü (frontend'de hızlı kontrol)
    try {
      final availabilityData = await JsonService.getAppointmentsForAvailabilityCheck();
      final appointments = availabilityData.map((data) {
        return Appointment(
          id: '',
          userId: '',
          hospitalId: '',
          doctorId: data['doctor_id'].toString(),
          date: data['date']?.toString() ?? '',
          time: data['time']?.toString() ?? '',
          status: data['status']?.toString() ?? 'completed',
          service: '',
          notes: '',
          review: null,
          createdAt: '',
        );
      }).toList();
      
      setState(() {
        _existingAppointments = appointments;
      });
      
      if (_isTimeBooked(_selectedDoctor!, _selectedDate!, _selectedTime!)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bu tarih ve saatte zaten bir randevu bulunmaktadır. Lütfen başka bir saat seçiniz.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }
    } catch (e) {
      print('Randevu kontrolü yapılamadı: $e');
      // Hata olsa bile devam et, backend'de kontrol edilecek
    }

    // Loading göster
    setState(() {
      _isLoading = true;
    });

    try {
      // Tarih formatını düzenle (YYYY-MM-DD)
      final dateString = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      
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
        final errorString = e.toString();
        if (errorString.contains('zaten bir randevu bulunmaktadır')) {
          errorMessage = 'Bu tarih ve saatte zaten bir randevu bulunmaktadır. Lütfen başka bir saat seçiniz.';
        } else if (errorString.contains('duplicate') || errorString.contains('unique')) {
          errorMessage = 'Bu saat için zaten bir randevunuz var';
        } else if (errorString.contains('foreign key') || errorString.contains('constraint')) {
          errorMessage = 'Seçilen bilgiler geçersiz. Lütfen tekrar seçin.';
        } else if (errorString.contains('network') || errorString.contains('connection')) {
          errorMessage = 'İnternet bağlantınızı kontrol edin';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
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
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
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
                                  getLabel: (doctor) => doctor.fullName,
                                  enabled: _selectedHospital != null && _filteredDoctors.isNotEmpty,
                                ),
                              ],
                            ),
                            _buildSection(
                              title: '3. Tarih ve saat',
                              subtitle: 'Müsait olduğunuz zamanı seçin',
                              children: [
                                _buildDateTimePicker(),
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
          if (!_isLoading) _buildBottomAction(),
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

  Widget _buildDateTimePicker() {
    final hasSelection = _selectedDate != null && _selectedTime != null;
    final dateText = _selectedDate != null ? _formatDate(_selectedDate!) : 'Tarih seçiniz';
    final timeText = _selectedTime != null ? _selectedTime! : '';
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
          onTap: () => _showDateTimePickerModal(),
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
                      setState(() {
                        _selectedDate = null;
                        _selectedTime = null;
                        _availableTimes = [];
                      });
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

  Future<void> _showDateTimePickerModal() async {
    DateTime? tempDate = _selectedDate;
    String? tempTime = _selectedTime;
    List<String> tempAvailableTimes = [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Tarih değiştiğinde saatleri güncelle
          if (tempDate != null && tempAvailableTimes.isEmpty) {
            tempAvailableTimes = _getAvailableTimes(tempDate!);
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
                                          tempAvailableTimes = _getAvailableTimes(date);
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
                                  setState(() {
                                    _selectedDate = tempDate;
                                    _selectedTime = tempTime;
                                    _availableTimes = tempAvailableTimes;
                                  });
                                  Navigator.pop(context);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppTheme.tealBlue,
                            disabledBackgroundColor: AppTheme.iconGray.withOpacity(0.3),
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

