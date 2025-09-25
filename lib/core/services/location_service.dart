import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_constants.dart';
import '../../models/user.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamController<Location>? _locationStreamController;
  StreamSubscription<Position>? _positionStreamSubscription;
  Location? _lastKnownLocation;
  bool _isListening = false;

  Stream<Location>? get locationStream => _locationStreamController?.stream;
  Location? get lastKnownLocation => _lastKnownLocation;
  bool get isListening => _isListening;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('Error checking location service: $e');
      return false;
    }
  }

  /// Check location permission status
  Future<LocationPermission> checkLocationPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Request location permission
  Future<LocationPermission> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Request location permission using permission_handler
  Future<PermissionStatus> requestLocationPermissionAdvanced() async {
    try {
      PermissionStatus status = await Permission.location.status;

      if (status.isDenied) {
        status = await Permission.location.request();
      }

      if (status.isPermanentlyDenied) {
        // Show dialog to go to settings
        return status;
      }

      return status;
    } catch (e) {
      debugPrint('Error requesting advanced location permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Get current location
  Future<Location?> getCurrentLocation({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      // Check if location service is enabled
      if (!await isLocationServiceEnabled()) {
        throw LocationServiceException('Location services are disabled');
      }

      // Check and request permission
      LocationPermission permission = await checkLocationPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestLocationPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw LocationPermissionException('Location permission denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: timeout,
      );

      final location = Location(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
      );

      _lastKnownLocation = location;
      return location;
    } on TimeoutException {
      throw LocationTimeoutException('Location request timed out');
    } on LocationServiceDisabledException {
      throw LocationServiceException('Location services are disabled');
    } on PermissionDeniedException {
      throw LocationPermissionException('Location permission denied');
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return _getDefaultLocation();
    }
  }

  /// Start listening to location changes
  Future<bool> startLocationUpdates({
    Duration interval = const Duration(seconds: 10),
    double distanceFilter = 10.0, // meters
  }) async {
    try {
      if (_isListening) {
        return true;
      }

      // Check permissions first
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        return false;
      }

      _locationStreamController = StreamController<Location>.broadcast();

      final locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter.toInt(),
      );

      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (Position position) {
              final location = Location(
                latitude: position.latitude,
                longitude: position.longitude,
                accuracy: position.accuracy,
                timestamp: DateTime.now(),
              );

              _lastKnownLocation = location;
              _locationStreamController?.add(location);
            },
            onError: (error) {
              debugPrint('Location stream error: $error');
              _locationStreamController?.addError(error);
            },
          );

      _isListening = true;
      return true;
    } catch (e) {
      debugPrint('Error starting location updates: $e');
      return false;
    }
  }

  /// Stop listening to location changes
  void stopLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _locationStreamController?.close();
    _locationStreamController = null;
    _isListening = false;
  }

  /// Calculate distance between two locations in meters
  double calculateDistance(Location from, Location to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Calculate bearing between two locations
  double calculateBearing(Location from, Location to) {
    return Geolocator.bearingBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Check if location is within a specified radius (in meters)
  bool isLocationWithinRadius(
    Location center,
    Location target,
    double radiusInMeters,
  ) {
    final distance = calculateDistance(center, target);
    return distance <= radiusInMeters;
  }

  /// Get location from coordinates
  Location createLocation(double latitude, double longitude) {
    return Location(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
    );
  }

  /// Get default location (India)
  Location _getDefaultLocation() {
    return Location(
      latitude: AppConstants.defaultLatitude,
      longitude: AppConstants.defaultLongitude,
      address: AppConstants.defaultCountry,
      timestamp: DateTime.now(),
    );
  }

  /// Format location for display
  String formatLocation(Location location, {int precision = 6}) {
    return '${location.latitude.toStringAsFixed(precision)}, '
        '${location.longitude.toStringAsFixed(precision)}';
  }

  /// Get location accuracy description
  String getAccuracyDescription(double? accuracy) {
    if (accuracy == null) return 'Unknown';

    if (accuracy <= 5) return 'Excellent';
    if (accuracy <= 10) return 'Good';
    if (accuracy <= 20) return 'Fair';
    if (accuracy <= 50) return 'Poor';
    return 'Very Poor';
  }

  /// Check if location is valid
  bool isValidLocation(Location? location) {
    if (location == null) return false;

    return location.latitude >= -90 &&
        location.latitude <= 90 &&
        location.longitude >= -180 &&
        location.longitude <= 180;
  }

  /// Private method to check permissions
  Future<bool> _checkPermissions() async {
    try {
      if (!await isLocationServiceEnabled()) {
        return false;
      }

      LocationPermission permission = await checkLocationPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestLocationPermission();
      }

      return permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever;
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      return false;
    }
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      debugPrint('Error opening location settings: $e');
      return false;
    }
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      debugPrint('Error opening app settings: $e');
      return false;
    }
  }

  /// Convert meters to readable distance string
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toInt()} m';
    } else {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  /// Convert bearing to compass direction
  String bearingToCompass(double bearing) {
    final directions = [
      'N',
      'NNE',
      'NE',
      'ENE',
      'E',
      'ESE',
      'SE',
      'SSE',
      'S',
      'SSW',
      'SW',
      'WSW',
      'W',
      'WNW',
      'NW',
      'NNW',
    ];

    final index = ((bearing + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }

  /// Dispose resources
  void dispose() {
    stopLocationUpdates();
    _lastKnownLocation = null;
  }

  /// Get location settings for different accuracy levels
  static LocationSettings getLocationSettings(LocationAccuracy accuracy) {
    switch (accuracy) {
      case LocationAccuracy.lowest:
        return const LocationSettings(
          accuracy: LocationAccuracy.lowest,
          distanceFilter: 100,
        );
      case LocationAccuracy.low:
        return const LocationSettings(
          accuracy: LocationAccuracy.low,
          distanceFilter: 50,
        );
      case LocationAccuracy.medium:
        return const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 25,
        );
      case LocationAccuracy.high:
        return const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        );
      case LocationAccuracy.best:
        return const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        );
      case LocationAccuracy.bestForNavigation:
        return const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 1,
        );
      default:
        return const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        );
    }
  }
}

// Custom Exceptions
class LocationServiceException implements Exception {
  final String message;
  LocationServiceException(this.message);

  @override
  String toString() => 'LocationServiceException: $message';
}

class LocationPermissionException implements Exception {
  final String message;
  LocationPermissionException(this.message);

  @override
  String toString() => 'LocationPermissionException: $message';
}

class LocationTimeoutException implements Exception {
  final String message;
  LocationTimeoutException(this.message);

  @override
  String toString() => 'LocationTimeoutException: $message';
}
