import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const _baseUrl = 'https://route-backend-jeu7.onrender.com';
  static Timer? _timer;
  static bool _isRunning = false;
  static bool _lastSendFailed = false;

  // Konum izni kontrolü
  static Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  // Mevcut konumu al
  static Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  // Konumu backend'e gönder
  static Future<void> sendLocation(double lat, double lon) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) return;

      await http.post(
        Uri.parse('$_baseUrl/drivers/$userId/location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': lat,
          'longitude': lon,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      _lastSendFailed = false;
    } catch (_) {
      _lastSendFailed = true;
    }
  }

  // 3 dakikada bir konum güncelle
  static void startTracking() {
    if (_isRunning) return;
    _isRunning = true;

    // Hemen bir kere gönder
    _updateLocation();

    // Sonra 3 dakikada bir
    _timer = Timer.periodic(const Duration(minutes: 3), (_) {
      _updateLocation();
    });
  }

  static Future<void> _updateLocation() async {
    final position = await getCurrentPosition();
    if (position != null) {
      await sendLocation(position.latitude, position.longitude);
    }
  }

  static void stopTracking() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  static bool get isRunning => _isRunning;
  static bool get lastSendFailed => _lastSendFailed;
}