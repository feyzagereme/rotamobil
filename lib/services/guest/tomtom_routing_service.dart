import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import 'guest_route_service.dart';

class TomTomRouteResult {
  final List<GuestAddress> orderedAddresses;
  final double totalDistanceKm;
  final int totalDurationMinutes;

  TomTomRouteResult({
    required this.orderedAddresses,
    required this.totalDistanceKm,
    required this.totalDurationMinutes,
  });
}

/// TomTom Routing API üzerinden trafik bilgili, gerçek yol ağına dayalı rota
/// hesaplar (misafir modu için — backend'e hiç dokunmaz).
class TomTomRoutingService {
  static const _baseUrl = 'https://api.tomtom.com/routing/1/calculateRoute';

  static bool get isConfigured => AppConfig.tomtomApiKey.isNotEmpty;

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

      final summary = (routes.first as Map<String, dynamic>)['summary'] as Map<String, dynamic>;
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
      );
    } catch (_) {
      return null;
    }
  }
}
