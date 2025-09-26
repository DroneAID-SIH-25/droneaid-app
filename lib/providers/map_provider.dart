import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/map_models.dart';
import '../models/drone.dart';
import '../models/mission.dart';
import '../models/user.dart';
import '../services/map_service.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

/// Provider for managing map state and real-time updates
class MapProvider extends ChangeNotifier {
  final MapService _mapService = MapService();
  final LocationService _locationService = LocationService();

  // Current user location
  LatLng? _currentUserLocation;
  LocationData? _currentLocationData;
  bool _isLocationLoading = false;
  String? _locationError;

  // Map markers and routes
  List<MapMarker> _markers = [];
  List<MapRoute> _routes = [];
  List<GeofenceArea> _geofences = [];
  List<DroneTrackingData> _trackedDrones = [];

  // Mission data
  Map<String, MissionMapData> _missionData = {};
  List<ETAInfo> _etaInfoList = [];

  // Map configuration
  MapLayerConfig _currentLayer = const MapLayerConfig(
    id: 'base',
    name: 'Base Map',
    type: MapLayerType.base,
    isVisible: true,
    isRequired: true,
  );

  double _mapZoom = 15.0;
  LatLng? _mapCenter;
  bool _isFollowingUser = false;

  // Geofence settings
  double _geofenceRadius = 1000.0; // 1km default
  bool _geofenceEnabled = true;

  // Real-time update streams
  StreamSubscription<LocationData>? _locationSubscription;
  StreamSubscription<List<Drone>>? _dronesSubscription;
  StreamSubscription<RouteUpdate>? _routeUpdatesSubscription;
  Timer? _updateTimer;

  // Getters
  LatLng? get currentUserLocation => _currentUserLocation;
  LocationData? get currentLocationData => _currentLocationData;
  bool get isLocationLoading => _isLocationLoading;
  String? get locationError => _locationError;

  List<MapMarker> get markers => List.unmodifiable(_markers);
  List<MapRoute> get routes => List.unmodifiable(_routes);
  List<GeofenceArea> get geofences => List.unmodifiable(_geofences);
  List<DroneTrackingData> get trackedDrones =>
      List.unmodifiable(_trackedDrones);

  Map<String, MissionMapData> get missionData => Map.unmodifiable(_missionData);
  List<ETAInfo> get etaInfoList => List.unmodifiable(_etaInfoList);

  MapLayerConfig get currentLayer => _currentLayer;
  double get mapZoom => _mapZoom;
  LatLng? get mapCenter => _mapCenter;
  bool get isFollowingUser => _isFollowingUser;

  double get geofenceRadius => _geofenceRadius;
  bool get geofenceEnabled => _geofenceEnabled;

  /// Initialize the map provider
  Future<void> initialize() async {
    try {
      await _getCurrentLocation();
      _startLocationUpdates();
      _startRealTimeUpdates();
    } catch (e) {
      _locationError = e.toString();
      notifyListeners();
    }
  }

  /// Get current user location
  Future<void> _getCurrentLocation() async {
    _isLocationLoading = true;
    _locationError = null;
    notifyListeners();

    try {
      final location = await _mapService.getCurrentLocation();
      if (location != null) {
        _currentUserLocation = location;
        _currentLocationData = _mapService.latLngToLocationData(location);
        _mapCenter = location;

        // Add user marker
        _addUserMarker(location);

        // Create initial geofence if enabled
        if (_geofenceEnabled) {
          _createUserGeofence(location);
        }
      }
    } catch (e) {
      _locationError = 'Failed to get location: $e';
    } finally {
      _isLocationLoading = false;
      notifyListeners();
    }
  }

