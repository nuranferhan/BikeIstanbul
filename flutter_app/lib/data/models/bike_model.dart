class BikeModel {
  final String id;
  final String serialNumber;
  final double latitude;
  final double longitude;
  final int batteryLevel;
  final String status;
  final String? stationName;
  final String? label;

  BikeModel({
    required this.id,
    required this.serialNumber,
    required this.latitude,
    required this.longitude,
    required this.batteryLevel,
    required this.status,
    this.stationName,
    this.label,
  });

  factory BikeModel.fromJson(Map<String, dynamic> json) => BikeModel(
        id: (json['id'] ?? '').toString(),
        serialNumber: (json['serial_number'] ?? json['serialNumber'] ?? '').toString(),
        latitude: (json['latitude'] ?? 41.0082).toDouble(),
        longitude: (json['longitude'] ?? 28.9784).toDouble(),
        batteryLevel: json['battery_level'] ?? 100,
        status: json['status'] ?? 'available',
        stationName: json['station_name']?.toString(),
        label: json['label']?.toString(),
      );
}
