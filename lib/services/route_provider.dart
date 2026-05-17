import 'package:flutter/material.dart';
import '../models/address_model.dart';
import '../services/mock_data_service.dart';

class RouteProvider extends ChangeNotifier {
  late List<Address> _addresses;

  RouteProvider() {
    _addresses = List<Address>.from(MockDataService.getTodayRoute().addresses);
  }

  List<Address> get addresses => _addresses;

  int get totalStops => _addresses.length;
  int get completedStops => _addresses.where((a) => a.isCompleted).length;
  double get completionPercentage =>
      _addresses.isEmpty ? 0 : (completedStops / totalStops) * 100;

  // Sıra değiştir
  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final item = _addresses.removeAt(oldIndex);
    _addresses.insert(newIndex, item);
    notifyListeners();
  }

  // Haritadan yeni adres ekle
  void addAddress(Address address) {
    _addresses.add(address);
    notifyListeners();
  }

  // Adresi sil
  void removeAddress(int index) {
    _addresses.removeAt(index);
    notifyListeners();
  }

  // Tamamlandı işaretle
  void toggleCompleted(int index) {
    final a = _addresses[index];
    _addresses[index] = a.copyWith(isCompleted: !a.isCompleted);
    notifyListeners();
  }
}
