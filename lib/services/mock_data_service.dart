import '../models/address_model.dart';
import '../models/route_model.dart' as route_models;
import '../models/driver_model.dart';

class MockDataService {
  // Mock addresses
  static List<Address> getMockAddresses() {
    return [
      Address(
        id: 1,
        orderNumber: 1,
        street: '119/1. Sokak, Evka 3 Mahallesi',
        district: 'Bornova',
        city: 'İzmir',
        postalCode: '35050',
        country: 'Türkiye',
        latitude: 38.3521,
        longitude: 27.1842,
        customerName: 'Sabit Bağlantıç / Ev',
        customerType: 'Başlangıç Noktası',
        isCompleted: false,
      ),
      Address(
        id: 2,
        orderNumber: 2,
        street: 'Meriç Mahallesi',
        district: 'Bornova',
        city: 'İzmir',
        postalCode: '35090',
        country: 'Türkiye',
        latitude: 38.3421,
        longitude: 27.1742,
        customerName: 'Diğer Lokasyon',
        customerType: 'Müşteri',
        isCompleted: false,
      ),
      Address(
        id: 3,
        orderNumber: 3,
        street: '633. Sokak, Fırat Mahallesi',
        district: 'Buca',
        city: 'İzmir',
        postalCode: '35380',
        country: 'Türkiye',
        latitude: 38.3321,
        longitude: 27.1642,
        customerName: 'Yeni Adres',
        customerType: 'Müşteri',
        isCompleted: false,
      ),
      Address(
        id: 4,
        orderNumber: 4,
        street: 'Bahriye Üçok Mahallesi',
        district: 'Karabağlar',
        city: 'İzmir',
        postalCode: '35160',
        country: 'Türkiye',
        latitude: 38.3221,
        longitude: 27.1542,
        customerName: 'Başka Sokak',
        customerType: 'Müşteri',
        isCompleted: false,
      ),
      Address(
        id: 5,
        orderNumber: 5,
        street: 'İpek Pazarı Caddesi',
        district: 'Konak',
        city: 'İzmir',
        postalCode: '35250',
        country: 'Türkiye',
        latitude: 38.3121,
        longitude: 27.1442,
        customerName: 'Son Adres',
        customerType: 'Müşteri',
        isCompleted: false,
      ),
      Address(
        id: 6,
        orderNumber: 6,
        street: '123. Caddesi, Alsancak',
        district: 'Alsancak',
        city: 'İzmir',
        postalCode: '35220',
        country: 'Türkiye',
        latitude: 38.3021,
        longitude: 27.1342,
        customerName: 'Alsancak Müşteri',
        customerType: 'Müşteri',
        isCompleted: false,
      ),
    ];
  }

  // Mock routes
  static List<route_models.Route> getMockRoutes() {
    final today = DateTime.now();
    return [
      route_models.Route(
        id: 1,
        routeNumber: 'Rota #1',
        date: today,
        addresses: getMockAddresses(),
        driverId: 'driver_001',
        driverName: 'Ahmet Yılmaz',
        createdAt: today.subtract(const Duration(hours: 2)),
      ),
      route_models.Route(
        id: 2,
        routeNumber: 'Rota #2',
        date: today.add(const Duration(days: 1)),
        addresses: getMockAddresses().sublist(0, 4),
        driverId: 'driver_001',
        driverName: 'Ahmet Yılmaz',
        createdAt: today.subtract(const Duration(hours: 1)),
      ),
    ];
  }

  // Get route for today
  static route_models.Route getTodayRoute() {
    return getMockRoutes()[0];
  }

  // Get next address from today's route
  static Address? getNextAddress() {
    final route = getTodayRoute();
    final pendingAddresses =
        route.addresses.where((a) => !a.isCompleted).toList();
    return pendingAddresses.isNotEmpty ? pendingAddresses.first : null;
  }

  // Mock driver
  static Driver getMockDriver() {
    return Driver(
      id: 'driver_001',
      name: 'Ahmet Yılmaz',
      email: 'ahmet.yilmaz@rotamobil.com',
      phone: '+90 532 123 45 67',
      position: 'Rota Sürücüsü',
      profileImageUrl: '',
      totalRoutes: 157,
      completionRate: 0.98,
    );
  }

  // Mock routes by month
  static Map<DateTime, List<route_models.Route>> getRoutesByMonth(
      int year, int month) {
    final routesByDate = <DateTime, List<route_models.Route>>{};
    final today = DateTime(year, month, 20);

    routesByDate[today] = [getTodayRoute()];
    routesByDate[DateTime(year, month, 10)] = [getMockRoutes()[1]];

    return routesByDate;
  }
}
