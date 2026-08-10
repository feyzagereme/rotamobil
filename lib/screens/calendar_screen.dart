import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../services/route_provider.dart';
import '../models/address_model.dart';
import '../theme/app_colors.dart';
import 'address_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _currentWeekStart;
  late DateTime _selectedDay;

  // Geçmiş/gelecek tarih rotaları
  List<dynamic> _historyRoutes = [];
  bool _isLoadingHistory = false;
  String? _historyError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    _selectedDay = now;
    _fetchHistory();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  bool _isToday(DateTime d) => _isSameDay(d, DateTime.now());
  bool get _isSelectedToday => _isSameDay(_selectedDay, DateTime.now());

  Future<void> _fetchHistory() async {
    setState(() { _isLoadingHistory = true; _historyError = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) {
        if (mounted) setState(() => _isLoadingHistory = false);
        return;
      }
      final response = await http.get(
        Uri.parse('${AppConfig.backendBaseUrl}/routes/$userId'),
        headers: await AuthService.authHeaders(),
      ).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _historyRoutes = jsonDecode(response.body) as List<dynamic>;
          _isLoadingHistory = false;
        });
      } else {
        setState(() { _isLoadingHistory = false; _historyError = 'Geçmiş rotalar alınamadı (${response.statusCode})'; });
      }
    } catch (_) {
      if (mounted) setState(() { _isLoadingHistory = false; _historyError = 'Sunucuya bağlanılamadı'; });
    }
  }

  /// Seçili güne ait rotanın duraklarını döner.
  List<Address> _addressesForDay(DateTime day) {
    for (final route in _historyRoutes) {
      final createdRaw = route['created_at'];
      if (createdRaw == null) continue;
      final dt = DateTime.tryParse(createdRaw.toString());
      if (dt == null) continue;
      if (dt.year != day.year || dt.month != day.month || dt.day != day.day) continue;

      final routeJson = (route['route_json'] as Map?)?.cast<String, dynamic>() ?? {};
      final stopsRaw = routeJson['stops'] ?? routeJson['addresses'];
      if (stopsRaw is! List) return [];
      return stopsRaw
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList()
          .asMap()
          .entries
          .map((e) => Address.fromRouteStop(e.value, fallbackOrder: e.key + 1))
          .where((a) => a.latitude != 0 && a.longitude != 0)
          .toList()
        ..sort((a, b) => a.orderNumber.compareTo(b.orderNumber));
    }
    return [];
  }

  /// O güne ait herhangi bir rota var mı? (takvimde nokta göstermek için)
  bool _hasRouteForDay(DateTime day) {
    if (_isSameDay(day, DateTime.now())) return true; // bugün için provider'dan bakılır
    for (final route in _historyRoutes) {
      final dt = DateTime.tryParse((route['created_at'] ?? '').toString());
      if (dt != null && _isSameDay(dt, day)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = List.generate(7, (i) => _currentWeekStart.add(Duration(days: i)));

    return Consumer<RouteProvider>(
      builder: (context, provider, _) {
        final addresses = _isSelectedToday
            ? provider.addresses
            : _addressesForDay(_selectedDay);
        final completed = addresses.where((a) => a.isCompleted).length;
        final total = addresses.length;

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
                            Text('TAKVİM',
                                style: TextStyle(fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.55),
                                    fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                            Row(children: [
                              _navBtn(Icons.chevron_left_rounded, () {
                                setState(() => _currentWeekStart =
                                    _currentWeekStart.subtract(const Duration(days: 7)));
                              }),
                              const SizedBox(width: 8),
                              Text(
                                '${DateFormat('d MMM', 'tr_TR').format(weekDays.first)} – ${DateFormat('d MMM', 'tr_TR').format(weekDays.last)}',
                                style: TextStyle(fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 8),
                              _navBtn(Icons.chevron_right_rounded, () {
                                setState(() => _currentWeekStart =
                                    _currentWeekStart.add(const Duration(days: 7)));
                              }),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text('Takvim',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                                color: Colors.white, letterSpacing: -0.5)),
                        const SizedBox(height: 20),

                        // ── Haftalık seçici
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 7,
                            itemBuilder: (context, i) {
                              final day = weekDays[i];
                              final isSelected = _isSameDay(day, _selectedDay);
                              final isToday = _isToday(day);
                              final hasRoute = _hasRouteForDay(day);

                              return GestureDetector(
                                onTap: () => setState(() => _selectedDay = day),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 42,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(21),
                                    border: isSelected
                                        ? Border.all(
                                            color: const Color(0xFF53D6FF).withValues(alpha: 0.6),
                                            width: 1.5)
                                        : null,
                                    boxShadow: isSelected
                                        ? [BoxShadow(
                                            color: const Color(0xFF53D6FF).withValues(alpha: 0.3),
                                            blurRadius: 12, spreadRadius: -2,
                                          )]
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        DateFormat('E', 'tr_TR').format(day).substring(0, 2).toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                                          color: isSelected
                                              ? const Color(0xFF53D6FF)
                                              : Colors.white.withValues(alpha: 0.4),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        day.day.toString(),
                                        style: TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.w800,
                                          color: isSelected
                                              ? Colors.white
                                              : isToday
                                                  ? const Color(0xFF53D6FF)
                                                  : Colors.white.withValues(alpha: 0.5),
                                        ),
                                      ),
                                      // Bugün noktası VEYA o günde rota varsa renkli nokta
                                      if (isToday || hasRoute)
                                        Container(
                                          width: 4, height: 4,
                                          margin: const EdgeInsets.only(top: 3),
                                          decoration: BoxDecoration(
                                            color: isToday
                                                ? const Color(0xFF53D6FF)
                                                : AppColors.success,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(DateFormat('EEEE', 'tr_TR').format(_selectedDay),
                                  style: const TextStyle(fontSize: 12,
                                      color: AppColors.textLight, fontWeight: FontWeight.w600)),
                              Text(DateFormat('d MMMM yyyy', 'tr_TR').format(_selectedDay),
                                  style: const TextStyle(fontSize: 18,
                                      fontWeight: FontWeight.w800, color: AppColors.textDark)),
                            ]),
                            Row(children: [
                              if (_isSelectedToday)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                                  ),
                                  child: const Text('Bugün',
                                      style: TextStyle(fontSize: 12,
                                          color: AppColors.success, fontWeight: FontWeight.w600)),
                                ),
                              if (_isLoadingHistory) ...[
                                const SizedBox(width: 8),
                                const SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                                ),
                              ],
                              if (_historyError != null && !_isSelectedToday) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _fetchHistory,
                                  child: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.error),
                                ),
                              ],
                            ]),
                          ],
                        ),

                        // ── İlerleme kartı (hem bugün hem geçmiş tarihler için)
                        if (total > 0) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0A1628), Color(0xFF0D47A1)],
                                begin: Alignment.topLeft, end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(
                                color: const Color(0xFF0D47A1).withValues(alpha: 0.3),
                                blurRadius: 16, offset: const Offset(0, 6),
                              )],
                            ),
                            child: Column(children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Rota İlerlemesi',
                                      style: TextStyle(fontSize: 13,
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontWeight: FontWeight.w600)),
                                  Text('$completed/$total',
                                      style: const TextStyle(fontSize: 13,
                                          color: Color(0xFF53D6FF), fontWeight: FontWeight.w700)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: total == 0 ? 0 : completed / total,
                                  minHeight: 6,
                                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                                  valueColor: AlwaysStoppedAnimation(
                                      completed == total && total > 0
                                          ? AppColors.success
                                          : const Color(0xFF53D6FF)),
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _isSelectedToday ? 'GÜNÜN ROTASI' : 'O GÜNÜN ROTASI',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                color: AppColors.textLight.withValues(alpha: 0.8),
                                letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 10),
                          ...addresses.asMap().entries.map((e) =>
                              _addressItem(context, e.key, e.value, readOnly: !_isSelectedToday)),

                        ] else if (_isLoadingHistory && !_isSelectedToday) ...[
                          const SizedBox(height: 48),
                          const Center(
                            child: CircularProgressIndicator(color: AppColors.accent),
                          ),
                        ] else ...[
                          const SizedBox(height: 48),
                          Center(
                            child: Column(children: [
                              Container(
                                width: 72, height: 72,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D47A1).withValues(alpha: 0.07),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.event_available_rounded,
                                    size: 34, color: AppColors.textLight),
                              ),
                              const SizedBox(height: 16),
                              const Text('Bu güne ait rota yok',
                                  style: TextStyle(fontSize: 15,
                                      fontWeight: FontWeight.w700, color: AppColors.textMid)),
                              const SizedBox(height: 6),
                              const Text('Rotalar web uygulamasından oluşturulur',
                                  style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                            ]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _addressItem(BuildContext context, int index, Address address, {bool readOnly = false}) {
    final isCompleted = address.isCompleted;
    return GestureDetector(
      onTap: readOnly
          ? null // Geçmiş rota detayına giremez (index artık geçersiz olabilir)
          : () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => AddressDetailScreen(address: address, index: index))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: readOnly
              ? Colors.white.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
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
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(address.customerName,
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: isCompleted || readOnly ? AppColors.textLight : AppColors.textDark,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    )),
                const SizedBox(height: 3),
                Text('${address.street}, ${address.district}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            if (!readOnly)
              const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.7)),
      ),
    );
  }
}
