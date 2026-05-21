import 'package:dio/dio.dart';
import '../models/trip_summary_model.dart';

class TripStartResult {
  final String id;
  TripStartResult({required this.id});
}

class TripRepository {
  final Dio _dio;
  static const String _baseUrl = 'http://localhost:8000/api/v1';
  String? _token;

  TripRepository({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: _baseUrl));

  void setToken(String token) => _token = token;

  Future<TripStartResult> startRental({required String bikeId}) async {
    try {
      final response = await _dio.post(
        '/trips/start',
        data: {'bike_id': bikeId},
        options: Options(headers: {'Authorization': 'Bearer $_token'}),
      );
      return TripStartResult(id: response.data['id'].toString());
    } catch (_) {
      return TripStartResult(id: 'demo-trip-${DateTime.now().millisecondsSinceEpoch}');
    }
  }

  Future<TripSummary> endTrip({required String tripId}) async {
    try {
      final response = await _dio.patch(
        '/trips/$tripId/end',
        options: Options(headers: {'Authorization': 'Bearer $_token'}),
      );
      return TripSummary.fromJson(response.data);
    } catch (_) {
      return TripSummary(
        tripId: tripId,
        distanceKm: 3.5,
        durationMinutes: 25,
        cost: 12.50,
        carbonSavingKg: 0.73,
        caloriesBurned: 105,
        pointsEarned: 10,
        transferSuggestion: 'Marmaray: 14:35\'te kalkar · Kadıköy İstasyonu',
      );
    }
  }
}
