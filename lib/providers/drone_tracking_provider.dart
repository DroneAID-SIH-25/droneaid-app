import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/drone.dart';
import '../models/user.dart';
import '../services/mock_data_service.dart';
import 'location_provider.dart';

class DroneTrackingProvider extends ChangeNotifier {
  final LocationProvider _locationProvider;
  final MockDataService _mockDataService = MockDataService();

  List<Drone> _allDrones = [];
  List<Drone> _nearbyDrones = [];
  List<Drone> _dronesInGeofence = [];
  Map<String, DroneMovementData> _droneMovements = {};
  Timer? _trackingTimer;
  bool _isTracking = false;
  String? _error;

  // Geofence settings
  static const double _geofenceRadius = 1000.0; // 1km in meters
  static const Duration _updateInterval = Duration(seconds: 2);

  DroneTrackingProvider(this._locationProvider);

  // Getters
  List<Drone> get allDrones => _allDrones;
  List<Drone> get nearbyDrones => _nearbyDrones;
  List<Drone> get dronesInGeofence => _dronesInGeofence;
  bool get isTracking => _isTracking;
  String? get error => _error;
  double get geofenceRadius => _geofenceRadius;

  Future<void> startTracking() async {
    if (_isTracking) return;

    try {
      _isTracking = true;
      _error = null;

      // Load initial drone data
      await _loadDrones();

      // Start tracking timer
      _trackingTimer = Timer.periodic(_updateInterval, (timer) {
        _updateDronePositions();
        _updateGeofenceDrones();
      });

      notifyListeners();
    } catch (e) {
      _error = 'Failed to start drone tracking: $e';
      _isTracking = false;
      notifyListeners();
    }
  }

