import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/guest/guest_route_service.dart';

/// Geçmişte kaydedilmiş bir rotanın salt-okunur özeti: mini harita + durak
/// listesi. Buradan rotayı düzenlemek/aktif etmek mümkün değil, sadece
/// görüntüleme amaçlı.
class GuestSavedRouteDetailScreen extends StatelessWidget {
  final SavedRoute route;
  const GuestSavedRouteDetailScreen({super.key, required this.route});

  String _formatDate(DateTime date) {
    const months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  LatLng get _center {
    if (route.addresses.isEmpty) return const LatLng(40.98, 27.52);
    final lats = route.addresses.map((a) => a.latitude);
    final lngs = route.addresses.map((a) => a.longitude);
    return LatLng(
      lats.reduce((a, b) => a + b) / lats.length,
      lngs.reduce((a, b) => a + b) / lngs.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final linePoints = route.geometry ??
        route.addresses.map((a) => LatLng(a.latitude, a.longitude)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A1628), Color(0xFF0D47A1)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        ),
                        Expanded(
                          child: Text(
                            route.name,
                            style: const TextStyle(
                                fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 48, top: 2),
                      child: Text(
                        _formatDate(route.date),
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.55)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF0F4F8),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                    child: SizedBox(
                      height: 200,
                      child: route.addresses.isEmpty
                          ? Container(color: const Color(0xFFE2E8F0))
                          : IgnorePointer(
                              child: FlutterMap(
                                options: MapOptions(initialCenter: _center, initialZoom: 12),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.rotamobil',
                                  ),
                                  if (linePoints.length > 1)
                                    PolylineLayer(polylines: [
                                      Polyline(
                                        points: linePoints,
                                        color: const Color(0xFF0D47A1).withValues(alpha: 0.75),
                                        strokeWidth: 3,
                                      ),
                                    ]),
                                  MarkerLayer(
                                    markers: route.addresses.asMap().entries.map((e) {
                                      final i = e.key;
                                      final a = e.value;
                                      return Marker(
                                        point: LatLng(a.latitude, a.longitude),
                                        width: 28,
                                        height: 28,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0D47A1),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${i + 1}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _stat('${route.addresses.length}', 'Durak'),
                        _stat('${route.totalKm.toStringAsFixed(1)} km', 'Mesafe'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: route.addresses.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final a = route.addresses[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF0D47A1).withValues(alpha: 0.1),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0D47A1)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a.name,
                                        style: const TextStyle(
                                            fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2236))),
                                    const SizedBox(height: 2),
                                    Text(
                                      a.fullAddress,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF9DAFC8)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A2236))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9DAFC8))),
      ],
    );
  }
}
