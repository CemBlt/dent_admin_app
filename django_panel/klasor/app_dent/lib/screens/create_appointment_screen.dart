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
    final isActive = _isFormValid();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
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
      _services = services;
      _existingAppointments = appointments;
      
      // Eğer preselectedHospitalId varsa, hastaneyi seç
      if (widget.preselectedHospitalId != null) {
        try {
          final preselectedHospital = hospitals.firstWhere(
            (h) => h.id == widget.preselectedHospitalId,
          );
          // İl ve ilçe bilgilerini ayarla
          final addressInfo = _parseAddress(preselectedHospital.address);
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
  Map<String, String> _parseAddress(String address) {
    final parts = address.split(',').map((e) => e.trim()).toList();
    if (parts.length >= 2) {
      return {'district': parts[0], 'city': parts[1]};
    }
    return {'district': address, 'city': ''};
  }

  // Tüm illeri getir
  List<String> get _cities {
    final cities = <String>{};
    for (var hospital in _allHospitals) {
      final addressInfo = _parseAddress(hospital.address);
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
      final addressInfo = _parseAddress(hospital.address);
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
      
      if (district != null) {
        _updateFilteredHospitals();
      }
    });
  }

  void _updateFilteredHospitals() {
    _filteredHospitals = _allHospitals.where((hospital) {
      final addressInfo = _parseAddress(hospital.address);
      final matchesCity = _selectedCity == null || addressInfo['city'] == _selectedCity;
      final matchesDistrict = _selectedDistrict == null || addressInfo['district'] == _selectedDistrict;
      return matchesCity && matchesDistrict;
    }).toList();
  }

  void _onHospitalSelected(Hospital? hospital) {
    setState(() {
      _selectedHospital = hospital;
      _selectedDoctor = null;
      _selectedDate = null;
      _selectedTime = null;
      _availableTimes = [];
      
      if (hospital != null) {
        _filteredDoctors = _allDoctors
            .where((doctor) => doctor.hospitalId == hospital.id)
            .toList();
      } else {
        _filteredDoctors = [];
      }
    });
  }

  void _onDoctorSelected(Doctor? doctor) {
    setState(() {
      _selectedDoctor = doctor;
      _selectedDate = null;
      _selectedTime = null;
      _availableTimes = [];
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

    final dayOfWeek = _getDayOfWeek(date.weekday);
    final doctorWorkingHours = _selectedDoctor!.workingHours[dayOfWeek] as Map<String, dynamic>?;
    
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
      
      // Dolu saatleri kontrol et
      if (!_isTimeBooked(date, timeStr)) {
        times.add(timeStr);
      }
      
      current = current.add(const Duration(minutes: 30));
      if (current.isAfter(end)) break;
    }
    
    return times;
  }

  bool _isTimeBooked(DateTime date, String time) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    return _existingAppointments.any((apt) {
      return apt.date == dateStr &&
          apt.time == time &&
          apt.doctorId == _selectedDoctor?.id &&
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSection(
                              title: '1. Konumunu belirle',
                              subtitle: 'Size en yakın klinikleri görmek için şehir ve ilçe seçin',
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
                              ],
                            ),
                            _buildSection(
                              title: '2. Hizmet sağlayıcını seç',
                              subtitle: 'Hastane, doktor ve hizmet bilgilerini belirleyin',
                              children: [
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
                                  enabled: _selectedHospital != null,
                                ),
                                const SizedBox(height: 18),
                                _buildFieldLabel('Hizmet'),
                                const SizedBox(height: 8),
                                _buildDropdown<Service>(
                                  value: _selectedService,
                                  items: _services,
                                  onChanged: (service) {
                                    setState(() {
                                      _selectedService = service;
                                    });
                                  },
                                  getLabel: (service) => service.name,
                                ),
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
                    _buildBottomAction(),
                  ],
                ),
        ),
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

