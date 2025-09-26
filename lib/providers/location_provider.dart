import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user.dart';

class LocationProvider extends ChangeNotifier {
  LocationData? _currentLocation;
  bool _isLocationServiceEnabled = false;
  bool _hasPermission = false;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Position>? _positionStream;

  // Getters
  LocationData? get currentLocation => _currentLocation;
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;
  bool get hasPermission => _hasPermission;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLocationAvailable => _currentLocation != null;

  // Default location set to India (New Delhi)
  static final LocationData _defaultIndiaLocation = LocationData(
    latitude: 28.6139,
    longitude: 77.2090,
    address: 'New Delhi, India',
  );

  LocationData get locationOrDefault =>
      _currentLocation ?? _defaultIndiaLocation;

  Future<void> initializeLocationService() async {
    _setLoading(true);
    _setError(null);

    try {
      // Check if location services are enabled
      _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!_isLocationServiceEnabled) {
        _setError('Location services are disabled');
        _setCurrentLocation(_defaultIndiaLocation);
        _setLoading(false);
        return;
      }

      // Request location permission
      await _requestLocationPermission();

      if (_hasPermission) {
        await getCurrentLocation();
        _startLocationTracking();
      } else {
        _setCurrentLocation(_defaultIndiaLocation);
      }
    } catch (e) {
      _setError('Failed to initialize location service: $e');
      _setCurrentLocation(_defaultIndiaLocation);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _setError('Location permissions are permanently denied');
        _hasPermission = false;
        return;
      }

      if (permission == LocationPermission.denied) {
        _setError('Location permissions denied');
        _hasPermission = false;
        return;
      }

      _hasPermission = true;
    } catch (e) {
      _setError('Failed to request location permission: $e');
      _hasPermission = false;
    }
  }

  Future<void> getCurrentLocation() async {
    if (!_hasPermission || !_isLocationServiceEnabled) {
      return;
    }

    try {
      _setLoading(true);
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final String? address = await _getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final LocationData location = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
      );

      _setCurrentLocation(location);
    } catch (e) {
      _setError('Failed to get current location: $e');
      // Use default India location as fallback
      _setCurrentLocation(_defaultIndiaLocation);
    } finally {
      _setLoading(false);
    }
  }

  void _startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) async {
            final String? address = await _getAddressFromCoordinates(
              position.latitude,
              position.longitude,
            );

            final LocationData location = LocationData(
              latitude: position.latitude,
              longitude: position.longitude,
              address: address,
              accuracy: position.accuracy,
              timestamp: DateTime.now(),
            );

            _setCurrentLocation(location);
          },
          onError: (error) {
            _setError('Location tracking error: $error');
          },
        );
  }

  Future<String?> _getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // For now, return a simple address format
      // In a real app, you would use a geocoding service
      return 'Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}';
    } catch (e) {
      debugPrint('Failed to get address: $e');
      return null;
    }
  }

  double calculateDistance(LocationData from, LocationData to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  bool isWithinGeofence(
    LocationData center,
    LocationData target,
    double radiusInMeters,
  ) {
    final double distance = calculateDistance(center, target);
    return distance <= radiusInMeters;
  }

  bool isDroneWithin1KmGeofence(LocationData droneLocation) {
    if (_currentLocation == null) return false;
    return isWithinGeofence(
      _currentLocation!,
      droneLocation,
      1000,
    ); // 1km in meters
  }

  List<LocationData> getDronesInGeofence(
    List<LocationData> droneLocations,
    double radiusInMeters,
  ) {
    if (_currentLocation == null) return [];

    return droneLocations.where((droneLocation) {
      return isWithinGeofence(_currentLocation!, droneLocation, radiusInMeters);
    }).toList();
  }

  Future<void> refreshLocation() async {
    await getCurrentLocation();
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  void _setCurrentLocation(LocationData? location) {
    _currentLocation = location;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}
