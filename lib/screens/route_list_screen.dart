import 'package:flutter/material.dart';
import '../services/mock_data_service.dart';
import '../theme/app_colors.dart';
import '../widgets/address_card.dart';

class RouteListScreen extends StatefulWidget {
  const RouteListScreen({Key? key}) : super(key: key);

  @override
  State<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends State<RouteListScreen> {
  late final addresses;

  @override
  void initState() {
    super.initState();
    addresses = MockDataService.getTodayRoute().addresses;
  }

  @override
  Widget build(BuildContext context) {
    final todayRoute = MockDataService.getTodayRoute();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Rota Listesi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${todayRoute.completedStops}/${todayRoute.totalStops}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tamamlanma Durumu',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${todayRoute.completionPercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: todayRoute.completionPercentage / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.lightBg,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      todayRoute.completionPercentage == 100
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Address list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                return AddressCard(
                  address: addresses[index],
                  onCheckboxChanged: () {
                    setState(() {
                      // Update can be handled here
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
