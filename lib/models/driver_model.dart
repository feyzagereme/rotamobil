class Driver {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String position;
  final String profileImageUrl;
  final int totalRoutes;
  final double completionRate;
  final bool notificationsEnabled;
  final bool gpsEnabled;
  final bool voiceGuidanceEnabled;

  Driver({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.position,
    required this.profileImageUrl,
    required this.totalRoutes,
    required this.completionRate,
    this.notificationsEnabled = true,
    this.gpsEnabled = true,
    this.voiceGuidanceEnabled = true,
  });

  Driver copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? position,
    String? profileImageUrl,
    int? totalRoutes,
    double? completionRate,
    bool? notificationsEnabled,
    bool? gpsEnabled,
    bool? voiceGuidanceEnabled,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      position: position ?? this.position,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      totalRoutes: totalRoutes ?? this.totalRoutes,
      completionRate: completionRate ?? this.completionRate,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      gpsEnabled: gpsEnabled ?? this.gpsEnabled,
      voiceGuidanceEnabled: voiceGuidanceEnabled ?? this.voiceGuidanceEnabled,
    );
  }
}
