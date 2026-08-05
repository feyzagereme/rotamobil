class AppConfig {
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://100.118.211.75:3000',
  );

  /// TomTom Routing API anahtarı (misafir modunda trafik bilgili rota için).
  /// Boşsa misafir rotası düz-çizgi (haversine) hesaba geri düşer.
  static const String tomtomApiKey = String.fromEnvironment('TOMTOM_API_KEY');
}