  void stopTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
    _isTracking = false;
    notifyListeners();
  }

  Future<void> _loadDrones() async {
    try {
      _allDrones = await _mockDataService.getMockDrones();

      // Initialize movement data for each drone
      for (final drone in _allDrones) {
        _droneMovements[drone.id] = DroneMovementData(
          currentLocation: drone.location,
          targetLocation: _generateRandomTargetLocation(drone.location),
          speed: _generateRandomSpeed(),
          lastUpdate: DateTime.now(),
        );
      }

      _updateGeofenceDrones();
    } catch (e) {
      _error = 'Failed to load drones: $e';
      rethrow;
    }
  }

  void _updateDronePositions() {
    final now = DateTime.now();

    for (int i = 0; i < _allDrones.length; i++) {
      final drone = _allDrones[i];
      final movement = _droneMovements[drone.id];

      if (movement != null) {
        final newLocation = _calculateNewPosition(movement, now);

        // Update drone with new location
        _allDrones[i] = drone.copyWith(location: newLocation);

        // Update movement data
        _droneMovements[drone.id] = movement.copyWith(
          currentLocation: newLocation,
          lastUpdate: now,
        );

        // Check if drone reached target, generate new target
        if (_isLocationReached(newLocation, movement.targetLocation)) {
          _droneMovements[drone.id] = movement.copyWith(
            targetLocation: _generateRandomTargetLocation(newLocation),
            speed: _generateRandomSpeed(),
          );
        }
      }
    }

    _updateGeofenceDrones();
  }

  LocationData _calculateNewPosition(DroneMovementData movement, DateTime now) {
    final timeDiff =
        now.difference(movement.lastUpdate).inMilliseconds / 1000.0;
    final distanceToMove = movement.speed * timeDiff; // meters per second

    final currentLat = movement.currentLocation.latitude;
    final currentLng = movement.currentLocation.longitude;
    final targetLat = movement.targetLocation.latitude;
    final targetLng = movement.targetLocation.longitude;

    // Calculate distance to target
    final distanceToTarget = _calculateDistance(
      currentLat,
      currentLng,
      targetLat,
      targetLng,
    );

    if (distanceToTarget <= distanceToMove) {
      // Reached target
      return movement.targetLocation;
    }

    // Calculate new position along the path
    final ratio = distanceToMove / distanceToTarget;
    final newLat = currentLat + (targetLat - currentLat) * ratio;
    final newLng = currentLng + (targetLng - currentLng) * ratio;

    return LocationData(
      latitude: newLat,
      longitude: newLng,
      address: 'In Flight',
      timestamp: now,
    );
  }

  void _updateGeofenceDrones() {
    final userLocation = _locationProvider.currentLocation;
    if (userLocation == null) {
      _dronesInGeofence = [];
      _nearbyDrones = [];
      notifyListeners();
      return;
    }

    _dronesInGeofence = _allDrones.where((drone) {
      final distance = _calculateDistance(
        userLocation.latitude,
        userLocation.longitude,
        drone.location.latitude,
        drone.location.longitude,
      );
      return distance <= _geofenceRadius;
    }).toList();

    // Sort by distance (closest first)
    _dronesInGeofence.sort((a, b) {
      final distanceA = _calculateDistance(
        userLocation.latitude,
        userLocation.longitude,
        a.location.latitude,
        a.location.longitude,
      );
      final distanceB = _calculateDistance(
        userLocation.latitude,
        userLocation.longitude,
        b.location.latitude,
        b.location.longitude,
      );
      return distanceA.compareTo(distanceB);
    });

    _nearbyDrones = _dronesInGeofence.take(5).toList(); // Top 5 nearest

    notifyListeners();
  }

  LocationData _generateRandomTargetLocation(LocationData currentLocation) {
    final random = Random();

    // Generate random target within 2km radius
    final distance = 500 + random.nextDouble() * 1500; // 500m to 2km
    final bearing = random.nextDouble() * 2 * pi;

    final newLat =
        currentLocation.latitude +
        (distance * cos(bearing)) / 111320; // 1 degree lat = ~111.32km
    final newLng =
        currentLocation.longitude +
        (distance * sin(bearing)) /
            (111320 * cos(currentLocation.latitude * pi / 180));

    return LocationData(
      latitude: newLat,
      longitude: newLng,
      address: 'Target Location',
    );
  }

  double _generateRandomSpeed() {
    final random = Random();
    return 15.0 + random.nextDouble() * 15.0; // 15-30 m/s (54-108 km/h)
  }

  bool _isLocationReached(LocationData current, LocationData target) {
    final distance = _calculateDistance(
      current.latitude,
      current.longitude,
      target.latitude,
      target.longitude,
    );
    return distance < 50; // Within 50 meters
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // Earth's radius in meters
    final double dLat = (lat2 - lat1) * pi / 180;
    final double dLon = (lon2 - lon1) * pi / 180;

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double getDistanceToUser(Drone drone) {
    final userLocation = _locationProvider.currentLocation;
    if (userLocation == null) return double.infinity;

    return _calculateDistance(
      userLocation.latitude,
      userLocation.longitude,
      drone.location.latitude,
      drone.location.longitude,
    );
  }

  Duration getEstimatedTimeOfArrival(Drone drone) {
    final distance = getDistanceToUser(drone);
    final movement = _droneMovements[drone.id];
    final speed = movement?.speed ?? 20.0; // Default speed

    final timeInSeconds = distance / speed;
    return Duration(seconds: timeInSeconds.round());
  }

  String getFormattedDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  String getFormattedETA(Duration eta) {
    if (eta.inMinutes < 1) {
      return '${eta.inSeconds}s';
    } else if (eta.inHours < 1) {
      return '${eta.inMinutes}m ${eta.inSeconds % 60}s';
    } else {
      return '${eta.inHours}h ${eta.inMinutes % 60}m';
    }
  }

  // Get drone details with calculated metrics
  DroneTrackingInfo getDroneTrackingInfo(Drone drone) {
    return DroneTrackingInfo(
      drone: drone,
      distanceToUser: getDistanceToUser(drone),
      estimatedTimeOfArrival: getEstimatedTimeOfArrival(drone),
      isInGeofence: _dronesInGeofence.contains(drone),
      movement: _droneMovements[drone.id],
    );
  }

  Future<void> refresh() async {
    if (_isTracking) {
      await _loadDrones();
    }
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

class DroneMovementData {
  final LocationData currentLocation;
  final LocationData targetLocation;
  final double speed; // meters per second
  final DateTime lastUpdate;

  DroneMovementData({
    required this.currentLocation,
    required this.targetLocation,
    required this.speed,
    required this.lastUpdate,
  });

  DroneMovementData copyWith({
    LocationData? currentLocation,
    LocationData? targetLocation,
    double? speed,
    DateTime? lastUpdate,
  }) {
    return DroneMovementData(
      currentLocation: currentLocation ?? this.currentLocation,
      targetLocation: targetLocation ?? this.targetLocation,
      speed: speed ?? this.speed,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

class DroneTrackingInfo {
  final Drone drone;
  final double distanceToUser;
  final Duration estimatedTimeOfArrival;
  final bool isInGeofence;
  final DroneMovementData? movement;

  DroneTrackingInfo({
    required this.drone,
    required this.distanceToUser,
    required this.estimatedTimeOfArrival,
    required this.isInGeofence,
    this.movement,
  });

  String get formattedDistance {
    if (distanceToUser < 1000) {
      return '${distanceToUser.round()} m';
    } else {
      return '${(distanceToUser / 1000).toStringAsFixed(1)} km';
    }
  }

  String get formattedETA {
    if (estimatedTimeOfArrival.inMinutes < 1) {
      return '${estimatedTimeOfArrival.inSeconds}s';
    } else if (estimatedTimeOfArrival.inHours < 1) {
      return '${estimatedTimeOfArrival.inMinutes}m';
    } else {
      return '${estimatedTimeOfArrival.inHours}h ${estimatedTimeOfArrival.inMinutes % 60}m';
    }
  }
}
