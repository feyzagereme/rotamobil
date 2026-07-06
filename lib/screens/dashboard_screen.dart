import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/route_provider.dart';
import '../services/vehicle_provider.dart';
import '../theme/app_colors.dart';
import 'address_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _briefingShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndShowBriefing());
  }

  void _checkAndShowBriefing() {
    final provider = context.read<RouteProvider>();
    if (provider.isLoading) {
      provider.addListener(_onProviderUpdate);
    } else {
      _showBriefing();
    }
  }

  void _onProviderUpdate() {
    final provider = context.read<RouteProvider>();
    if (!provider.isLoading && !_briefingShown) {
      provider.removeListener(_onProviderUpdate);
      _showBriefing();
    }
  }

  void _showBriefing() {
    if (_briefingShown || !mounted) return;
    final provider = context.read<RouteProvider>();
    if (provider.addresses.isEmpty) return;
    setState(() => _briefingShown = true);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _DailyBriefingSheet(provider: provider),
      );
    });
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = ['Oca','Şub','Mar','Nis','May','Haz','Tem','Ağu','Eyl','Eki','Kas','Ara'];
    const days = ['Pazartesi','Salı','Çarşamba','Perşembe','Cuma','Cumartesi','Pazar'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
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

        return Scaffold(
          backgroundColor: const Color(0xFF0A1628),
          body: Column(
            children: [
              // ── Gradient header
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
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.55),
                                    fontWeight: FontWeight.w500)),
                            Row(
                              children: [
                                const _VehicleSelector(),
                                const SizedBox(width: 10),
                                if (provider.isLoading)
                                  const SizedBox(width: 16, height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38))
                                else
                                  GestureDetector(
                                    onTap: () => provider.refresh(),
                                    child: Icon(Icons.refresh_rounded,
                                        color: Colors.white.withValues(alpha: 0.55), size: 20),
                                  ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: Icon(Icons.help_outline_rounded,
                                      color: Colors.white.withValues(alpha: 0.55), size: 20),
                                  onPressed: () => _showGuide(context),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text('Bugünün Rotası',
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5)),
                        const SizedBox(height: 24),

                        // ── Donut chart + istatistikler
                        Row(
                          children: [
                            // Sol: dikey istatistikler
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _statRow(Icons.location_on_outlined, 'Toplam', '$total durak'),
                                  const SizedBox(height: 14),
                                  _statRow(Icons.check_circle_outline_rounded, 'Tamamlanan', '$completed durak',
                                      color: AppColors.success),
                                  const SizedBox(height: 14),
                                  _statRow(Icons.pending_outlined, 'Kalan', '${total - completed} durak',
                                      color: const Color(0xFF53D6FF)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Sağ: donut chart
                            SizedBox(
                              width: 110, height: 110,
                              child: CustomPaint(
                                painter: _DonutPainter(
                                  progress: total == 0 ? 0 : pct / 100,
                                  completed: completed,
                                  total: total,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('%${pct.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white)),
                                      Text('tamamlandı',
                                          style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.white.withValues(alpha: 0.5),
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Beyaz içerik
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: provider.isLoading && addresses.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : provider.errorMessage != null && addresses.isEmpty
                          ? _ErrorView(message: provider.errorMessage!, onRetry: provider.refresh)
                          : CustomScrollView(
                              slivers: [
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                                    child: nextAddress != null
                                        ? _NextStopCard(
                                            address: nextAddress,
                                            onTap: () {
                                              final index = addresses.indexOf(nextAddress);
                                              Navigator.push(context,
                                                  MaterialPageRoute(
                                                      builder: (_) => AddressDetailScreen(
                                                          address: nextAddress, index: index)));
                                            },
                                          )
                                        : total > 0
                                            ? _AllDoneCard()
                                            : _EmptyCard(onRetry: provider.refresh),
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('TÜM DURAKLAR',
                                            style: TextStyle(fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textMid,
                                                letterSpacing: 1.2)),
                                        Text('sürükle & sırala',
                                            style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                                      ],
                                    ),
                                  ),
                                ),
                                SliverReorderableList(
                                  itemCount: addresses.length,
                                  onReorder: (o, n) {
                                    HapticFeedback.lightImpact();
                                    provider.reorder(o, n);
                                  },
                                  itemBuilder: (ctx, index) {
                                    final address = addresses[index];
                                    return Material(
                                      key: ValueKey(address.id),
                                      color: Colors.transparent,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                        child: _StopCard(
                                          address: address,
                                          index: index,
                                          onTap: () => Navigator.push(context,
                                              MaterialPageRoute(
                                                  builder: (_) => AddressDetailScreen(
                                                      address: address, index: index))),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SliverToBoxAdapter(child: SizedBox(height: 32)),
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

  Widget _statRow(IconData icon, String label, String value, {Color color = Colors.white}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.8)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w500)),
            Text(value,
                style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

// ── Araç seçici: seçili araca göre rota/filo verisini değiştirir
class _VehicleSelector extends StatelessWidget {
  const _VehicleSelector();

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = context.watch<VehicleProvider>();
    return PopupMenuButton<int>(
      initialValue: vehicleProvider.selectedVehicleId,
      onSelected: (id) => context.read<VehicleProvider>().select(id),
      itemBuilder: (context) => List.generate(
        VehicleProvider.vehicleCount,
        (i) => PopupMenuItem<int>(
          value: i,
          child: Text(vehicleProvider.labelFor(i)),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_shipping_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              vehicleProvider.labelFor(vehicleProvider.selectedVehicleId),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const Icon(Icons.arrow_drop_down_rounded, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// ── Donut chart painter
class _DonutPainter extends CustomPainter {
  final double progress;
  final int completed;
  final int total;
  const _DonutPainter({required this.progress, required this.completed, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 8;
    const strokeW = 10.0;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(cx, cy), radius, trackPaint);

    if (progress > 0) {
      // Progress arc
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [Color(0xFF53D6FF), Color(0xFF22C55E)],
        ).createShader(rect);

      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress;
}

// ── Sonraki durak kartı
class _NextStopCard extends StatelessWidget {
  final dynamic address;
  final VoidCallback onTap;
  const _NextStopCard({required this.address, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D47A1).withValues(alpha: 0.4),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.navigation_rounded, color: Color(0xFF53D6FF), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sonraki Durak',
                      style: TextStyle(fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  const SizedBox(height: 3),
                  Text(address.customerName,
                      style: const TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 3),
                  Text('${address.street}, ${address.district}',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllDoneCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 32),
          SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Harika iş!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.success)),
            Text('Tüm duraklar tamamlandı.', style: TextStyle(fontSize: 12, color: AppColors.textMid)),
          ]),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyCard({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(children: [
        Icon(Icons.route_rounded, size: 40, color: AppColors.textLight),
        const SizedBox(height: 12),
        const Text('Bugün için rota bulunamadı.',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMid)),
        const SizedBox(height: 4),
        const Text('Yönetici tarafından henüz atanmamış olabilir.',
            style: TextStyle(fontSize: 12, color: AppColors.textLight), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Yenile',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0D47A1))),
          ),
        ),
      ]),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textLight),
        const SizedBox(height: 16),
        Text(message,
            style: const TextStyle(fontSize: 14, color: AppColors.textMid),
            textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Tekrar Dene'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D47A1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ]),
    );
  }
}

// ── Durak kartı (glassmorphism)
class _StopCard extends StatelessWidget {
  final dynamic address;
  final int index;
  final VoidCallback onTap;
  const _StopCard({required this.address, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCompleted = address.isCompleted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // Sürükle tutacağı
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
                child: Icon(Icons.drag_handle_rounded,
                    color: AppColors.textLight.withValues(alpha: 0.5), size: 18),
              ),
            ),

            // İnce daire (durum)
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? AppColors.success : const Color(0xFF0D47A1),
                  width: 1.5,
                ),
                color: isCompleted
                    ? AppColors.success.withValues(alpha: 0.08)
                    : Colors.transparent,
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
                    Text('${address.street}, ${address.district}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),

            // Üç nokta menü
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  size: 18, color: AppColors.textLight.withValues(alpha: 0.6)),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'detail') onTap();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'detail',
                  child: Row(children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textMid),
                    SizedBox(width: 10),
                    Text('Detay', style: TextStyle(fontSize: 13)),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Guide Sheet (aynı kalıyor)
class _GuideSheet extends StatefulWidget {
  const _GuideSheet();
  @override
  State<_GuideSheet> createState() => _GuideSheetState();
}

class _GuideSheetState extends State<_GuideSheet> {
  int _selectedSection = 0;

  static const _sections = [
    _GuideSection(icon: Icons.route_rounded, title: 'Rota', color: AppColors.accent, items: [
      _GuideItem(Icons.dashboard_rounded, 'Ana Ekran', 'Bugünün rotası, sonraki durak ve ilerleme durumunu görürsün.'),
      _GuideItem(Icons.drag_handle_rounded, 'Sıralama', '≡ ikonuna basılı tutup sürükleyerek rota sırasını değiştirebilirsin.'),
      _GuideItem(Icons.sync_rounded, 'Haritaya Yansıma', 'Sıra değiştiğinde harita otomatik güncellenir.'),
    ]),
    _GuideSection(icon: Icons.map_rounded, title: 'Harita', color: AppColors.success, items: [
      _GuideItem(Icons.touch_app_rounded, 'Adres Ekle', 'Haritada boş bir yere dokun, adres bilgisi otomatik gelir.'),
      _GuideItem(Icons.location_on_rounded, 'Marker', 'Haritadaki numaralı noktalara tıklayarak adres detayını görebilirsin.'),
      _GuideItem(Icons.navigation_rounded, 'Navigasyon', 'Adres detayında "Navigasyonu Başlat" ile Google Maps açılır.'),
    ]),
    _GuideSection(icon: Icons.check_circle_rounded, title: 'Ziyaret', color: AppColors.warning, items: [
      _GuideItem(Icons.info_rounded, 'Adres Detayı', 'Listedeki veya haritadaki herhangi bir adrese tıklayarak detay sayfasını açabilirsin.'),
      _GuideItem(Icons.check_rounded, 'Tamamlandı', 'Detay sayfasında "Ziyareti Tamamlandı İşaretle" butonuna bas.'),
      _GuideItem(Icons.notes_rounded, 'Notlar', 'Adres detayında not ekleyip düzenleyebilirsin.'),
    ]),
    _GuideSection(icon: Icons.person_rounded, title: 'Profil', color: AppColors.textLight, items: [
      _GuideItem(Icons.bar_chart_rounded, 'Özet', 'Profil ekranında bugünün tamamlanan ve kalan adres sayısını görürsün.'),
      _GuideItem(Icons.settings_rounded, 'Ayarlar', 'Bildirim, GPS ve sesli rehber tercihlerini buradan yönetebilirsin.'),
      _GuideItem(Icons.logout_rounded, 'Çıkış', 'Profil ekranının altından hesabından çıkış yapabilirsin.'),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final section = _sections[_selectedSection];
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFFF0F4F8),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(children: [
        Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.stroke, borderRadius: BorderRadius.circular(2))),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(children: [
            Icon(Icons.menu_book_rounded, size: 20, color: AppColors.textMid),
            SizedBox(width: 8),
            Text('Kullanıcı Kılavuzu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          ]),
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
                    border: Border.all(color: isActive ? s.color : AppColors.stroke, width: 1.5),
                  ),
                  child: Row(children: [
                    Icon(s.icon, size: 16, color: isActive ? s.color : AppColors.textLight),
                    const SizedBox(width: 6),
                    Text(s.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: isActive ? s.color : AppColors.textLight)),
                  ]),
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
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                          color: section.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(item.icon, size: 20, color: section.color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.title, style: const TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w700, color: AppColors.textDark)),
                      const SizedBox(height: 4),
                      Text(item.description, style: const TextStyle(fontSize: 13,
                          color: AppColors.textMid, height: 1.5)),
                    ])),
                  ]),
                );
              },
            ),
          ),
        ),
      ]),
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

// ── Günlük Özet Bottom Sheet
class _DailyBriefingSheet extends StatelessWidget {
  final RouteProvider provider;
  const _DailyBriefingSheet({required this.provider});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın!';
    if (hour < 18) return 'İyi günler!';
    return 'İyi akşamlar!';
  }

  String _todayFull() {
    final now = DateTime.now();
    const months = ['Ocak','Şubat','Mart','Nisan','Mayıs','Haziran',
        'Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'];
    const days = ['Pazartesi','Salı','Çarşamba','Perşembe','Cuma','Cumartesi','Pazar'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final total = provider.totalStops;
    final completed = provider.completedStops;
    final nextAddress = provider.addresses.where((a) => !a.isCompleted).isNotEmpty
        ? provider.addresses.firstWhere((a) => !a.isCompleted)
        : null;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A1628),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tutamaç
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst kısım
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting(),
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w800,
                                color: Colors.white, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text(_todayFull(),
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.5))),
                      ],
                    ),
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF53D6FF).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF53D6FF).withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.route_rounded,
                          color: Color(0xFF53D6FF), size: 26),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Stat satırları
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      _statRow('Toplam Durak', '$total durak', Icons.location_on_rounded, Colors.white),
                      const SizedBox(height: 12),
                      _statRow('Tamamlanan', '$completed durak', Icons.check_circle_rounded, AppColors.success),
                      const SizedBox(height: 12),
                      _statRow('Kalan', '${total - completed} durak', Icons.pending_rounded, const Color(0xFF53D6FF)),
                    ],
                  ),
                ),

                if (nextAddress != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF53D6FF).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.navigation_rounded,
                              color: Color(0xFF53D6FF), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('İlk Durak',
                                  style: TextStyle(fontSize: 11,
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontWeight: FontWeight.w600)),
                              Text(nextAddress.customerName,
                                  style: const TextStyle(fontSize: 13,
                                      fontWeight: FontWeight.w700, color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Başlat butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF53D6FF),
                      foregroundColor: const Color(0xFF0A1628),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Rotayı Başlat',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color, ),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.55))),
        const Spacer(),
        Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}