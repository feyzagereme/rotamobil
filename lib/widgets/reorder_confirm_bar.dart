import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Sürükleyip bırakma sonrası çıkan onay barı. Sürücü rota sırasını
/// sürükleyerek değiştirdikten sonra, gerçek yeniden hesaplama (backend
/// isteği) yalnızca "Onayla" ile tetiklenir; "Vazgeç" sürüklemeden önceki
/// sıraya döner. Bkz. RouteProvider.previewReorder /
/// confirmPendingReorder / cancelPendingReorder.
class ReorderConfirmBar extends StatelessWidget {
  final String label;
  final bool isBusy;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const ReorderConfirmBar({
    super.key,
    required this.label,
    required this.isBusy,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.stroke)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '"$label" öne alındı. Rota yeniden hesaplansın mı?',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMid, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: isBusy ? null : onCancel,
              child: const Text('Vazgeç', style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton.icon(
              onPressed: isBusy ? null : onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: isBusy
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(isBusy ? 'Hesaplanıyor...' : 'Onayla'),
            ),
          ],
        ),
      ),
    );
  }
}
