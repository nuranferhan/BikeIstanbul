import 'package:dio/dio.dart';
import '../models/bike_model.dart';

class BikeRepository {
  final Dio _dio;
  static const String _baseUrl = 'http://localhost:8000/api/v1';

  BikeRepository({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: _baseUrl));

  Future<List<BikeModel>> fetchNearby({
    required double latitude,
    required double longitude,
    int radiusMeters = 500,
  }) async {
    try {
      final response = await _dio.get(
        '/bikes/nearby',
        queryParameters: {'lat': latitude, 'lng': longitude, 'radius': radiusMeters},
      );
      final data = (response.data is Map<String, dynamic>)
          ? (response.data['bikes'] as List<dynamic>? ?? const [])
          : (response.data as List<dynamic>);
      return data
          .map((e) => BikeModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return _demoBikes();
    }
  }

  List<BikeModel> _demoBikes() => [
        BikeModel(id: '1', serialNumber: 'BK001', latitude: 41.0082, longitude: 28.9784, batteryLevel: 87, status: 'available', stationName: 'Sultanahmet', label: 'Kiralama için uygun'),
        BikeModel(id: '2', serialNumber: 'BK002', latitude: 41.0102, longitude: 28.9764, batteryLevel: 45, status: 'available', stationName: 'Karaköy', label: 'İstanbulkart uyumlu'),
        BikeModel(id: '3', serialNumber: 'BK003', latitude: 41.0062, longitude: 28.9804, batteryLevel: 92, status: 'available', stationName: 'Kadıköy', label: 'Yüksek batarya'),
        BikeModel(id: '4', serialNumber: 'BK004', latitude: 41.0092, longitude: 28.9744, batteryLevel: 15, status: 'available', stationName: 'Beşiktaş', label: 'Şarj gerekiyor'),
      ];
}
