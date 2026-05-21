class TripSummary {
  final String tripId;
  final double distanceKm;
  final int durationMinutes;
  final double cost;
  final double carbonSavingKg;
  final int caloriesBurned;
  final int pointsEarned;
  final String? transferSuggestion;

  TripSummary({
    required this.tripId,
    required this.distanceKm,
    required this.durationMinutes,
    required this.cost,
    required this.carbonSavingKg,
    required this.caloriesBurned,
    required this.pointsEarned,
    this.transferSuggestion,
  });

  factory TripSummary.fromJson(Map<String, dynamic> json) => TripSummary(
        tripId: _readTripId(json),
        distanceKm: (json['distance_km'] ?? json['distanceKm'] ?? 0).toDouble(),
        durationMinutes: json['duration_minutes'] ?? json['durationMinutes'] ?? 0,
        cost: (json['cost'] ?? 0).toDouble(),
        carbonSavingKg: (json['carbon_saving_kg'] ?? json['co2_saving'] ?? 0).toDouble(),
        caloriesBurned: json['calories_burned'] ?? json['caloriesBurned'] ?? 0,
        pointsEarned: json['points_earned'] ?? json['pointsEarned'] ?? 0,
        transferSuggestion: json['transfer_suggestion']?.toString(),
      );

  static String _readTripId(Map<String, dynamic> json) {
    final nested = json['trip'];
    if (nested is Map<String, dynamic>) {
      final nestedId = nested['id'];
      if (nestedId != null) {
        return nestedId.toString();
      }
    }
    return (json['trip_id'] ?? json['id'] ?? '').toString();
  }
}
