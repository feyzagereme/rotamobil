class AppConfig {
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'https://route-backend-1.onrender.com',
  );

  /// TomTom Routing API anahtarı (misafir modunda trafik bilgili rota için).
  /// Boşsa misafir rotası düz-çizgi (haversine) hesaba geri düşer.
  static const String tomtomApiKey = String.fromEnvironment('TOMTOM_API_KEY');
}
