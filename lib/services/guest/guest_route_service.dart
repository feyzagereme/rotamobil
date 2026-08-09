import 'dart:convert';
import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuestAddress {
  final int id;
  final String name;
  final String fullAddress;
  final double latitude;
  final double longitude;
  bool isCompleted;

  GuestAddress({
    required this.id,
    required this.name,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'fullAddress': fullAddress,
    'latitude': latitude, 'longitude': longitude,
    'isCompleted': isCompleted,
  };

  factory GuestAddress.fromJson(Map<String, dynamic> json) => GuestAddress(
    id: json['id'], name: json['name'], fullAddress: json['fullAddress'],
    latitude: json['latitude'], longitude: json['longitude'],
    isCompleted: json['isCompleted'] ?? false,
  );
}

class SavedRoute {
  final String id;
  final String name;
  final DateTime date;
  final List<GuestAddress> addresses;
  final double totalKm;
  // Kaydedilirken TomTom'dan gerçek yol geometrisi alınabildiyse burada
  // saklanır; null ise detay ekranı duraklar arasına düz çizgi çizer.
  final List<LatLng>? geometry;

  SavedRoute({
    required this.id,
    required this.name,
    required this.date,
    required this.addresses,
    required this.totalKm,
    this.geometry,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name,
    'date': date.toIso8601String(),
    'addresses': addresses.map((a) => a.toJson()).toList(),
    'totalKm': totalKm,
    if (geometry != null) 'geometry': geometry!.map((p) => [p.latitude, p.longitude]).toList(),
  };

  factory SavedRoute.fromJson(Map<String, dynamic> json) => SavedRoute(
    id: json['id'], name: json['name'],
    date: DateTime.parse(json['date']),
    addresses: (json['addresses'] as List)
        .map((a) => GuestAddress.fromJson(a)).toList(),
    totalKm: json['totalKm']?.toDouble() ?? 0,
    geometry: (json['geometry'] as List?)
        ?.map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList(),
  );
}

class GuestRouteService {
  static const _addressesKey = 'guest_addresses';
  static const _savedRoutesKey = 'guest_saved_routes';
  static const _favoritesKey = 'guest_favorites';
  static const _lastRouteStatsKey = 'guest_last_route_stats';

  // Haversine mesafe hesabı
  static double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
        sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  // En kısa rota (nearest neighbor greedy)
  static List<GuestAddress> calculateShortestRoute(
      List<GuestAddress> addresses, double startLat, double startLon) {
    if (addresses.isEmpty) return [];
    final remaining = List<GuestAddress>.from(addresses);
    final result = <GuestAddress>[];
    double curLat = startLat, curLon = startLon;

    while (remaining.isNotEmpty) {
      double minDist = double.infinity;
      GuestAddress? nearest;
      for (final a in remaining) {
        final d = distanceKm(curLat, curLon, a.latitude, a.longitude);
        if (d < minDist) { minDist = d; nearest = a; }
      }
      if (nearest != null) {
        result.add(nearest);
        curLat = nearest.latitude;
        curLon = nearest.longitude;
        remaining.remove(nearest);
      }
    }
    return result;
  }

  static double totalDistance(List<GuestAddress> addresses,
      double startLat, double startLon) {
    if (addresses.isEmpty) return 0;
    double total = distanceKm(startLat, startLon,
        addresses.first.latitude, addresses.first.longitude);
    for (int i = 0; i < addresses.length - 1; i++) {
      total += distanceKm(addresses[i].latitude, addresses[i].longitude,
          addresses[i + 1].latitude, addresses[i + 1].longitude);
    }
    return total;
  }

  // Adres yükle/kaydet
  static Future<List<GuestAddress>> loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_addressesKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => GuestAddress.fromJson(e)).toList();
  }

  static Future<void> saveAddresses(List<GuestAddress> addresses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_addressesKey, jsonEncode(addresses.map((a) => a.toJson()).toList()));
  }

  static Future<void> clearAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_addressesKey);
  }

  // Son hesaplanan gerçek rota mesafesi/süresi (TomTom veya haversine).
  // Hangi adres listesine ait olduğu bir "imza" ile saklanır; adres
  // listesi değişirse (ekleme/silme/sıra) imza uyuşmaz ve çağıran taraf
  // otomatik olarak canlı tahmine geri döner.
  static String _signature(List<GuestAddress> addresses) =>
      addresses.map((a) => a.id).join(',');

  static Future<void> saveRouteStats({
    required double totalKm,
    required int totalMinutes,
    required List<GuestAddress> addresses,
    List<LatLng>? geometry,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastRouteStatsKey, jsonEncode({
      'totalKm': totalKm,
      'totalMinutes': totalMinutes,
      'signature': _signature(addresses),
      if (geometry != null) 'geometry': geometry.map((p) => [p.latitude, p.longitude]).toList(),
    }));
  }

  static Future<({double totalKm, int totalMinutes, List<LatLng>? geometry})?> loadRouteStatsIfValid(
      List<GuestAddress> addresses) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastRouteStatsKey);
    if (raw == null) return null;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['signature'] != _signature(addresses)) return null;
    final geometryRaw = data['geometry'] as List?;
    return (
      totalKm: (data['totalKm'] as num).toDouble(),
      totalMinutes: data['totalMinutes'] as int,
      geometry: geometryRaw
          ?.map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()))
          .toList(),
    );
  }

  // Geçmiş rotalar
  static Future<List<SavedRoute>> loadSavedRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedRoutesKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => SavedRoute.fromJson(e)).toList();
  }

  static Future<void> saveRoute(SavedRoute route) async {
    final routes = await loadSavedRoutes();
    routes.insert(0, route);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedRoutesKey,
        jsonEncode(routes.map((r) => r.toJson()).toList()));
  }

  // Favoriler
  static Future<List<GuestAddress>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_favoritesKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => GuestAddress.fromJson(e)).toList();
  }

  static Future<void> saveFavorite(GuestAddress address) async {
    final favs = await loadFavorites();
    if (favs.any((f) => f.id == address.id)) return;
    favs.add(address);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favoritesKey,
        jsonEncode(favs.map((f) => f.toJson()).toList()));
  }

  static Future<void> removeFavorite(int id) async {
    final favs = await loadFavorites();
    favs.removeWhere((f) => f.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favoritesKey,
        jsonEncode(favs.map((f) => f.toJson()).toList()));
  }
}