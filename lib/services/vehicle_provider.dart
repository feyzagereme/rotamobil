import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama genelinde seçili aracı (0..4 → Araç 1..5) tutar.
/// Tüm sürücüler aynı hesapla giriş yapar, bu seçici ile hangi aracın
/// rotasını/filo durumunu izleyecekleri belirlenir.
class VehicleProvider extends ChangeNotifier {
  static const String _prefsKey = 'selected_vehicle_id';
  static const int vehicleCount = 5;

  int _selectedVehicleId = 0;

  VehicleProvider() {
    _restore();
  }

  int get selectedVehicleId => _selectedVehicleId;

  String labelFor(int vehicleId) => 'Araç ${vehicleId + 1}';

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_prefsKey);
    if (stored != null && stored >= 0 && stored < vehicleCount) {
      _selectedVehicleId = stored;
      notifyListeners();
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
