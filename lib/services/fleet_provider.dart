import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'auth_service.dart';

/// Masaüstünden Render backend'e senkronize edilen araç çalışma alanını
/// çeker. Periyodik senkron [SyncScheduler] tarafından yürütülür
/// (bkz. main.dart / MainApp); bu provider yalnızca [load] sunar.
///
/// İçerik:
/// - fixedHome
/// - dropped
/// - repeatByAddress
/// - planByDay
/// - forcedFirstStopByDay
class FleetProvider extends ChangeNotifier {
  static const String _baseUrl = AppConfig.backendBaseUrl;

  Map<String, dynamic>? _workspace;
  DateTime? _updatedAt;

  bool _syncFailed = false;
  bool _isLoading = false;

  Map<String, dynamic>? get workspace => _workspace;
  DateTime? get updatedAt => _updatedAt;
  bool get syncFailed => _syncFailed;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? get fixedHome {
    final value = _workspace?['fixedHome'];

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  List<dynamic> get dropped {
    return List<dynamic>.from(_workspace?['dropped'] as List? ?? const []);
  }

  Map<String, dynamic> get repeatByAddress {
    final value = _workspace?['repeatByAddress'];

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  Map<String, dynamic> get planByDay {
    final value = _workspace?['planByDay'];

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  Map<String, dynamic> get forcedFirstStopByDay {
    final value = _workspace?['forcedFirstStopByDay'];

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  Future<void> load() async {
    if (_isLoading) return;

    _isLoading = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        _isLoading = false;
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/fleet/$userId'),
        headers: await AuthService.authHeaders(),
      );

      // 404: admin web'den henüz hiç çalışma alanı kaydetmemiş — bu
      // gerçek bir senkronizasyon hatası değil, normal bir "veri yok"
      // durumu (bkz. server.js GET /fleet/:user_id). route_provider.dart
      // 404'ü aynı şekilde ayrı ele alıyor; burada da _syncFailed hiç
      // set edilmemeli, aksi halde sürücü ilk kurulumda kalıcı bir
      // "bağlantı yok" ikonu görür ve zamanla gerçek hataları da görmezden
      // gelmeye başlar.
      if (response.statusCode == 404) {
        _workspace = null;
        _syncFailed = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _syncFailed = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      final workspaceRaw = decoded['workspace'];

      if (workspaceRaw is Map) {
        _workspace = Map<String, dynamic>.from(workspaceRaw);
      } else {
        // "workspace" alanı yoksa/null ise henüz veri girilmemiş demektir,
        // hata değil.
        _workspace = null;
      }

      // Backend updatedAt bilgisini cevabın üst seviyesinde döndürüyor.
      final updatedAtRaw = decoded['updatedAt']?.toString();

      _updatedAt = updatedAtRaw != null
          ? DateTime.tryParse(updatedAtRaw)
          : null;

      _syncFailed = false;
      _isLoading = false;

      notifyListeners();
    } catch (e) {
      debugPrint('Fleet senkronizasyon hatası: $e');

      _syncFailed = true;
      _isLoading = false;

      notifyListeners();
    }
  }

}
