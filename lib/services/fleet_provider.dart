import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'auth_service.dart';

/// Masaüstünden Render backend'e senkronize edilen araç çalışma alanını
/// periyodik olarak çeker.
///
/// İçerik:
/// - fixedHome
/// - dropped
/// - repeatByAddress
/// - planByDay
/// - forcedFirstStopByDay
class FleetProvider extends ChangeNotifier {
  static const String _baseUrl = AppConfig.backendBaseUrl;

  int? _vehicleId;
  Map<String, dynamic>? _workspace;
  DateTime? _updatedAt;

  Timer? _syncTimer;
  bool _syncFailed = false;
  bool _isLoading = false;

  FleetProvider() {
    startAutoSync();
  }

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

  Future<void> switchVehicle(int vehicleId) async {
    if (_vehicleId == vehicleId) {
      await load();
      return;
    }

    _vehicleId = vehicleId;
    _workspace = null;
    _updatedAt = null;

    notifyListeners();

    await load();
  }

  Future<void> load() async {
    if (_vehicleId == null || _isLoading) return;

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

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _syncFailed = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      final vehiclesRaw = decoded['vehicles'];

      if (vehiclesRaw is! Map) {
        _workspace = null;
        _syncFailed = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final vehicles = Map<String, dynamic>.from(vehiclesRaw);

      final vehicleRaw = vehicles[_vehicleId.toString()];

      if (vehicleRaw is Map) {
        // Web tarafı workspace alanı oluşturmuyor.
        // Araç verisinin kendisi doğrudan workspace.
        _workspace = Map<String, dynamic>.from(vehicleRaw);
      } else {
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

  void startAutoSync() {
    _syncTimer?.cancel();

    _syncTimer = Timer.periodic(const Duration(seconds: 10), (_) => load());
  }

  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  @override
  void dispose() {
    stopAutoSync();
    super.dispose();
  }
}
