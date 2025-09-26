import 'package:latlong2/latlong.dart';
import 'mission.dart';
import 'user.dart';
import 'drone.dart';

/// Extension for Location/LocationData to work with LatLng
extension LocationDataExtensions on LocationData {
  LatLng toLatLng() => LatLng(latitude, longitude);
}

extension LatLngExtensions on LatLng {
  LocationData toLocationData() => LocationData(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.now(),
  );
}

/// Map marker information
class MapMarker {
  final String id;
  final LatLng position;
  final MapMarkerType type;
  final String title;
  final String? subtitle;
  final Map<String, dynamic>? data;
  final MarkerPriority priority;
  final bool isVisible;
  final DateTime createdAt;

  MapMarker({
    required this.id,
    required this.position,
    required this.type,
    required this.title,
    this.subtitle,
    this.data,
    this.priority = MarkerPriority.normal,
    this.isVisible = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  MapMarker copyWith({
    String? id,
    LatLng? position,
    MapMarkerType? type,
    String? title,
    String? subtitle,
    Map<String, dynamic>? data,
    MarkerPriority? priority,
    bool? isVisible,
    DateTime? createdAt,
  }) {
    return MapMarker(
      id: id ?? this.id,
      position: position ?? this.position,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      data: data ?? this.data,
      priority: priority ?? this.priority,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum MapMarkerType {
  user,
  drone,
  gcsStation,
  emergency,
  waypoint,
  target,
  obstacle,
  geofence,
}

enum MarkerPriority { low, normal, high, critical }

extension MapMarkerTypeExtensions on MapMarkerType {
  String get displayName {
    switch (this) {
      case MapMarkerType.user:
        return 'User Location';
      case MapMarkerType.drone:
        return 'Drone';
      case MapMarkerType.gcsStation:
        return 'GCS Station';
      case MapMarkerType.emergency:
        return 'Emergency';
      case MapMarkerType.waypoint:
        return 'Waypoint';
      case MapMarkerType.target:
        return 'Target';
      case MapMarkerType.obstacle:
        return 'Obstacle';
      case MapMarkerType.geofence:
        return 'Geofence';
    }
  }

  String get iconPath {
    switch (this) {
      case MapMarkerType.user:
        return 'assets/icons/user_marker.png';
      case MapMarkerType.drone:
        return 'assets/icons/drone_marker.png';
      case MapMarkerType.gcsStation:
        return 'assets/icons/gcs_marker.png';
      case MapMarkerType.emergency:
        return 'assets/icons/emergency_marker.png';
      case MapMarkerType.waypoint:
        return 'assets/icons/waypoint_marker.png';
      case MapMarkerType.target:
        return 'assets/icons/target_marker.png';
      case MapMarkerType.obstacle:
        return 'assets/icons/obstacle_marker.png';
      case MapMarkerType.geofence:
        return 'assets/icons/geofence_marker.png';
    }
  }
}

/// Route information for map display
class MapRoute {
  final String id;
  final List<LatLng> points;
  final RouteType type;
  final RouteStatus status;
  final double distance;
  final String eta;
  final MarkerPriority priority;
  final Map<String, dynamic>? metadata;

  const MapRoute({
    required this.id,
    required this.points,
    required this.type,
    this.status = RouteStatus.planned,
    required this.distance,
    required this.eta,
    this.priority = MarkerPriority.normal,
    this.metadata,
  });

  MapRoute copyWith({
    String? id,
    List<LatLng>? points,
    RouteType? type,
    RouteStatus? status,
    double? distance,
    String? eta,
    MarkerPriority? priority,
    Map<String, dynamic>? metadata,
  }) {
    return MapRoute(
      id: id ?? this.id,
      points: points ?? this.points,
      type: type ?? this.type,
      status: status ?? this.status,
      distance: distance ?? this.distance,
      eta: eta ?? this.eta,
      priority: priority ?? this.priority,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum RouteType { direct, optimized, waypoint, emergency, patrol }

enum RouteStatus { planned, active, completed, cancelled }

extension RouteTypeExtensions on RouteType {
  String get displayName {
    switch (this) {
      case RouteType.direct:
        return 'Direct Route';
      case RouteType.optimized:
        return 'Optimized Route';
      case RouteType.waypoint:
        return 'Waypoint Route';
      case RouteType.emergency:
        return 'Emergency Route';
      case RouteType.patrol:
        return 'Patrol Route';
    }
  }
}

/// Geofence area for map visualization
class GeofenceArea {
  final String id;
  final LatLng center;
  final double radiusInMeters;
  final GeofenceAreaType type;
  final String name;
  final bool isActive;
  final List<LatLng>? customBoundary;

  const GeofenceArea({
    required this.id,
    required this.center,
    required this.radiusInMeters,
    required this.type,
    required this.name,
    this.isActive = true,
    this.customBoundary,
  });

  bool get isCircular => customBoundary == null;
  bool get isPolygon => customBoundary != null && customBoundary!.length > 2;

  GeofenceArea copyWith({
    String? id,
    LatLng? center,
    double? radiusInMeters,
    GeofenceAreaType? type,
    String? name,
    bool? isActive,
    List<LatLng>? customBoundary,
  }) {
    return GeofenceArea(
      id: id ?? this.id,
      center: center ?? this.center,
      radiusInMeters: radiusInMeters ?? this.radiusInMeters,
      type: type ?? this.type,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      customBoundary: customBoundary ?? this.customBoundary,
    );
  }
}

enum GeofenceAreaType { monitoring, restricted, service, emergency, noFly }

extension GeofenceAreaTypeExtensions on GeofenceAreaType {
  String get displayName {
    switch (this) {
      case GeofenceAreaType.monitoring:
        return 'Monitoring Zone';
      case GeofenceAreaType.restricted:
        return 'Restricted Area';
      case GeofenceAreaType.service:
        return 'Service Area';
      case GeofenceAreaType.emergency:
        return 'Emergency Zone';
      case GeofenceAreaType.noFly:
        return 'No-Fly Zone';
    }
  }
}

/// Real-time tracking data for drones
class DroneTrackingData {
  final String droneId;
  final LatLng position;
  final double altitude;
  final double heading;
  final double speed;
  final int batteryLevel;
  final DroneStatus status;
  final String? missionId;
  final DateTime timestamp;
  final bool isInGeofence;

  const DroneTrackingData({
    required this.droneId,
    required this.position,
    required this.altitude,
    required this.heading,
    required this.speed,
    required this.batteryLevel,
    required this.status,
    this.missionId,
    required this.timestamp,
    this.isInGeofence = false,
  });

  bool get isOperational => status.isOperational;
  bool get hasLowBattery => batteryLevel < 20;
  bool get isCriticalBattery => batteryLevel < 10;

  DroneTrackingData copyWith({
    String? droneId,
    LatLng? position,
    double? altitude,
    double? heading,
    double? speed,
    int? batteryLevel,
    DroneStatus? status,
    String? missionId,
    DateTime? timestamp,
    bool? isInGeofence,
  }) {
    return DroneTrackingData(
      droneId: droneId ?? this.droneId,
      position: position ?? this.position,
      altitude: altitude ?? this.altitude,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      status: status ?? this.status,
      missionId: missionId ?? this.missionId,
      timestamp: timestamp ?? this.timestamp,
      isInGeofence: isInGeofence ?? this.isInGeofence,
    );
  }
}

/// Map layer configuration
class MapLayerConfig {
  final String id;
  final String name;
  final bool isVisible;
  final bool isRequired;
  final MapLayerType type;
  final double opacity;

  const MapLayerConfig({
    required this.id,
    required this.name,
    this.isVisible = true,
    this.isRequired = false,
    required this.type,
    this.opacity = 1.0,
  });

  MapLayerConfig copyWith({
    String? id,
    String? name,
    bool? isVisible,
    bool? isRequired,
    MapLayerType? type,
    double? opacity,
  }) {
    return MapLayerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      isVisible: isVisible ?? this.isVisible,
      isRequired: isRequired ?? this.isRequired,
      type: type ?? this.type,
      opacity: opacity ?? this.opacity,
    );
  }
}

enum MapLayerType {
  base,
  satellite,
  hybrid,
  markers,
  routes,
  geofences,
  weather,
  traffic,
}

extension MapLayerTypeExtensions on MapLayerType {
  String get displayName {
    switch (this) {
      case MapLayerType.base:
        return 'Base Map';
      case MapLayerType.satellite:
        return 'Satellite';
      case MapLayerType.hybrid:
        return 'Hybrid';
      case MapLayerType.markers:
        return 'Markers';
      case MapLayerType.routes:
        return 'Routes';
      case MapLayerType.geofences:
        return 'Geofences';
      case MapLayerType.weather:
        return 'Weather';
      case MapLayerType.traffic:
        return 'Traffic';
    }
  }
}

/// Mission visualization data
class MissionMapData {
  final String missionId;
  final MapMarker startMarker;
  final MapMarker targetMarker;
  final MapRoute route;
  final List<MapMarker> waypoints;
  final DroneTrackingData? assignedDrone;
  final MissionStatus status;
  final MissionPriority priority;
  final double progress;

  const MissionMapData({
    required this.missionId,
    required this.startMarker,
    required this.targetMarker,
    required this.route,
    this.waypoints = const [],
    this.assignedDrone,
    required this.status,
    required this.priority,
    this.progress = 0.0,
  });

  bool get isActive => status == MissionStatus.inProgress;
  bool get isComplete => status == MissionStatus.completed;
  bool get isPending => status == MissionStatus.assigned;
  bool get isCritical => priority == MissionPriority.critical;

  MissionMapData copyWith({
    String? missionId,
    MapMarker? startMarker,
    MapMarker? targetMarker,
    MapRoute? route,
    List<MapMarker>? waypoints,
    DroneTrackingData? assignedDrone,
    MissionStatus? status,
    MissionPriority? priority,
    double? progress,
  }) {
    return MissionMapData(
      missionId: missionId ?? this.missionId,
      startMarker: startMarker ?? this.startMarker,
      targetMarker: targetMarker ?? this.targetMarker,
      route: route ?? this.route,
      waypoints: waypoints ?? this.waypoints,
      assignedDrone: assignedDrone ?? this.assignedDrone,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      progress: progress ?? this.progress,
    );
  }
}

/// ETA information display
class ETAInfo {
  final String missionId;
  final double distanceRemaining;
  final Duration timeRemaining;
  final String formattedETA;
  final double progress;
  final LatLng currentPosition;
  final LatLng destination;

  const ETAInfo({
    required this.missionId,
    required this.distanceRemaining,
    required this.timeRemaining,
    required this.formattedETA,
    required this.progress,
    required this.currentPosition,
    required this.destination,
  });

  bool get isNearby => distanceRemaining < 100; // Within 100m
  bool get isImminent => timeRemaining.inMinutes < 2;

  ETAInfo copyWith({
    String? missionId,
    double? distanceRemaining,
    Duration? timeRemaining,
    String? formattedETA,
    double? progress,
    LatLng? currentPosition,
    LatLng? destination,
  }) {
    return ETAInfo(
      missionId: missionId ?? this.missionId,
      distanceRemaining: distanceRemaining ?? this.distanceRemaining,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      formattedETA: formattedETA ?? this.formattedETA,
      progress: progress ?? this.progress,
      currentPosition: currentPosition ?? this.currentPosition,
      destination: destination ?? this.destination,
    );
  }
}
