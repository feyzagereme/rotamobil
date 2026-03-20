import 'package:flutter/material.dart';
import '../models/route_model.dart' as route_models;
import '../models/address_model.dart';
import '../services/mock_data_service.dart';
import '../theme/app_colors.dart';
import '../widgets/stat_card.dart';
import '../widgets/route_preview_item.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late route_models.Route todayRoute;
  late Address? nextAddress;

  @override
  void initState() {
    super.initState();
    todayRoute = MockDataService.getTodayRoute();
    nextAddress = MockDataService.getNextAddress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Bugünün Rota',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryDark,
                      AppColors.primary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rota Özeti',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            icon: '📍',
                            value: todayRoute.totalStops.toString(),
                            label: 'Adres',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatCard(
                            icon: '📏',
                            value: todayRoute.totalDistance.toStringAsFixed(1),
                            label: 'km',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatCard(
                            icon: '⏱️',
                            value: '2.5',
                            label: 'saat',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Next Address Card
              if (nextAddress != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightBg,
                    border: Border(
                      left: BorderSide(
                        color: AppColors.accent,
                        width: 4,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sonraki Adres',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        nextAddress!.street,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${nextAddress!.district}, ${nextAddress!.city}',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Uzaklık: 2,3 km • 12 dakika',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Quick Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.map),
                      label: const Text('Haritayı Aç'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.call),
                      label: const Text('Ara'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Route Preview
              Text(
                'Rota Özeti (${todayRoute.totalStops} Adres)',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...todayRoute.addresses.take(3).map(
                    (address) => RoutePreviewItem(address: address),
                  ),
              if (todayRoute.addresses.length > 3) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Ve ${todayRoute.addresses.length - 3} adres daha...',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
