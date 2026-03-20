import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _showBottomSheet = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Harita',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Map placeholder
          Container(
            color: const Color(0xFFE8F4F8),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.map,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Google Maps',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Harita burada gösterilecek',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Map controls (top right)
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  onPressed: () {},
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  onPressed: () {},
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  onPressed: () {},
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),

          // Bottom sheet
          if (_showBottomSheet)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomSheet(),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCCCCCC),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Current location info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mevcut Konum',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '119/1. Sokak, Evka 3 Mahallesi, Bornova',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Navigation button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.navigation),
                label: const Text('Navigasyonu Başlat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
