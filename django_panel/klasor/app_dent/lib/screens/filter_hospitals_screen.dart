import 'package:flutter/material.dart';
import '../models/hospital.dart';
import '../services/json_service.dart';
import '../theme/app_theme.dart';
import '../widgets/image_widget.dart';
import 'hospital_detail_screen.dart';

class FilterHospitalsScreen extends StatefulWidget {
  const FilterHospitalsScreen({super.key});

  @override
  State<FilterHospitalsScreen> createState() => _FilterHospitalsScreenState();
}

class _FilterHospitalsScreenState extends State<FilterHospitalsScreen> {
  List<Hospital> _allHospitals = [];
  List<Hospital> _filteredHospitals = [];
  List<Hospital> _displayedHospitals = [];
  
  String? _selectedCity;
  String? _selectedDistrict;
  
  final ScrollController _scrollController = ScrollController();
  int _displayedCount = 10; // İlk 10 hastane gösterilecek
  final int _loadMoreCount = 5; // Her seferinde 5 hastane daha yüklenecek
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final hospitals = await JsonService.getHospitals();

    setState(() {
      _allHospitals = hospitals;
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
      _updateFilteredHospitals();
    });
  }

  void _onDistrictSelected(String? district) {
    setState(() {
      _selectedDistrict = district;
      _updateFilteredHospitals();
    });
  }

  void _updateFilteredHospitals() {
    _filteredHospitals = _allHospitals.where((hospital) {
      final addressInfo = _parseAddress(hospital.address);
      final matchesCity = _selectedCity == null || addressInfo['city'] == _selectedCity;
      final matchesDistrict = _selectedDistrict == null || addressInfo['district'] == _selectedDistrict;
      return matchesCity && matchesDistrict;
    }).toList();
    
    // İsme göre sırala
    _filteredHospitals.sort((a, b) => a.name.compareTo(b.name));
    
    // İlk 10 hastaneyi göster
    _displayedCount = 10;
    _displayedHospitals = _filteredHospitals.take(_displayedCount).toList();
  }

  void _onScroll() {
    // Scroll pozisyonu %80'e ulaştığında daha fazla hastane yükle
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    if (currentScroll >= maxScroll * 0.8) {
      if (_displayedCount < _filteredHospitals.length) {
        setState(() {
          _displayedCount = (_displayedCount + _loadMoreCount)
              .clamp(0, _filteredHospitals.length);
          _displayedHospitals = _filteredHospitals.take(_displayedCount).toList();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Hastane Filtrele'),
        backgroundColor: AppTheme.accentTeal,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filtre Bölümü
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // İl Seçimi
                      DropdownButtonFormField<String>(
                        value: _selectedCity,
                        decoration: InputDecoration(
                          labelText: 'İl Seçiniz',
                          prefixIcon: const Icon(Icons.location_city),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppTheme.inputBackground,
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Tüm İller'),
                          ),
                          ..._cities.map((city) => DropdownMenuItem<String>(
                                value: city,
                                child: Text(city),
                              )),
                        ],
                        onChanged: _onCitySelected,
                      ),
                      if (_selectedCity != null) ...[
                        const SizedBox(height: 16),
                        // İlçe Seçimi
                        DropdownButtonFormField<String>(
                          value: _selectedDistrict,
                          decoration: InputDecoration(
                            labelText: 'İlçe Seçiniz',
                            prefixIcon: const Icon(Icons.location_on),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: AppTheme.inputBackground,
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Tüm İlçeler'),
                            ),
                            ..._districts.map((district) => DropdownMenuItem<String>(
                                  value: district,
                                  child: Text(district),
                                )),
                          ],
                          onChanged: _onDistrictSelected,
                        ),
                      ],
                    ],
                  ),
                ),
                // Sonuç Sayısı
                if (_selectedCity != null || _selectedDistrict != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    color: AppTheme.backgroundSecondary,
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_hospital,
                          size: 18,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_filteredHospitals.length} hastane bulundu',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Hastane Listesi
                Expanded(
                  child: _filteredHospitals.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: AppTheme.iconSecondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedCity == null && _selectedDistrict == null
                                      ? 'Lütfen il veya ilçe seçiniz'
                                      : 'Seçilen kriterlere uygun hastane bulunamadı',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.lightText,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(20),
                          itemCount: _displayedHospitals.length +
                              (_displayedCount < _filteredHospitals.length ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _displayedHospitals.length) {
                              // Loading indicator
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final hospital = _displayedHospitals[index];
                            return _buildHospitalCard(hospital);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildHospitalCard(Hospital hospital) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HospitalDetailScreen(
                  hospital: hospital,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Hastane Fotoğrafı
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: hospital.image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: buildImage(
                            hospital.image!,
                            fit: BoxFit.cover,
                            errorWidget: Icon(
                              Icons.local_hospital,
                              size: 40,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.local_hospital,
                          size: 40,
                          color: AppTheme.primaryBlue,
                        ),
                ),
                const SizedBox(width: 16),
                // Hastane Bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hospital.name,
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppTheme.iconSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              hospital.address,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.lightText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.iconSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

