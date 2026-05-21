class StationModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int availableBikes;
  final int capacity;
  final int airQualityIndex;
  final bool isActive;

  StationModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.availableBikes,
    required this.capacity,
    this.airQualityIndex = 50,
    this.isActive = true,
  });

  factory StationModel.fromJson(Map<String, dynamic> json) => StationModel(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        latitude: (json['latitude'] ?? 41.0082).toDouble(),
        longitude: (json['longitude'] ?? 28.9784).toDouble(),
        availableBikes: json['available_bikes'] ?? 0,
        capacity: json['capacity'] ?? 10,
        airQualityIndex: json['air_quality_index'] ?? 50,
        isActive: json['is_active'] ?? true,
      );
}
