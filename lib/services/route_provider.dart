import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/address_model.dart';
import '../config/app_config.dart';

class RouteProvider extends ChangeNotifier {
  static const String _baseUrl = AppConfig.backendBaseUrl;
  static const String _cacheKeyRoute = 'cached_route_json';
  static const String _cacheKeyVehicleId = 'cached_route_vehicle_id';

  List<Address> _addresses = [];
  String? _activeRouteId;
  String? _activeRouteName;
  String _routeStatus = 'active';
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _syncTimer;
  int? _vehicleId;

  // Ağ bağlantısı olmadığında, cihazda daha önce kaydedilmiş son rota
  // gösteriliyorsa true olur. Kullanıcıya "çevrimdışı, eski veri" bilgisi
  // vermek için kullanılır.
  bool _isOffline = false;
  DateTime? _cachedAt;

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
  int? get vehicleId => _vehicleId;
  bool get isOffline => _isOffline;
  DateTime? get cachedAt => _cachedAt;

  Future<void> switchVehicle(int vehicleId) async {
    if (_vehicleId == vehicleId) return;
    _vehicleId = vehicleId;
    _addresses = [];
    _activeRouteId = null;
    _activeRouteName = null;
    notifyListeners();
    await loadActiveRoute();
  }

  bool get isOptimizing => _isOptimizing;
  String? get optimizeError => _optimizeError;

  int get totalStops => _addresses.length;
  int get completedStops => _addresses.where((a) => a.isCompleted).length;
  double get completionPercentage =>
      _addresses.isEmpty ? 0 : (completedStops / totalStops) * 100;
  bool get isRouteCompleted => _routeStatus == 'completed';
  bool get allStopsCompleted =>
      _addresses.isNotEmpty && completedStops == totalStops;

  void _applyRouteData(Map<String, dynamic> decoded) {
    final routeJson = _asMap(decoded['route_json']);
    final stopsRaw = routeJson['stops'] ?? routeJson['addresses'] ?? [];
    final stops = stopsRaw is List ? stopsRaw : [];

    _activeRouteId = decoded['id']?.toString();
    _activeRouteName = decoded['name']?.toString();
    _routeStatus = decoded['status']?.toString() ?? 'active';
    var parsedAddresses =
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

    // Rota, "ev -> duraklar -> ev" şeklinde kapalı bir döngü olarak
    // oluşturuluyor (bkz. backend /routes/optimize). İlk durak
    // (başlangıç/hastane) otomatik tamamlanmış sayılır — sürücü zaten
    // orada. Son durak (hastaneye dönüş) diğer duraklar gibi elle
    // tamamlanır, sadece görünümü farklıdır. İkisi de sayaca dahildir.
    if (parsedAddresses.length > 2) {
      final first = parsedAddresses.first;
      final last = parsedAddresses.last;
      const epsilon = 0.0001; // ~11 metre tolerans
      final isClosedLoop =
          (first.latitude - last.latitude).abs() < epsilon &&
          (first.longitude - last.longitude).abs() < epsilon;
      if (isClosedLoop) {
        final middle = parsedAddresses.sublist(1, parsedAddresses.length - 1);
        parsedAddresses = [
          first.copyWith(isStartPoint: true, isCompleted: true),
          ...middle,
          last.copyWith(isReturnToBase: true),
        ];
      }
    }

    _addresses = parsedAddresses;
  }

