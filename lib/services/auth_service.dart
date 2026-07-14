import 'dart:convert';
import 'package:http/http.dart' as http;
import 'notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'https://route-backend-jeu7.onrender.com';
  static const String _keyLoggedIn = 'is_logged_in';
  static const String _keyUsername = 'username';

  /// Giriş yapar. Hata varsa hata mesajı döner, başarılıysa null döner.
  static Future<String?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final role = body["role"] as String?;
        if (role != null && role != "driver") {
          return 'Bu hesap sürücü hesabı değil, mobil uygulamaya giriş yapamaz.';
        }

        final prefs = await SharedPreferences.getInstance();

        final userId = body["user_id"];
        if (userId != null) {
          await prefs.setInt(
            "user_id",
            userId is int ? userId : int.parse(userId.toString()),
          );
        }

        final vehicleId = body["vehicle_id"];
        if (vehicleId != null) {
          await prefs.setInt(
            "assigned_vehicle_id",
            vehicleId is int ? vehicleId : int.parse(vehicleId.toString()),
          );
        } else {
          await prefs.remove("assigned_vehicle_id");
        }

        await prefs.setBool(_keyLoggedIn, true);
        await prefs.setString(_keyUsername, username);

        if (userId != null) {
          final resolvedUserId = userId is int ? userId : int.parse(userId.toString());
          await NotificationService.syncTokenAfterLogin(resolvedUserId);
        }

        return null;
      } else {
        return body['error'] ?? 'Kullanıcı adı veya şifre hatalı';
      }
    } catch (e) {
      return 'Sunucuya bağlanılamadı. İnternet bağlantınızı kontrol edin.';
    }
  }

  /// Oturumu kapatır.
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyUsername);
    await prefs.remove("user_id");
  }

  /// Uygulama açılışında oturum açık mı kontrol eder.
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  /// Giriş yapan kullanıcı adını döner.
  static Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername) ?? '';
  }
}