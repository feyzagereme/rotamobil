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
  static const _enabledKey = 'notifications_enabled';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  /// Profil ekranındaki "Bildirimler" anahtarından çağrılır. Kapatılınca
  /// backend'deki fcm_token null'lanır (push artık gönderilmez); tekrar
  /// açılınca cihazda zaten alınmış token varsa hemen yeniden gönderilir.
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    final userId = prefs.getInt('user_id');
    if (userId == null) return;
    if (enabled) {
      final token = prefs.getString('fcm_token');
      if (token != null) await sendTokenToBackend(userId, token);
    } else {
      await sendTokenToBackend(userId, null);
    }
  }

  static Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken(
      vapidKey: 'BGrZiA9A4_BV1kktLmlF8OPb5HHZ5MFq0eJRghQmwvFQzYkBoKMxIOmAPe3j7x89tS-YPZ75rq7vjJE47NYuhMw',
    );
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
    if (!(await isEnabled())) return; // kullanıcı bildirimleri kapatmış

    await sendTokenToBackend(userId, token);
  }

  /// Login başarılı olduktan hemen sonra da çağrılır (kullanıcı ID'si o an
  /// belli olduğu için token'ı hemen backend'e eşleştirebiliriz). token
  /// null verilirse backend'deki kayıtlı token temizlenir (bildirimleri
  /// kapatma akışında kullanılır).
  static Future<void> sendTokenToBackend(int userId, String? token) async {
    try {
      await http.post(
        Uri.parse('${AuthService.baseUrl}/users/$userId/fcm-token'),
        headers: await AuthService.authHeaders(),
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
    if (!(await isEnabled())) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('fcm_token');
    if (token != null) {
      await sendTokenToBackend(userId, token);
    }
  }
}