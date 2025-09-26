import 'dart:async';
import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import '../models/drone.dart';
import '../models/user.dart';
import '../models/mission.dart';
import '../models/gcs_station.dart';
import 'location_service.dart';

/// Comprehensive map service for drone tracking, route optimization, and geofencing
class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  final LocationService _locationService = LocationService();
  final Distance _distance = const Distance();

  // Constants
  static const double _defaultGeofenceRadius = 1000.0; // 1km in meters
  static const double _droneSpeed = 15.0; // 15 m/s average drone speed
  static const double _earthRadius = 6371000.0; // Earth radius in meters

  /// Get current location using location service
  Future<LocationData?> getCurrentLocation() async {
    try {
      return await _locationService.getCurrentLocation();
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Calculate route points between start and end locations
  /// For now returns straight line points, can be extended for actual routing
  Future<List<LatLng>> getRoutePoints(
    LatLng start,
    LatLng end, {
    int waypoints = 10,
  }) async {
    List<LatLng> routePoints = [];

    // Calculate intermediate points for smooth route visualization
    for (int i = 0; i <= waypoints; i++) {
      double ratio = i / waypoints;
      double lat = start.latitude + (end.latitude - start.latitude) * ratio;
      double lng = start.longitude + (end.longitude - start.longitude) * ratio;
      routePoints.add(LatLng(lat, lng));
    }

    return routePoints;
  }

  /// Check if a drone is within geofence of user location
  bool isWithinGeofence(
    LocationData userLocation,
    LocationData droneLocation, {
    double? radius,
  }) {
    double geofenceRadius = radius ?? _defaultGeofenceRadius;

    double distance = calculateDistance(
      LatLng(userLocation.latitude, userLocation.longitude),
      LatLng(droneLocation.latitude, droneLocation.longitude),
    );

    return distance <= geofenceRadius;
  }

  /// Get all drones within geofence of a center point
  List<Drone> getDronesInGeofence(
    LocationData centerLocation,
    List<Drone> allDrones, {
    double? radius,
  }) {
    double geofenceRadius = radius ?? _defaultGeofenceRadius;

    return allDrones.where((drone) {
      return isWithinGeofence(
        centerLocation,
        drone.location,
        radius: geofenceRadius,
      );
    }).toList();
  }

  /// Calculate distance between two points in meters
  double calculateDistance(LatLng start, LatLng end) {
    return _distance.as(LengthUnit.Meter, start, end);
  }

  /// Calculate bearing between two points in degrees
  double calculateBearing(LatLng start, LatLng end) {
    double lat1Rad = start.latitude * (math.pi / 180);
    double lat2Rad = end.latitude * (math.pi / 180);
    double deltaLonRad = (end.longitude - start.longitude) * (math.pi / 180);

    double x = math.sin(deltaLonRad) * math.cos(lat2Rad);
    double y =
        math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(deltaLonRad);

    double bearingRad = math.atan2(x, y);
    double bearingDeg = bearingRad * (180 / math.pi);

    return (bearingDeg + 360) % 360;
  }

  /// Calculate ETA based on distance and speed
  String calculateETA(double distanceInMeters, {double? speedMps}) {
    double speed = speedMps ?? _droneSpeed;
    double timeInSeconds = distanceInMeters / speed;

    if (timeInSeconds < 60) {
      return '${timeInSeconds.round()}s';
    } else if (timeInSeconds < 3600) {
      int minutes = (timeInSeconds / 60).round();
      return '${minutes}m';
    } else {
      int hours = (timeInSeconds / 3600).floor();
      int minutes = ((timeInSeconds % 3600) / 60).round();
      return '${hours}h ${minutes}m';
    }
  }

  /// Optimize route using nearest neighbor algorithm (KNN approach)
  RouteOptimizationResult optimizeRoute(
    LatLng startPoint,
    List<LatLng> targets, {
    MissionPriority? priority,
  }) {
    if (targets.isEmpty) {
      return RouteOptimizationResult(
        optimizedRoute: [startPoint],
        totalDistance: 0.0,
        estimatedDuration: '0s',
        routeEfficiency: 1.0,
      );
    }

    List<LatLng> optimizedRoute = [startPoint];
    List<LatLng> remainingTargets = List.from(targets);
    LatLng currentPosition = startPoint;
    double totalDistance = 0.0;

    // Apply priority-based sorting first
    if (priority != null && priority == MissionPriority.critical) {
      // For critical missions, prioritize closest targets
      remainingTargets.sort((a, b) {
        double distanceA = calculateDistance(currentPosition, a);
        double distanceB = calculateDistance(currentPosition, b);
        return distanceA.compareTo(distanceB);
      });
    }

    // Nearest neighbor optimization
    while (remainingTargets.isNotEmpty) {
      double shortestDistance = double.infinity;
      LatLng nearestTarget = remainingTargets.first;

      for (LatLng target in remainingTargets) {
        double distance = calculateDistance(currentPosition, target);
        if (distance < shortestDistance) {
          shortestDistance = distance;
          nearestTarget = target;
        }
      }

      optimizedRoute.add(nearestTarget);
      totalDistance += shortestDistance;
      currentPosition = nearestTarget;
      remainingTargets.remove(nearestTarget);
    }

    // Calculate route efficiency (compared to naive approach)
    double naiveDistance = _calculateNaiveRouteDistance(startPoint, targets);
    double routeEfficiency = naiveDistance > 0
        ? (naiveDistance / totalDistance)
        : 1.0;

    String estimatedDuration = calculateETA(totalDistance);

    return RouteOptimizationResult(
      optimizedRoute: optimizedRoute,
      totalDistance: totalDistance,
      estimatedDuration: estimatedDuration,
      routeEfficiency: routeEfficiency,
    );
  }

  /// Calculate total distance for naive route (no optimization)
  double _calculateNaiveRouteDistance(LatLng start, List<LatLng> targets) {
    if (targets.isEmpty) return 0.0;

    double totalDistance = 0.0;
    LatLng currentPos = start;

    for (LatLng target in targets) {
      totalDistance += calculateDistance(currentPos, target);
      currentPos = target;
    }

    return totalDistance;
  }

  /// Find optimal GCS station for a target location
  GCSStation? findOptimalGCSStation(
    LatLng targetLocation,
    List<GCSStation> gcsStations,
  ) {
    if (gcsStations.isEmpty) return null;

    GCSStation optimalStation = gcsStations.first;
    double shortestDistance = calculateDistance(
      LatLng(
        optimalStation.coordinates.latitude,
        optimalStation.coordinates.longitude,
      ),
      targetLocation,
    );

    for (GCSStation station in gcsStations.skip(1)) {
      double distance = calculateDistance(
        LatLng(station.coordinates.latitude, station.coordinates.longitude),
        targetLocation,
      );

      if (distance < shortestDistance) {
        shortestDistance = distance;
        optimalStation = station;
      }
    }

    return optimalStation;
  }

  /// Check for basic obstacle awareness (simulation)
  List<ObstacleInfo> detectObstacles(LatLng start, LatLng end) {
    List<ObstacleInfo> obstacles = [];

    // Simulate common obstacles in India
    double distance = calculateDistance(start, end);

    // Add simulated obstacles based on distance and terrain
    if (distance > 5000) {
      // Long distance missions
      obstacles.add(
        ObstacleInfo(
          type: ObstacleType.terrain,
          position: _getMiddlePoint(start, end),
          severity: ObstacleSeverity.medium,
          description: 'Elevated terrain detected',
        ),
      );
    }

    // Simulate weather obstacles
    if (_isInWeatherZone(start, end)) {
      obstacles.add(
        ObstacleInfo(
          type: ObstacleType.weather,
          position: start,
          severity: ObstacleSeverity.high,
          description: 'Adverse weather conditions',
        ),
      );
    }

    return obstacles;
  }

  /// Get middle point between two coordinates
  LatLng _getMiddlePoint(LatLng start, LatLng end) {
    double midLat = (start.latitude + end.latitude) / 2;
    double midLng = (start.longitude + end.longitude) / 2;
    return LatLng(midLat, midLng);
  }

  /// Simulate weather zone detection
  bool _isInWeatherZone(LatLng start, LatLng end) {
    // Simple simulation - in real implementation, this would check weather APIs
    return DateTime.now().hour < 6 ||
        DateTime.now().hour > 20; // Night conditions
  }

  /// Calculate geofence polygon points for visualization
  List<LatLng> calculateGeofencePolygon(
    LatLng center,
    double radiusInMeters, {
    int points = 32,
  }) {
    List<LatLng> polygonPoints = [];

    for (int i = 0; i < points; i++) {
      double angle = (i * 2 * math.pi) / points;
      double lat =
          center.latitude +
          (radiusInMeters / _earthRadius) * (180 / math.pi) * math.cos(angle);
      double lng =
          center.longitude +
          (radiusInMeters /
                  (_earthRadius * math.cos(center.latitude * math.pi / 180))) *
              (180 / math.pi) *
              math.sin(angle);
      polygonPoints.add(LatLng(lat, lng));
    }

    return polygonPoints;
  }

  /// Format distance for display
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      double km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }

  /// Format coordinates for display
  String formatCoordinates(LatLng position) {
    return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
  }

  /// Convert LocationData to LatLng
  LatLng locationDataToLatLng(LocationData locationData) {
    return LatLng(locationData.latitude, locationData.longitude);
  }

  /// Convert LatLng to LocationData
  LocationData latLngToLocationData(LatLng latLng) {
    return LocationData(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
      accuracy: 5.0, // Default accuracy
      timestamp: DateTime.now(),
    );
  }

  /// Generate mock flight path for simulation
  List<LatLng> generateFlightPath(
    LatLng start,
    LatLng end, {
    double altitudeVariation = 0.001,
  }) {
    List<LatLng> flightPath = [];
    int waypoints = 20;

    for (int i = 0; i <= waypoints; i++) {
      double ratio = i / waypoints;
      double lat = start.latitude + (end.latitude - start.latitude) * ratio;
      double lng = start.longitude + (end.longitude - start.longitude) * ratio;

      // Add slight altitude variation for realistic flight path
      if (i > 0 && i < waypoints) {
        double variation = (math.sin(ratio * math.pi * 3) * altitudeVariation);
        lat += variation;
        lng += variation * 0.5;
      }

      flightPath.add(LatLng(lat, lng));
    }

    return flightPath;
  }

  /// Get coverage area for drone based on its capabilities
  CoverageArea getDroneCoverageArea(Drone drone) {
    double baseRadius = drone.maxRange * 1000; // Convert km to meters

    // Adjust radius based on battery level
    double batteryFactor = drone.batteryLevel / 100.0;
    double effectiveRadius = baseRadius * batteryFactor;

    return CoverageArea(
      center: LatLng(drone.location.latitude, drone.location.longitude),
      radius: effectiveRadius,
      droneId: drone.id,
      capabilities: drone.capabilities,
    );
  }

  /// Check if point is within service area
  bool isWithinServiceArea(LatLng point, List<GCSStation> gcsStations) {
    const double defaultCoverageRadiusKm = 50.0; // Default 50km coverage

    for (GCSStation station in gcsStations) {
      double distance = calculateDistance(
        LatLng(station.coordinates.latitude, station.coordinates.longitude),
        point,
      );

      if (distance <= defaultCoverageRadiusKm * 1000) {
        // Convert km to meters
        return true;
      }
    }

    return false;
  }
}

