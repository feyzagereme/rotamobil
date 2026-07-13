import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Masaüstünden senkronize edilen filo (araç bazlı çalışma alanı) durumunu
/// 10 saniyede bir çeker: sabit başlangıç adresi, kuyruktan düşürülen
/// adresler, tekrar tipleri.
class FleetProvider extends ChangeNotifier {
  static const String _baseUrl = 'https://route-backend-jeu7.onrender.com';

  int? _vehicleId;
  Map<String, dynamic>? _workspace;
  DateTime? _updatedAt;
  Timer? _syncTimer;
  bool _syncFailed = false;

  FleetProvider() {
    startAutoSync();
  }

 Map<String, dynamic>? get workspace => _workspace;
  DateTime? get updatedAt => _updatedAt;
  bool get syncFailed => _syncFailed;

  Map<String, dynamic>? get fixedHome =>
      _workspace?['fixedHome'] as Map<String, dynamic>?;

  List<String> get dropped =>
      List<String>.from(_workspace?['dropped'] as List? ?? const []);

  Future<void> switchVehicle(int vehicleId) async {
    if (_vehicleId == vehicleId) return;
    _vehicleId = vehicleId;
    _workspace = null;
    _updatedAt = null;
    notifyListeners();
    await load();
  }

  Future<void> load() async {
    if (_vehicleId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) return;

      final response = await http.get(Uri.parse('$_baseUrl/fleet/$userId'));

      if (response.statusCode < 200 || response.statusCode >= 300) return;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final vehicles = decoded['vehicles'] as Map<String, dynamic>? ?? {};
      final entry = vehicles[_vehicleId.toString()] as Map<String, dynamic>?;

      _workspace = entry?['workspace'] as Map<String, dynamic>?;
      final updatedAtRaw = entry?['updatedAt'] as String?;
      _updatedAt = updatedAtRaw != null
          ? DateTime.tryParse(updatedAtRaw)
          : null;
      _syncFailed = false;
      notifyListeners();
    } catch (_) {
      // Rota akışını bozmamak için sayfayı kilitlemiyoruz, ama durumu
      // dışarıya bildiriyoruz ki UI küçük bir uyarı gösterebilsin.
      _syncFailed = true;
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
