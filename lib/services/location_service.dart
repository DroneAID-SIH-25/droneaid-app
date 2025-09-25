import 'dart:async';

import 'package:geolocator/geolocator.dart';
import '../models/user.dart';

/// Service for handling device location operations
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _currentPosition;
  final StreamController<LocationData> _locationController =
      StreamController<LocationData>.broadcast();

  /// Stream of location updates
  Stream<LocationData> get locationStream => _locationController.stream;

  /// Current cached position
  Position? get currentPosition => _currentPosition;

  /// Check if location services are enabled and permissions are granted
  Future<bool> isLocationServiceReady() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      print('Error checking location service: $e');
      return false;
    }
  }

  /// Get current location once
  Future<LocationData?> getCurrentLocation() async {
    try {
      bool isReady = await isLocationServiceReady();
      if (!isReady) {
        throw LocationServiceException('Location services not available');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentPosition = position;

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
    } catch (e) {
      print('Error getting current location: $e');
      throw LocationServiceException('Failed to get current location: $e');
    }
  }

  /// Start listening to location updates
  Future<void> startLocationUpdates({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // meters
    Duration? timeInterval,
  }) async {
    try {
      bool isReady = await isLocationServiceReady();
      if (!isReady) {
        throw LocationServiceException('Location services not available');
      }

      // Stop existing subscription if any
      await stopLocationUpdates();

      LocationSettings locationSettings = LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        timeLimit: timeInterval,
      );

      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (Position position) {
              _currentPosition = position;

              final locationData = LocationData(
                latitude: position.latitude,
                longitude: position.longitude,
                accuracy: position.accuracy,
                timestamp: position.timestamp,
              );

              _locationController.add(locationData);
            },
            onError: (error) {
              print('Location stream error: $error');
              _locationController.addError(
                LocationServiceException('Location update failed: $error'),
              );
            },
          );
    } catch (e) {
      print('Error starting location updates: $e');
      throw LocationServiceException('Failed to start location updates: $e');
    }
  }

  /// Stop location updates
  Future<void> stopLocationUpdates() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  /// Calculate distance between two points in meters
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Calculate bearing between two points in degrees
  double calculateBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Check if location is within a certain radius of a target point
  bool isWithinRadius(
    LocationData currentLocation,
    LocationData targetLocation,
    double radiusInMeters,
  ) {
    double distance = calculateDistance(
      currentLocation.latitude,
      currentLocation.longitude,
      targetLocation.latitude,
      targetLocation.longitude,
    );
    return distance <= radiusInMeters;
  }

  /// Get location permission status
  Future<LocationPermissionStatus> getPermissionStatus() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      switch (permission) {
        case LocationPermission.denied:
          return LocationPermissionStatus.denied;
        case LocationPermission.deniedForever:
          return LocationPermissionStatus.deniedForever;
        case LocationPermission.whileInUse:
          return LocationPermissionStatus.whileInUse;
        case LocationPermission.always:
          return LocationPermissionStatus.always;
        default:
          return LocationPermissionStatus.denied;
      }
    } catch (e) {
      print('Error getting permission status: $e');
      return LocationPermissionStatus.denied;
    }
  }

  /// Request location permissions
  Future<LocationPermissionStatus> requestPermissions() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      switch (permission) {
        case LocationPermission.denied:
          return LocationPermissionStatus.denied;
        case LocationPermission.deniedForever:
          return LocationPermissionStatus.deniedForever;
        case LocationPermission.whileInUse:
          return LocationPermissionStatus.whileInUse;
        case LocationPermission.always:
          return LocationPermissionStatus.always;
        default:
          return LocationPermissionStatus.denied;
      }
    } catch (e) {
      print('Error requesting permissions: $e');
      return LocationPermissionStatus.denied;
    }
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      print('Error opening location settings: $e');
      return false;
    }
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      print('Error opening app settings: $e');
      return false;
    }
  }

  /// Get last known position (if available)
  Future<LocationData?> getLastKnownPosition() async {
    try {
      Position? position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
    } catch (e) {
      print('Error getting last known position: $e');
      return null;
    }
  }

  /// Check if location is mock/fake
  bool isMockLocation(Position position) {
    return position.isMocked;
  }

  /// Format coordinates for display
  String formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  /// Convert coordinates to human readable address (requires geocoding service)
  String formatCoordinatesForHumans(double latitude, double longitude) {
    // Format in degrees, minutes, seconds
    String latDirection = latitude >= 0 ? 'N' : 'S';
    String lonDirection = longitude >= 0 ? 'E' : 'W';

    double absLat = latitude.abs();
    double absLon = longitude.abs();

    int latDegrees = absLat.floor();
    int lonDegrees = absLon.floor();

    double latMinutes = (absLat - latDegrees) * 60;
    double lonMinutes = (absLon - lonDegrees) * 60;

    int latMin = latMinutes.floor();
    int lonMin = lonMinutes.floor();

    double latSeconds = (latMinutes - latMin) * 60;
    double lonSeconds = (lonMinutes - lonMin) * 60;

    return '${latDegrees}°${latMin}\'${latSeconds.toStringAsFixed(1)}"$latDirection, '
        '${lonDegrees}°${lonMin}\'${lonSeconds.toStringAsFixed(1)}"$lonDirection';
  }

  /// Dispose the service
  Future<void> dispose() async {
    await stopLocationUpdates();
    await _locationController.close();
  }
}

/// Location permission status enum
enum LocationPermissionStatus { denied, deniedForever, whileInUse, always }

/// Custom exception for location service errors
class LocationServiceException implements Exception {
  final String message;

  const LocationServiceException(this.message);

  @override
  String toString() => 'LocationServiceException: $message';
}

/// Extension for LocationPermissionStatus
extension LocationPermissionStatusExtension on LocationPermissionStatus {
  String get displayName {
    switch (this) {
      case LocationPermissionStatus.denied:
        return 'Denied';
      case LocationPermissionStatus.deniedForever:
        return 'Permanently Denied';
      case LocationPermissionStatus.whileInUse:
        return 'While Using App';
      case LocationPermissionStatus.always:
        return 'Always';
    }
  }

  bool get isGranted {
    return this == LocationPermissionStatus.whileInUse ||
        this == LocationPermissionStatus.always;
  }

  bool get isPermanentlyDenied {
    return this == LocationPermissionStatus.deniedForever;
  }
}
