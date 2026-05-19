import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/route_provider.dart';
import 'address_detail_screen.dart';
import '../models/address_model.dart';
import '../theme/app_colors.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
    setState(() { _isLoadingRoutes = true; _routeError = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("user_id") ?? 1;
      final response = await http.get(
        Uri.parse("https://route-backend-wkiy.onrender.com/routes/$userId"),
      );
      if (response.statusCode == 200) {
        setState(() { _backendRoutes = jsonDecode(response.body); _isLoadingRoutes = false; });
      } else {
        setState(() { _routeError = "Rotalar alınamadı: ${response.statusCode}"; _isLoadingRoutes = false; });
      }
    } catch (e) {
      setState(() { _routeError = "Sunucuya bağlanılamadı"; _isLoadingRoutes = false; });
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
          backgroundColor: AppColors.bgLight,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.surface,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(height: 1, color: AppColors.stroke),
                ),
                title: const Text('Rota Listesi',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                actions: [
                  if (_isRecalculating)
                    const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                          ),
                          SizedBox(width: 6),
                          Text('Hesaplanıyor...', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                        ],
                      ),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('$completed/$total',
                          style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),

              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tamamlanma Durumu',
                              style: TextStyle(fontSize: 12, color: AppColors.textMid, fontWeight: FontWeight.w600)),
                          Text('%${pct.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: pct / 100,
                          minHeight: 8,
                          backgroundColor: AppColors.stroke,
                          valueColor: AlwaysStoppedAnimation(pct == 100 ? AppColors.success : AppColors.accent),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          Icon(Icons.drag_indicator_rounded, size: 14, color: AppColors.textLight),
                          SizedBox(width: 4),
                          Text('Sırayı değiştirmek için basılı tut ve sürükle',
                              style: TextStyle(fontSize: 11, color: AppColors.textLight)),
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
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.stroke),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Backend Rotaları',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                        const SizedBox(height: 8),
                        if (_isLoadingRoutes)
                          const Text('Rotalar yükleniyor...',
                              style: TextStyle(fontSize: 12, color: AppColors.textMid))
                        else if (_routeError != null)
                          Text(_routeError!,
                              style: const TextStyle(fontSize: 12, color: AppColors.error))
                        else if (_backendRoutes.isEmpty)
                          const Text("Backend'de kayıtlı rota yok.",
                              style: TextStyle(fontSize: 12, color: AppColors.textMid))
                        else
                          ..._backendRoutes.map((route) {
                            final routeJson = route["route_json"];
                            final totalKm = routeJson is Map ? routeJson["totalKm"] : null;
                            final totalMin = routeJson is Map ? routeJson["totalMin"] : null;
                            final path = routeJson is Map ? routeJson["path"] : null;
                            final stopCount = path is List ? (path.isNotEmpty ? path.length - 1 : 0) : null;
                            final routeAddresses = path is List
                                ? path.skip(1).map((e) => e.toString()).toList()
                                : <String>[];
                            String detailText = '';
                            if (totalKm != null) detailText += '${totalKm.toString()} km';
                            if (totalMin != null) detailText += detailText.isEmpty ? '$totalMin dk' : ' • $totalMin dk';
                            if (stopCount != null) detailText += detailText.isEmpty ? '$stopCount durak' : ' • $stopCount durak';

                            return Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.route_rounded, color: AppColors.primaryDark),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(route["name"] ?? 'İsimsiz Rota',
                                            style: const TextStyle(
                                              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                                        if (detailText.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(detailText,
                                              style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
                                        ],
                                        if (routeAddresses.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          ...routeAddresses.take(3).map(
                                            (address) => Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Text('• $address',
                                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 10, color: AppColors.textMid)),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
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
                            builder: (_) => AddressDetailScreen(address: address, index: index),
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

  const _AddressItem({required this.address, required this.index, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isCompleted = address.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFF8FAF8) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? AppColors.success.withValues(alpha: 0.3) : AppColors.stroke,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 72,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.success.withValues(alpha: 0.06)
                  : AppColors.accent.withValues(alpha: 0.06),
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
                    color: isCompleted ? AppColors.success : AppColors.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.drag_indicator_rounded,
                  size: 18,
                  color: isCompleted ? AppColors.success.withValues(alpha: 0.4) : AppColors.textLight,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.customerName,
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: isCompleted ? AppColors.textLight : AppColors.textDark,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(address.street,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMid),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${address.district}, ${address.city}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Adresi Sil',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  content: Text('${address.customerName} rotadan kaldırılsın mı?',
                      style: const TextStyle(fontSize: 14, color: AppColors.textMid)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('İptal', style: TextStyle(color: AppColors.textLight)),
                    ),
                    ElevatedButton(
                      onPressed: () { Navigator.pop(ctx); onDelete(); },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
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
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}
