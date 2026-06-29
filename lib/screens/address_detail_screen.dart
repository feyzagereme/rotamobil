import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/address_model.dart';
import '../services/route_provider.dart';
import '../theme/app_colors.dart';

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
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _toggleCompleted() {
    HapticFeedback.mediumImpact();
    setState(() => _isCompleted = !_isCompleted);
    context.read<RouteProvider>().toggleCompleted(widget.index);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
            _isCompleted ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: Colors.white, size: 18,
          ),
          const SizedBox(width: 8),
          Text(_isCompleted
              ? 'Ziyaret tamamlandı olarak işaretlendi'
              : 'Ziyaret tamamlanmadı olarak işaretlendi'),
        ]),
        backgroundColor: _isCompleted ? AppColors.success : AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final address = widget.address;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Column(
        children: [
          // ── Harita header
          SizedBox(
            height: 260,
            child: Stack(
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
                      userAgentPackageName: 'com.example.rotamobil',
                    ),
                    MarkerLayer(markers: [
                      Marker(
                        point: LatLng(address.latitude, address.longitude),
                        width: 52, height: 52,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isCompleted
                                ? AppColors.success
                                : const Color(0xFF0D47A1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 10, offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isCompleted
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 22)
                                : Text('${widget.index + 1}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
                // Üstten gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF0A1628).withValues(alpha: 0.8),
                        Colors.transparent,
                        Colors.transparent,
                        const Color(0xFF0A1628).withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
                // Geri butonu
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        GestureDetector(
                          onTap: _launchNavigation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF53D6FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(children: [
                              Icon(Icons.navigation_rounded,
                                  color: Color(0xFF0A1628), size: 16),
                              SizedBox(width: 6),
                              Text('Navigasyon',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0A1628))),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── İçerik
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF0F4F8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── İsim + durum
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(address.customerName,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark,
                                      letterSpacing: -0.5)),
                              const SizedBox(height: 4),
                              Text('Durak #${widget.index + 1}',
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.textLight)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isCompleted
                                ? AppColors.success.withValues(alpha: 0.1)
                                : const Color(0xFF53D6FF).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isCompleted
                                  ? AppColors.success.withValues(alpha: 0.3)
                                  : const Color(0xFF53D6FF).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(
                              _isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 13,
                              color: _isCompleted
                                  ? AppColors.success
                                  : const Color(0xFF53D6FF),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _isCompleted ? 'Tamamlandı' : 'Bekliyor',
                              style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: _isCompleted
                                    ? AppColors.success
                                    : const Color(0xFF53D6FF),
                              ),
                            ),
                          ]),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Adres bilgileri kartı
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8, offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(children: [
                        _infoRow(Icons.location_on_rounded, 'Adres',
                            address.fullAddress, const Color(0xFF0D47A1)),
                        const Divider(height: 20, color: Color(0xFFE2E8F0)),
                        _infoRow(Icons.map_rounded, 'Koordinat',
                            '${address.latitude.toStringAsFixed(5)}, ${address.longitude.toStringAsFixed(5)}',
                            AppColors.textMid),
                      ]),
                    ),

                    const SizedBox(height: 12),

                    // ── Aksiyon butonları
                    Row(children: [
                      Expanded(
                        child: _actionBtn(
                          Icons.navigation_rounded,
                          'Navigasyon',
                          const Color(0xFF0D47A1),
                          _launchNavigation,
                          filled: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _actionBtn(
                          Icons.call_rounded,
                          'Ara',
                          AppColors.success,
                          () => _launchCall('+90 532 000 00 00'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _actionBtn(
                          Icons.share_rounded,
                          'Paylaş',
                          AppColors.textMid,
                          () {},
                        ),
                      ),
                    ]),

                    const SizedBox(height: 12),

                    // ── Notlar kartı
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8, offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(children: [
                                Icon(Icons.notes_rounded,
                                    size: 18, color: AppColors.textMid),
                                SizedBox(width: 8),
                                Text('Notlar',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark)),
                              ]),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _editingNote = !_editingNote),
                                child: Text(
                                  _editingNote ? 'Kaydet' : 'Düzenle',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF53D6FF),
                                      fontWeight: FontWeight.w600),
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
                                  style: const TextStyle(
                                      fontSize: 14, color: AppColors.textDark),
                                  decoration: InputDecoration(
                                    hintText: 'Not ekleyin...',
                                    hintStyle: const TextStyle(
                                        color: AppColors.textLight),
                                    filled: true,
                                    fillColor: const Color(0xFFF0F4F8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF53D6FF), width: 1.5),
                                    ),
                                  ),
                                )
                              : Text(
                                  _noteController.text.isNotEmpty
                                      ? _noteController.text
                                      : 'Not eklenmemiş.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _noteController.text.isNotEmpty
                                        ? AppColors.textMid
                                        : AppColors.textLight,
                                    fontStyle: _noteController.text.isEmpty
                                        ? FontStyle.italic
                                        : null,
                                  ),
                                ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Tamamla butonu
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _toggleCompleted,
                        icon: Icon(
                          _isCompleted
                              ? Icons.cancel_outlined
                              : Icons.check_circle_rounded,
                          size: 20,
                        ),
                        label: Text(
                          _isCompleted
                              ? 'Tamamlandıyı Geri Al'
                              : 'Ziyareti Tamamlandı İşaretle',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCompleted
                              ? AppColors.textLight
                              : AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textDark)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color,
      VoidCallback onTap, {bool filled = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled ? color : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled ? color : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: filled
                  ? color.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: [
          Icon(icon, size: 22, color: filled ? Colors.white : color),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: filled ? Colors.white : color)),
        ]),
      ),
    );
  }
}