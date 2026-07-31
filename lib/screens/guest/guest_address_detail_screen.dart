import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/guest/guest_route_service.dart';

class GuestAddressDetailScreen extends StatefulWidget {
  final GuestAddress address;
  final int index;
  const GuestAddressDetailScreen({super.key, required this.address, required this.index});
  @override
  State<GuestAddressDetailScreen> createState() => _GuestAddressDetailScreenState();
}

class _GuestAddressDetailScreenState extends State<GuestAddressDetailScreen> {
  late bool _isCompleted;
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.address.isCompleted;
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final favs = await GuestRouteService.loadFavorites();
    setState(() => _isFavorite = favs.any((f) => f.id == widget.address.id));
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await GuestRouteService.removeFavorite(widget.address.id);
    } else {
      await GuestRouteService.saveFavorite(widget.address);
    }
    setState(() => _isFavorite = !_isFavorite);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isFavorite ? 'Favorilere eklendi' : 'Favorilerden çıkarıldı'),
        backgroundColor: _isFavorite ? const Color(0xFF22C55E) : const Color(0xFF5A6A85),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
    }
  }

  Future<void> _launchNavigation() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${widget.address.latitude},${widget.address.longitude}&travelmode=driving',
    );
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final address = widget.address;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Column(
        children: [
          SizedBox(
            height: 250,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(address.latitude, address.longitude),
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.rotamobil',
                    ),
                    MarkerLayer(markers: [
                      Marker(
                        point: LatLng(address.latitude, address.longitude),
                        width: 52, height: 52,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isCompleted ? const Color(0xFF22C55E) : const Color(0xFF0D47A1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10, offset: const Offset(0, 4),
                            )],
                          ),
                          child: Center(
                            child: _isCompleted
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                                : Text('${widget.index + 1}',
                                    style: const TextStyle(color: Colors.white,
                                        fontSize: 16, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF0A1628).withValues(alpha: 0.8),
                        Colors.transparent, Colors.transparent,
                        const Color(0xFF0A1628).withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                        Row(children: [
                          GestureDetector(
                            onTap: _toggleFavorite,
                            child: Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: _isFavorite ? Colors.red : Colors.white, size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _launchNavigation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF53D6FF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(children: [
                                Icon(Icons.navigation_rounded, color: Color(0xFF0A1628), size: 16),
                                SizedBox(width: 6),
                                Text('Navigasyon', style: TextStyle(fontSize: 12,
                                    fontWeight: FontWeight.w700, color: Color(0xFF0A1628))),
                              ]),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF0F4F8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24), topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(address.name,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                                color: Color(0xFF1A2236), letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text('Durak #${widget.index + 1}',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF9DAFC8))),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isCompleted
                              ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                              : const Color(0xFF53D6FF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isCompleted
                                ? const Color(0xFF22C55E).withValues(alpha: 0.3)
                                : const Color(0xFF53D6FF).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _isCompleted ? 'Tamamlandı' : 'Bekliyor',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                              color: _isCompleted ? const Color(0xFF22C55E) : const Color(0xFF53D6FF)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8, offset: const Offset(0, 2),
                      )],
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D47A1).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.location_on_rounded,
                            size: 18, color: Color(0xFF0D47A1)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Adres', style: TextStyle(fontSize: 11,
                            color: Color(0xFF9DAFC8), fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text(address.fullAddress,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF1A2236))),
                      ])),
                    ]),
                  ),

                  const SizedBox(height: 12),

                  Row(children: [
                    Expanded(
                      child: _actionBtn(Icons.navigation_rounded, 'Navigasyon',
                          const Color(0xFF0D47A1), _launchNavigation, filled: true),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _actionBtn(Icons.share_rounded, 'Paylaş',
                          const Color(0xFF5A6A85), () {}),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _actionBtn(
                        _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        _isFavorite ? 'Favoride' : 'Favori',
                        Colors.red,
                        _toggleFavorite,
                      ),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        setState(() => _isCompleted = !_isCompleted);
                        widget.address.isCompleted = _isCompleted;
                        final addresses = await GuestRouteService.loadAddresses();
                        final idx = addresses.indexWhere((a) => a.id == widget.address.id);
                        if (idx != -1) {
                          addresses[idx] = GuestAddress(
                            id: widget.address.id,
                            name: widget.address.name,
                            fullAddress: widget.address.fullAddress,
                            latitude: widget.address.latitude,
                            longitude: widget.address.longitude,
                            isCompleted: _isCompleted,
                          );
                          await GuestRouteService.saveAddresses(addresses);
                        }
                      },
                      icon: Icon(_isCompleted ? Icons.cancel_outlined : Icons.check_circle_rounded, size: 20),
                      label: Text(_isCompleted ? 'Tamamlandıyı Geri Al' : 'Ziyareti Tamamlandı İşaretle',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCompleted ? const Color(0xFF9DAFC8) : const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color,
      VoidCallback onTap, {bool filled = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled ? color : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: filled ? color : const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(
            color: filled ? color.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2),
          )],
        ),
        child: Column(children: [
          Icon(icon, size: 22, color: filled ? Colors.white : color),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: filled ? Colors.white : color)),
        ]),
      ),
    );
  }
}