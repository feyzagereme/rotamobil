import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: const Color(0xFF53D6FF).withValues(alpha: 0.3)),
                  image: const DecorationImage(
                    image: AssetImage('assets/icon/app_icon.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Başlık
              const Text(
                'Rota360',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'En kısa rotayı hesapla,\nzamanını verimli kullan.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.55),
                  height: 1.5,
                ),
              ),

              const Spacer(),

              // Özellikler
              _featureRow(Icons.map_rounded, 'Harita üzerinden adres ekle'),
              const SizedBox(height: 16),
              _featureRow(Icons.alt_route_rounded, 'En kısa rotayı otomatik hesapla'),
              const SizedBox(height: 16),
              _featureRow(Icons.navigation_rounded, 'Sırayla navigasyon başlat'),
              const SizedBox(height: 16),
              _featureRow(Icons.history_rounded, 'Geçmiş rotaları kaydet'),

              const Spacer(),

              // Butonlar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pushReplacementNamed('/guest'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF53D6FF),
                    foregroundColor: const Color(0xFF0A1628),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Misafir Olarak Başla',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).pushReplacementNamed('/login'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Hastane Personeli Girişi',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: Text(
                  'Tekirdağ Şehir Hastanesi · Palyatif Bakım',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.25)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String text) {
    return Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF53D6FF).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF53D6FF)),
      ),
      const SizedBox(width: 14),
      Text(text,
          style: TextStyle(
              fontSize: 14, color: Colors.white.withValues(alpha: 0.75))),
    ]);
  }
}