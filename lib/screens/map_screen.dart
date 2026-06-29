import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/route_provider.dart';
import '../models/address_model.dart';
import '../theme/app_colors.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;
  int? _selectedIndex;
  LatLng? _pendingPin;
  String? _pendingAddressText;
  bool _isGeocoding = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  LatLng _center(List<Address> addresses) {
    if (addresses.isEmpty) return const LatLng(38.33, 27.18);
    final lats = addresses.map((a) => a.latitude).toList();
    final lngs = addresses.map((a) => a.longitude).toList();
    return LatLng(
      lats.reduce((a, b) => a + b) / lats.length,
      lngs.reduce((a, b) => a + b) / lngs.length,
    );
  }

  void _selectAddress(int index, List<Address> addresses) {
    setState(() {
      _selectedIndex = index;
      _pendingPin = null;
      _pendingAddressText = null;
    });
    _mapController.move(LatLng(addresses[index].latitude, addresses[index].longitude), 14);
  }

  Future<void> _launchNavigation(Address address) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${address.latitude},${address.longitude}'
      '&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _onMapTap(TapPosition _, LatLng latlng) async {
    setState(() {
      _selectedIndex = null;
      _pendingPin = latlng;
      _pendingAddressText = null;
      _isGeocoding = true;
    });

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': latlng.latitude.toString(),
        'lon': latlng.longitude.toString(),
        'format': 'json',
        'accept-language': 'tr',
      });
      final res = await http.get(uri, headers: {'User-Agent': 'RotaMobil/1.0'});
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final addr = json['address'] as Map<String, dynamic>? ?? {};
        final road = addr['road'] ?? addr['pedestrian'] ?? addr['suburb'] ?? '';
        final district = addr['suburb'] ?? addr['district'] ?? addr['town'] ?? '';
        final short = road.isNotEmpty
            ? '$road${district.isNotEmpty ? ', $district' : ''}'
            : (json['display_name'] as String).split(',').take(2).join(',');
        if (mounted) setState(() { _pendingAddressText = short; _isGeocoding = false; });
      }
    } catch (_) {
      if (mounted) setState(() {
        _pendingAddressText = '${latlng.latitude.toStringAsFixed(5)}, ${latlng.longitude.toStringAsFixed(5)}';
        _isGeocoding = false;
      });
    }
  }

  void _addPendingToRoute(RouteProvider provider) {
    if (_pendingPin == null) return;
    final newAddress = Address(
      id: DateTime.now().millisecondsSinceEpoch,
      orderNumber: provider.addresses.length + 1,
      street: _pendingAddressText ?? 'Yeni Adres',
      district: '', city: 'İzmir', postalCode: '', country: 'Türkiye',
      latitude: _pendingPin!.latitude,
      longitude: _pendingPin!.longitude,
      customerName: 'Yeni Durak ${provider.addresses.length + 1}',
      customerType: 'Müşteri',
    );
    provider.addAddress(newAddress);
    setState(() { _pendingPin = null; _pendingAddressText = null; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Adres rotaya eklendi'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RouteProvider>(
      builder: (context, provider, _) {
        final addresses = provider.addresses;
        final center = _center(addresses);
        final selectedAddress = _selectedIndex != null && _selectedIndex! < addresses.length
            ? addresses[_selectedIndex!]
            : null;
        final showBottomSheet = selectedAddress != null || _pendingPin != null;

        return Scaffold(
          body: Stack(
            children: [
              // ── Harita
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 12,
                  onTap: _onMapTap,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.rotamobil',
                  ),
                  PolylineLayer(polylines: [
                    Polyline(
                      points: addresses.map((a) => LatLng(a.latitude, a.longitude)).toList(),
                      color: const Color(0xFF53D6FF).withValues(alpha: 0.8),
                      strokeWidth: 3,
                    ),
                  ]),
                  MarkerLayer(markers: [
                    ...addresses.asMap().entries.map((entry) {
                      final i = entry.key;
                      final a = entry.value;
                      final isSelected = _selectedIndex == i;
                      return Marker(
                        point: LatLng(a.latitude, a.longitude),
                        width: isSelected ? 52 : 38,
                        height: isSelected ? 52 : 38,
                        child: GestureDetector(
                          onTap: () => _selectAddress(i, addresses),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: a.isCompleted
                                  ? AppColors.success
                                  : isSelected
                                      ? const Color(0xFF0A1628)
                                      : const Color(0xFF0D47A1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF53D6FF)
                                    : Colors.white,
                                width: isSelected ? 3 : 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? const Color(0xFF53D6FF).withValues(alpha: 0.4)
                                      : Colors.black.withValues(alpha: 0.2),
                                  blurRadius: isSelected ? 12 : 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: a.isCompleted
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                  : Text('${i + 1}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isSelected ? 17 : 13,
                                        fontWeight: FontWeight.w800,
                                      )),
                            ),
                          ),
                        ),
                      );
                    }),
                    if (_pendingPin != null)
                      Marker(
                        point: _pendingPin!,
                        width: 44, height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.warning.withValues(alpha: 0.4),
                                blurRadius: 10, offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                  ]),
                ],
              ),

              // ── Üst bar
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0A1628).withValues(alpha: 0.85),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A1628).withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: const Text('Harita',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                          const Spacer(),
                          _mapBtn(Icons.fit_screen_rounded,
                              () => _mapController.move(center, 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── İpucu
              if (!showBottomSheet)
                Positioned(
                  top: 90, left: 0, right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1628).withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.touch_app_rounded, color: Colors.white54, size: 14),
                        SizedBox(width: 6),
                        Text('Yeni adres eklemek için haritaya dokun',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ]),
                    ),
                  ),
                ),

              // ── Zoom kontrolleri
              Positioned(
                right: 12,
                bottom: showBottomSheet ? 230 : 120,
                child: Column(children: [
                  _mapBtn(Icons.add_rounded, () => _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1)),
                  const SizedBox(height: 8),
                  _mapBtn(Icons.remove_rounded, () => _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1)),
                  const SizedBox(height: 8),
                  _mapBtn(Icons.my_location_rounded,
                      () => _mapController.move(center, 12)),
                ]),
              ),

              // ── Alt panel
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A1628),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: showBottomSheet
                      ? Column(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            width: 40, height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                            child: selectedAddress != null
                                ? _selectedPanel(selectedAddress)
                                : _pendingPanel(provider),
                          ),
                        ])
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _bottomStat('${addresses.length}', 'Adres'),
                              Container(width: 1, height: 32,
                                  color: Colors.white.withValues(alpha: 0.15)),
                              _bottomStat('${provider.completedStops}', 'Tamamlandı'),
                              Container(width: 1, height: 32,
                                  color: Colors.white.withValues(alpha: 0.15)),
                              _bottomStat('—', 'Mesafe'),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _selectedPanel(Address address) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: address.isCompleted
                ? AppColors.success.withValues(alpha: 0.15)
                : const Color(0xFF53D6FF).withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: address.isCompleted
                  ? AppColors.success.withValues(alpha: 0.4)
                  : const Color(0xFF53D6FF).withValues(alpha: 0.4),
            ),
          ),
          child: Center(
            child: address.isCompleted
                ? const Icon(Icons.check_rounded, color: AppColors.success, size: 18)
                : Text('${_selectedIndex! + 1}',
                    style: const TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w800, color: Color(0xFF53D6FF))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(address.customerName,
                style: const TextStyle(fontSize: 15,
                    fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 2),
            Text('${address.street}, ${address.district}',
                style: TextStyle(fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
        _mapBtn(Icons.close_rounded,
            () => setState(() => _selectedIndex = null)),
      ]),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _launchNavigation(address),
          icon: const Icon(Icons.navigation_rounded, size: 18),
          label: const Text('Navigasyonu Başlat'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF53D6FF),
            foregroundColor: const Color(0xFF0A1628),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      ),
    ]);
  }

  Widget _pendingPanel(RouteProvider provider) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
          ),
          child: const Icon(Icons.add_location_alt_rounded,
              color: AppColors.warning, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Yeni Adres',
                style: TextStyle(fontSize: 15,
                    fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 2),
            _isGeocoding
                ? Row(children: [
                    SizedBox(
                      width: 12, height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(width: 6),
                    Text('Adres aranıyor...',
                        style: TextStyle(fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.5))),
                  ])
                : Text(_pendingAddressText ?? 'Konum seçildi',
                    style: TextStyle(fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.65)),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
        _mapBtn(Icons.close_rounded, () => setState(() {
          _pendingPin = null;
          _pendingAddressText = null;
        })),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => setState(() {
              _pendingPin = null;
              _pendingAddressText = null;
            }),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white60,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('İptal'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _isGeocoding ? null : () => _addPendingToRoute(provider),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Rotaya Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF53D6FF),
              foregroundColor: const Color(0xFF0A1628),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ]),
    ]);
  }

  Widget _mapBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF0A1628).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }

  Widget _bottomStat(String value, String label) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value,
          style: const TextStyle(fontSize: 16,
              fontWeight: FontWeight.w800, color: Colors.white)),
      const SizedBox(height: 2),
      Text(label,
          style: TextStyle(fontSize: 11,
              color: Colors.white.withValues(alpha: 0.5))),
    ]);
  }
}