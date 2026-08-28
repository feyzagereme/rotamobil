import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Firebase yapılandırması tek noktada toplandı — eskiden `main.dart` içine
/// gömülüydü.
///
/// Web değerleri gizli değildir (zaten istemciyle birlikte dağıtılır) ama
/// derleme zamanında `--dart-define` ile ezilebilsin diye buraya taşındı.
/// Örn:
///   flutter build web \
///     --dart-define=FIREBASE_WEB_API_KEY=... \
///     --dart-define=FIREBASE_WEB_APP_ID=...
///
/// Native platformlar (Android/iOS) kendi `google-services.json` /
/// `GoogleService-Info.plist` dosyalarını kullanır; bu yüzden web dışında
/// `null` döner ve `Firebase.initializeApp` options'sız çağrılır.
class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  /// Web'de [web], diğer platformlarda `null` (native yapılandırma dosyası
  /// kullanılır).
  static FirebaseOptions? get currentPlatform => kIsWeb ? web : null;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_WEB_API_KEY',
      defaultValue: 'AIzaSyDNntalqnmuOiJrgrpahfI3RRg8r9cM91w',
    ),
    authDomain: String.fromEnvironment(
      'FIREBASE_WEB_AUTH_DOMAIN',
      defaultValue: 'rota360-35ce3.firebaseapp.com',
    ),
    projectId: String.fromEnvironment(
      'FIREBASE_WEB_PROJECT_ID',
      defaultValue: 'rota360-35ce3',
    ),
    storageBucket: String.fromEnvironment(
      'FIREBASE_WEB_STORAGE_BUCKET',
      defaultValue: 'rota360-35ce3.firebasestorage.app',
    ),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_WEB_MESSAGING_SENDER_ID',
      defaultValue: '434121736536',
    ),
    appId: String.fromEnvironment(
      'FIREBASE_WEB_APP_ID',
      defaultValue: '1:434121736536:web:e8a409cb916d03dec7e52d',
    ),
  );
}
