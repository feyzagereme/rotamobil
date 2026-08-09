import 'package:flutter/material.dart';
import '../../services/guest/guest_route_service.dart';
import 'guest_saved_route_detail_screen.dart';

class GuestHistoryScreen extends StatefulWidget {
  const GuestHistoryScreen({super.key});
  @override
  State<GuestHistoryScreen> createState() => _GuestHistoryScreenState();
}

class _GuestHistoryScreenState extends State<GuestHistoryScreen> {
  List<SavedRoute> _routes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final routes = await GuestRouteService.loadSavedRoutes();
    setState(() => _routes = routes);
  }

  String _formatDate(DateTime date) {
    const months = ['Oca','Şub','Mar','Nis','May','Haz','Tem','Ağu','Eyl','Eki','Kas','Ara'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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
                  Text('GEÇMİŞ',
                      style: TextStyle(fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  const SizedBox(height: 6),
                  const Text('Rotalarım',
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
              child: _routes.isEmpty
                  ? Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D47A1).withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.history_rounded,
                              size: 34, color: Color(0xFF9DAFC8)),
                        ),
                        const SizedBox(height: 16),
                        const Text('Henüz kayıtlı rota yok',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                                color: Color(0xFF5A6A85))),
                        const SizedBox(height: 6),
                        const Text('Ana sayfadan rotaları kaydet',
                            style: TextStyle(fontSize: 13, color: Color(0xFF9DAFC8))),
                      ]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                      itemCount: _routes.length,
                      itemBuilder: (context, index) {
                        final route = _routes[index];
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GuestSavedRouteDetailScreen(route: route),
                            ),
                          ),
                          child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
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
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D47A1).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.route_rounded,
                                  color: Color(0xFF0D47A1), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(route.name,
                                    style: const TextStyle(fontSize: 14,
                                        fontWeight: FontWeight.w700, color: Color(0xFF1A2236))),
                                const SizedBox(height: 3),
                                Text('${route.addresses.length} durak · ${route.totalKm.toStringAsFixed(1)} km',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF9DAFC8))),
                                const SizedBox(height: 2),
                                Text(_formatDate(route.date),
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF9DAFC8))),
                              ],
                            )),
                            const Icon(Icons.chevron_right_rounded,
                                color: Color(0xFF9DAFC8), size: 18),
                          ]),
                          ),
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