class LocationModel {
  final double latitude;
  final double longitude;
  final String address;

  LocationModel({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      address: json['address'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude, 'address': address};
  }
}
