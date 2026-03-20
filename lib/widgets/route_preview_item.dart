import 'package:flutter/material.dart';
import '../models/address_model.dart';
import '../theme/app_colors.dart';

class RoutePreviewItem extends StatelessWidget {
  final Address address;

  const RoutePreviewItem({
    Key? key,
    required this.address,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(
            color: AppColors.accent,
            width: 4,
          ),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Number circle
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                address.orderNumber.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.street,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  address.district,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
