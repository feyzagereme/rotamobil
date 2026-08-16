import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/address_model.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

/// Yönetici filo özetinde bir sürücüye dokununca açılan detay ekranı.
/// Tam konum takibi değil — durakların tamamlanma sırasını ve şu anda
/// "sıradaki durak" olarak hangisinin beklendiğini gösterir.
class AdminDriverDetailScreen extends StatefulWidget {
  const AdminDriverDetailScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  final int userId;
  final String username;

  @override
  State<AdminDriverDetailScreen> createState() =>
      _AdminDriverDetailScreenState();
}

class _AdminDriverDetailScreenState extends State<AdminDriverDetailScreen> {
  static const _baseUrl = AuthService.baseUrl;

  List<Address>? _stops;
  double _totalKm = 0;
  int _totalMin = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/routes/${widget.userId}/active'),
            headers: await AuthService.authHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 404) {
        setState(() {
          _stops = [];
          _error = null;
          _loading = false;
        });
        return;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        setState(() {
          _error = 'Sunucu hatası: ${response.statusCode}';
          _loading = false;
        });
        return;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final routeJson = decoded['route_json'] is Map
          ? decoded['route_json'] as Map<String, dynamic>
          : decoded;
      final rawStops = (routeJson['stops'] as List?) ?? const [];

      final stops = <Address>[];
      for (var i = 0; i < rawStops.length; i++) {
        stops.add(
          Address.fromRouteStop(
            rawStops[i] as Map<String, dynamic>,
            fallbackOrder: i + 1,
          ),
        );
      }
      stops.sort((a, b) => a.orderNumber.compareTo(b.orderNumber));

      setState(() {
        _stops = stops;
        _totalKm = (routeJson['totalKm'] as num?)?.toDouble() ?? 0;
        _totalMin = (routeJson['totalMin'] as num?)?.toInt() ?? 0;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(title: Text(widget.username)),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading && _stops == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _stops == null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.textMid),
            ),
          ),
        ],
      );
    }
    final stops = _stops ?? [];
    if (stops.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              'Bugün için atanmış rota yok.',
              style: TextStyle(color: AppColors.textMid),
            ),
          ),
        ],
      );
    }

    final nextIndex = stops.indexWhere((a) => !a.isCompleted);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statColumn(
                '${stops.where((a) => a.isCompleted).length}/${stops.length}',
                'Tamamlanan',
              ),
              _statColumn('${_totalKm.toStringAsFixed(1)} km', 'Mesafe'),
              _statColumn('~$_totalMin dk', 'Süre'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < stops.length; i++)
          _StopTile(address: stops[i], isNext: i == nextIndex),
      ],
    );
  }

  Widget _statColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({required this.address, required this.isNext});

  final Address address;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final completed = address.isCompleted;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: isNext ? AppColors.accent : AppColors.stroke,
          width: isNext ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed
                  ? AppColors.success
                  : isNext
                  ? AppColors.accent
                  : AppColors.stroke,
            ),
            child: Icon(
              completed ? Icons.check_rounded : Icons.circle,
              size: completed ? 18 : 8,
              color: completed || isNext ? Colors.white : AppColors.textLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isNext)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'SIRADAKİ DURAK',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                Text(
                  address.fullAddress,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: completed ? AppColors.textLight : AppColors.textDark,
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                if ((address.notes ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    address.notes!,
                    style: const TextStyle(
                      color: AppColors.textMid,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
