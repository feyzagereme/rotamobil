import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/route_provider.dart';
import '../theme/app_colors.dart';
import 'address_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _bannerVisible = true;

  String _todayLabel() {
    final now = DateTime.now();
    const months = ['Oca','Şub','Mar','Nis','May','Haz','Tem','Ağu','Eyl','Eki','Kas','Ara'];
    const days = ['Pazartesi','Salı','Çarşamba','Perşembe','Cuma','Cumartesi','Pazar'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  void _showGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _GuideSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RouteProvider>(
      builder: (context, provider, _) {
        final addresses = provider.addresses;
        final completed = provider.completedStops;
        final total = provider.totalStops;
        final pct = provider.completionPercentage;
        final nextAddress = addresses.where((a) => !a.isCompleted).isNotEmpty
            ? addresses.firstWhere((a) => !a.isCompleted)
            : null;
        final hasRoute = total > 0;

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
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_todayLabel(),
                        style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                    const Text('Bugünün Rotası',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  ],
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$completed/$total Tamamlandı',
                        style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    icon: provider.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, color: AppColors.textLight),
                    onPressed: provider.isLoading ? null : provider.refresh,
                    tooltip: 'Rotayı Yenile',
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline_rounded, color: AppColors.textLight),
                    onPressed: () => _showGuide(context),
                    tooltip: 'Nasıl Kullanılır?',
                  ),
                ],
              ),
              // ── Araç rotası bildirimi
              if (_bannerVisible && hasRoute)
                SliverToBoxAdapter(
                  child: _RouteBanner(
                    routeName: provider.activeRouteName ?? 'Aktif Rota',
                    addressCount: total,
                    onDismiss: () => setState(() => _bannerVisible = false),
                  ),
                ),

              if (provider.errorMessage != null && !hasRoute)
                SliverToBoxAdapter(
                  child: _InfoBanner(
                    message: provider.errorMessage!,
                    onRefresh: provider.refresh,
                  ),
                ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── İlerleme kartı
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.stroke),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Günlük İlerleme',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                                Text('%${pct.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                minHeight: 8,
                                backgroundColor: AppColors.stroke,
                                valueColor: AlwaysStoppedAnimation(pct == 100 ? AppColors.success : AppColors.accent),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _statBox(Icons.location_on_rounded, total.toString(), 'Toplam Adres'),
                                const SizedBox(width: 10),
                                _statBox(Icons.check_circle_rounded, completed.toString(), 'Tamamlanan', color: AppColors.success),
                                const SizedBox(width: 10),
                                _statBox(Icons.route_rounded, provider.activeRouteName ?? '-', 'Rota'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Sonraki durak
                      if (nextAddress != null) ...[
                        const Text('Sonraki Durak',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                color: AppColors.textMid, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            final index = addresses.indexOf(nextAddress);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddressDetailScreen(address: nextAddress, index: index),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.stroke),
                              boxShadow: [
                                BoxShadow(color: AppColors.accent.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.navigation_rounded, color: AppColors.accent, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(nextAddress.customerName,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                                      const SizedBox(height: 3),
                                      Text('${nextAddress.street}, ${nextAddress.district}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textMid),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 3),
                                      Text('Sıra: ${nextAddress.orderNumber}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: hasRoute
                                ? AppColors.success.withValues(alpha: 0.08)
                                : AppColors.accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: hasRoute
                                  ? AppColors.success.withValues(alpha: 0.3)
                                  : AppColors.accent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                hasRoute ? Icons.check_circle_rounded : Icons.route_rounded,
                                color: hasRoute ? AppColors.success : AppColors.accent,
                                size: 28,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  hasRoute ? 'Tüm adresler tamamlandı!' : 'Henüz aktif rota yok. Web panelden rota atanınca burada görünecek.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: hasRoute ? AppColors.success : AppColors.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Rota listesi başlığı
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Rota ($total Adres)',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                  color: AppColors.textMid, letterSpacing: 0.5)),
                          const Text('Sürükleyerek sırayla',
                              style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              // ── Sürüklenebilir rota listesi
              SliverReorderableList(
                itemCount: addresses.length,
                onReorderItem: provider.reorder,
                itemBuilder: (ctx, index) {
                  final address = addresses[index];
                  return Material(
                    key: ValueKey(address.id),
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.stroke),
                        ),
                        child: Row(
                          children: [
                            ReorderableDragStartListener(
                              index: index,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                child: Icon(Icons.drag_handle_rounded, color: AppColors.textLight, size: 20),
                              ),
                            ),
                            Container(
                              width: 30, height: 30,
                              decoration: BoxDecoration(
                                color: address.isCompleted
                                    ? AppColors.success.withValues(alpha: 0.12)
                                    : AppColors.accent.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: address.isCompleted
                                    ? const Icon(Icons.check_rounded, size: 16, color: AppColors.success)
                                    : Text('${index + 1}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddressDetailScreen(address: address, index: index),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(address.customerName,
                                          style: TextStyle(
                                            fontSize: 13, fontWeight: FontWeight.w600,
                                            color: address.isCompleted ? AppColors.textLight : AppColors.textDark,
                                            decoration: address.isCompleted ? TextDecoration.lineThrough : null,
                                          )),
                                      const SizedBox(height: 2),
                                      Text('${address.street}, ${address.district}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (!address.isCompleted)
                              const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 18),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }

  Widget _statBox(IconData icon, String value, String label, {Color color = AppColors.accent}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String message;
  final Future<void> Function() onRefresh;

  const _InfoBanner({required this.message, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: AppColors.textMid),
            ),
          ),
          TextButton(
            onPressed: onRefresh,
            child: const Text('Yenile'),
          ),
        ],
      ),
    );
  }
}

// ── Araç rotası bildirim banner'ı
class _RouteBanner extends StatelessWidget {
  final String routeName;
  final int addressCount;
  final VoidCallback onDismiss;

  const _RouteBanner({required this.routeName, required this.addressCount, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_shipping_rounded, color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routeName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$addressCount adres · Bugün için hazır',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.5), size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kullanıcı Kılavuzu BottomSheet
class _GuideSheet extends StatefulWidget {
  const _GuideSheet();

  @override
  State<_GuideSheet> createState() => _GuideSheetState();
}

class _GuideSheetState extends State<_GuideSheet> {
  int _selectedSection = 0;

  static const _sections = [
    _GuideSection(
      icon: Icons.route_rounded,
      title: 'Rota',
      color: AppColors.accent,
      items: [
        _GuideItem(Icons.dashboard_rounded, 'Ana Ekran', 'Bugünün rotası, sonraki durak ve ilerleme durumunu görürsün.'),
        _GuideItem(Icons.drag_handle_rounded, 'Sıralama', '≡ ikonuna basılı tutup sürükleyerek rota sırasını değiştirebilirsin.'),
        _GuideItem(Icons.sync_rounded, 'Haritaya Yansıma', 'Sıra değiştiğinde harita otomatik güncellenir.'),
      ],
    ),
    _GuideSection(
      icon: Icons.map_rounded,
      title: 'Harita',
      color: AppColors.success,
      items: [
        _GuideItem(Icons.touch_app_rounded, 'Adres Ekle', 'Haritada boş bir yere dokun, adres bilgisi otomatik gelir.'),
        _GuideItem(Icons.location_on_rounded, 'Marker', 'Haritadaki numaralı noktalara tıklayarak adres detayını görebilirsin.'),
        _GuideItem(Icons.navigation_rounded, 'Navigasyon', 'Adres detayında "Navigasyonu Başlat" ile Google Maps açılır.'),
      ],
    ),
    _GuideSection(
      icon: Icons.check_circle_rounded,
      title: 'Ziyaret',
      color: AppColors.warning,
      items: [
        _GuideItem(Icons.info_rounded, 'Adres Detayı', 'Listedeki veya haritadaki herhangi bir adrese tıklayarak detay sayfasını açabilirsin.'),
        _GuideItem(Icons.check_rounded, 'Tamamlandı', 'Detay sayfasında "Ziyareti Tamamlandı İşaretle" butonuna bas.'),
        _GuideItem(Icons.notes_rounded, 'Notlar', 'Adres detayında not ekleyip düzenleyebilirsin.'),
      ],
    ),
    _GuideSection(
      icon: Icons.person_rounded,
      title: 'Profil',
      color: AppColors.textLight,
      items: [
        _GuideItem(Icons.bar_chart_rounded, 'Özet', 'Profil ekranında bugünün tamamlanan ve kalan adres sayısını görürsün.'),
        _GuideItem(Icons.settings_rounded, 'Ayarlar', 'Bildirim, GPS ve sesli rehber tercihlerini buradan yönetebilirsin.'),
        _GuideItem(Icons.logout_rounded, 'Çıkış', 'Profil ekranının altından hesabından çıkış yapabilirsin.'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final section = _sections[_selectedSection];

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.stroke,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded, size: 20, color: AppColors.textMid),
                SizedBox(width: 8),
                Text('Kullanıcı Kılavuzu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _sections.length,
              itemBuilder: (ctx, i) {
                final s = _sections[i];
                final isActive = i == _selectedSection;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSection = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8, bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? s.color.withValues(alpha: 0.15) : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive ? s.color : AppColors.stroke,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(s.icon, size: 16, color: isActive ? s.color : AppColors.textLight),
                        const SizedBox(width: 6),
                        Text(s.title,
                            style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: isActive ? s.color : AppColors.textLight,
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: ListView.builder(
                key: ValueKey(_selectedSection),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: section.items.length,
                itemBuilder: (ctx, i) {
                  final item = section.items[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.stroke),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: section.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(item.icon, size: 20, color: section.color),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title,
                                  style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  )),
                              const SizedBox(height: 4),
                              Text(item.description,
                                  style: const TextStyle(
                                    fontSize: 13, color: AppColors.textMid, height: 1.5,
                                  )),
                            ],
                          ),
                        ),
                      ],
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

class _GuideSection {
  final IconData icon;
  final String title;
  final Color color;
  final List<_GuideItem> items;
  const _GuideSection({required this.icon, required this.title, required this.color, required this.items});
}

class _GuideItem {
  final IconData icon;
  final String title;
  final String description;
  const _GuideItem(this.icon, this.title, this.description);
}
