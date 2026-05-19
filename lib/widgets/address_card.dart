import 'package:flutter/material.dart';
import '../models/address_model.dart';
import '../theme/app_colors.dart';

class AddressCard extends StatefulWidget {
  final Address address;
  final VoidCallback? onCheckboxChanged;
  final bool showCheckbox;

  const AddressCard({
    Key? key,
    required this.address,
    this.onCheckboxChanged,
    this.showCheckbox = true,
  }) : super(key: key);

  @override
  State<AddressCard> createState() => _AddressCardState();
}

class _AddressCardState extends State<AddressCard> {
  late bool isCompleted;

  @override
  void initState() {
    super.initState();
    isCompleted = widget.address.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.bgLight : AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order number circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.success : AppColors.primaryDark,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.address.orderNumber.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Address details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.address.street,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        isCompleted ? AppColors.textLight : AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.address.district}, ${widget.address.city}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.address.customerType,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMid,
                  ),
                ),
              ],
            ),
          ),
          // Checkbox
          if (widget.showCheckbox)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    isCompleted = !isCompleted;
                  });
                  widget.onCheckboxChanged?.call();
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.success : Colors.white,
                    border: Border.all(
                      color:
                          isCompleted ? AppColors.success : AppColors.primary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isCompleted
                      ? const Center(
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
                        )
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
