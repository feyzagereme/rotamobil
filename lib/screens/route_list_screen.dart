import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/route_provider.dart';
import 'address_detail_screen.dart';
import '../models/address_model.dart';
import '../theme/app_colors.dart';

class RouteListScreen extends StatefulWidget {
  const RouteListScreen({super.key});
  @override
  State<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends State<RouteListScreen> {
  bool _isRecalculating = false;

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    HapticFeedback.lightImpact();
    context.read<RouteProvider>().reorder(oldIndex, newIndex);
    setState(() => _isRecalculating = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _isRecalculating = false);
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
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('DURAK LİSTESİ',
                                style: TextStyle(fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.55),
                                    fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                            if (_isRecalculating)
                              Row(children: [
                                const SizedBox(width: 12, height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2,
                                        color: Color(0xFF53D6FF))),
                                const SizedBox(width: 6),
                                Text('Sıralanıyor...',
                                    style: TextStyle(fontSize: 12,
                                        color: Colors.white.withValues(alpha: 0.7))),
                              ])
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                child: Text('$completed / $total tamamlandı',
                                    style: const TextStyle(fontSize: 12,
                                        color: Colors.white, fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text('Rota Listesi',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                                color: Colors.white, letterSpacing: -0.5)),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tamamlanma',
                                style: TextStyle(fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.6))),
                            Text('%${pct.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12,
                                    color: Color(0xFF53D6FF), fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: total == 0 ? 0 : pct / 100,
                            minHeight: 6,
                            backgroundColor: Colors.white.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation(
                                pct == 100 ? AppColors.success : const Color(0xFF53D6FF)),
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
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  ),
                  child: addresses.isEmpty
                      ? Center(
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.route_rounded, size: 48, color: AppColors.textLight),
                            const SizedBox(height: 12),
                            const Text('Rota bulunamadı.',
                                style: TextStyle(fontSize: 14, color: AppColors.textMid)),
                          ]),
                        )
                      : Column(children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                            child: Row(children: [
                              Icon(Icons.drag_indicator_rounded, size: 13,
                                  color: AppColors.textLight.withValues(alpha: 0.6)),
                              const SizedBox(width: 4),
                              Text('Basılı tut ve sürükle',
                                  style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                            ]),
                          ),
                          Expanded(
                            child: ReorderableListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: addresses.length,
                              onReorder: _onReorder,
                              itemBuilder: (context, index) {
                                final address = addresses[index];
                                return _GlassCard(
                                  key: ValueKey(address.id),
                                  address: address,
                                  index: index,
                                  onTap: () => Navigator.push(context,
                                      MaterialPageRoute(builder: (_) =>
                                          AddressDetailScreen(address: address, index: index))),
                                  onDelete: () =>
                                      context.read<RouteProvider>().removeAddress(index),
                                );
                              },
                            ),
                          ),
                        ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Address address;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GlassCard({
    super.key,
    required this.address,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = address.isCompleted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
              child: Icon(Icons.drag_handle_rounded,
                  color: AppColors.textLight.withValues(alpha: 0.4), size: 18),
            ),
            // İnce daire
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? AppColors.success : const Color(0xFF0D47A1),
                  width: 1.5,
                ),
                color: isCompleted
                    ? AppColors.success.withValues(alpha: 0.08)
                    : const Color(0xFF0D47A1).withValues(alpha: 0.05),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check_rounded, size: 14, color: AppColors.success)
                    : Text('${index + 1}',
                        style: const TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w700, color: Color(0xFF0D47A1))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(address.customerName,
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: isCompleted ? AppColors.textLight : AppColors.textDark,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        )),
                    const SizedBox(height: 3),
                    Text(address.street,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMid),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 1),
                    Text('${address.district}, ${address.city}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
              ),
            ),
            // Üç nokta
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  size: 18, color: AppColors.textLight.withValues(alpha: 0.6)),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'detail') onTap();
                if (val == 'delete') _confirmDelete(context);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'detail',
                    child: Row(children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textMid),
                      SizedBox(width: 10),
                      Text('Detay', style: TextStyle(fontSize: 13)),
                    ])),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                      SizedBox(width: 10),
                      Text('Kaldır', style: TextStyle(fontSize: 13, color: AppColors.error)),
                    ])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Durağı Kaldır',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        content: Text('${address.customerName} rotadan kaldırılsın mı?',
            style: const TextStyle(fontSize: 14, color: AppColors.textMid)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal', style: TextStyle(color: AppColors.textLight))),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); onDelete(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error,
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );
  }
}