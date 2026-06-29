import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/guest/guest_route_service.dart';
import 'guest_map_screen.dart';
import 'guest_address_detail_screen.dart';

class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});
  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  List<GuestAddress> _addresses = [];
  List<GuestAddress> _sortedAddresses = [];
  bool _routeCalculated = false;
  double _totalKm = 0;
  final double _startLat = 40.9833;
  final double _startLon = 27.5167;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final addresses = await GuestRouteService.loadAddresses();
    setState(() {
      _addresses = addresses;
      _sortedAddresses = List.from(addresses);
      _routeCalculated = false;
    });
  }

  void _calculateRoute() {
    if (_addresses.isEmpty) return;
    HapticFeedback.mediumImpact();
    final sorted = GuestRouteService.calculateShortestRoute(
        _addresses, _startLat, _startLon);
    final km = GuestRouteService.totalDistance(sorted, _startLat, _startLon);
    setState(() {
      _sortedAddresses = sorted;
      _totalKm = km;
      _routeCalculated = true;
    });
    GuestRouteService.saveAddresses(sorted);
  }

  Future<void> _saveRoute() async {
    if (_sortedAddresses.isEmpty) return;
    final now = DateTime.now();
    const months = ['Oca','Şub','Mar','Nis','May','Haz','Tem','Ağu','Eyl','Eki','Kas','Ara'];
    final name = '${now.day} ${months[now.month - 1]} rotası';
    await GuestRouteService.saveRoute(SavedRoute(
      id: now.millisecondsSinceEpoch.toString(),
      name: name,
      date: now,
      addresses: List.from(_sortedAddresses),
      totalKm: _totalKm,
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Rota kaydedildi'),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
    }
  }

  Future<void> _removeAddress(int index) async {
    _addresses.removeAt(index);
    await GuestRouteService.saveAddresses(_addresses);
    _load();
  }

  Future<void> _clearAll() async {
    await GuestRouteService.clearAddresses();
    setState(() {
      _addresses = [];
      _sortedAddresses = [];
      _routeCalculated = false;
      _totalKm = 0;
    });
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = ['Oca','Şub','Mar','Nis','May','Haz','Tem','Ağu','Eyl','Eki','Kas','Ara'];
    const days = ['Pazartesi','Salı','Çarşamba','Perşembe','Cuma','Cumartesi','Pazar'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _routeCalculated ? _sortedAddresses : _addresses;
    final completed = displayList.where((a) => a.isCompleted).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Column(
        children: [
          // Header
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_todayLabel(),
                            style: TextStyle(fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w500)),
                        Row(children: [
                          if (_addresses.isNotEmpty)
                            GestureDetector(
                              onTap: _saveRoute,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                child: const Row(children: [
                                  Icon(Icons.save_rounded, size: 14, color: Colors.white),
                                  SizedBox(width: 5),
                                  Text('Kaydet', style: TextStyle(fontSize: 12, color: Colors.white)),
                                ]),
                              ),
                            ),
                          const SizedBox(width: 8),
                          if (_addresses.isNotEmpty)
                            GestureDetector(
                              onTap: _clearAll,
                              child: Icon(Icons.delete_outline_rounded,
                                  color: Colors.white.withValues(alpha: 0.55), size: 20),
                            ),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text('Rotam',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                            color: Colors.white, letterSpacing: -0.5)),
                    if (_routeCalculated) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        _headerStat('${_addresses.length}', 'Durak'),
                        const SizedBox(width: 20),
                        _headerStat('${_totalKm.toStringAsFixed(1)} km', 'Mesafe'),
                        const SizedBox(width: 20),
                        _headerStat('~${(_totalKm / 40 * 60).toInt()} dk', 'Süre'),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // İçerik
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF0F4F8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: _addresses.isEmpty
                  ? _emptyState()
                  : Column(children: [
                      // Rota hesapla butonu
                      if (!_routeCalculated)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _calculateRoute,
                              icon: const Icon(Icons.alt_route_rounded, size: 20),
                              label: const Text('En Kısa Rotayı Hesapla',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D47A1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF22C55E), size: 18),
                              const SizedBox(width: 8),
                              Text('En kısa rota hesaplandı · $completed/${displayList.length} tamamlandı',
                                  style: const TextStyle(fontSize: 13,
                                      color: Color(0xFF22C55E), fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),

                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_routeCalculated ? 'OPTİMAL SIRA' : 'DURAKLAR',
                                style: const TextStyle(fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF9DAFC8), letterSpacing: 1.2)),
                            Text('${_addresses.length} durak',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF9DAFC8))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: displayList.length,
                          itemBuilder: (context, index) {
                            final address = displayList[index];
                            return _AddressCard(
                              address: address,
                              index: index,
                              isOptimal: _routeCalculated,
                              onTap: () async {
                                await Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => GuestAddressDetailScreen(
                                      address: address, index: index),
                                ));
                                _load();
                              },
                              onDelete: () => _removeAddress(
                                  _addresses.indexOf(address)),
                              onToggle: () async {
                                setState(() => address.isCompleted = !address.isCompleted);
                                await GuestRouteService.saveAddresses(_addresses);
                              },
                            );
                          },
                        ),
                      ),
                    ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => const GuestMapScreen(pickMode: true),
          ));
          _load();
        },
        backgroundColor: const Color(0xFF53D6FF),
        foregroundColor: const Color(0xFF0A1628),
        icon: const Icon(Icons.add_location_rounded),
        label: const Text('Adres Ekle', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_location_alt_rounded,
                size: 38, color: Color(0xFF9DAFC8)),
          ),
          const SizedBox(height: 20),
          const Text('Henüz durak eklenmedi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                  color: Color(0xFF5A6A85))),
          const SizedBox(height: 8),
          const Text('Haritadan veya arama yaparak\ngideceğin yerleri ekle.',
              style: TextStyle(fontSize: 13, color: Color(0xFF9DAFC8), height: 1.5),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => const GuestMapScreen(pickMode: true),
              ));
              _load();
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('İlk Durağı Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _headerStat(String value, String label) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: const TextStyle(fontSize: 16,
          fontWeight: FontWeight.w800, color: Colors.white)),
      Text(label, style: TextStyle(fontSize: 11,
          color: Colors.white.withValues(alpha: 0.5))),
    ]);
  }
}