  /// Start location updates
  void _startLocationUpdates() {
    _locationSubscription = _locationService.locationStream.listen(
      (locationData) {
        _currentLocationData = locationData;
        _currentUserLocation = LatLng(
          locationData.latitude,
          locationData.longitude,
        );

        if (_isFollowingUser) {
          _mapCenter = _currentUserLocation;
        }

        // Update user marker
        _addUserMarker(_currentUserLocation!);

        // Update geofence if enabled
        if (_geofenceEnabled && _currentUserLocation != null) {
          _updateUserGeofence(_currentUserLocation!);
        }

        notifyListeners();
      },
      onError: (error) {
        _locationError = error.toString();
        notifyListeners();
      },
    );

    // Start location service
    _locationService.startLocationUpdates(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
  }

  /// Start real-time updates for drones and routes
  void _startRealTimeUpdates() {
    // Listen to drones in geofence
    _dronesSubscription = _mapService.dronesInGeofenceStream.listen((drones) {
      _updateDroneMarkers(drones);
      notifyListeners();
    });

    // Listen to route updates
    _routeUpdatesSubscription = _mapService.routeUpdatesStream.listen((
      routeUpdate,
    ) {
      _updateRouteProgress(routeUpdate);
      notifyListeners();
    });

    // Periodic updates
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _updateETAInformation();
    });
  }

  /// Add or update user marker
  void _addUserMarker(LatLng location) {
    final userMarkerId = 'user_location';
    final existingIndex = _markers.indexWhere((m) => m.id == userMarkerId);

    final userMarker = MapMarker(
      id: userMarkerId,
      position: location,
      type: MapMarkerType.user,
      title: 'Your Location',
      subtitle: _currentLocationData?.accuracy != null
          ? 'Accuracy: ${_currentLocationData!.accuracy!.toStringAsFixed(1)}m'
          : null,
      priority: MarkerPriority.high,
    );

    if (existingIndex >= 0) {
      _markers[existingIndex] = userMarker;
    } else {
      _markers.add(userMarker);
    }
  }

  /// Create user geofence
  void _createUserGeofence(LatLng center) {
    final geofenceId = 'user_geofence';
    final existingIndex = _geofences.indexWhere((g) => g.id == geofenceId);

    final geofence = GeofenceArea(
      id: geofenceId,
      center: center,
      radiusInMeters: _geofenceRadius,
      type: GeofenceAreaType.monitoring,
      name: 'Monitoring Zone',
      isActive: _geofenceEnabled,
    );

    if (existingIndex >= 0) {
      _geofences[existingIndex] = geofence;
    } else {
      _geofences.add(geofence);
    }
  }

  /// Update user geofence
  void _updateUserGeofence(LatLng center) {
    final geofenceIndex = _geofences.indexWhere((g) => g.id == 'user_geofence');
    if (geofenceIndex >= 0) {
      _geofences[geofenceIndex] = _geofences[geofenceIndex].copyWith(
        center: center,
      );
    }
  }

  /// Update drone markers from tracking data
  void _updateDroneMarkers(List<Drone> drones) {
    // Remove old drone markers
    _markers.removeWhere((m) => m.type == MapMarkerType.drone);
    _trackedDrones.clear();

    for (final drone in drones) {
      final dronePosition = LatLng(
        drone.location.latitude,
        drone.location.longitude,
      );

      // Add drone marker
      final droneMarker = MapMarker(
        id: 'drone_${drone.id}',
        position: dronePosition,
        type: MapMarkerType.drone,
        title: drone.name,
        subtitle: '${drone.statusDisplay} • ${drone.batteryDisplay}',
        priority: drone.status == DroneStatus.emergency
            ? MarkerPriority.critical
            : MarkerPriority.high,
        data: {'droneId': drone.id, 'status': drone.status.name},
      );
      _markers.add(droneMarker);

      // Add to tracked drones
      final trackingData = DroneTrackingData(
        droneId: drone.id,
        position: dronePosition,
        altitude: 0.0, // Would come from real telemetry
        heading: 0.0, // Would come from real telemetry
        speed: 0.0, // Would come from real telemetry
        batteryLevel: drone.batteryLevel,
        status: drone.status,
        missionId: drone.currentMissionId,
        timestamp: DateTime.now(),
        isInGeofence: _currentUserLocation != null
            ? _mapService.isWithinGeofence(
                _currentUserLocation!,
                dronePosition,
                _geofenceRadius,
              )
            : false,
      );
      _trackedDrones.add(trackingData);
    }
  }

  /// Update route progress from real-time data
  void _updateRouteProgress(RouteUpdate routeUpdate) {
    final routeIndex = _routes.indexWhere((r) => r.id == routeUpdate.missionId);
    if (routeIndex >= 0) {
      final updatedRoute = _routes[routeIndex].copyWith(
        metadata: {
          ..._routes[routeIndex].metadata ?? {},
          'progress': routeUpdate.progress,
          'currentPosition': routeUpdate.currentPosition,
          'eta': routeUpdate.eta,
        },
      );
      _routes[routeIndex] = updatedRoute;
    }

    // Update ETA info
    _updateETAForMission(routeUpdate);
  }

  /// Update ETA information
  void _updateETAInformation() {
    // This would typically fetch real-time data from the backend
    // For now, we'll update based on current tracking data
    for (final drone in _trackedDrones) {
      if (drone.missionId != null && _currentUserLocation != null) {
        final distance = _mapService.calculateDistance(
          drone.position,
          _currentUserLocation!,
        );
        final eta = _mapService.calculateETA(distance);

        _updateETAForDrone(drone.droneId, drone.missionId!, distance, eta);
      }
    }
  }

  /// Update ETA for specific mission
  void _updateETAForMission(RouteUpdate routeUpdate) {
    final existingIndex = _etaInfoList.indexWhere(
      (e) => e.missionId == routeUpdate.missionId,
    );

    final etaInfo = ETAInfo(
      missionId: routeUpdate.missionId,
      distanceRemaining: routeUpdate.remainingDistance,
      timeRemaining: Duration(
        seconds: (routeUpdate.remainingDistance / 15.0)
            .round(), // Assuming 15 m/s speed
      ),
      formattedETA: routeUpdate.eta,
      progress: routeUpdate.progress,
      currentPosition: routeUpdate.currentPosition,
      destination: _currentUserLocation ?? const LatLng(0, 0),
    );

    if (existingIndex >= 0) {
      _etaInfoList[existingIndex] = etaInfo;
    } else {
      _etaInfoList.add(etaInfo);
    }
  }

  /// Update ETA for specific drone
  void _updateETAForDrone(
    String droneId,
    String missionId,
    double distance,
    String eta,
  ) {
    final existingIndex = _etaInfoList.indexWhere(
      (e) => e.missionId == missionId,
    );

    if (existingIndex >= 0 && _currentUserLocation != null) {
      final drone = _trackedDrones.firstWhere((d) => d.droneId == droneId);

      final updatedETA = _etaInfoList[existingIndex].copyWith(
        distanceRemaining: distance,
        formattedETA: eta,
        currentPosition: drone.position,
      );

      _etaInfoList[existingIndex] = updatedETA;
    }
  }

  /// Add mission to map
  void addMission(Mission mission, Drone assignedDrone) {
    final startLocation = LatLng(
      mission.startLocation.latitude,
      mission.startLocation.longitude,
    );
    final targetLocation = LatLng(
      mission.targetLocation.latitude,
      mission.targetLocation.longitude,
    );

    // Create markers
    final startMarker = MapMarker(
      id: 'mission_start_${mission.id}',
      position: startLocation,
      type: MapMarkerType.gcsStation,
      title: 'Mission Start',
      subtitle: mission.title,
      priority: mission.priority == MissionPriority.critical
          ? MarkerPriority.critical
          : MarkerPriority.high,
    );

    final targetMarker = MapMarker(
      id: 'mission_target_${mission.id}',
      position: targetLocation,
      type: mission.type == MissionType.search
          ? MapMarkerType.emergency
          : MapMarkerType.target,
      title: mission.title,
      subtitle: mission.description,
      priority: mission.priority == MissionPriority.critical
          ? MarkerPriority.critical
          : MarkerPriority.high,
    );

    // Create route
    final routePoints = _mapService.getRoutePoints(
      startLocation,
      targetLocation,
    );
    final distance = _mapService.calculateDistance(
      startLocation,
      targetLocation,
    );
    final eta = _mapService.calculateETA(distance);

    final route = MapRoute(
      id: mission.id,
      points: routePoints,
      type: mission.type == MissionType.search
          ? RouteType.emergency
          : RouteType.direct,
      status: mission.status == MissionStatus.inProgress
          ? RouteStatus.active
          : RouteStatus.planned,
      distance: distance,
      eta: eta,
      priority: mission.priority == MissionPriority.critical
          ? MarkerPriority.critical
          : MarkerPriority.normal,
      metadata: {'missionId': mission.id},
    );

    // Create mission map data
    final missionMapData = MissionMapData(
      missionId: mission.id,
      startMarker: startMarker,
      targetMarker: targetMarker,
      route: route,
      status: mission.status,
      priority: mission.priority,
      progress: mission.progress,
    );

    // Add to collections
    _markers.addAll([startMarker, targetMarker]);
    _routes.add(route);
    _missionData[mission.id] = missionMapData;

    notifyListeners();
  }

  /// Remove mission from map
  void removeMission(String missionId) {
    // Remove markers
    _markers.removeWhere((m) => m.id.contains(missionId));

    // Remove route
    _routes.removeWhere((r) => r.id == missionId);

    // Remove mission data
    _missionData.remove(missionId);

    // Remove ETA info
    _etaInfoList.removeWhere((e) => e.missionId == missionId);

    notifyListeners();
  }

  /// Update geofence settings
  void updateGeofenceSettings({double? radius, bool? enabled}) {
    if (radius != null) _geofenceRadius = radius;
    if (enabled != null) _geofenceEnabled = enabled;

    if (_currentUserLocation != null) {
      if (_geofenceEnabled) {
        _createUserGeofence(_currentUserLocation!);
      } else {
        _geofences.removeWhere((g) => g.id == 'user_geofence');
      }
    }

    notifyListeners();
  }

  /// Set map center and zoom
  void setMapView({LatLng? center, double? zoom}) {
    if (center != null) {
      _mapCenter = center;
      _isFollowingUser = false;
    }
    if (zoom != null) _mapZoom = zoom;
    notifyListeners();
  }

  /// Toggle user following mode
  void toggleUserFollowing() {
    _isFollowingUser = !_isFollowingUser;
    if (_isFollowingUser && _currentUserLocation != null) {
      _mapCenter = _currentUserLocation;
    }
    notifyListeners();
  }

  /// Change map layer
  void changeMapLayer(MapLayerConfig layer) {
    _currentLayer = layer;
    notifyListeners();
  }

  /// Center map on user location
  void centerOnUser() {
    if (_currentUserLocation != null) {
      _mapCenter = _currentUserLocation;
      _isFollowingUser = true;
      notifyListeners();
    }
  }

  /// Center map on mission
  void centerOnMission(String missionId) {
    final mission = _missionData[missionId];
    if (mission != null) {
      _mapCenter = mission.targetMarker.position;
      _isFollowingUser = false;
      notifyListeners();
    }
  }

  /// Update drones in geofence
  void updateDronesInGeofence(List<Drone> allDrones) {
    if (_currentUserLocation != null) {
      _mapService.updateGeofenceMonitoring(_currentUserLocation!, allDrones);
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _dronesSubscription?.cancel();
    _routeUpdatesSubscription?.cancel();
    _updateTimer?.cancel();
    _locationService.stopLocationUpdates();
    _mapService.dispose();
    super.dispose();
  }
}
