import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/route_provider.dart';
import 'address_detail_screen.dart';
import '../models/address_model.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class _C {
  static const bg        = Color(0xFFF0F4F8);
  static const surface   = Color(0xFFFFFFFF);
  static const accent    = Color(0xFF53D6FF);
  static const accentDark= Color(0xFF0D47A1);
  static const textDark  = Color(0xFF1A2236);
  static const textMid   = Color(0xFF5A6A85);
  static const textLight = Color(0xFF9DAFC8);
  static const stroke    = Color(0xFFE2E8F0);
  static const success   = Color(0xFF22C55E);
}

class RouteListScreen extends StatefulWidget {
  const RouteListScreen({Key? key}) : super(key: key);

  @override
  State<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends State<RouteListScreen> {
  bool _isRecalculating = false;

    bool _isLoadingRoutes = false;
    List<dynamic> _backendRoutes = [];
    String? _routeError;

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    HapticFeedback.lightImpact();
    context.read<RouteProvider>().reorder(oldIndex, newIndex);

    setState(() => _isRecalculating = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _isRecalculating = false);
  }

  @override
  void initState() {
    super.initState();
    _fetchBackendRoutes();
  }

  Future<void> _fetchBackendRoutes() async {
    setState(() {
      _isLoadingRoutes = true;
      _routeError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("user_id") ?? 1;

      final response = await http.get(
        Uri.parse("https://route-backend-wkiy.onrender.com/routes/$userId"),
      );

      if (response.statusCode == 200) {
        setState(() {
          _backendRoutes = jsonDecode(response.body);
          _isLoadingRoutes = false;
        });
      } else {
        setState(() {
          _routeError = "Rotalar alınamadı: ${response.statusCode}";
          _isLoadingRoutes = false;
        });
      }
    } catch (e) {
      setState(() {
        _routeError = "Sunucuya bağlanılamadı";
        _isLoadingRoutes = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RouteProvider>(
      builder: (context, provider, _) {
        final addresses = provider.addresses;
        final completed = provider.completedStops;
        final total = provider.totalStops;
        final pct = provider.completionPercentage;

        return Scaffold(
          backgroundColor: _C.bg,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: _C.surface,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(height: 1, color: _C.stroke),
                ),
                title: const Text('Rota Listesi',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _C.textDark)),
                actions: [
                  if (_isRecalculating)
                    const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: _C.accent),
                          ),
                          SizedBox(width: 6),
                          Text('Hesaplanıyor...', style: TextStyle(fontSize: 12, color: _C.textLight)),
                        ],
                      ),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _C.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('$completed/$total',
                          style: const TextStyle(fontSize: 12, color: _C.accentDark, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),

              SliverToBoxAdapter(
                child: Container(
                  color: _C.surface,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tamamlanma Durumu',
                              style: TextStyle(fontSize: 12, color: _C.textMid, fontWeight: FontWeight.w600)),
                          Text('%${pct.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 12, color: _C.accent, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: pct / 100,
                          minHeight: 8,
                          backgroundColor: _C.stroke,
                          valueColor: AlwaysStoppedAnimation(pct == 100 ? _C.success : _C.accent),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          Icon(Icons.drag_indicator_rounded, size: 14, color: _C.textLight),
                          SizedBox(width: 4),
                          Text('Sırayı değiştirmek için basılı tut ve sürükle',
                              style: TextStyle(fontSize: 11, color: _C.textLight)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),


                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _C.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _C.stroke),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Backend Rotaları",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: _C.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      if (_isLoadingRoutes)
                                        const Text(
                                          "Rotalar yükleniyor...",
                                          style: TextStyle(fontSize: 12, color: _C.textMid),
                                        )
                                      else if (_routeError != null)
                                        Text(
                                          _routeError!,
                                          style: const TextStyle(fontSize: 12, color: Colors.red),
                                        )
                                      else if (_backendRoutes.isEmpty)
                                        const Text(
                                          "Backend’de kayıtlı rota yok.",
                                          style: TextStyle(fontSize: 12, color: _C.textMid),
                                        )
                                      else
                                        ..._backendRoutes.map((route) {
                                          final routeJson = route["route_json"];

                                          final totalKm = routeJson is Map ? routeJson["totalKm"] : null;
                                          final totalMin = routeJson is Map ? routeJson["totalMin"] : null;
                                          final path = routeJson is Map ? routeJson["path"] : null;
final stopCount = path is List ? (path.length > 0 ? path.length - 1 : 0) : null;
final routeAddresses = path is List
    ? path.skip(1).map((e) => e.toString()).toList()
    : <String>[];
                                          String detailText = "";

                                          if (totalKm != null) {
                                            detailText += "${totalKm.toString()} km";
                                          }

                                          if (totalMin != null) {
                                            detailText += detailText.isEmpty ? "$totalMin dk" : " • $totalMin dk";
                                          }

                                          if (stopCount != null) {
                                            detailText += detailText.isEmpty ? "$stopCount durak" : " • $stopCount durak";
                                          }

                                          return Container(
                                            margin: const EdgeInsets.only(top: 8),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: _C.accent.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.route_rounded, color: _C.accentDark),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        route["name"] ?? "İsimsiz Rota",
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w600,
                                                          color: _C.textDark,
                                                        ),
                                                      ),
                                                      if (detailText.isNotEmpty) ...[
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          detailText,
                                                          style: const TextStyle(
                                                            fontSize: 11,
                                                            color: _C.textMid,
                                                          ),
                                                        ),
                                                      ],
                                                      if (routeAddresses.isNotEmpty) ...[
                                                        const SizedBox(height: 6),
                                                        ...routeAddresses.take(3).map(
                                                          (address) => Padding(
                                                            padding: const EdgeInsets.only(top: 2),
                                                            child: Text(
                                                              "• $address",
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: const TextStyle(
                                                                fontSize: 10,
                                                                color: _C.textMid,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                    ],
                                  ),
                                ),
                              ),
                            ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverReorderableList(
                  itemCount: addresses.length,
                  onReorder: _onReorder,
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    return ReorderableDragStartListener(
                      key: ValueKey(address.id),
                      index: index,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddressDetailScreen(
                              address: address,
                              index: index,
                            ),
                          ),
                        ),
                        child: _AddressItem(
                          address: address,
                          index: index,
                          onDelete: () => context.read<RouteProvider>().removeAddress(index),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }
}

class _AddressItem extends StatelessWidget {
  final Address address;
  final int index;
  final VoidCallback onDelete;

  const _AddressItem({
    required this.address,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = address.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFF8FAF8) : _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? _C.success.withOpacity(0.3) : _C.stroke,
        ),
      ),
      child: Row(
        children: [
          // Sürükleme tutacağı
          Container(
            width: 44,
            height: 72,
            decoration: BoxDecoration(
              color: isCompleted
                  ? _C.success.withOpacity(0.06)
                  : _C.accent.withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isCompleted ? _C.success : _C.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.drag_indicator_rounded,
                  size: 18,
                  color: isCompleted ? _C.success.withOpacity(0.4) : _C.textLight,
                ),
              ],
            ),
          ),

          // Adres bilgisi
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.customerName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isCompleted ? _C.textLight : _C.textDark,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(address.street,
                      style: const TextStyle(fontSize: 12, color: _C.textMid),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${address.district}, ${address.city}',
                      style: const TextStyle(fontSize: 11, color: _C.textLight)),
                ],
              ),
            ),
          ),

          // Sil butonu
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Adresi Sil',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A2236))),
                  content: Text('${address.customerName} rotadan kaldırılsın mı?',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF5A6A85))),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('İptal', style: TextStyle(color: Color(0xFF9DAFC8))),
                    ),
                    ElevatedButton(
                      onPressed: () { Navigator.pop(ctx); onDelete(); },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Sil'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: _C.textLight),
          ),
        ],
      ),
    );
  }
}