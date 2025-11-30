import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Konum servisi - kullanıcının konumunu almak ve mesafe hesaplamak için
class LocationService {
  static const String _permissionRequestedKey = 'location_permission_requested';
  static const String _locationPermissionDeniedKey = 'location_permission_denied';

  /// Kullanıcının mevcut konumunu alır
  /// İzin yoksa null döner
  static Future<Position?> getCurrentLocation() async {
    try {
      // Konum servislerinin açık olup olmadığını kontrol et
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // İzin durumunu kontrol et
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // İzin daha önce istenmemişse iste
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // İzin reddedildi
          await _savePermissionDenied(true);
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // İzin kalıcı olarak reddedilmiş
        await _savePermissionDenied(true);
        return null;
      }

      // İzin verildi, konumu al
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // İzin verildi, reddedilmedi olarak işaretle
      await _savePermissionDenied(false);
      
      return position;
    } catch (e) {
      return null;
    }
  }

  /// İzin durumunu kontrol eder
  static Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Konum servislerinin açık olup olmadığını kontrol eder
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// İzin iste
  static Future<LocationPermission> requestPermission() async {
    await _savePermissionRequested(true);
    return await Geolocator.requestPermission();
  }

  /// İki nokta arasındaki mesafeyi kilometre cinsinden hesaplar
  /// Haversine formülü kullanılır
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // km
  }

  /// İzin daha önce istenmiş mi?
  static Future<bool> hasRequestedPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionRequestedKey) ?? false;
  }

  /// İzin kalıcı olarak reddedilmiş mi?
  static Future<bool> isPermissionDeniedForever() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.deniedForever;
  }

  /// İzin reddedilmiş mi? (SharedPreferences'dan)
  static Future<bool> wasPermissionDenied() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_locationPermissionDeniedKey) ?? false;
  }

  /// İzin istenme durumunu kaydet
  static Future<void> _savePermissionRequested(bool requested) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionRequestedKey, requested);
  }

  /// İzin reddedilme durumunu kaydet
  static Future<void> _savePermissionDenied(bool denied) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationPermissionDeniedKey, denied);
  }

  /// Ayarlara yönlendir (Android için)
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Uygulama ayarlarına yönlendir (iOS için)
  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}


