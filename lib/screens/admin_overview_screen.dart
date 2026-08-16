import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class _DriverSummary {
  const _DriverSummary({
    required this.userId,
    required this.username,
    required this.hasRouteToday,
    required this.totalStops,
    required this.completedStops,
    required this.totalKm,
    required this.totalMin,
  });

  final int userId;
  final String username;
  final bool hasRouteToday;
  final int totalStops;
  final int completedStops;
  final double totalKm;
  final int totalMin;

  factory _DriverSummary.fromJson(Map<String, dynamic> json) {
    return _DriverSummary(
      userId: json['userId'] as int,
      username: json['username'] as String,
      hasRouteToday: json['hasRouteToday'] as bool? ?? false,
      totalStops: json['totalStops'] as int? ?? 0,
      completedStops: json['completedStops'] as int? ?? 0,
      totalKm: (json['totalKm'] as num?)?.toDouble() ?? 0.0,
      totalMin: json['totalMin'] as int? ?? 0,
    );
  }
}

/// Yönetici hesabıyla girişte gösterilen, tüm sürücülerin bugünkü rota
/// ilerlemesini tek ekranda özetleyen görünüm. Normal sürücü sekmelerinin
/// (Harita/Liste/Takvim) yerine geçer — yönetici kendi rotasını değil,
/// filonun tamamının durumunu görür.
class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  static const _baseUrl = AuthService.baseUrl;

  List<_DriverSummary>? _drivers;
  String? _error;
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/routes/today/summary'),
            headers: await AuthService.authHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        setState(() {
          _error = 'Sunucu hatası: ${response.statusCode}';
          _loading = false;
        });
        return;
      }

      final decoded = jsonDecode(response.body) as List;
      setState(() {
        _drivers = decoded
            .map((e) => _DriverSummary.fromJson(e as Map<String, dynamic>))
            .toList();
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Bağlantı hatası: $e';
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Filo Özeti'),
        actions: [
          IconButton(
            tooltip: 'Çıkış Yap',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _drivers == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _drivers == null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textLight),
          const SizedBox(height: 12),
          Center(
            child: Text(_error!, style: const TextStyle(color: AppColors.textMid)),
          ),
        ],
      );
    }
    final drivers = _drivers ?? [];
    if (drivers.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text('Kayıtlı sürücü yok.',
                style: TextStyle(color: AppColors.textMid)),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: drivers.length,
      itemBuilder: (context, i) => _DriverSummaryCard(summary: drivers[i]),
    );
  }
}

class _DriverSummaryCard extends StatelessWidget {
  const _DriverSummaryCard({required this.summary});

  final _DriverSummary summary;

  @override
  Widget build(BuildContext context) {
    final total = summary.totalStops;
    final completed = summary.completedStops;
    final progress = total == 0 ? 0.0 : completed / total;
    final noRoute = !summary.hasRouteToday || total == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded,
                    color: AppColors.primaryDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  summary.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (!noRoute)
                Text(
                  '$completed / $total',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.primaryDark,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (noRoute)
            const Text(
              'Bugün için atanmış rota yok',
              style: TextStyle(color: AppColors.textLight, fontSize: 12.5),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.stroke,
                valueColor: AlwaysStoppedAnimation(
                  progress >= 1.0 ? AppColors.success : AppColors.accent,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${summary.totalKm.toStringAsFixed(1)} km · ~${summary.totalMin} dk',
              style: const TextStyle(color: AppColors.textMid, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
