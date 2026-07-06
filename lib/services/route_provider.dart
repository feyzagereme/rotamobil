import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/address_model.dart';

class RouteProvider extends ChangeNotifier {
  static const String _baseUrl = 'https://route-backend-jeu7.onrender.com';

  List<Address> _addresses = [];
  String? _activeRouteId;
  String? _activeRouteName;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _syncTimer;

  bool _isOptimizing = false;
  String? _optimizeError;

  RouteProvider() {
    loadActiveRoute();
    startAutoSync();
  }

  List<Address> get addresses => _addresses;
  String? get activeRouteId => _activeRouteId;
  String? get activeRouteName => _activeRouteName;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isOptimizing => _isOptimizing;
  String? get optimizeError => _optimizeError;

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
        _errorMessage = null;
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
      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool('is_guest') ?? true;
      if (isGuest) {
        _addresses = [];
        _errorMessage = null;
      } else {
        _errorMessage = 'Rota yüklenirken hata oluştu: $e';
      }
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

  // ── Rota Optimizasyonu ────────────────────────────────────────────
  // Kullanıcının o anki GPS konumundan başlayıp, tüm tamamlanmamış
  // durakları en kısa toplam mesafeyle gezecek sırayı backend'den alır
  // ve _addresses listesini bu sıraya göre yeniden düzenler.
  Future<bool> optimizeRoute() async {
    if (_addresses.isEmpty) return false;

    _isOptimizing = true;
    _optimizeError = null;
    notifyListeners();

    try {
      // 1. Kullanıcının o anki konumunu al
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _optimizeError = 'Konum servisleri kapalı. Lütfen GPS\'i açın.';
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _optimizeError = 'Konum izni reddedildi.';
          return false;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _optimizeError =
            'Konum izni kalıcı olarak reddedildi. Ayarlardan izin verin.';
        return false;
      }

      final position = await Geolocator.getCurrentPosition();

      // 2. Sadece henüz tamamlanmamış durakları optimize et
      final pendingAddresses =
          _addresses.where((a) => !a.isCompleted).toList();
      final completedAddresses =
          _addresses.where((a) => a.isCompleted).toList();

      if (pendingAddresses.isEmpty) {
        _optimizeError = 'Optimize edilecek tamamlanmamış durak yok.';
        return false;
      }

      // 3. Backend'e istek at
      final response = await http.post(
        Uri.parse('$_baseUrl/routes/optimize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'origin': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
          'stops': pendingAddresses
              .map((a) => {
                    'id': a.id,
                    'latitude': a.latitude,
                    'longitude': a.longitude,
                  })
              .toList(),
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _optimizeError = 'Rota optimize edilemedi: ${response.statusCode}';
        return false;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final optimizedOrder = List<int>.from(decoded['optimizedOrder']);

      // 4. _addresses listesini yeni sıraya göre düzenle
      //    (tamamlanmış duraklar en başta sabit kalır, tamamlanmamışlar
      //     optimize edilmiş sırayla arkasından eklenir)
      final reordered = optimizedOrder.map((i) => pendingAddresses[i]).toList();
      _addresses = [...completedAddresses, ...reordered];

      // orderNumber alanlarını da güncelle (görsel sıralama için)
      for (int i = 0; i < _addresses.length; i++) {
        _addresses[i] = _addresses[i].copyWith(orderNumber: i + 1);
      }

      _optimizeError = null;
      return true;
    } catch (e) {
      _optimizeError = 'Rota optimizasyonu sırasında hata oluştu: $e';
      return false;
    } finally {
      _isOptimizing = false;
      notifyListeners();
    }
  }

  void _loadMockData() {
    _activeRouteId = 'mock-1';
    _activeRouteName = 'Test Rotası';
    _addresses = [
      Address(
        id: 1, orderNumber: 1,
        street: 'Atatürk Caddesi No:12', district: 'Altındağ', city: 'Tekirdağ',
        postalCode: '59100', country: 'Türkiye',
        latitude: 40.9833, longitude: 27.5167,
        customerName: 'Ahmet Yılmaz', customerType: 'visit',
      ),
      Address(
        id: 2, orderNumber: 2,
        street: 'Cumhuriyet Sokak No:5', district: 'Süleymanpaşa', city: 'Tekirdağ',
        postalCode: '59100', country: 'Türkiye',
        latitude: 40.9800, longitude: 27.5100,
        customerName: 'Fatma Kaya', customerType: 'visit',
      ),
      Address(
        id: 3, orderNumber: 3,
        street: 'İnönü Bulvarı No:33', district: 'Ergene', city: 'Tekirdağ',
        postalCode: '59100', country: 'Türkiye',
        latitude: 40.9750, longitude: 27.5200,
        customerName: 'Mehmet Demir', customerType: 'visit',
      ),
      Address(
        id: 4, orderNumber: 4,
        street: 'Barbaros Mahallesi No:8', district: 'Çorlu', city: 'Tekirdağ',
        postalCode: '59860', country: 'Türkiye',
        latitude: 41.1500, longitude: 27.8000,
        customerName: 'Ayşe Çelik', customerType: 'visit',
      ),
    ];
    _errorMessage = null;
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