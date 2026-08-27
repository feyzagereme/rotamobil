import 'package:flutter/material.dart';

/// Ekranın ortasında, büyük ve okunaklı bir uyarı/hata kartı gösterir.
///
/// Önceden tüm uyarılar ekranın altında küçük SnackBar olarak çıkıyordu ve
/// "konum bulunamadı" gibi önemli mesajlar fark edilmiyordu. Bu kart:
/// - ekranın tam ortasında, büyük yazıyla
/// - arkada karartma (dokununca kapanır)
/// - sağ üstte küçük bir çarpı (×) tuşu — kullanıcı ona basınca kapanır
/// - kendiliğinden kapanmaz (önemli mesaj kaçmasın diye)
///
/// Sadece hata ve uyarılar için kullanılır; "Kaydedildi" gibi kısa olumlu
/// bilgiler eskisi gibi altta SnackBar olarak kalır.
enum AppNoticeSeverity { warning, error }

class AppNotice {
  AppNotice._();

  static OverlayEntry? _entry;

  static void show(
    BuildContext context,
    String message, {
    AppNoticeSeverity severity = AppNoticeSeverity.warning,
  }) {
    dismiss();
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (_) => _AppNoticeCard(
        message: message,
        severity: severity,
        onClose: dismiss,
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  static void dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

class _AppNoticeCard extends StatefulWidget {
  const _AppNoticeCard({
    required this.message,
    required this.severity,
    required this.onClose,
  });

  final String message;
  final AppNoticeSeverity severity;
  final VoidCallback onClose;

  @override
  State<_AppNoticeCard> createState() => _AppNoticeCardState();
}

class _AppNoticeCardState extends State<_AppNoticeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  bool get _isError => widget.severity == AppNoticeSeverity.error;

  Color get _accent =>
      _isError ? const Color(0xFFE53935) : const Color(0xFFF59E0B);

  IconData get _icon =>
      _isError ? Icons.error_outline_rounded : Icons.warning_amber_rounded;

  String get _title => _isError ? 'Hata' : 'Uyarı';

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    return FadeTransition(
      opacity: curved,
      child: Stack(
        children: [
          // Arka karartma — dokununca kapanır.
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(color: Colors.black.withValues(alpha: 0.45)),
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
              child: Container(
                margin: const EdgeInsets.all(28),
                constraints: const BoxConstraints(maxWidth: 440),
                child: Material(
                  color: Colors.white,
                  elevation: 12,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 12, 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_icon, color: _accent, size: 26),
                            const SizedBox(width: 10),
                            Text(
                              _title,
                              style: TextStyle(
                                color: _accent,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            // Sağ üstteki küçük çarpı tuşu.
                            IconButton(
                              onPressed: widget.onClose,
                              icon: const Icon(Icons.close_rounded),
                              iconSize: 22,
                              color: const Color(0xFF5A6A85),
                              tooltip: 'Kapat',
                              splashRadius: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 320),
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Text(
                                  widget.message,
                                  style: const TextStyle(
                                    color: Color(0xFF1A2236),
                                    fontSize: 18,
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
