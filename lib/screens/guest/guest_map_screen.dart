import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../services/guest/guest_route_service.dart';
import '../../services/maps_launcher.dart';

class GuestMapScreen extends StatefulWidget {
  final bool pickMode;
  const GuestMapScreen({super.key, this.pickMode = false});
  @override
  State<GuestMapScreen> createState() => _GuestMapScreenState();
}

class _GuestMapScreenState extends State<GuestMapScreen> {
  late final MapController _mapController;
  List<GuestAddress> _addresses = [];
  LatLng? _pendingPin;
  String? _pendingText;
  bool _isGeocoding = false;
  int? _selectedIndex;
  double? _realTotalKm;
  int? _realTotalMinutes;
  List<LatLng>? _routeGeometry;

  bool _showSearch = false;
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _load();
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
      _pendingText = short.isNotEmpty ? short : null;
      _isGeocoding = false;
      _showSearch = false;
      _searchResults = [];
      _searchController.clear();
    });
    _mapController.move(point, 16);
  }

  Future<void> _load() async {
    final addresses = await GuestRouteService.loadAddresses();
    final stats = await GuestRouteService.loadRouteStatsIfValid(addresses);
    setState(() {
      _addresses = addresses;
      _realTotalKm = stats?.totalKm;
      _realTotalMinutes = stats?.totalMinutes;
      _routeGeometry = stats?.geometry;
    });
  }

  Future<void> _onMapTap(TapPosition _, LatLng latlng) async {
    setState(() {
      _selectedIndex = null;
      _pendingPin = latlng;
      _pendingText = null;
      _isGeocoding = true;
    });
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': latlng.latitude.toString(),
        'lon': latlng.longitude.toString(),
        'format': 'json', 'accept-language': 'tr',
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
        if (mounted) {
          setState(() { _pendingText = short; _isGeocoding = false; });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _pendingText = '${latlng.latitude.toStringAsFixed(4)}, ${latlng.longitude.toStringAsFixed(4)}';
          _isGeocoding = false;
        });
      }
    }
  }

  Future<void> _addAddress() async {
    if (_pendingPin == null) return;
    final newAddress = GuestAddress(
      id: DateTime.now().millisecondsSinceEpoch,
      name: _pendingText ?? 'Yeni Durak',
      fullAddress: _pendingText ?? '${_pendingPin!.latitude.toStringAsFixed(4)}, ${_pendingPin!.longitude.toStringAsFixed(4)}',
      latitude: _pendingPin!.latitude,
      longitude: _pendingPin!.longitude,
    );
    _addresses.add(newAddress);
    await GuestRouteService.saveAddresses(_addresses);
    setState(() { _pendingPin = null; _pendingText = null; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Durak eklendi'),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
      if (widget.pickMode) Navigator.pop(context);
    }
  }

  Future<void> _launchNav(GuestAddress address) async {
    await launchNavigation(context, address.latitude, address.longitude);
  }

  LatLng get _center {
    if (_addresses.isEmpty) return const LatLng(40.98, 27.52);
    final lats = _addresses.map((a) => a.latitude);
    final lngs = _addresses.map((a) => a.longitude);
    return LatLng(
      lats.reduce((a, b) => a + b) / lats.length,
      lngs.reduce((a, b) => a + b) / lngs.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showPanel = _pendingPin != null || _selectedIndex != null;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 12,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.rotamobil',
              ),
              if (_addresses.length > 1)
                PolylineLayer(polylines: [
                  Polyline(
                    points: _routeGeometry ??
                        _addresses.map((a) => LatLng(a.latitude, a.longitude)).toList(),
                    color: const Color(0xFF53D6FF).withValues(alpha: 0.7),
                    strokeWidth: 3,
                  ),
                ]),
              MarkerLayer(markers: [
                ..._addresses.asMap().entries.map((e) {
                  final i = e.key;
                  final a = e.value;
                  final isSelected = _selectedIndex == i;
                  return Marker(
                    point: LatLng(a.latitude, a.longitude),
                    width: isSelected ? 52 : 38,
                    height: isSelected ? 52 : 38,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedIndex = isSelected ? null : i;
                        _pendingPin = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: a.isCompleted
                              ? const Color(0xFF22C55E)
                              : isSelected
                                  ? const Color(0xFF0A1628)
                                  : const Color(0xFF0D47A1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF53D6FF) : Colors.white,
                            width: isSelected ? 3 : 2.5,
                          ),
                          boxShadow: [BoxShadow(
                            color: isSelected
                                ? const Color(0xFF53D6FF).withValues(alpha: 0.4)
                                : Colors.black.withValues(alpha: 0.2),
                            blurRadius: isSelected ? 12 : 6,
                          )],
                        ),
                        child: Center(
                          child: a.isCompleted
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                              : Text('${i + 1}', style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSelected ? 17 : 13,
                                  fontWeight: FontWeight.w800)),
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
                        color: const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                          blurRadius: 10,
                        )],
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    ),
                  ),
              ]),
            ],
          ),

          // Üst bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF0A1628).withValues(alpha: 0.9), Colors.transparent],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Row(children: [
                    if (widget.pickMode)
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: _mapBtn(Icons.arrow_back_rounded),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1628).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Text('Harita',
                            style: TextStyle(fontSize: 15,
                                fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    const Spacer(),
                    _mapBtn(Icons.search_rounded,
                        onTap: () => setState(() => _showSearch = !_showSearch)),
                    const SizedBox(width: 8),
                    _mapBtn(Icons.fit_screen_rounded,
                        onTap: () => _mapController.move(_center, 12)),
                  ]),
                ),
              ),
            ),
          ),

          // Adres arama
          if (_showSearch)
            Positioned(
              top: 70, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1628).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12)],
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
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _searchAddress(_searchController.text),
                      child: Icon(Icons.search_rounded,
                          color: Colors.white.withValues(alpha: 0.8), size: 20),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() {
                        _showSearch = false;
                        _searchResults = [];
                        _searchController.clear();
                      }),
                      child: Icon(Icons.close_rounded,
                          color: Colors.white.withValues(alpha: 0.6), size: 20),
                    ),
                  ]),
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.only(top: 10, bottom: 4),
                      child: SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF53D6FF)),
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
                                const Icon(Icons.location_on_rounded,
                                    color: Color(0xFF53D6FF), size: 16),
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
          if (!showPanel && !_showSearch)
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
                    Text('Durak eklemek için haritaya dokun',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                ),
              ),
            ),

          // Zoom butonları
          Positioned(
            right: 12,
            bottom: showPanel ? 230 : 120,
            child: Column(children: [
              _mapBtn(Icons.add_rounded,
                  onTap: () => _mapController.move(_mapController.camera.center,
                      _mapController.camera.zoom + 1)),
              const SizedBox(height: 8),
              _mapBtn(Icons.remove_rounded,
                  onTap: () => _mapController.move(_mapController.camera.center,
                      _mapController.camera.zoom - 1)),
              const SizedBox(height: 8),
              _mapBtn(Icons.my_location_rounded,
                  onTap: () => _mapController.move(_center, 12)),
            ]),
          ),

          // Alt panel
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0A1628),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24), topRight: Radius.circular(24),
                ),
              ),
              child: showPanel
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
                        child: _selectedIndex != null
                            ? _selectedPanel(_addresses[_selectedIndex!])
                            : _pendingPanel(),
                      ),
                    ])
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _bottomStat('${_addresses.length}', 'Durak'),
                          Container(width: 1, height: 32,
                              color: Colors.white.withValues(alpha: 0.15)),
                          _bottomStat(
                              _addresses.isNotEmpty
                                  ? '${(_realTotalKm ?? GuestRouteService.totalDistance(_addresses, 40.98, 27.52)).toStringAsFixed(1)} km'
                                  : '—',
                              'Mesafe'),
                          Container(width: 1, height: 32,
                              color: Colors.white.withValues(alpha: 0.15)),
                          _bottomStat(
                              _addresses.isNotEmpty
                                  ? '~${_realTotalMinutes ?? (GuestRouteService.totalDistance(_addresses, 40.98, 27.52) / 40 * 60).toInt()} dk'
                                  : '—',
                              'Süre'),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectedPanel(GuestAddress address) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF53D6FF).withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF53D6FF).withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text('${_selectedIndex! + 1}',
                style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w800, color: Color(0xFF53D6FF))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(address.name, style: const TextStyle(fontSize: 15,
              fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 2),
          Text(address.fullAddress, style: TextStyle(fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6)),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        _mapBtn(Icons.close_rounded,
            onTap: () => setState(() => _selectedIndex = null)),
      ]),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _launchNav(address),
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

  Widget _pendingPanel() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
          ),
          child: const Icon(Icons.add_location_alt_rounded,
              color: Color(0xFFF59E0B), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Yeni Durak',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 2),
          _isGeocoding
              ? Row(children: [
                  SizedBox(width: 12, height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5,
                          color: Colors.white.withValues(alpha: 0.5))),
                  const SizedBox(width: 6),
                  Text('Adres aranıyor...',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
                ])
              : Text(_pendingText ?? 'Konum seçildi',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.65)),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
        ])),
        _mapBtn(Icons.close_rounded,
            onTap: () => setState(() { _pendingPin = null; _pendingText = null; })),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => setState(() { _pendingPin = null; _pendingText = null; }),
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
            onPressed: _isGeocoding ? null : _addAddress,
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

  Widget _mapBtn(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF0A1628).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)],
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }

  Widget _bottomStat(String value, String label) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: const TextStyle(fontSize: 15,
          fontWeight: FontWeight.w800, color: Colors.white)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
    ]);
  }
}