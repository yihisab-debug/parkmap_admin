class ParkingLot {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int totalSpots;
  final int pricePerHour;

  ParkingLot({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.totalSpots,
    required this.pricePerHour,
  });

  factory ParkingLot.fromMap(String id, Map<String, dynamic> map) {
    return ParkingLot(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      totalSpots: (map['totalSpots'] ?? 0) as int,
      pricePerHour: (map['pricePerHour'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'totalSpots': totalSpots,
      'pricePerHour': pricePerHour,
    };
  }
}
