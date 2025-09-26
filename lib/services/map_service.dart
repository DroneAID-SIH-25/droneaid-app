import 'dart:async';
import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../models/user.dart';
import '../models/drone.dart';
import '../models/mission.dart';
import 'location_service.dart';

/// Comprehensive map service for route optimization, geofencing, and tracking
class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  final LocationService _locationService = LocationService();
  final Distance _distance = const Distance();

  // Constants
  static const double _defaultGeofenceRadius = 1000.0; // 1km in meters
  static const double _droneSpeed = 15.0; // Average drone speed in m/s
  static const int _routeOptimizationMaxPoints = 50;

  // Stream controllers for real-time updates
  final StreamController<List<Drone>> _dronesInGeofenceController =
      StreamController<List<Drone>>.broadcast();
  final StreamController<RouteUpdate> _routeUpdatesController =
      StreamController<RouteUpdate>.broadcast();

  /// Stream of drones within geofence
  Stream<List<Drone>> get dronesInGeofenceStream =>
      _dronesInGeofenceController.stream;

  /// Stream of route updates
  Stream<RouteUpdate> get routeUpdatesStream => _routeUpdatesController.stream;

  /// Get current device location
  Future<LatLng?> getCurrentLocation() async {
    try {
      final locationData = await _locationService.getCurrentLocation();
      if (locationData == null) return null;

      return LatLng(locationData.latitude, locationData.longitude);
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Generate route points between two locations (straight line with waypoints)
  List<LatLng> getRoutePoints(LatLng start, LatLng end, {int waypoints = 10}) {
    final List<LatLng> routePoints = [start];

    for (int i = 1; i < waypoints; i++) {
      final double ratio = i / waypoints;
      final double lat =
          start.latitude + (end.latitude - start.latitude) * ratio;
      final double lng =
          start.longitude + (end.longitude - start.longitude) * ratio;
      routePoints.add(LatLng(lat, lng));
    }

    routePoints.add(end);
    return routePoints;
  }

  /// Check if a location is within geofence
  bool isWithinGeofence(LatLng center, LatLng target, double radiusInMeters) {
    final double distance = _distance.as(LengthUnit.Meter, center, target);
    return distance <= radiusInMeters;
  }

  /// Get all drones within geofence of a location
  List<Drone> getDronesInGeofence(
    LatLng center,
    List<Drone> allDrones, {
    double radiusInMeters = _defaultGeofenceRadius,
  }) {
    return allDrones.where((drone) {
      final dronePosition = LatLng(
        drone.location.latitude,
        drone.location.longitude,
      );
      return isWithinGeofence(center, dronePosition, radiusInMeters);
    }).toList();
  }

  /// Update geofence monitoring
  void updateGeofenceMonitoring(LatLng center, List<Drone> allDrones) {
    final dronesInRange = getDronesInGeofence(center, allDrones);
    _dronesInGeofenceController.add(dronesInRange);
  }

  /// Calculate straight-line distance between two points
  double calculateDistance(LatLng start, LatLng end) {
    return _distance.as(LengthUnit.Meter, start, end);
  }

  /// Calculate estimated time of arrival
  String calculateETA(double distanceInMeters, {double speedMs = _droneSpeed}) {
    final double timeInSeconds = distanceInMeters / speedMs;

    if (timeInSeconds < 60) {
      return '${timeInSeconds.round()}s';
    } else if (timeInSeconds < 3600) {
      final int minutes = (timeInSeconds / 60).round();
      return '${minutes}m';
    } else {
      final int hours = (timeInSeconds / 3600).floor();
      final int minutes = ((timeInSeconds % 3600) / 60).round();
      return '${hours}h ${minutes}m';
    }
  }

  /// Optimize route using K-Nearest Neighbor approach
  List<LatLng> optimizeRoute(LatLng start, List<LatLng> targets) {
    if (targets.isEmpty) return [start];
    if (targets.length == 1) return [start, targets.first];

    // Limit targets for performance
    final limitedTargets = targets.take(_routeOptimizationMaxPoints).toList();
    final List<LatLng> optimizedRoute = [start];
    final List<LatLng> unvisited = List.from(limitedTargets);
    LatLng currentPosition = start;

    // KNN algorithm - always go to nearest unvisited point
    while (unvisited.isNotEmpty) {
      double minDistance = double.infinity;
      LatLng? nearest;

      for (final target in unvisited) {
        final double distance = calculateDistance(currentPosition, target);
        if (distance < minDistance) {
          minDistance = distance;
          nearest = target;
        }
      }

      if (nearest != null) {
        optimizedRoute.add(nearest);
        unvisited.remove(nearest);
        currentPosition = nearest;
      }
    }

    return optimizedRoute;
  }

  /// Optimize route with priority consideration
  List<LatLng> optimizeRouteWithPriority(
    LatLng start,
    List<RouteTarget> targets,
  ) {
    if (targets.isEmpty) return [start];

    // Sort by priority first (critical first)
    final sortedTargets = List<RouteTarget>.from(targets);
    sortedTargets.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    // Separate critical missions (must go first)
    final criticalTargets = sortedTargets
        .where((t) => t.priority == MissionPriority.critical)
        .map((t) => t.location)
        .toList();

    final nonCriticalTargets = sortedTargets
        .where((t) => t.priority != MissionPriority.critical)
        .map((t) => t.location)
        .toList();

    // Optimize critical targets first
    final List<LatLng> optimizedRoute = [];
    LatLng currentPos = start;

    if (criticalTargets.isNotEmpty) {
      final criticalRoute = optimizeRoute(currentPos, criticalTargets);
      optimizedRoute.addAll(criticalRoute);
      currentPos = criticalRoute.last;
    } else {
      optimizedRoute.add(start);
    }

    // Then optimize non-critical targets
    if (nonCriticalTargets.isNotEmpty) {
      final regularRoute = optimizeRoute(currentPos, nonCriticalTargets);
      // Skip the starting point as it's already added
      optimizedRoute.addAll(regularRoute.skip(1));
    }

    return optimizedRoute;
  }

  /// Calculate total route distance
  double calculateRouteDistance(List<LatLng> route) {
    if (route.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      totalDistance += calculateDistance(route[i], route[i + 1]);
    }
    return totalDistance;
  }

  /// Generate mission routes for GCS overview
  List<MissionRoute> generateMissionRoutes(
    List<Mission> missions,
    Map<String, LatLng> gcsLocations,
  ) {
    return missions.map((mission) {
      final gcsLocation =
          gcsLocations[mission.assignedOperatorId] ??
          LatLng(0, 0); // Fallback if GCS location not found

      final missionLocation = LatLng(
        mission.targetLocation.latitude,
        mission.targetLocation.longitude,
      );

      final distance = calculateDistance(gcsLocation, missionLocation);
      final eta = calculateETA(distance);

      return MissionRoute(
        missionId: mission.id,
        startLocation: gcsLocation,
        endLocation: missionLocation,
        waypoints: getRoutePoints(gcsLocation, missionLocation),
        distance: distance,
        eta: eta,
        priority: mission.priority,
        status: mission.status,
      );
    }).toList();
  }

  /// Create geofence circle points for visualization
  List<LatLng> createGeofenceCircle(
    LatLng center,
    double radiusInMeters, {
    int points = 64,
  }) {
    final List<LatLng> circlePoints = [];
    const double earthRadius = 6378137.0; // Earth radius in meters

    for (int i = 0; i < points; i++) {
      final double angle = (i * 360.0 / points) * (math.pi / 180.0);

      final double lat =
          center.latitude +
          (radiusInMeters / earthRadius) * (180.0 / math.pi) * math.cos(angle);
      final double lng =
          center.longitude +
          (radiusInMeters / earthRadius) *
              (180.0 / math.pi) *
              math.sin(angle) /
              math.cos(center.latitude * math.pi / 180.0);

      circlePoints.add(LatLng(lat, lng));
    }

    // Close the circle
    if (circlePoints.isNotEmpty) {
      circlePoints.add(circlePoints.first);
    }

    return circlePoints;
  }

  /// Check if drone needs maintenance based on location and usage
  bool needsMaintenanceCheck(Drone drone, LatLng homeBase) {
    final droneLocation = LatLng(
      drone.location.latitude,
      drone.location.longitude,
    );
    final distanceFromBase = calculateDistance(homeBase, droneLocation);

    return drone.needsMaintenance ||
        drone.batteryLevel < 20 ||
        distanceFromBase > drone.maxRange * 1000 * 0.8; // 80% of max range
  }

  /// Find nearest available drone to a location
  Drone? findNearestDrone(LatLng targetLocation, List<Drone> availableDrones) {
    if (availableDrones.isEmpty) return null;

    Drone? nearestDrone;
    double minDistance = double.infinity;

    for (final drone in availableDrones) {
      if (!drone.isAvailable || !drone.isOperational) continue;

      final droneLocation = LatLng(
        drone.location.latitude,
        drone.location.longitude,
      );

      final distance = calculateDistance(droneLocation, targetLocation);

      // Check if drone can reach the location
      if (distance <= drone.maxRange * 1000 && distance < minDistance) {
        minDistance = distance;
        nearestDrone = drone;
      }
    }

    return nearestDrone;
  }

  /// Convert LocationData to LatLng
  LatLng locationDataToLatLng(LocationData location) {
    return LatLng(location.latitude, location.longitude);
  }

  /// Convert LatLng to LocationData
  LocationData latLngToLocationData(LatLng latLng) {
    return LocationData(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
      timestamp: DateTime.now(),
    );
  }

  /// Update route progress for real-time tracking
  void updateRouteProgress(
    String missionId,
    LatLng currentPosition,
    List<LatLng> route,
  ) {
    if (route.isEmpty) return;

    // Find closest point on route
    double minDistance = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < route.length; i++) {
      final distance = calculateDistance(currentPosition, route[i]);
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    final progress = closestIndex / (route.length - 1);
    final remainingDistance = calculateRouteDistance(
      route.sublist(closestIndex),
    );
    final eta = calculateETA(remainingDistance);

    _routeUpdatesController.add(
      RouteUpdate(
        missionId: missionId,
        currentPosition: currentPosition,
        progress: progress,
        remainingDistance: remainingDistance,
        eta: eta,
        closestWaypointIndex: closestIndex,
      ),
    );
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _dronesInGeofenceController.close();
    await _routeUpdatesController.close();
  }
}

/// Route target with priority information
class RouteTarget {
  final LatLng location;
  final MissionPriority priority;
  final String? id;

  const RouteTarget({required this.location, required this.priority, this.id});
}

/// Mission route information
class MissionRoute {
  final String missionId;
  final LatLng startLocation;
  final LatLng endLocation;
  final List<LatLng> waypoints;
  final double distance;
  final String eta;
  final MissionPriority priority;
  final MissionStatus status;

  const MissionRoute({
    required this.missionId,
    required this.startLocation,
    required this.endLocation,
    required this.waypoints,
    required this.distance,
    required this.eta,
    required this.priority,
    required this.status,
  });

  bool get isActive => status == MissionStatus.inProgress;
  bool get isPending => status == MissionStatus.assigned;
  bool get isComplete => status == MissionStatus.completed;
}

/// Route update information for real-time tracking
class RouteUpdate {
  final String missionId;
  final LatLng currentPosition;
  final double progress; // 0.0 to 1.0
  final double remainingDistance;
  final String eta;
  final int closestWaypointIndex;

  const RouteUpdate({
    required this.missionId,
    required this.currentPosition,
    required this.progress,
    required this.remainingDistance,
    required this.eta,
    required this.closestWaypointIndex,
  });
}

/// Geofence configuration
class GeofenceConfig {
  final LatLng center;
  final double radiusInMeters;
  final String? name;
  final GeofenceType type;

  const GeofenceConfig({
    required this.center,
    required this.radiusInMeters,
    this.name,
    this.type = GeofenceType.monitoring,
  });
}

enum GeofenceType { monitoring, restricted, emergency, serviceArea }

extension GeofenceTypeExtension on GeofenceType {
  String get displayName {
    switch (this) {
      case GeofenceType.monitoring:
        return 'Monitoring Zone';
      case GeofenceType.restricted:
        return 'Restricted Area';
      case GeofenceType.emergency:
        return 'Emergency Zone';
      case GeofenceType.serviceArea:
        return 'Service Area';
    }
  }
}
