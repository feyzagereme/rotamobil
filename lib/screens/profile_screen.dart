import 'package:flutter/material.dart';
import '../services/mock_data_service.dart';
import '../models/driver_model.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Driver driver;
  late bool notificationsEnabled;
  late bool gpsEnabled;
  late bool voiceGuidanceEnabled;

  @override
  void initState() {
    super.initState();
    driver = MockDataService.getMockDriver();
    notificationsEnabled = driver.notificationsEnabled;
    gpsEnabled = driver.gpsEnabled;
    voiceGuidanceEnabled = driver.voiceGuidanceEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Profil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        driver.name[0],
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    driver.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    driver.position,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),

            // Profile sections
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Work Information Section
                  _buildSectionTitle('İş Bilgileri'),
                  const SizedBox(height: 12),
                  _buildProfileItem('Durumu', 'Çalışmaya Hazır'),
                  _buildProfileItem(
                      'Toplam Rota', driver.totalRoutes.toString()),
                  _buildProfileItem(
                    'Tamamlanma Oranı',
                    '${(driver.completionRate * 100).toStringAsFixed(0)}%',
                  ),
                  const SizedBox(height: 24),

                  // Settings Section
                  _buildSectionTitle('Ayarlar'),
                  const SizedBox(height: 12),
                  _buildToggleItem(
                    'Bildirimler',
                    notificationsEnabled,
                    (value) {
                      setState(() {
                        notificationsEnabled = value;
                      });
                    },
                  ),
                  _buildToggleItem(
                    'GPS Konum Takibi',
                    gpsEnabled,
                    (value) {
                      setState(() {
                        gpsEnabled = value;
                      });
                    },
                  ),
                  _buildToggleItem(
                    'Sesli Rehber',
                    voiceGuidanceEnabled,
                    (value) {
                      setState(() {
                        voiceGuidanceEnabled = value;
                      });
                    },
                  ),
                  const SizedBox(height: 32),

                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Çıkış Yap',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textLight,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.lightBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textDark,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String label, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.lightBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textDark,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.success,
            activeTrackColor: AppColors.success.withOpacity(0.3),
            inactiveTrackColor: AppColors.textLight.withOpacity(0.2),
          ),
        ],
      ),
    );
  }
}
