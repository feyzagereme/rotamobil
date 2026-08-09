class Address {
  final int id;
  final int orderNumber;
  final String street;
  final String district;
  final String city;
  final String postalCode;
  final String country;
  final double latitude;
  final double longitude;
  final String customerName;
  final String customerType;
  final bool isCompleted;
  final String? notes;
  final String? phone;

  /// Bu durak, sürücünün rotaya başladığı hastane/başlangıç noktasıysa
  /// true. Sürücü zaten orada olduğu için otomatik tamamlanmış sayılır,
  /// elle işaretlenmesi gerekmez.
  final bool isStartPoint;

  /// Bu durak, sürücünün son duraktan sonra döneceği hastane noktasıysa
  /// true. Diğer duraklar gibi elle "tamamlandı" işaretlenir, sadece
  /// görünümü (etiket/ikon) farklıdır.
  final bool isReturnToBase;

  Address({
    required this.id,
    required this.orderNumber,
    required this.street,
    required this.district,
    required this.city,
    required this.postalCode,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.customerName,
    required this.customerType,
    this.isCompleted = false,
    this.notes,
    this.phone,
    this.isStartPoint = false,
    this.isReturnToBase = false,
  });

  String get fullAddress => '$street, $district, $city, $postalCode, $country';

  factory Address.fromRouteStop(
    Map<String, dynamic> json, {
    int fallbackOrder = 1,
  }) {
    final order = _toInt(json['order'] ?? json['orderNumber'], fallbackOrder);
    final id = _toInt(json['id'] ?? json['code'], order);
    final addressText = _toString(
      json['address'] ?? json['fullAddress'] ?? json['street'] ?? json['title'],
      'Adres bilgisi yok',
    );

    return Address(
      id: id,
      orderNumber: order,
      street: _toString(json['street'] ?? addressText, addressText),
      district: _toString(json['district'] ?? json['county'], ''),
      city: _toString(json['city'] ?? json['province'], ''),
      postalCode: _toString(json['postalCode'] ?? json['postal_code'], ''),
      country: _toString(json['country'], 'Türkiye'),
      latitude: _toDouble(json['latitude'] ?? json['lat'], 0),
      longitude: _toDouble(json['longitude'] ?? json['lng'] ?? json['lon'], 0),
      customerName: _toString(
        json['customerName'] ??
            json['customer_name'] ??
            json['title'] ??
            json['name'],
        'Durak $order',
      ),
      customerType: _toString(
        json['customerType'] ?? json['customer_type'] ?? json['type'],
        'visit',
      ),
      isCompleted: _toBool(json['completed'] ?? json['isCompleted'], false),
      notes: json['notes']?.toString(),
      phone: _toNullableString(json['phone'] ?? json['customerPhone'] ?? json['telefon']),
    );
  }

  Map<String, dynamic> toRouteStopJson() {
    return {
      'id': id,
      'order': orderNumber,
      'street': street,
      'district': district,
      'city': city,
      'postalCode': postalCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'customerName': customerName,
      'customerType': customerType,
      'completed': isCompleted,
      'notes': notes,
      'phone': phone,
    };
  }

  Address copyWith({
    bool? isCompleted,
    int? orderNumber,
    bool? isStartPoint,
    bool? isReturnToBase,
    String? notes,
  }) {
    return Address(
      id: id,
      orderNumber: orderNumber ?? this.orderNumber,
      street: street,
      district: district,
      city: city,
      postalCode: postalCode,
      country: country,
      latitude: latitude,
      longitude: longitude,
      customerName: customerName,
      customerType: customerType,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      isStartPoint: isStartPoint ?? this.isStartPoint,
      isReturnToBase: isReturnToBase ?? this.isReturnToBase,
    );
  }

  static String _toString(dynamic value, String fallback) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String? _toNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int _toInt(dynamic value, int fallback) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static double _toDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  static bool _toBool(dynamic value, bool fallback) {
    if (value == null) return fallback;
    if (value is bool) return value;
    final text = value.toString().toLowerCase().trim();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
    return fallback;
  }
}