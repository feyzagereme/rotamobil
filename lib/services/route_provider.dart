import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/address_model.dart';

class RouteProvider extends ChangeNotifier {
  static const String _baseUrl = 'https://route-backend-wkiy.onrender.com';

  List<Address> _addresses = [];
  String? _activeRouteId;
  String? _activeRouteName;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _syncTimer;

  RouteProvider() {
    loadActiveRoute();
    startAutoSync();
  }

  List<Address> get addresses => _addresses;
  String? get activeRouteId => _activeRouteId;
  String? get activeRouteName => _activeRouteName;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalStops => _addresses.length;
  int get completedStops => _addresses.where((a) => a.isCompleted).length;
  double get completionPercentage =>
      _addresses.isEmpty ? 0 : (completedStops / totalStops) * 100;

  Future<void> loadActiveRoute() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        _addresses = [];
        _activeRouteId = null;
        _activeRouteName = null;
        _errorMessage =
            'Kullanıcı bilgisi bulunamadı. Lütfen tekrar giriş yapın.';
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/routes/$userId/active'),
      );

      if (response.statusCode == 404) {
        _addresses = [];
        _activeRouteId = null;
        _activeRouteName = null;
        _errorMessage = 'Aktif rota bulunamadı.';
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _errorMessage = 'Aktif rota alınamadı: ${response.statusCode}';
        return;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final routeJson = _asMap(decoded['route_json']);
      final stopsRaw = routeJson['stops'] ?? routeJson['addresses'] ?? [];
      final stops = stopsRaw is List ? stopsRaw : [];

      _activeRouteId = decoded['id']?.toString();
      _activeRouteName = decoded['name']?.toString();
      _addresses =
          stops
              .whereType<Map>()
              .map((item) => item.cast<String, dynamic>())
              .toList()
              .asMap()
              .entries
              .map(
                (entry) => Address.fromRouteStop(
                  entry.value,
                  fallbackOrder: entry.key + 1,
                ),
              )
              .where(
                (address) => address.latitude != 0 && address.longitude != 0,
              )
              .toList()
            ..sort((a, b) => a.orderNumber.compareTo(b.orderNumber));

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Rota yüklenirken hata oluştu: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      loadActiveRoute();
    });
  }

  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> refresh() => loadActiveRoute();

  // Sıra değiştir: şimdilik sadece local sıralama yapar.
  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final item = _addresses.removeAt(oldIndex);
    _addresses.insert(newIndex, item);
    notifyListeners();
  }

  // Haritadan yeni adres ekle: şimdilik sadece local ekleme yapar.
  void addAddress(Address address) {
    _addresses.add(address);
    notifyListeners();
  }

  // Adresi sil: şimdilik sadece local silme yapar.
  void removeAddress(int index) {
    _addresses.removeAt(index);
    notifyListeners();
  }

  // Tamamlandı işaretle ve backend'e gönder.
  Future<void> toggleCompleted(int index) async {
    if (index < 0 || index >= _addresses.length) return;

    final current = _addresses[index];
    final updated = current.copyWith(isCompleted: !current.isCompleted);
    _addresses[index] = updated;
    notifyListeners();

    if (_activeRouteId == null) return;

    try {
      final response = await http.patch(
        Uri.parse(
          '$_baseUrl/routes/$_activeRouteId/stops/${updated.id}/complete',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'completed': updated.isCompleted}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _addresses[index] = current;
        _errorMessage =
            'Tamamlandı bilgisi kaydedilemedi: ${response.statusCode}';
        notifyListeners();
      }
    } catch (e) {
      _addresses[index] = current;
      _errorMessage = 'Tamamlandı bilgisi gönderilemedi: $e';
      notifyListeners();
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  @override
  void dispose() {
    stopAutoSync();
    super.dispose();
  }
}
