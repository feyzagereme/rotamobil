import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/route_provider.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool notificationsEnabled = true;
  bool gpsEnabled = true;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadSettings();
  }

  Future<void> _loadUsername() async {
    final username = await AuthService.getUsername();
    if (mounted) setState(() => _username = username.isNotEmpty ? username : 'Misafir');
  }

  Future<void> _loadSettings() async {
    final notif = await NotificationService.isEnabled();
    final gps = await LocationService.isEnabled();
    if (mounted) {
      setState(() {
        notificationsEnabled = notif;
        gpsEnabled = gps;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Çıkış Yap',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
            style: TextStyle(fontSize: 14, color: AppColors.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal', style: TextStyle(color: AppColors.textMid)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RouteProvider>();
    final initials = _username.isNotEmpty ? _username[0].toUpperCase() : 'M';
    final completed = provider.completedStops;
    final total = provider.totalStops;
    final pct = provider.completionPercentage;

    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      body: Column(
        children: [
          // ── Mavi header
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                    ),
                    child: Center(
                      child: Text(initials,
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_username,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 3),
                        Text('Rota Sürücüsü',
                            style: TextStyle(
                                fontSize: 13, color: Colors.white.withValues(alpha: 0.65))),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                          ),
                          child: const Text('● Aktif',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── İçerik
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF0F4F8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Bugünün özeti kartı
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D47A1).withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Bugünün Özeti',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w600)),
                              Text('%${pct.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF53D6FF),
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: total == 0 ? 0 : pct / 100,
                              minHeight: 6,
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation(
                                pct == 100 ? AppColors.success : const Color(0xFF53D6FF),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _miniStat('$completed', 'Tamamlanan', AppColors.success),
                              const SizedBox(width: 10),
                              _miniStat('${total - completed}', 'Kalan', const Color(0xFF53D6FF)),
                              const SizedBox(width: 10),
                              _miniStat('$total', 'Toplam', Colors.white),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Ayarlar
                    _sectionLabel('AYARLAR'),
                    const SizedBox(height: 10),
                    _card([
                      _toggleRow(Icons.notifications_rounded, 'Bildirimler',
                          notificationsEnabled, (v) {
                        setState(() => notificationsEnabled = v);
                        NotificationService.setEnabled(v);
                      }),
                      _divider(),
                      _toggleRow(Icons.gps_fixed_rounded, 'GPS Konum Takibi',
                          gpsEnabled, (v) {
                        setState(() => gpsEnabled = v);
                        LocationService.setEnabled(v);
                      }),
                    ]),

                    const SizedBox(height: 20),

                    // ── Hesap
                    _sectionLabel('HESAP'),
                    const SizedBox(height: 10),
                    _card([
                      _infoRow(Icons.person_rounded, 'Kullanıcı Adı', _username),
                      _divider(),
                      _infoRow(Icons.business_rounded, 'Kurum', 'Tekirdağ Şehir Hastanesi'),
                      _divider(),
                      _infoRow(Icons.local_hospital_rounded, 'Birim', 'Palyatif Bakım'),
                      _divider(),
                      _infoRow(Icons.info_outline_rounded, 'Versiyon', 'v1.0.0'),
                    ]),

                    const SizedBox(height: 24),

                    // ── Çıkış butonu
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('Çıkış Yap',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: AppColors.textLight, letterSpacing: 1.2));
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => Divider(height: 1, color: AppColors.stroke, indent: 16, endIndent: 16);

  Widget _toggleRow(IconData icon, String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF0D47A1)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label,
              style: const TextStyle(fontSize: 14, color: AppColors.textDark))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF53D6FF),
            activeTrackColor: const Color(0xFF53D6FF).withValues(alpha: 0.3),
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
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF0D47A1)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label,
              style: const TextStyle(fontSize: 14, color: AppColors.textDark))),
          Text(value,
              style: const TextStyle(fontSize: 13, color: AppColors.textLight, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}