  Future<void> loadActiveRoute() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      _addresses = [];
      _activeRouteId = null;
      _activeRouteName = null;
      _errorMessage =
          'Kullanıcı bilgisi bulunamadı. Lütfen tekrar giriş yapın.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final Uri uri = _vehicleId != null
          ? Uri.parse('$_baseUrl/vehicles/$_vehicleId/active-route')
          : Uri.parse('$_baseUrl/routes/$userId/active');
     final response = await http
          .get(uri, headers: await AuthService.authHeaders())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 404) {
        _addresses = [];
        _activeRouteId = null;
        _activeRouteName = null;
        _errorMessage = null;
        _isOffline = false;
        await prefs.remove(_cacheKeyRoute);
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Sunucu hatası: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      _applyRouteData(decoded);
      _isOffline = false;
      _cachedAt = DateTime.now();
      _errorMessage = null;

      // Başarılı veriyi cihaza kaydet — internet kesilirse ya da uygulama
      // kapatılıp açılırsa bu son bilinen rota gösterilebilsin diye.
      await prefs.setString(_cacheKeyRoute, jsonEncode(decoded));
      await prefs.setString(
        '${_cacheKeyRoute}_time',
        _cachedAt!.toIso8601String(),
      );
      if (_vehicleId != null) {
        await prefs.setInt(_cacheKeyVehicleId, _vehicleId!);
      } else {
        await prefs.remove(_cacheKeyVehicleId);
      }
    } catch (e) {
      // Ağ hatası: cihazda daha önce kaydedilmiş bir rota varsa onu göster,
      // kullanıcı tamamen boş bir ekranla karşılaşmasın.
      final cachedJson = prefs.getString(_cacheKeyRoute);
      final cachedVehicleId = prefs.getInt(_cacheKeyVehicleId);
      final sameVehicle = _vehicleId == null
          ? cachedVehicleId == null
          : cachedVehicleId == _vehicleId;

      if (cachedJson != null && sameVehicle) {
        try {
          final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
          _applyRouteData(decoded);
          _isOffline = true;
          final cachedTimeRaw = prefs.getString('${_cacheKeyRoute}_time');
          _cachedAt = cachedTimeRaw != null
              ? DateTime.tryParse(cachedTimeRaw)
              : null;
          _errorMessage = null;
        } catch (_) {
          _errorMessage = 'Rota yüklenirken hata oluştu: $e';
        }
      } else {
        final isGuest = prefs.getBool('is_guest') ?? true;
        if (isGuest) {
          _addresses = [];
          _errorMessage = null;
        } else {
          _errorMessage = 'Rota yüklenirken hata oluştu: $e';
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      loadActiveRoute();
    });
  }

  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> refresh() => loadActiveRoute();

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final previous = List<Address>.from(_addresses);
    final item = _addresses.removeAt(oldIndex);
    _addresses.insert(newIndex, item);
    notifyListeners();

    if (_activeRouteId == null) return;

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/routes/$_activeRouteId/stops'),
        headers: await AuthService.authHeaders(),
        body: jsonEncode({
          'stops': _addresses
              .asMap()
              .entries
              .map((e) => {'id': e.value.id, 'order': e.key + 1})
              .toList(),
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _addresses = previous;
        _errorMessage = 'Durak sırası kaydedilemedi: ${response.statusCode}';
        notifyListeners();
      }
    } catch (e) {
      _addresses = previous;
      _errorMessage = 'Durak sırası gönderilemedi: $e';
      notifyListeners();
    }
  }

  Future<void> addAddress(Address address) async {
    _addresses.add(address);
    notifyListeners();

    if (_activeRouteId == null) return;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/routes/$_activeRouteId/stops'),
        headers: await AuthService.authHeaders(),
        body: jsonEncode({
          'stop': {
            'street': address.street,
            'district': address.district,
            'city': address.city,
            'postalCode': address.postalCode,
            'latitude': address.latitude,
            'longitude': address.longitude,
            'customerName': address.customerName,
            'customerType': address.customerType,
          },
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final savedStop = decoded['stop'] as Map<String, dynamic>?;
        if (savedStop != null) {
          final index = _addresses.indexOf(address);
          if (index != -1) {
            _addresses[index] = Address.fromRouteStop(
              savedStop,
              fallbackOrder: address.orderNumber,
            );
            notifyListeners();
          }
        }
      } else {
        _addresses.remove(address);
        _errorMessage = 'Durak kaydedilemedi: ${response.statusCode}';
        notifyListeners();
      }
    } catch (e) {
      _addresses.remove(address);
      _errorMessage = 'Durak gönderilemedi: $e';
      notifyListeners();
    }
  }

  void removeAddress(int index) {
    _addresses.removeAt(index);
    notifyListeners();
  }

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
        headers: await AuthService.authHeaders(),
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

  Future<void> updateNote(int index, String note) async {
    if (index < 0 || index >= _addresses.length) return;

    final current = _addresses[index];
    final updated = current.copyWith(notes: note);
    _addresses[index] = updated;
    notifyListeners();

    if (_activeRouteId == null) return;

    try {
      final response = await http.patch(
        Uri.parse(
          '$_baseUrl/routes/$_activeRouteId/stops/${updated.id}/note',
        ),
        headers: await AuthService.authHeaders(),
        body: jsonEncode({'note': note}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _addresses[index] = current;
        _errorMessage = 'Not kaydedilemedi: ${response.statusCode}';
        notifyListeners();
      }
    } catch (e) {
      _addresses[index] = current;
      _errorMessage = 'Not gönderilemedi: $e';
      notifyListeners();
    }
  }

  /// Sürücü, günün rotasını (tüm gerçek durakları tamamlayıp hastaneye
  /// dönünce) bitirdiğinde çağrılır. Durak tamamlamadan ayrı bir kavram —
  /// rotanın kendisini "completed" yapar.
  Future<bool> completeRoute() async {
    if (_activeRouteId == null) return false;

    final previousStatus = _routeStatus;
    _routeStatus = 'completed';
    notifyListeners();

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/routes/$_activeRouteId/complete'),
        headers: await AuthService.authHeaders(),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _routeStatus = previousStatus;
        _errorMessage = 'Rota tamamlanamadı: ${response.statusCode}';
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      _routeStatus = previousStatus;
      _errorMessage = 'Rota tamamlanamadı: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> optimizeRoute() async {
    if (_addresses.isEmpty) return false;

    _isOptimizing = true;
    _optimizeError = null;
    notifyListeners();

    try {
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

      final pendingAddresses =
          _addresses.where((a) => !a.isCompleted).toList();
      final completedAddresses =
          _addresses.where((a) => a.isCompleted).toList();

      if (pendingAddresses.isEmpty) {
        _optimizeError = 'Optimize edilecek tamamlanmamış durak yok.';
        return false;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/routes/optimize'),
        headers: await AuthService.authHeaders(),
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

      final reordered = optimizedOrder.map((i) => pendingAddresses[i]).toList();
      _addresses = [...completedAddresses, ...reordered];

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