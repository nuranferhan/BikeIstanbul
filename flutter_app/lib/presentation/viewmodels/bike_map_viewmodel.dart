import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/bike_model.dart';
import '../../../data/models/station_model.dart';
import '../../../data/models/trip_summary_model.dart';
import '../../../data/repositories/bike_repository.dart';
import '../../../data/repositories/trip_repository.dart';

enum MapState { idle, loading, error }

class BikeMapViewModel extends ChangeNotifier {
  final BikeRepository _bikeRepository;
  final TripRepository _tripRepository;

  BikeMapViewModel({
    required BikeRepository bikeRepository,
    required TripRepository tripRepository,
  })  : _bikeRepository = bikeRepository,
        _tripRepository = tripRepository;

  MapState _state = MapState.idle;
  String? _errorMessage;
  List<BikeModel> _nearbyBikes = [];
  List<StationModel> _stations = [];
  BikeModel? _selectedBike;
  String? _activeTripId;

  MapState get state => _state;
  String? get errorMessage => _errorMessage;
  List<BikeModel> get nearbyBikes => _nearbyBikes;
  List<StationModel> get stations => _stations;
  BikeModel? get selectedBike => _selectedBike;
  bool get hasActiveTrip => _activeTripId != null;

  Future<void> loadNearbyBikes(LatLng userLocation) async {
    _setState(MapState.loading);
    try {
      _nearbyBikes = await _bikeRepository.fetchNearby(
        latitude: userLocation.latitude,
        longitude: userLocation.longitude,
        radiusMeters: 500,
      );
      _setState(MapState.idle);
    } catch (e) {
      _setError('Bisikletler yüklenemedi: $e');
    }
  }

  void selectBike(BikeModel bike) {
    _selectedBike = bike;
    notifyListeners();
  }

  void clearSelection() {
    _selectedBike = null;
    notifyListeners();
  }

  Future<bool> startRental(String bikeId) async {
    _setState(MapState.loading);
    try {
      final trip = await _tripRepository.startRental(bikeId: bikeId);
      _activeTripId = trip.id;
      _selectedBike = null;
      _setState(MapState.idle);
      return true;
    } catch (e) {
      _setError('Kiralama başlatılamadı: $e');
      return false;
    }
  }

  Future<TripSummary?> endTrip() async {
    if (_activeTripId == null) return null;
    _setState(MapState.loading);
    try {
      final summary = await _tripRepository.endTrip(tripId: _activeTripId!);
      _activeTripId = null;
      _setState(MapState.idle);
      return summary;
    } catch (e) {
      _setError('Yolculuk sonlandırılamadı: $e');
      return null;
    }
  }

  void _setState(MapState newState) {
    _state = newState;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _state = MapState.error;
    _errorMessage = message;
    notifyListeners();
  }
}
