import 'package:flutter/material.dart'; // For debugPrint
import '../models/hospital.dart';
import '../models/doctor.dart';
import '../models/tip.dart';
import '../models/appointment.dart';
import '../models/service.dart';
import '../models/user.dart';
import '../models/review.dart';
import '../models/rating.dart';
import 'supabase_service.dart';
import 'auth_service.dart';

class JsonService {
  // ==================== HASTANELER ====================
  
  /// Hastaneleri Supabase'den getirir
  static Future<List<Hospital>> getHospitals() async {
    try {
      final response = await SupabaseService.supabase
          .from('hospitals')
          .select()
          .order('created_at', ascending: false);
      
      final List<dynamic> data = response;
      return data.map((json) => _hospitalFromDb(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Supabase formatından Hospital modeline çevirir
  static Hospital _hospitalFromDb(Map<String, dynamic> dbData) {
    return Hospital(
      id: dbData['id'].toString(),
      name: dbData['name'] ?? '',
      address: dbData['address'] ?? '',
      latitude: (dbData['latitude'] ?? 0.0).toDouble(),
      longitude: (dbData['longitude'] ?? 0.0).toDouble(),
      phone: dbData['phone'] ?? '',
      email: dbData['email'] ?? '',
      description: dbData['description'] ?? '',
      image: dbData['image'],
      gallery: dbData['gallery'] != null 
          ? List<String>.from(dbData['gallery'] as List) 
          : null,
      services: dbData['services'] != null 
          ? (dbData['services'] as List).map((e) => e.toString()).toList()
          : [],
      workingHours: dbData['working_hours'] ?? {},
      createdAt: dbData['created_at'] ?? '',
      provinceId: dbData['province_id']?.toString(),
      provinceName: dbData['province_name'],
      districtId: dbData['district_id']?.toString(),
      districtName: dbData['district_name'],
      neighborhoodId: dbData['neighborhood_id']?.toString(),
      neighborhoodName: dbData['neighborhood_name'],
    );
  }

  /// Hastane ara
  static Future<List<Hospital>> searchHospitals(String query) async {
    final allHospitals = await getHospitals();
    if (query.isEmpty) return allHospitals;
    
    final lowerQuery = query.toLowerCase();
    return allHospitals.where((hospital) {
      return hospital.name.toLowerCase().contains(lowerQuery) ||
          hospital.address.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // ==================== DOKTORLAR ====================

  /// Doktorları Supabase'den getirir
  static Future<List<Doctor>> getDoctors() async {
    try {
      final response = await SupabaseService.supabase
          .from('doctors')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      final List<dynamic> data = response;
      return data.map((json) => _doctorFromDb(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Supabase formatından Doctor modeline çevirir
  static Doctor _doctorFromDb(Map<String, dynamic> dbData) {
    return Doctor(
      id: dbData['id'].toString(),
      hospitalId: dbData['hospital_id'].toString(),
      name: dbData['name'] ?? '',
      surname: dbData['surname'] ?? '',
      specialty: dbData['specialty'] ?? '',
      image: dbData['image'],
      bio: dbData['bio'] ?? '',
      workingHours: dbData['working_hours'] ?? {},
      createdAt: dbData['created_at'] ?? '',
      services: dbData['services'] != null
          ? (dbData['services'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }

  /// Belirli bir hastanenin doktorlarını getir
  static Future<List<Doctor>> getDoctorsByHospital(String hospitalId) async {
    try {
      final response = await SupabaseService.supabase
          .from('doctors')
          .select()
          .eq('hospital_id', hospitalId)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      final List<dynamic> data = response;
      return data.map((json) => _doctorFromDb(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Popüler doktorları getir (örnek: ilk 4 doktor)
  static Future<List<Doctor>> getPopularDoctors() async {
    final allDoctors = await getDoctors();
    return allDoctors.take(4).toList();
  }

  // ==================== RANDEVULAR ====================

  /// Randevuları Supabase'den getirir
  static Future<List<Appointment>> getAppointments() async {
    try {
      final response = await SupabaseService.supabase
          .from('appointments')
          .select()
          .order('created_at', ascending: false);
      
      final List<dynamic> data = response;
      return data.map((json) => _appointmentFromDb(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Supabase formatından Appointment modeline çevirir
  static Appointment _appointmentFromDb(Map<String, dynamic> dbData) {
    return Appointment(
      id: dbData['id'].toString(),
      userId: dbData['user_id'].toString(),
      hospitalId: dbData['hospital_id'].toString(),
      doctorId: dbData['doctor_id'].toString(),
      date: dbData['date'] ?? '',
      time: dbData['time'] ?? '',
      status: dbData['status'] ?? 'pending',
      service: dbData['service_id'].toString(),
      notes: dbData['notes'] ?? '',
      review: dbData['review'] as String?,
      createdAt: dbData['created_at'] ?? '',
    );
  }

  /// Kullanıcının randevularını getir
  static Future<List<Appointment>> getUserAppointments(String userId) async {
    try {
      final response = await SupabaseService.supabase
          .from('appointments')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);
      
      final List<dynamic> data = response;
      return data.map((json) => _appointmentFromDb(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Appointment ID'ye göre yorumu getirir
  static Future<Review?> getReviewByAppointmentId(String appointmentId) async {
    try {
      final response = await SupabaseService.supabase
          .from('reviews')
          .select()
          .eq('appointment_id', appointmentId)
          .maybeSingle();
      
      if (response == null) {
        return null;
      }
      
      return _reviewFromDb(response as Map<String, dynamic>);
    } catch (e) {
      print('Yorum getirme hatası: $e');
      return null;
    }
  }

  /// Supabase formatından Review modeline çevirir
  static Review _reviewFromDb(Map<String, dynamic> dbData) {
    return Review(
      id: dbData['id'].toString(),
      userId: dbData['user_id'].toString(),
      hospitalId: dbData['hospital_id'].toString(),
      doctorId: dbData['doctor_id']?.toString(),
      appointmentId: dbData['appointment_id'].toString(),
      comment: dbData['comment'] ?? '',
      createdAt: dbData['created_at'] ?? '',
    );
  }

  /// Randevu yorumunu reviews tablosuna ekler veya günceller
  static Future<bool> updateAppointmentReview(String appointmentId, String review) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) {
        print('Kullanıcı giriş yapmamış');
        return false;
      }

      // Önce randevu bilgilerini al
      final appointmentResponse = await SupabaseService.supabase
          .from('appointments')
          .select('hospital_id, doctor_id')
          .eq('id', appointmentId)
          .maybeSingle();
      
      if (appointmentResponse == null) {
        print('Randevu bulunamadı');
        return false;
      }

      final appointment = appointmentResponse as Map<String, dynamic>;
      final hospitalId = appointment['hospital_id'].toString();
      final doctorId = appointment['doctor_id'].toString();

      // Mevcut yorumu kontrol et
      final existingReviewResponse = await SupabaseService.supabase
          .from('reviews')
          .select('id')
          .eq('appointment_id', appointmentId)
          .maybeSingle();

      if (existingReviewResponse != null) {
        // Yorum varsa güncelle
        final existingReview = existingReviewResponse as Map<String, dynamic>;
        if (review.isEmpty) {
          // Yorum boşsa sil
          await SupabaseService.supabase
              .from('reviews')
              .delete()
              .eq('id', existingReview['id']);
        } else {
          // Yorumu güncelle
          await SupabaseService.supabase
              .from('reviews')
              .update({'comment': review})
              .eq('id', existingReview['id']);
        }
      } else {
        // Yorum yoksa ve yeni yorum varsa ekle
        if (review.isNotEmpty) {
          await SupabaseService.supabase
              .from('reviews')
              .insert({
                'user_id': userId,
                'hospital_id': hospitalId,
                'doctor_id': doctorId,
                'appointment_id': appointmentId,
                'comment': review,
              });
        }
      }
      
      return true;
    } catch (e) {
      print('Yorum güncelleme hatası: $e');
      return false;
    }
  }

  /// Yeni randevu oluşturur
  static Future<Appointment?> createAppointment({
    required String userId,
    required String hospitalId,
    required String doctorId,
    required String date,
    required String time,
    required String serviceId,
    String notes = '',
  }) async {
    try {
      final response = await SupabaseService.supabase
          .from('appointments')
          .insert({
            'user_id': userId,
            'hospital_id': hospitalId,
            'doctor_id': doctorId,
            'date': date,
            'time': time,
            'status': 'pending',
            'service_id': serviceId,
            'notes': notes,
          })
          .select()
          .single();
      
      return _appointmentFromDb(response);
    } catch (e) {
      // Hata detayını logla
      print('Randevu oluşturma hatası: $e');
      rethrow; // Hatayı yukarı fırlat ki detaylı mesaj gösterilebilsin
    }
  }

  // ==================== HİZMETLER ====================

  /// Hizmetleri Supabase'den getirir
  static Future<List<Service>> getServices() async {
    try {
      final response = await SupabaseService.supabase
          .from('services')
          .select()
          .order('name', ascending: true);
      
      final List<dynamic> data = response;
      return data.map((json) => _serviceFromDb(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Supabase formatından Service modeline çevirir
  static Service _serviceFromDb(Map<String, dynamic> dbData) {
    return Service(
      id: dbData['id'].toString(),
      name: dbData['name'] ?? '',
      description: dbData['description'] ?? '',
    );
  }

  /// Hizmet getir
  static Future<Service?> getService(String serviceId) async {
    try {
      final response = await SupabaseService.supabase
          .from('services')
          .select()
          .eq('id', serviceId)
          .single();
      
      return _serviceFromDb(response);
    } catch (e) {
      return null;
    }
  }

  // ==================== KULLANICILAR ====================

  /// Kullanıcıları Supabase'den getirir
  static Future<List<User>> getUsers() async {
    try {
      final response = await SupabaseService.supabase
          .from('user_profiles')
          .select()
          .order('created_at', ascending: false);
      
      final List<dynamic> data = response;
      return data.map((json) => _userFromDb(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Supabase formatından User modeline çevirir
  static User _userFromDb(Map<String, dynamic> dbData) {
    return User(
      id: dbData['id'].toString(),
      email: dbData['email'] ?? '', // auth.users'dan alınacak
      password: '', // Şifre gösterilmez
      name: dbData['name'] ?? '',
      surname: dbData['surname'] ?? '',
      phone: dbData['phone'] ?? '',
      profileImage: dbData['profile_image'],
      createdAt: dbData['created_at'] ?? '',
    );
  }

  /// Kullanıcı getir
  static Future<User?> getUser(String userId) async {
    try {
      // Önce user_profiles tablosundan kayıt ara
      final response = await SupabaseService.supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      // Eğer user_profiles tablosunda kayıt varsa, onu döndür
      if (response != null) {
        return _userFromDb(response as Map<String, dynamic>);
      }
      
      // Eğer user_profiles tablosunda kayıt yoksa, Supabase Auth'dan bilgileri al
      // Sadece mevcut kullanıcı için Auth bilgilerine erişebiliriz
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == userId) {
        final currentUser = SupabaseService.supabase.auth.currentUser;
        if (currentUser != null) {
          // user_metadata'dan bilgileri al
          final userMetadata = currentUser.userMetadata ?? {};
          final email = currentUser.email ?? '';
          
          // Auth'dan gelen bilgilerle User objesi oluştur
          return User(
            id: currentUser.id,
            email: email,
            password: '', // Şifre gösterilmez
            name: userMetadata['name']?.toString() ?? '',
            surname: userMetadata['surname']?.toString() ?? '',
            phone: userMetadata['phone']?.toString() ?? '',
            profileImage: null,
            createdAt: currentUser.createdAt ?? DateTime.now().toIso8601String(),
          );
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Kullanıcı getirme hatası: $e');
      return null;
    }
  }

  // ==================== YORUMLAR ====================

  /// Yorumları Supabase'den getirir
  static Future<List<Review>> getReviews() async {
    try {
      final response = await SupabaseService.supabase
          .from('reviews')
          .select()
          .order('created_at', ascending: false);
      
      final List<dynamic> data = response;
      return data.map((json) => _reviewFromDb(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Belirli bir hastanenin yorumlarını getir
  static Future<List<Review>> getReviewsByHospital(String hospitalId) async {
    try {
      final response = await SupabaseService.supabase
          .from('reviews')
          .select()
          .eq('hospital_id', hospitalId)
          .order('created_at', ascending: false);
      
      final List<dynamic> data = response;
      return data.map((json) => _reviewFromDb(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Belirli bir doktorun yorumlarını getir
  static Future<List<Review>> getReviewsByDoctor(String doctorId) async {
    try {
      final response = await SupabaseService.supabase
          .from('reviews')
          .select()
          .eq('doctor_id', doctorId)
          .order('created_at', ascending: false);
      
      final List<dynamic> data = response;
      return data.map((json) => _reviewFromDb(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Yeni yorum oluşturur
  static Future<Review?> createReview({
    required String userId,
    required String hospitalId,
    String? doctorId,
    required String appointmentId,
    required String comment,
  }) async {
    try {
      final response = await SupabaseService.supabase
          .from('reviews')
          .insert({
            'user_id': userId,
            'hospital_id': hospitalId,
            'doctor_id': doctorId,
            'appointment_id': appointmentId,
            'comment': comment,
          })
          .select()
          .single();
      
      return _reviewFromDb(response);
    } catch (e) {
      return null;
    }
  }

  // ==================== PUANLAMALAR ====================

  /// Puanlamaları Supabase'den getirir
  static Future<List<Rating>> getRatings() async {
    try {
      final response = await SupabaseService.supabase
          .from('ratings')
          .select()
          .order('created_at', ascending: false);
      
      final List<dynamic> data = response;
      return data.map((json) => _ratingFromDb(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Supabase formatından Rating modeline çevirir
  static Rating _ratingFromDb(Map<String, dynamic> dbData) {
    return Rating(
      id: dbData['id'].toString(),
      userId: dbData['user_id'].toString(),
      hospitalId: dbData['hospital_id'].toString(),
      doctorId: dbData['doctor_id']?.toString(),
      appointmentId: dbData['appointment_id'].toString(),
      hospitalRating: dbData['hospital_rating'] ?? 0,
      doctorRating: dbData['doctor_rating'],
      createdAt: dbData['created_at'] ?? '',
    );
  }

  /// Belirli bir hastanenin puanlamalarını getir
  static Future<List<Rating>> getRatingsByHospital(String hospitalId) async {
    try {
      final response = await SupabaseService.supabase
          .from('ratings')
          .select()
          .eq('hospital_id', hospitalId)
          .order('created_at', ascending: false);
      
      final List<dynamic> data = response;
      return data.map((json) => _ratingFromDb(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Belirli bir doktorun puanlamalarını getir
  static Future<List<Rating>> getRatingsByDoctor(String doctorId) async {
    try {
      final response = await SupabaseService.supabase
          .from('ratings')
          .select()
          .eq('doctor_id', doctorId)
          .order('created_at', ascending: false);
      
      final List<dynamic> data = response;
      return data.map((json) => _ratingFromDb(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Appointment ID'ye göre puanlamayı getir
  static Future<Rating?> getRatingByAppointmentId(String appointmentId) async {
    try {
      final response = await SupabaseService.supabase
          .from('ratings')
          .select()
          .eq('appointment_id', appointmentId)
          .maybeSingle();
      
      if (response == null) {
        return null;
      }
      
      return _ratingFromDb(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Puanlama getirme hatası: $e');
      return null;
    }
  }

  /// Hastane ortalama puanını hesapla
  static Future<double> getHospitalAverageRating(String hospitalId) async {
    final ratings = await getRatingsByHospital(hospitalId);
    if (ratings.isEmpty) return 0.0;
    
    final total = ratings.fold<int>(
      0,
      (sum, rating) => sum + rating.hospitalRating,
    );
    return total / ratings.length;
  }

  /// Doktor ortalama puanını hesapla
  static Future<double> getDoctorAverageRating(String doctorId) async {
    final ratings = await getRatingsByDoctor(doctorId);
    final validRatings = ratings.where((r) => r.doctorRating != null).toList();
    if (validRatings.isEmpty) return 0.0;
    
    final total = validRatings.fold<int>(
      0,
      (sum, rating) => sum + (rating.doctorRating ?? 0),
    );
    return total / validRatings.length;
  }

  /// Yeni puanlama oluşturur
  static Future<Rating?> createRating({
    required String userId,
    required String hospitalId,
    String? doctorId,
    required String appointmentId,
    required int hospitalRating,
    int? doctorRating,
  }) async {
    try {
      final response = await SupabaseService.supabase
          .from('ratings')
          .insert({
            'user_id': userId,
            'hospital_id': hospitalId,
            'doctor_id': doctorId,
            'appointment_id': appointmentId,
            'hospital_rating': hospitalRating,
            'doctor_rating': doctorRating,
          })
          .select()
          .single();
      
      return _ratingFromDb(response);
    } catch (e) {
      return null;
    }
  }

  /// Puanlamayı günceller veya oluşturur
  static Future<Rating?> updateOrCreateRating({
    required String userId,
    required String hospitalId,
    String? doctorId,
    required String appointmentId,
    required int hospitalRating,
    int? doctorRating,
  }) async {
    try {
      // Önce mevcut puanlamayı kontrol et
      final existingRating = await getRatingByAppointmentId(appointmentId);
      
      if (existingRating != null) {
        // Mevcut puanlamayı güncelle
        final response = await SupabaseService.supabase
            .from('ratings')
            .update({
              'hospital_rating': hospitalRating,
              'doctor_rating': doctorRating,
            })
            .eq('appointment_id', appointmentId)
            .select()
            .single();
        
        return _ratingFromDb(response);
      } else {
        // Yeni puanlama oluştur
        return await createRating(
          userId: userId,
          hospitalId: hospitalId,
          doctorId: doctorId,
          appointmentId: appointmentId,
          hospitalRating: hospitalRating,
          doctorRating: doctorRating,
        );
      }
    } catch (e) {
      debugPrint('Puanlama güncelleme hatası: $e');
      return null;
    }
  }

  // ==================== İPUÇLARI ====================

  /// İpuçlarını getir (opsiyonel - Supabase'de tips tablosu varsa)
  static Future<List<Tip>> getTips() async {
    try {
      final response = await SupabaseService.supabase
          .from('tips')
          .select()
          .order('created_at', ascending: false);
      
      final List<dynamic> data = response;
      return data.map((json) => _tipFromDb(json)).toList();
    } catch (e) {
      // Eğer tips tablosu yoksa boş liste döndür
      return [];
    }
  }

  /// Supabase formatından Tip modeline çevirir
  static Tip _tipFromDb(Map<String, dynamic> dbData) {
    return Tip(
      id: dbData['id'].toString(),
      title: dbData['title'] ?? '',
      content: dbData['content'] ?? '',
      image: dbData['image'],
      createdAt: dbData['created_at'] ?? '',
    );
  }
}
