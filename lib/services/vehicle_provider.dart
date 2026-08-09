import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama genelinde seçili aracı (0..4 → Araç 1..5) tutar.
/// Tüm sürücüler aynı hesapla giriş yapar, bu seçici ile hangi aracın
/// rotasını/filo durumunu izleyecekleri belirlenir.
class VehicleProvider extends ChangeNotifier {
  static const String _prefsKey = 'selected_vehicle_id';
  static const int vehicleCount = 5;

  int _selectedVehicleId = 0;

  /// [initialVehicleId]: main() içinde prefs'ten senkron okunan
  /// assigned_vehicle_id değeri. Async _restore() bitmeden önce
  /// _handleVehicleChange() ateşlendiğinde doğru aracın yüklenmesini sağlar.
  VehicleProvider({int? initialVehicleId}) {
    if (initialVehicleId != null && initialVehicleId >= 0) {
      _selectedVehicleId = initialVehicleId;
    }
    _restore();
  }

  int get selectedVehicleId => _selectedVehicleId;

  String labelFor(int vehicleId) => 'Araç ${vehicleId + 1}';

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();

    // 1) Son elle yapılan seçim (örn. dispatcher UI)
    final manual = prefs.getInt(_prefsKey);
    if (manual != null && manual >= 0 && manual < vehicleCount) {
      if (_selectedVehicleId != manual) {
        _selectedVehicleId = manual;
        notifyListeners();
      }
      return;
    }

    // 2) Giriş sırasında backend'den gelen atanmış araç
    //    (auth_service.login → "assigned_vehicle_id")
    final assigned = prefs.getInt('assigned_vehicle_id');
    if (assigned != null && assigned >= 0) {
      if (_selectedVehicleId != assigned) {
        _selectedVehicleId = assigned;
        notifyListeners();
      }
    }
  }

  Future<void> select(int vehicleId) async {
    if (_selectedVehicleId == vehicleId) return;
    _selectedVehicleId = vehicleId;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, vehicleId);
  }
}
