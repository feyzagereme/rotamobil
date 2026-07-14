import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Firebase Cloud Messaging (push bildirim) kurulumunu yönetir.
/// - Bildirim izni ister
/// - Cihaz token'ını alır, cihazda saklar
/// - Giriş yapmış kullanıcı varsa token'ı backend'e gönderir
/// - Token yenilenirse (nadiren olur) otomatik günceller
class NotificationService {
  static Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    if (token != null) {
      await _saveAndSendToken(token);
    }

    messaging.onTokenRefresh.listen(_saveAndSendToken);
  }

  static Future<void> _saveAndSendToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);

    final userId = prefs.getInt('user_id');
    if (userId == null) return; // henüz giriş yapılmamış, login sonrası gönderilecek

    await sendTokenToBackend(userId, token);
  }

  /// Login başarılı olduktan hemen sonra da çağrılır (kullanıcı ID'si o an
  /// belli olduğu için token'ı hemen backend'e eşleştirebiliriz).
  static Future<void> sendTokenToBackend(int userId, String token) async {
    try {
      await http.post(
        Uri.parse('${AuthService.baseUrl}/users/$userId/fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fcm_token': token}),
      );
    } catch (_) {
      // Sessizce geç — bildirim token'ı gönderilemese de uygulama akışı
      // bozulmamalı, bir sonraki denemede (token refresh ya da login) tekrar
      // gönderilecek.
    }
  }

  /// Giriş sonrası çağrılır: cihazda zaten alınmış bir token varsa hemen
  /// backend'e gönderir (initialize() sırasında henüz giriş yapılmamış
  /// olabileceği için orada gönderilememiş olabilir).
  static Future<void> syncTokenAfterLogin(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('fcm_token');
    if (token != null) {
      await sendTokenToBackend(userId, token);
    }
  }
}