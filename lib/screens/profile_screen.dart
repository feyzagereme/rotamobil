import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/mock_data_service.dart';
import '../models/driver_model.dart';
import '../models/route_model.dart' as route_models;

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
  static const error     = Color(0xFFE53935);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Driver driver;
  late route_models.Route todayRoute;
  late bool notificationsEnabled;
  late bool gpsEnabled;
  late bool voiceGuidanceEnabled;
  String _username = '';

  @override
  void initState() {
    super.initState();
    driver = MockDataService.getMockDriver();
    todayRoute = MockDataService.getTodayRoute();
    notificationsEnabled = driver.notificationsEnabled;
    gpsEnabled = driver.gpsEnabled;
    voiceGuidanceEnabled = driver.voiceGuidanceEnabled;
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final username = await AuthService.getUsername();
    if (mounted) setState(() => _username = username.isNotEmpty ? username : 'Misafir');
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Çıkış Yap',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _C.textDark)),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
            style: TextStyle(fontSize: 14, color: _C.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal', style: TextStyle(color: _C.textMid)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  String _todayDate() {
    final now = DateTime.now();
    const months = ['Ocak','Şubat','Mart','Nisan','Mayıs','Haziran',
                    'Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final initials = _username.isNotEmpty ? _username[0].toUpperCase() : 'M';
    final completed = todayRoute.completedStops;
    final total = todayRoute.totalStops;
    final pct = todayRoute.completionPercentage;

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
            title: const Text('Profil',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _C.textDark)),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Profil başlığı ──────────────────────────────────────
                Container(
                  color: _C.surface,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _C.accent.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: _C.stroke, width: 1.5),
                        ),
                        child: Center(
                          child: Text(initials,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _C.accentDark)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_username,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _C.textDark)),
                            const SizedBox(height: 3),
                            const Text('Rota Sürücüsü',
                                style: TextStyle(fontSize: 13, color: _C.textLight)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _C.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('● Aktif',
                                  style: TextStyle(fontSize: 11, color: _C.success, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Bugünün Özeti ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('BUGÜNÜN ÖZETİ',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                    color: _C.textLight, letterSpacing: 1.0)),
                            Text(_todayDate(),
                                style: const TextStyle(fontSize: 11, color: _C.textLight)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _C.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _C.stroke),
                        ),
                        child: Column(
                          children: [
                            // İlerleme
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('$completed / $total adres tamamlandı',
                                    style: const TextStyle(fontSize: 13, color: _C.textMid)),
                                Text('%${pct.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _C.textDark)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                minHeight: 6,
                                backgroundColor: _C.stroke,
                                valueColor: AlwaysStoppedAnimation(pct == 100 ? _C.success : _C.accent),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Özet satırları
                            _summaryRow(Icons.straighten_rounded, 'Toplam Mesafe', '${todayRoute.totalDistance.toStringAsFixed(1)} km'),
                            Divider(height: 20, color: _C.stroke),
                            _summaryRow(Icons.timer_rounded, 'Tahmini Süre', '2 saat 30 dk'),
                            Divider(height: 20, color: _C.stroke),
                            _summaryRow(Icons.route_rounded, 'Toplam Rota', '${driver.totalRoutes} rota'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Ayarlar ───────────────────────────────────────
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 10),
                        child: Text('AYARLAR',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                color: _C.textLight, letterSpacing: 1.0)),
                      ),
                      _settingsCard([
                        _toggleRow(Icons.notifications_rounded, 'Bildirimler',
                            notificationsEnabled, (v) => setState(() => notificationsEnabled = v)),
                        Divider(height: 1, color: _C.stroke),
                        _toggleRow(Icons.gps_fixed_rounded, 'GPS Konum Takibi',
                            gpsEnabled, (v) => setState(() => gpsEnabled = v)),
                        Divider(height: 1, color: _C.stroke),
                        _toggleRow(Icons.record_voice_over_rounded, 'Sesli Rehber',
                            voiceGuidanceEnabled, (v) => setState(() => voiceGuidanceEnabled = v)),
                      ]),

                      const SizedBox(height: 20),

                      // ── Hesap ─────────────────────────────────────────
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 10),
                        child: Text('HESAP',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                color: _C.textLight, letterSpacing: 1.0)),
                      ),
                      _settingsCard([
                        _infoRow(Icons.person_rounded, 'Kullanıcı Adı', _username),
                        Divider(height: 1, color: _C.stroke),
                        _infoRow(Icons.business_rounded, 'Kurum', 'Tekirdağ Şehir Hastanesi'),
                        Divider(height: 1, color: _C.stroke),
                        _infoRow(Icons.info_outline_rounded, 'Versiyon', 'v1.0.0'),
                      ]),

                      const SizedBox(height: 24),

                      // Çıkış butonu
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('Çıkış Yap',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _C.error,
                            side: const BorderSide(color: _C.error, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _C.textLight),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: _C.textMid))),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.textDark)),
      ],
    );
  }

  Widget _settingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.stroke),
      ),
      child: Column(children: children),
    );
  }

  Widget _toggleRow(IconData icon, String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _C.textMid),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: _C.textDark))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _C.accent,
            activeTrackColor: _C.accent.withOpacity(0.3),
            inactiveTrackColor: _C.stroke,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _C.textMid),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: _C.textDark))),
          Text(value, style: const TextStyle(fontSize: 13, color: _C.textLight, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}