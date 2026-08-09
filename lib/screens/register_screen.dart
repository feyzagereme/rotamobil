import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

/// Rota360 sürücü hesapları sistem yöneticisi tarafından oluşturulur.
/// Bu ekran kullanıcıya o bilgiyi açıklar ve yöneticiyle iletişim kurmak
/// için bir e-posta kısayolu sunar.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  static const String _adminEmail = '360.rotaa@gmail.com';

  Future<void> _openEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _adminEmail,
      queryParameters: {
        'subject': 'Rota360 Sürücü Hesabı Talebi',
        'body': 'Merhaba,\n\nRota360 uygulaması için sürücü hesabı oluşturulmasını talep ediyorum.\n\nAd Soyad: \nBirim/Araç: ',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-posta uygulaması açılamadı. $_adminEmail adresine yazabilirsiniz.'),
            backgroundColor: AppColors.primaryDark,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        image: const DecorationImage(
                          image: AssetImage('assets/icon/app_icon.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Hesap Nasıl Oluşturulur?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Bilgi kartı
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _infoRow(
                            icon: Icons.admin_panel_settings_rounded,
                            color: AppColors.accent,
                            title: 'Yönetici tarafından oluşturulur',
                            subtitle: 'Rota360 sürücü hesapları bağımsız kayıt desteklemez. '
                                'Hesabınız sistem yöneticiniz tarafından oluşturulur.',
                          ),
                          const Divider(height: 28, color: AppColors.stroke),
                          _infoRow(
                            icon: Icons.email_rounded,
                            color: AppColors.success,
                            title: 'Yöneticinize başvurun',
                            subtitle: 'Hesap talebinizi $_adminEmail adresine iletebilirsiniz.',
                          ),
                          const Divider(height: 28, color: AppColors.stroke),
                          _infoRow(
                            icon: Icons.lock_reset_rounded,
                            color: AppColors.warning,
                            title: 'Şifrenizi mi unuttunuz?',
                            subtitle: 'Giriş ekranındaki "Şifremi Unuttum" seçeneğini kullanın '
                                'veya yöneticinize başvurun.',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Yöneticiye e-posta at
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openEmail(context),
                        icon: const Icon(Icons.email_rounded, size: 18),
                        label: const Text('Yöneticiye Yaz'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.primaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Zaten hesabın var mı? Giriş Yap',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Geri butonu
            Positioned(
              top: 4, left: 12,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  )),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(
                    fontSize: 13, color: AppColors.textMid, height: 1.4,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
