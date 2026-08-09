import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../config/app_config.dart';
import 'guest/guest_route_service.dart';

class TomTomRouteResult {
  final List<GuestAddress> orderedAddresses;
  final double totalDistanceKm;
  final int totalDurationMinutes;
  final List<LatLng> geometry;

  TomTomRouteResult({
    required this.orderedAddresses,
    required this.totalDistanceKm,
    required this.totalDurationMinutes,
    required this.geometry,
  });
}

/// TomTom Routing API üzerinden trafik bilgili, gerçek yol ağına dayalı rota
/// hesaplar. Hem misafir modu (yeniden sıralama + özet) hem üye/sürücü akışı
/// (sabit sıra, sadece gerçek yol geometrisi) için kullanılır.
class TomTomRoutingService {
  static const _baseUrl = 'https://api.tomtom.com/routing/1/calculateRoute';

  static bool get isConfigured => AppConfig.tomtomApiKey.isNotEmpty;

  static List<LatLng> _parseGeometry(Map<String, dynamic> route) {
    final legs = route['legs'] as List? ?? const [];
    final points = <LatLng>[];
    for (final leg in legs) {
      final legPoints = (leg as Map<String, dynamic>)['points'] as List? ?? const [];
      for (final p in legPoints) {
        final point = p as Map<String, dynamic>;
        points.add(LatLng(
          (point['latitude'] as num).toDouble(),
          (point['longitude'] as num).toDouble(),
        ));
      }
    }
    return points;
  }

  /// API key tanımlı değilse, tek durak varsa ya da istek herhangi bir
  /// sebeple başarısız olursa null döner — çağıran taraf düz-çizgi
  /// (haversine) hesaba geri dönmeli.
  static Future<TomTomRouteResult?> calculateOptimizedRoute(
    List<GuestAddress> addresses,
    double startLat,
    double startLon,
  ) async {
    if (!isConfigured || addresses.length < 2) return null;

    try {
      final points = [
        '$startLat,$startLon',
        ...addresses.map((a) => '${a.latitude},${a.longitude}'),
      ].join(':');

      final uri = Uri.parse('$_baseUrl/$points/json').replace(queryParameters: {
        'key': AppConfig.tomtomApiKey,
        'traffic': 'true',
        'computeBestOrder': 'true',
        'routeType': 'fastest',
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = json['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final route = routes.first as Map<String, dynamic>;

      final summary = route['summary'] as Map<String, dynamic>;
      final lengthInMeters = (summary['lengthInMeters'] as num).toDouble();
      final travelTimeInSeconds = (summary['travelTimeInSeconds'] as num).toInt();

      // TomTom son noktayı sabit varış olarak kabul edip yeniden sıralamıyor;
      // computeBestOrder sadece başlangıç ile varış arasındaki duraklara
      // uygulanıyor (optimizedWaypoints uzunluğu addresses.length - 1 olur).
      var ordered = addresses;
      final optimized = json['optimizedWaypoints'] as List?;
      if (optimized != null && addresses.length >= 2 &&
          optimized.length == addresses.length - 1) {
        final middle = addresses.sublist(0, addresses.length - 1);
        final destination = addresses.last;
        final reorderedMiddle = List<GuestAddress>.filled(middle.length, middle.first);
        for (final wp in optimized) {
          final entry = wp as Map<String, dynamic>;
          reorderedMiddle[entry['optimizedIndex'] as int] = middle[entry['providedIndex'] as int];
        }
        ordered = [...reorderedMiddle, destination];
      }

      return TomTomRouteResult(
        orderedAddresses: ordered,
        totalDistanceKm: lengthInMeters / 1000,
        totalDurationMinutes: (travelTimeInSeconds / 60).round(),
        geometry: _parseGeometry(route),
      );
    } catch (_) {
      return null;
    }
  }

  /// Sırası zaten belli olan bir nokta dizisi için (yeniden sıralama
  /// yapmadan) gerçek yol geometrisini döner. Üye/sürücü akışında backend'in
  /// belirlediği durak sırasını bozmadan haritada gerçek rota çizmek için
  /// kullanılır. API key tanımlı değilse ya da istek başarısız olursa null
  /// döner — çağıran taraf düz-çizgi çizime geri dönmeli.
  static Future<List<LatLng>?> fetchRouteGeometry(List<LatLng> orderedPoints) async {
    if (!isConfigured || orderedPoints.length < 2) return null;

    try {
      final points = orderedPoints.map((p) => '${p.latitude},${p.longitude}').join(':');
      final uri = Uri.parse('$_baseUrl/$points/json').replace(queryParameters: {
        'key': AppConfig.tomtomApiKey,
        'traffic': 'true',
        'routeType': 'fastest',
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = json['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;

      return _parseGeometry(routes.first as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
