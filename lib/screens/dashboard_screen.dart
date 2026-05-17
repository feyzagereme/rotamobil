import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/route_provider.dart';
import '../models/address_model.dart';
import 'address_detail_screen.dart';

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

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

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
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_todayLabel(),
                        style: const TextStyle(fontSize: 11, color: _C.textLight)),
                    const Text('Bugünün Rotası',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _C.textDark)),
                  ],
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _C.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$completed/$total Tamamlandı',
                        style: const TextStyle(fontSize: 12, color: _C.accentDark, fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline_rounded, color: _C.textLight),
                    onPressed: () => _showGuide(context),
                    tooltip: 'Nasıl Kullanılır?',
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── İlerleme kartı ─────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _C.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _C.stroke),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Günlük İlerleme',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _C.textDark)),
                                Text('%${pct.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _C.accent)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                minHeight: 8,
                                backgroundColor: _C.stroke,
                                valueColor: AlwaysStoppedAnimation(pct == 100 ? _C.success : _C.accent),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _statBox(Icons.location_on_rounded, total.toString(), 'Toplam Adres'),
                                const SizedBox(width: 10),
                                _statBox(Icons.check_circle_rounded, completed.toString(), 'Tamamlanan', color: _C.success),
                                const SizedBox(width: 10),
                                _statBox(Icons.straighten_rounded, '44.7 km', 'Mesafe'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Sonraki durak ───────────────────────────────────
                      if (nextAddress != null) ...[
                        const Text('Sonraki Durak',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                color: _C.textMid, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _C.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _C.stroke),
                            boxShadow: [
                              BoxShadow(color: _C.accent.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: _C.accent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.navigation_rounded, color: _C.accent, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(nextAddress.customerName,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _C.textDark)),
                                    const SizedBox(height: 3),
                                    Text('${nextAddress.street}, ${nextAddress.district}',
                                        style: const TextStyle(fontSize: 12, color: _C.textMid),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 3),
                                    const Text('2,3 km  •  ~12 dk',
                                        style: TextStyle(fontSize: 11, color: _C.textLight)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: _C.textLight),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.map_rounded, size: 18),
                                label: const Text('Haritayı Aç'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _C.accentDark,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.call_rounded, size: 18),
                                label: const Text('Ara'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _C.accentDark,
                                  side: const BorderSide(color: _C.stroke, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _C.success.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _C.success.withOpacity(0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: _C.success, size: 28),
                              SizedBox(width: 14),
                              Text('Tüm adresler tamamlandı!',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _C.success)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Rota listesi ────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Rota Listesi ($total Adres)',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                  color: _C.textMid, letterSpacing: 0.5)),
                          const Text('Tümünü gör',
                              style: TextStyle(fontSize: 12, color: _C.accent, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...addresses.take(4).toList().asMap().entries.map(
                        (e) => _routeItem(e.key, e.value, context),
                      ),
                      if (total > 4)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Center(
                            child: Text('Ve ${total - 4} adres daha...',
                                style: const TextStyle(fontSize: 12, color: _C.textLight)),
                          ),
                        ),
                      const SizedBox(height: 24),
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

  Widget _statBox(IconData icon, String value, String label, {Color color = _C.accent}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: _C.textLight)),
          ],
        ),
      ),
    );
  }

  Widget _routeItem(int index, Address address, BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddressDetailScreen(address: address, index: index),
        ),
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: address.isCompleted ? _C.success.withOpacity(0.12) : _C.accent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: address.isCompleted
                  ? const Icon(Icons.check_rounded, size: 16, color: _C.success)
                  : Text('${index + 1}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _C.accent)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(address.customerName,
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: address.isCompleted ? _C.textLight : _C.textDark,
                      decoration: address.isCompleted ? TextDecoration.lineThrough : null,
                    )),
                const SizedBox(height: 2),
                Text('${address.street}, ${address.district}',
                    style: const TextStyle(fontSize: 11, color: _C.textLight),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (!address.isCompleted)
            const Icon(Icons.chevron_right_rounded, color: _C.textLight, size: 18),
        ],
      ),
    ),
    );
  }
}

// ── Kullanıcı Kılavuzu BottomSheet ────────────────────────────────────────────
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
      color: Color(0xFF53D6FF),
      items: [
        _GuideItem(Icons.dashboard_rounded, 'Ana Ekran', 'Bugünün rotası, sonraki durak ve ilerleme durumunu görürsün.'),
        _GuideItem(Icons.list_rounded, 'Liste Ekranı', 'Tüm adresleri görürsün. Basılı tutup sürükleyerek sırayı değiştirebilirsin.'),
        _GuideItem(Icons.sync_rounded, 'Otomatik Hesaplama', 'Sıra değiştiğinde rota süresi otomatik yeniden hesaplanır.'),
      ],
    ),
    _GuideSection(
      icon: Icons.map_rounded,
      title: 'Harita',
      color: Color(0xFF22C55E),
      items: [
        _GuideItem(Icons.touch_app_rounded, 'Adres Ekle', 'Haritada boş bir yere dokun, adres bilgisi otomatik gelir.'),
        _GuideItem(Icons.location_on_rounded, 'Marker', 'Haritadaki numaralı noktalara tıklayarak adres detayını görebilirsin.'),
        _GuideItem(Icons.navigation_rounded, 'Navigasyon', 'Adres detayında "Navigasyonu Başlat" ile Google Maps açılır.'),
      ],
    ),
    _GuideSection(
      icon: Icons.check_circle_rounded,
      title: 'Ziyaret',
      color: Color(0xFFF59E0B),
      items: [
        _GuideItem(Icons.info_rounded, 'Adres Detayı', 'Listedeki veya haritadaki herhangi bir adrese tıklayarak detay sayfasını açabilirsin.'),
        _GuideItem(Icons.check_rounded, 'Tamamlandı', 'Detay sayfasında "Ziyareti Tamamlandı İşaretle" butonuna bas.'),
        _GuideItem(Icons.notes_rounded, 'Notlar', 'Adres detayında not ekleyip düzenleyebilirsin.'),
      ],
    ),
    _GuideSection(
      icon: Icons.person_rounded,
      title: 'Profil',
      color: Color(0xFF9DAFC8),
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
        color: Color(0xFFF0F4F8),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Tutaç
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Başlık
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded, size: 20, color: Color(0xFF5A6A85)),
                SizedBox(width: 8),
                Text('Kullanıcı Kılavuzu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A2236))),
              ],
            ),
          ),
          // Kategori sekmeleri
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
                      color: isActive ? s.color.withOpacity(0.15) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive ? s.color : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(s.icon, size: 16, color: isActive ? s.color : const Color(0xFF9DAFC8)),
                        const SizedBox(width: 6),
                        Text(s.title,
                            style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: isActive ? s.color : const Color(0xFF9DAFC8),
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Kılavuz maddeleri
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: section.color.withOpacity(0.1),
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
                                    color: Color(0xFF1A2236),
                                  )),
                              const SizedBox(height: 4),
                              Text(item.description,
                                  style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF5A6A85), height: 1.5,
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