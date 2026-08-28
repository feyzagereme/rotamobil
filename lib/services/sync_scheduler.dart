import 'dart:async';

/// Tek bir periyodik zamanlayıcı — eskiden [RouteProvider] ve [FleetProvider]
/// ayrı ayrı 10 sn'lik `Timer.periodic` çalıştırıyordu (dakikada 12 istek).
/// Artık her iki senkron tek [onTick] içinde toplanıp tek zamanlayıcıyla
/// tetikleniyor.
///
/// [start]/[stop] uygulama yaşam döngüsüne bağlanır: ön planda çalışır,
/// arka plana geçince durur (bkz. `MainApp.didChangeAppLifecycleState`).
class SyncScheduler {
  SyncScheduler({
    required this.onTick,
    this.interval = const Duration(seconds: 10),
  });

  /// Her turda çağrılır. Hatalar burada yutulmalı — atılan bir hata
  /// zamanlayıcıyı durdurmaz ama loglanmadan kaybolur.
  final Future<void> Function() onTick;
  final Duration interval;

  Timer? _timer;
  bool _tickInFlight = false;

  bool get isRunning => _timer != null;

  /// Zamanlayıcıyı başlatır ve hemen bir tur çalıştırır. Zaten
  /// çalışıyorsa yeniden bir tur tetikler (ör. ön plana dönüşte anında
  /// tazeleme) ama ikinci bir zamanlayıcı kurmaz.
  void start() {
    _fireOnce();
    _timer ??= Timer.periodic(interval, (_) => _fireOnce());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _fireOnce() {
    if (_tickInFlight) return; // önceki tur bitmeden üst üste binmesin
    _tickInFlight = true;
    Future(() async {
      try {
        await onTick();
      } finally {
        _tickInFlight = false;
      }
    });
  }
}
