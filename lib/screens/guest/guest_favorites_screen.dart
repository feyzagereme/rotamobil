import 'package:flutter/material.dart';
import '../../services/guest/guest_route_service.dart';
import '../../widgets/app_notice.dart';

class GuestFavoritesScreen extends StatefulWidget {
  const GuestFavoritesScreen({super.key});
  @override
  State<GuestFavoritesScreen> createState() => _GuestFavoritesScreenState();
}

class _GuestFavoritesScreenState extends State<GuestFavoritesScreen> {
  List<GuestAddress> _favorites = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final favs = await GuestRouteService.loadFavorites();
    setState(() => _favorites = favs);
  }

  Future<void> _addToRoute(GuestAddress address) async {
    final addresses = await GuestRouteService.loadAddresses();
    final exists = addresses.any((a) => a.id == address.id);
    if (exists) {
      if (mounted) {
        AppNotice.show(context, 'Bu durak zaten rotada');
      }
      return;
    }
    addresses.add(GuestAddress(
      id: DateTime.now().millisecondsSinceEpoch,
      name: address.name, fullAddress: address.fullAddress,
      latitude: address.latitude, longitude: address.longitude,
    ));
    await GuestRouteService.saveAddresses(addresses);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Rotaya eklendi'),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
    }
  }

  Future<void> _remove(int id) async {
    await GuestRouteService.removeFavorite(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A1628), Color(0xFF0D47A1)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('FAVORİLER',
                      style: TextStyle(fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  const SizedBox(height: 6),
                  const Text('Sık Gidilen Yerler',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                          color: Colors.white, letterSpacing: -0.5)),
                ]),
              ),
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
              child: _favorites.isEmpty
                  ? Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D47A1).withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite_border_rounded,
                              size: 34, color: Color(0xFF9DAFC8)),
                        ),
                        const SizedBox(height: 16),
                        const Text('Henüz favori yok',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                                color: Color(0xFF5A6A85))),
                        const SizedBox(height: 6),
                        const Text('Durak detayından favorilere ekleyebilirsin',
                            style: TextStyle(fontSize: 13, color: Color(0xFF9DAFC8))),
                      ]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                      itemCount: _favorites.length,
                      itemBuilder: (context, index) {
                        final fav = _favorites[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8, offset: const Offset(0, 2),
                            )],
                          ),
                          child: Row(children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.favorite_rounded,
                                  color: Colors.red, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(fav.name,
                                    style: const TextStyle(fontSize: 14,
                                        fontWeight: FontWeight.w600, color: Color(0xFF1A2236))),
                                const SizedBox(height: 3),
                                Text(fav.fullAddress,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF9DAFC8)),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            )),
                            IconButton(
                              onPressed: () => _addToRoute(fav),
                              icon: const Icon(Icons.add_circle_outline_rounded,
                                  color: Color(0xFF0D47A1), size: 22),
                              tooltip: 'Rotaya Ekle',
                            ),
                            IconButton(
                              onPressed: () => _remove(fav.id),
                              icon: Icon(Icons.favorite_rounded,
                                  color: Colors.red.withValues(alpha: 0.7), size: 20),
                              tooltip: 'Favoriden Çıkar',
                            ),
                          ]),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}