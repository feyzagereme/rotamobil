import 'address_model.dart';

class Route {
  final int id;
  final String routeNumber;
  final DateTime date;
  final List<Address> addresses;
  final String driverId;
  final String driverName;
  final DateTime createdAt;
  final bool isCompleted;

  Route({
    required this.id,
    required this.routeNumber,
    required this.date,
    required this.addresses,
    required this.driverId,
    required this.driverName,
    required this.createdAt,
    this.isCompleted = false,
  });

  double get totalDistance {
    // Basit hesaplama - gerçekte lat/lng arası harita API kullanılmalı
    return 44.7;
  }

  int get totalStops => addresses.length;

  int get completedStops => addresses.where((a) => a.isCompleted).length;

  double get completionPercentage {
    if (addresses.isEmpty) return 0.0;
    return (completedStops / addresses.length) * 100;
  }

  String get estimatedTime => '2.5 saat'; // Basit mock

  Route copyWith({
    int? id,
    String? routeNumber,
    DateTime? date,
    List<Address>? addresses,
    String? driverId,
    String? driverName,
    DateTime? createdAt,
    bool? isCompleted,
  }) {
    return Route(
      id: id ?? this.id,
      routeNumber: routeNumber ?? this.routeNumber,
      date: date ?? this.date,
      addresses: addresses ?? this.addresses,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
