import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/address_model.dart';
import '../services/route_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_notice.dart';

class AddressDetailScreen extends StatefulWidget {
  final Address address;
  final int index;

  const AddressDetailScreen({
    super.key,
    required this.address,
    required this.index,
  });

  @override
  State<AddressDetailScreen> createState() => _AddressDetailScreenState();
}

class _AddressDetailScreenState extends State<AddressDetailScreen> {
  late bool _isCompleted;
  final _noteController = TextEditingController();
  bool _editingNote = false;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.address.isCompleted;
    _noteController.text = widget.address.notes ?? '';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _launchNavigation() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${widget.address.latitude},${widget.address.longitude}'
      '&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchCall(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _toggleCompleted() async {
    final target = !_isCompleted;
    HapticFeedback.mediumImpact();
    setState(() => _isCompleted = target);

    // RouteProvider.toggleCompleted artık gerçekten kaydedilip
    // kaydedilmediğini bool olarak dönüyor — önceden bu sonuç hiç
    // kontrol edilmiyordu, backend'e kayıt sessizce başarısız olsa
    // bile ekran her zaman "başarılı" gösteriyordu.
    final success = await context.read<RouteProvider>().toggleCompleted(widget.index);
    if (!mounted) return;

    if (!success) {
      setState(() => _isCompleted = !target);
      final error = context.read<RouteProvider>().errorMessage;
      AppNotice.show(
        context,
        error ?? 'Değişiklik kaydedilemedi, tekrar deneyin.',
        severity: AppNoticeSeverity.error,
      );
      return;
    }

    if (!target) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ziyaret tamamlanmadı olarak işaretlendi'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Ziyaret tamamlandı olarak işaretlendi'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final address = widget.address;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(address.latitude, address.longitude),
                      initialZoom: 15,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.rota360.rotamobil',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(address.latitude, address.longitude),
                            width: 48,
                            height: 48,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _isCompleted ? AppColors.success : AppColors.primaryDark,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isCompleted
                                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                                    : Text(
                                        '${widget.index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primaryDark.withValues(alpha: 0.4),
                          Colors.transparent,
                          Colors.transparent,
                          AppColors.primaryDark.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.navigation_rounded),
                onPressed: _launchNavigation,
                tooltip: 'Navigasyonu Başlat',
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.stroke),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    address.displayName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    address.customerType,
                                    style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _isCompleted
                                    ? AppColors.success.withValues(alpha: 0.1)
                                    : AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _isCompleted
                                      ? AppColors.success.withValues(alpha: 0.3)
                                      : AppColors.accent.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isCompleted
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    size: 14,
                                    color: _isCompleted ? AppColors.success : AppColors.accent,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _isCompleted ? 'Tamamlandı' : 'Bekliyor',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _isCompleted ? AppColors.success : AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(color: AppColors.stroke, height: 1),
                        const SizedBox(height: 16),
                        _infoRow(Icons.format_list_numbered_rounded, 'Rota Sırası', '#${address.orderNumber}'),
                        const SizedBox(height: 12),
                        _infoRow(Icons.location_on_rounded, 'Adres', address.fullAddress),
                        const SizedBox(height: 12),
                        _infoRow(Icons.map_rounded, 'Koordinat',
                            '${address.latitude.toStringAsFixed(5)}, ${address.longitude.toStringAsFixed(5)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _actionCard(Icons.navigation_rounded, 'Navigasyon', AppColors.primaryDark, _launchNavigation),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: address.phone == null
                            ? _actionCard(Icons.call_rounded, 'Ara', AppColors.stroke, null)
                            : _actionCard(Icons.call_rounded, 'Ara', AppColors.textMid, () => _launchCall(address.phone!)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _actionCard(Icons.share_rounded, 'Kopyala', AppColors.textMid, () async {
                          await Clipboard.setData(ClipboardData(text: address.fullAddress));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Adres panoya kopyalandı'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              margin: const EdgeInsets.all(12),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.stroke),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.notes_rounded, size: 18, color: AppColors.textMid),
                                SizedBox(width: 8),
                                Text('Notlar',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                if (_editingNote) {
                                  context.read<RouteProvider>().updateNote(
                                        widget.index,
                                        _noteController.text,
                                      );
                                }
                                setState(() => _editingNote = !_editingNote);
                              },
                              child: Text(
                                _editingNote ? 'Kaydet' : 'Düzenle',
                                style: const TextStyle(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _editingNote
                            ? TextField(
                                controller: _noteController,
                                maxLines: 4,
                                autofocus: true,
                                style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                                decoration: InputDecoration(
                                  hintText: 'Not ekleyin...',
                                  hintStyle: const TextStyle(color: AppColors.textLight),
                                  filled: true,
                                  fillColor: AppColors.bgLight,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                                  ),
                                ),
                              )
                            : Text(
                                _noteController.text.isNotEmpty ? _noteController.text : 'Not eklenmemiş.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _noteController.text.isNotEmpty ? AppColors.textMid : AppColors.textLight,
                                  fontStyle: _noteController.text.isEmpty ? FontStyle.italic : null,
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: ElevatedButton.icon(
                        onPressed: _toggleCompleted,
                        icon: Icon(
                          _isCompleted ? Icons.cancel_outlined : Icons.check_circle_rounded,
                          size: 20,
                        ),
                        label: Text(
                          _isCompleted ? 'Tamamlanmadı Olarak İşaretle' : 'Ziyareti Tamamlandı İşaretle',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCompleted ? AppColors.textLight : AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textLight),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionCard(IconData icon, String label, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
