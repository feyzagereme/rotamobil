import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _currentWeekStart;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    _selectedDay = now;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isToday(DateTime d) => _isSameDay(d, DateTime.now());

  // Seçili gün bugün mü — bugünse provider adreslerini göster, değilse boş
  bool get _isSelectedToday => _isSameDay(_selectedDay, DateTime.now());

  @override
  Widget build(BuildContext context) {
    final weekDays = List.generate(7, (i) => _currentWeekStart.add(Duration(days: i)));

    return Consumer<RouteProvider>(
      builder: (context, provider, _) {
        final addresses = _isSelectedToday ? provider.addresses : <Address>[];
        final completed = addresses.where((a) => a.isCompleted).length;
        final total = addresses.length;

        return Scaffold(
          backgroundColor: _C.bg,
          body: Column(
            children: [
              // ── App Bar ──────────────────────────────────────────────
              Container(
                color: _C.surface,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Takvim',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _C.textDark)),
                            // Hafta navigasyonu
                            Row(
                              children: [
                                _navButton(Icons.chevron_left_rounded, () {
                                  setState(() {
                                    _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
                                  });
                                }),
                                const SizedBox(width: 4),
                                Text(
                                  '${DateFormat('d MMM', 'tr_TR').format(weekDays.first)} – ${DateFormat('d MMM', 'tr_TR').format(weekDays.last)}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.textMid),
                                ),
                                const SizedBox(width: 4),
                                _navButton(Icons.chevron_right_rounded, () {
                                  setState(() {
                                    _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
                                  });
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Haftalık gün seçici ───────────────────────────
                      SizedBox(
                        height: 76,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: 7,
                          itemBuilder: (context, i) {
                            final day = weekDays[i];
                            final isSelected = _isSameDay(day, _selectedDay);
                            final isToday = _isToday(day);

                            return GestureDetector(
                              onTap: () => setState(() => _selectedDay = day),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 44,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: isSelected ? _C.accentDark : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? _C.accentDark
                                        : isToday
                                            ? _C.accent
                                            : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat('E', 'tr_TR').format(day).substring(0, 2).toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? Colors.white.withOpacity(0.7) : _C.textLight,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      day.day.toString(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected
                                            ? Colors.white
                                            : isToday
                                                ? _C.accent
                                                : _C.textDark,
                                      ),
                                    ),
                                    // Bugün noktası
                                    if (isToday && !isSelected)
                                      Container(
                                        width: 4, height: 4,
                                        decoration: const BoxDecoration(color: _C.accent, shape: BoxShape.circle),
                                      )
                                    else
                                      const SizedBox(height: 4),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(height: 1, color: _C.stroke),
                    ],
                  ),
                ),
              ),

              // ── İçerik ───────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Seçili gün başlığı
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE', 'tr_TR').format(_selectedDay),
                                style: const TextStyle(fontSize: 12, color: _C.textLight, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                DateFormat('d MMMM yyyy', 'tr_TR').format(_selectedDay),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _C.textDark),
                              ),
                            ],
                          ),
                          if (_isSelectedToday)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _C.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _C.success.withOpacity(0.3)),
                              ),
                              child: const Text('Bugün',
                                  style: TextStyle(fontSize: 12, color: _C.success, fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_isSelectedToday) ...[
                        // İstatistikler
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _C.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _C.stroke),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Rota İlerlemesi',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.textDark)),
                                  Text('$completed/$total',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _C.accent)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: total == 0 ? 0 : completed / total,
                                  minHeight: 6,
                                  backgroundColor: _C.stroke,
                                  valueColor: AlwaysStoppedAnimation(
                                    completed == total && total > 0 ? _C.success : _C.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Adres listesi
                        const Text('GÜNÜN ROTASI',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                color: _C.textLight, letterSpacing: 1.0)),
                        const SizedBox(height: 10),

                        ...addresses.asMap().entries.map((e) => _addressItem(context, e.key, e.value)),
                      ] else ...[
                        // Başka gün seçildi
                        Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: _C.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _C.stroke),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.event_available_rounded, size: 48,
                                  color: _C.textLight.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              const Text('Bu güne ait rota yok',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _C.textMid)),
                              const SizedBox(height: 6),
                              const Text('Rotalar web uygulamasından oluşturulur',
                                  style: TextStyle(fontSize: 12, color: _C.textLight)),
                            ],
                          ),
                        ),
                      ],

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

  Widget _addressItem(BuildContext context, int index, Address address) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddressDetailScreen(address: address, index: index),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: address.isCompleted ? _C.success.withOpacity(0.3) : _C.stroke,
          ),
        ),
        child: Row(
          children: [
            // Zaman çizelgesi sol taraf
            Column(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: address.isCompleted
                        ? _C.success.withOpacity(0.12)
                        : _C.accent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: address.isCompleted
                        ? const Icon(Icons.check_rounded, size: 14, color: _C.success)
                        : Text('${index + 1}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _C.accent)),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.customerName,
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: address.isCompleted ? _C.textLight : _C.textDark,
                      decoration: address.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text('${address.street}, ${address.district}',
                      style: const TextStyle(fontSize: 11, color: _C.textLight),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _C.textLight, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: _C.bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: _C.textMid),
      ),
    );
  }
}