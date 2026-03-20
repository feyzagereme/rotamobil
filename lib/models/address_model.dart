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
  });

  String get fullAddress => '$street, $district, $city, $postalCode, $country';

  Address copyWith({bool? isCompleted}) {
    return Address(
      id: id,
      orderNumber: orderNumber,
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
      notes: notes,
    );
  }
}
