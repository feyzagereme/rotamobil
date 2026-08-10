import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/route_provider.dart';
import '../services/tomtom_routing_service.dart';
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
  List<LatLng>? _routeGeometry;
  String? _geometrySignature;

  bool _showSearch = false;
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isAddingToRoute = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Nominatim usage policy metin başına en fazla 1 istek istiyor — bu yüzden
  // her tuş vuruşunda değil, sadece kullanıcı arama yapmayı onayladığında
  // (Enter / arama ikonu) çağrılır, yazarken otomatik tetiklenmez.
  Future<void> _searchAddress(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    setState(() { _isSearching = true; _searchResults = []; });
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': trimmed,
        'format': 'json',
        'addressdetails': '1',
        'limit': '6',
        'countrycodes': 'tr',
        'accept-language': 'tr',
      });
      final res = await http.get(uri, headers: {'User-Agent': 'RotaMobil/1.0'});
      if (res.statusCode == 200) {
        final results = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
        if (mounted) setState(() { _searchResults = results; _isSearching = false; });
      } else if (mounted) {
        setState(() => _isSearching = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final lat = double.tryParse(result['lat']?.toString() ?? '');
    final lon = double.tryParse(result['lon']?.toString() ?? '');
    if (lat == null || lon == null) return;
    final addr = result['address'] as Map<String, dynamic>? ?? {};
    final road = (addr['road'] ?? addr['pedestrian'] ?? addr['suburb'] ?? '').toString();
    final district = (addr['suburb'] ?? addr['district'] ?? addr['town'] ?? '').toString();
    final short = road.isNotEmpty
        ? '$road${district.isNotEmpty ? ', $district' : ''}'
        : (result['display_name'] as String? ?? '').split(',').take(2).join(',');
    final point = LatLng(lat, lon);
    setState(() {
      _selectedIndex = null;
      _pendingPin = point;
      _pendingAddressText = short.isNotEmpty ? short : null;
      _isGeocoding = false;
      _showSearch = false;
      _searchResults = [];
      _searchController.clear();
    });
    _mapController.move(point, 16);
  }

  // Backend/sürücünün belirlediği durak sırasını bozmadan, TomTom'dan
  // gerçek yol geometrisini çeker. Adres listesi (veya sırası) değişmediği
  // sürece tekrar istek atmaz.
  void _syncRouteGeometry(List<Address> addresses) {
    if (addresses.length < 2) return;
    final signature = addresses.map((a) => '${a.id}:${a.orderNumber}').join(',');
    if (signature == _geometrySignature) return;
    _geometrySignature = signature;
    TomTomRoutingService.fetchRouteGeometry(
      addresses.map((a) => LatLng(a.latitude, a.longitude)).toList(),
    ).then((geometry) {
      if (mounted && _geometrySignature == signature) {
        setState(() => _routeGeometry = geometry);
      }
    });
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
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Google Maps açılamadı'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
          ),
        );
      }
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
      if (mounted) {
        setState(() {
          _pendingAddressText = '${latlng.latitude.toStringAsFixed(5)}, ${latlng.longitude.toStringAsFixed(5)}';
          _isGeocoding = false;
        });
      }
    }
  }

  Future<void> _addPendingToRoute(RouteProvider provider) async {
    if (_pendingPin == null || _isAddingToRoute) return;
    final pin = _pendingPin!;
    final addressText = _pendingAddressText;
    final orderNumber = provider.addresses.length + 1;

    final newAddress = Address(
      id: 0, // Backend tarafından atanacak gerçek ID
      orderNumber: orderNumber,
      street: addressText ?? 'Yeni Adres',
      district: '',
      city: '',
      postalCode: '',
      country: 'Türkiye',
      latitude: pin.latitude,
      longitude: pin.longitude,
      customerName: 'Yeni Durak $orderNumber',
      customerType: 'Müşteri',
    );

    setState(() {
      _pendingPin = null;
      _pendingAddressText = null;
      _isAddingToRoute = true;
    });

    final error = await provider.addAddressAndPersist(newAddress);

    if (!mounted) return;
    setState(() => _isAddingToRoute = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Adres rotaya eklendi'),
        backgroundColor: error != null ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RouteProvider>(
      builder: (context, provider, _) {
        final addresses = provider.addresses;
        _syncRouteGeometry(addresses);
        final center = _center(addresses);
        final selectedAddress = _selectedIndex != null && _selectedIndex! < addresses.length
            ? addresses[_selectedIndex!]
            : null;
        final showBottomSheet = selectedAddress != null || _pendingPin != null;

        return Scaffold(
          body: Stack(
            children: [
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
                    userAgentPackageName: 'com.rota360.rotamobil',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routeGeometry ??
                            addresses.map((a) => LatLng(a.latitude, a.longitude)).toList(),
                        color: AppColors.accent.withValues(alpha: 0.8),
                        strokeWidth: 3,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      ...addresses.asMap().entries.map((entry) {
                        final i = entry.key;
                        final a = entry.value;
                        final isSelected = _selectedIndex == i;
                        return Marker(
                          point: LatLng(a.latitude, a.longitude),
                          width: isSelected ? 48 : 36,
                          height: isSelected ? 48 : 36,
                          child: GestureDetector(
                            onTap: () => _selectAddress(i, addresses),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: a.isCompleted
                                    ? AppColors.success
                                    : isSelected
                                        ? AppColors.primaryDark
                                        : AppColors.accent,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  )
                                ],
                              ),
                              child: Center(
                                child: a.isCompleted
                                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                                    : Text('${i + 1}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isSelected ? 16 : 13,
                                          fontWeight: FontWeight.bold,
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
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: const Icon(Icons.add, color: Colors.white, size: 22),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // Üst bar
              Positioned(
                top: 0, left: 0, right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                              )
                            ],
                          ),
                          child: const Text('Harita',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                        ),
                        const Spacer(),
                        _mapButton(Icons.search_rounded,
                            () => setState(() => _showSearch = !_showSearch)),
                        const SizedBox(width: 8),
                        _mapButton(Icons.fit_screen_rounded, () => _mapController.move(center, 12)),
                        const SizedBox(width: 8),
                        _mapButton(Icons.refresh_rounded, provider.refresh),
                      ],
                    ),
                  ),
                ),
              ),

              // Adres arama
              if (_showSearch)
                Positioned(
                  top: 70, left: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.textDark.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12)],
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            textInputAction: TextInputAction.search,
                            onSubmitted: _searchAddress,
                            decoration: InputDecoration(
                              hintText: 'Adres, sokak veya semt yaz...',
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _searchAddress(_searchController.text),
                          child: const Icon(Icons.search_rounded, color: Colors.white70, size: 20),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setState(() {
                            _showSearch = false;
                            _searchResults = [];
                            _searchController.clear();
                          }),
                          child: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                        ),
                      ]),
                      if (_isSearching)
                        const Padding(
                          padding: EdgeInsets.only(top: 10, bottom: 4),
                          child: SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                        )
                      else if (_searchResults.isNotEmpty) ...[
                        const Divider(color: Colors.white24, height: 16),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 260),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            itemBuilder: (context, i) {
                              final r = _searchResults[i];
                              return GestureDetector(
                                onTap: () => _selectSearchResult(r),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                  child: Row(children: [
                                    const Icon(Icons.location_on_rounded, color: AppColors.accent, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        (r['display_name'] as String? ?? '').split(',').take(3).join(','),
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ]),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ]),
                  ),
                ),

              // İpucu
              if (!showBottomSheet && !_showSearch)
                Positioned(
                  top: 80, left: 0, right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.textDark.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text('Yeni adres eklemek için haritaya dokun',
                              style: TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),

              // Zoom kontrolleri
              Positioned(
                right: 12,
                bottom: showBottomSheet ? 230 : 120,
                child: Column(
                  children: [
                    _mapButton(Icons.add, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
                    const SizedBox(height: 8),
                    _mapButton(Icons.remove, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
                    const SizedBox(height: 8),
                    _mapButton(Icons.my_location_rounded, () => _mapController.move(center, 12)),
                  ],
                ),
              ),

              // Alt panel
              if (showBottomSheet)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 40, height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.stroke,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          child: selectedAddress != null
                              ? _selectedPanel(selectedAddress)
                              : _pendingPanel(provider),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _bottomStat('${addresses.length}', 'Adres'),
                        Container(width: 1, height: 32, color: AppColors.stroke),
                        _bottomStat('${provider.completedStops}', 'Tamamlandı'),
                        Container(width: 1, height: 32, color: AppColors.stroke),
                        _bottomStat(provider.activeRouteName ?? 'Aktif', 'Rota'),
                      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: address.isCompleted
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: address.isCompleted
                    ? const Icon(Icons.check, color: AppColors.success, size: 18)
                    : Text('${_selectedIndex! + 1}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.accent)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(address.customerName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text('${address.street}, ${address.district}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textMid)),
                ],
              ),
            ),
            _mapButton(Icons.close_rounded, () => setState(() => _selectedIndex = null)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _launchNavigation(address),
            icon: const Icon(Icons.navigation_rounded, size: 18),
            label: const Text('Navigasyonu Başlat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _pendingPanel(RouteProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_location_alt_rounded, color: AppColors.warning, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Yeni Adres',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  _isGeocoding
                      ? const Row(children: [
                          SizedBox(
                            width: 12, height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.textLight),
                          ),
                          SizedBox(width: 6),
                          Text('Adres aranıyor...', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                        ])
                      : Text(_pendingAddressText ?? 'Konum seçildi',
                          style: const TextStyle(fontSize: 13, color: AppColors.textMid),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            _mapButton(Icons.close_rounded, () => setState(() {
              _pendingPin = null;
              _pendingAddressText = null;
            })),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() { _pendingPin = null; _pendingAddressText = null; }),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMid,
                  side: const BorderSide(color: AppColors.stroke),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('İptal'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: (_isGeocoding || _isAddingToRoute)
                    ? null
                    : () => _addPendingToRoute(provider),
                icon: _isAddingToRoute
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.add_rounded, size: 18),
                label: Text(_isAddingToRoute ? 'Ekleniyor...' : 'Rotaya Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.stroke,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _mapButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
            )
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.textDark),
      ),
    );
  }

  Widget _bottomStat(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
      ],
    );
  }
}