class _AddressCard extends StatelessWidget {
  final GuestAddress address;
  final int index;
  final bool isOptimal;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _AddressCard({
    required this.address, required this.index, required this.isOptimal,
    required this.onTap, required this.onDelete, required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          const SizedBox(width: 12),
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: address.isCompleted
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF0D47A1),
                width: 1.5,
              ),
              color: address.isCompleted
                  ? const Color(0xFF22C55E).withValues(alpha: 0.08)
                  : Colors.transparent,
            ),
            child: Center(
              child: address.isCompleted
                  ? const Icon(Icons.check_rounded, size: 14, color: Color(0xFF22C55E))
                  : Text('${index + 1}',
                      style: const TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w700, color: Color(0xFF0D47A1))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(address.name,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: address.isCompleted
                            ? const Color(0xFF9DAFC8)
                            : const Color(0xFF1A2236),
                        decoration: address.isCompleted
                            ? TextDecoration.lineThrough : null)),
                const SizedBox(height: 3),
                Text(address.fullAddress,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9DAFC8)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, size: 18,
                color: const Color(0xFF9DAFC8).withValues(alpha: 0.7)),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) {
              if (val == 'toggle') onToggle();
              if (val == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'toggle',
                  child: Row(children: [
                    Icon(address.isCompleted
                        ? Icons.radio_button_unchecked_rounded
                        : Icons.check_circle_outline_rounded,
                        size: 16, color: const Color(0xFF5A6A85)),
                    const SizedBox(width: 10),
                    Text(address.isCompleted ? 'Geri Al' : 'Tamamlandı',
                        style: const TextStyle(fontSize: 13)),
                  ])),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFE53935)),
                    SizedBox(width: 10),
                    Text('Kaldır', style: TextStyle(fontSize: 13, color: Color(0xFFE53935))),
                  ])),
            ],
          ),
        ]),
      ),
    );
  }
}