/// Result of route optimization
class RouteOptimizationResult {
  final List<LatLng> optimizedRoute;
  final double totalDistance;
  final String estimatedDuration;
  final double routeEfficiency;

  RouteOptimizationResult({
    required this.optimizedRoute,
    required this.totalDistance,
    required this.estimatedDuration,
    required this.routeEfficiency,
  });

  Map<String, dynamic> toJson() {
    return {
      'optimizedRoute': optimizedRoute
          .map(
            (point) => {
              'latitude': point.latitude,
              'longitude': point.longitude,
            },
          )
          .toList(),
      'totalDistance': totalDistance,
      'estimatedDuration': estimatedDuration,
      'routeEfficiency': routeEfficiency,
    };
  }
}

/// Obstacle information for route planning
class ObstacleInfo {
  final ObstacleType type;
  final LatLng position;
  final ObstacleSeverity severity;
  final String description;

  ObstacleInfo({
    required this.type,
    required this.position,
    required this.severity,
    required this.description,
  });
}

enum ObstacleType { terrain, weather, building, restricted, wildlife }

enum ObstacleSeverity { low, medium, high, critical }

/// Coverage area for a drone
class CoverageArea {
  final LatLng center;
  final double radius;
  final String droneId;
  final List<String> capabilities;

  CoverageArea({
    required this.center,
    required this.radius,
    required this.droneId,
    required this.capabilities,
  });

  bool containsPoint(LatLng point) {
    double distance = MapService().calculateDistance(center, point);
    return distance <= radius;
  }
}

/// Extension for easier LatLng operations
extension LatLngExtensions on LatLng {
  /// Convert to LocationData
  LocationData toLocationData() {
    return LocationData(
      latitude: latitude,
      longitude: longitude,
      accuracy: 5.0,
      timestamp: DateTime.now(),
    );
  }

  /// Create LatLng with offset in meters
  LatLng offsetByMeters({
    required double northMeters,
    required double eastMeters,
  }) {
    const double earthRadius = 6371000.0;

    double newLat = latitude + (northMeters / earthRadius) * (180 / math.pi);
    double newLng =
        longitude +
        (eastMeters / (earthRadius * math.cos(latitude * math.pi / 180))) *
            (180 / math.pi);

    return LatLng(newLat, newLng);
  }
}
