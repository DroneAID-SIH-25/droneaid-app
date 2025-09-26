import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import 'drone_tracking_provider.dart';
import '../models/gcs_station.dart';
import '../models/user.dart';
import '../models/mission.dart';
import '../models/drone.dart';

class MapProvider extends ChangeNotifier {
  // Map state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Real-time updates
  bool _isRealTimeEnabled = true;
  bool get isRealTimeEnabled => _isRealTimeEnabled;

  // Map display options
  bool _showCoverage = true;
  bool get showCoverage => _showCoverage;

  bool _showRoutes = true;
  bool get showRoutes => _showRoutes;

  bool _showDrones = true;
  bool get showDrones => _showDrones;

  bool _showEmergencies = true;
  bool get showEmergencies => _showEmergencies;

  bool _showMissions = true;
  bool get showMissions => _showMissions;

  // Map center and zoom
  LatLng _mapCenter = const LatLng(28.6139, 77.2090); // New Delhi default
  LatLng get mapCenter => _mapCenter;

  double _zoomLevel = 13.0;
  double get zoomLevel => _zoomLevel;

  // Update interval for real-time data
  int _updateIntervalSeconds = 5;
  int get updateIntervalSeconds => _updateIntervalSeconds;

  // Map layers
  List<MapLayer> _activeLayers = [];
  List<MapLayer> get activeLayers => _activeLayers;

  // Emergency locations
  List<EmergencyLocation> _emergencyLocations = [];
  List<EmergencyLocation> get emergencyLocations => _emergencyLocations;

  // Mission waypoints
  Map<String, List<LatLng>> _missionWaypoints = {};
  Map<String, List<LatLng>> get missionWaypoints => _missionWaypoints;

  // Coverage areas
  List<CoverageArea> _coverageAreas = [];
  List<CoverageArea> get coverageAreas => _coverageAreas;

  // Search and rescue zones
  List<SearchZone> _searchZones = [];
  List<SearchZone> get searchZones => _searchZones;

  // User location and tracking
  LatLng? _userLocation;
  LatLng? get userLocation => _userLocation;

  LatLng get currentCenter => _mapCenter;
  double get currentZoom => _zoomLevel;

  // Geofence settings
  bool _showGeofence = true;
  bool get showGeofence => _showGeofence;

  double _geofenceRadius = 1000.0; // meters
  double get geofenceRadius => _geofenceRadius;

  // Route points
  List<LatLng> _routePoints = [];
  List<LatLng> get routePoints => _routePoints;

  // Selected drone
  String? _selectedDroneId;
  String? get selectedDrone => _selectedDroneId;

  Drone? get selectedDroneObject {
    if (_selectedDroneId == null) return null;
    try {
      return _drones.firstWhere((drone) => drone.id == _selectedDroneId);
    } catch (e) {
      return null;
    }
  }

  // Drones in geofence
  List<DroneInfo> _dronesInGeofence = [];
  List<DroneInfo> get dronesInGeofence => _dronesInGeofence;

  // Emergency requests
  List<EmergencyLocation> _emergencyRequests = [];
  List<EmergencyLocation> get emergencyRequests => _emergencyRequests;

  // Location tracking
  bool _isTrackingLocation = false;
  bool get isTrackingLocation => _isTrackingLocation;

  bool _isLocationEnabled = true;
  bool get isLocationEnabled => _isLocationEnabled;

  // Filtered drones
  List<DroneInfo> _filteredDrones = [];
  List<DroneInfo> get filteredDrones => _filteredDrones;

  // GCS Station management
  List<GCSStation> _gcsStations = [];
  List<GCSStation> get gcsStations => _gcsStations;

  bool _showGCSStations = true;
  bool get showGCSStations => _showGCSStations;

  String? _selectedGCSStation;
  String? get selectedGCSStation => _selectedGCSStation;

  // Mission management
  Mission? _selectedMission;
  Mission? get selectedMission => _selectedMission;

  List<Mission> _filteredMissions = [];
  List<Mission> get filteredMissions => _filteredMissions;

  List<LatLng> _currentRoute = [];
  List<LatLng> get currentRoute => _currentRoute;

  // Search functionality
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // Mission and priority filters
  Set<MissionStatus> _missionStatusFilter = <MissionStatus>{};
  Set<MissionStatus> get missionStatusFilter => _missionStatusFilter;

  MissionPriority? _priorityFilter;
  MissionPriority? get priorityFilter => _priorityFilter;

  // Drone and mission data
  List<Drone> _drones = [];
  List<Drone> get drones => _drones;

  List<Mission> _missions = [];
  List<Mission> get missions => _missions;

  List<Mission> _activeMissions = [];
  List<Mission> get activeMissions => _activeMissions;

  // Coverage radius
  double _totalCoverageRadius = 5000.0;
  double get totalCoverageRadius => _totalCoverageRadius;

  // Constructor
  MapProvider() {
    _initializeMap();
  }

  /// Initialize map with default data
  void _initializeMap() {
    _isLoading = true;
    notifyListeners();

    // Load default coverage areas
    _loadDefaultCoverageAreas();

    // Load emergency locations
    _loadEmergencyLocations();

    // Load GCS stations
    _loadGCSStations();

    _isLoading = false;
    notifyListeners();
  }

  /// Load default coverage areas for Delhi NCR
  void _loadDefaultCoverageAreas() {
    _coverageAreas = [
      CoverageArea(
        id: 'coverage_001',
        name: 'Central Delhi Coverage',
        center: const LatLng(28.6139, 77.2090),
        radius: 5000, // 5km radius
        color: const Color(0xFF2196F3).withOpacity(0.3),
        isActive: true,
      ),
      CoverageArea(
        id: 'coverage_002',
        name: 'South Delhi Coverage',
        center: const LatLng(28.5355, 77.2470),
        radius: 7000, // 7km radius
        color: const Color(0xFF4CAF50).withOpacity(0.3),
        isActive: true,
      ),
      CoverageArea(
        id: 'coverage_003',
        name: 'Gurgaon Coverage',
        center: const LatLng(28.4595, 77.0266),
        radius: 6000, // 6km radius
        color: const Color(0xFFFF9800).withOpacity(0.3),
        isActive: true,
      ),
    ];
  }

  /// Load GCS stations
  void _loadGCSStations() {
    _gcsStations = [
      GCSStation(
        name: 'Delhi Control Station',
        code: 'DEL_001',
        location: 'Delhi NCR',
        coordinates: Location(
          latitude: 28.6139,
          longitude: 77.2090,
          address: 'Delhi NCR Control Center',
        ),
        organizationId: 'org_001',
        contactEmail: 'delhi@droneaid.gov.in',
        contactPhone: '+91-11-12345678',
        currentOperators: 3,
      ),
      GCSStation(
        name: 'Mumbai Control Station',
        code: 'MUM_001',
        location: 'Mumbai',
        coordinates: Location(
          latitude: 19.0760,
          longitude: 72.8777,
          address: 'Mumbai Control Center',
        ),
        organizationId: 'org_001',
        contactEmail: 'mumbai@droneaid.gov.in',
        contactPhone: '+91-22-12345678',
        currentOperators: 2,
      ),
      GCSStation(
        name: 'Bangalore Control Station',
        code: 'BLR_001',
        location: 'Bangalore',
        coordinates: Location(
          latitude: 12.9716,
          longitude: 77.5946,
          address: 'Bangalore Control Center',
        ),
        organizationId: 'org_001',
        contactEmail: 'bangalore@droneaid.gov.in',
        contactPhone: '+91-80-12345678',
        currentOperators: 1,
        isActive: false,
      ),
    ];
  }

  /// Load emergency locations
  void _loadEmergencyLocations() {
    _emergencyLocations = [
      EmergencyLocation(
        id: 'emergency_001',
        type: EmergencyType.fire,
        position: const LatLng(28.6129, 77.2295),
        severity: EmergencySeverity.high,
        description: 'Building fire reported',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        priority: EmergencyPriority.high,
        status: EmergencyStatus.active,
      ),
      EmergencyLocation(
        id: 'emergency_002',
        type: EmergencyType.medical,
        position: const LatLng(28.5355, 77.3910),
        severity: EmergencySeverity.critical,
        description: 'Medical emergency - cardiac arrest',
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        priority: EmergencyPriority.critical,
        status: EmergencyStatus.inProgress,
      ),
      EmergencyLocation(
        id: 'emergency_003',
        type: EmergencyType.accident,
        position: const LatLng(28.7041, 77.1025),
        severity: EmergencySeverity.medium,
        description: 'Traffic accident - multiple vehicles',
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        priority: EmergencyPriority.normal,
        status: EmergencyStatus.active,
      ),
    ];
  }

  /// Toggle real-time updates
  void toggleRealTimeUpdates() {
    _isRealTimeEnabled = !_isRealTimeEnabled;
    notifyListeners();
  }

  /// Toggle coverage areas display
  void toggleCoverage() {
    _showCoverage = !_showCoverage;
    notifyListeners();
  }

  /// Toggle routes display
  void toggleRoutes() {
    _showRoutes = !_showRoutes;
    notifyListeners();
  }

  /// Toggle drone display
  void toggleDrones() {
    _showDrones = !_showDrones;
    notifyListeners();
  }

  /// Toggle emergency markers display
  void toggleEmergencies() {
    _showEmergencies = !_showEmergencies;
    notifyListeners();
  }

  /// Toggle mission waypoints display
  void toggleMissions() {
    _showMissions = !_showMissions;
    notifyListeners();
  }

  /// Set update interval for real-time data
  void setUpdateInterval(int seconds) {
    _updateIntervalSeconds = seconds.clamp(1, 60);
    notifyListeners();
  }

  /// Update map center
  void updateMapCenter(LatLng newCenter) {
    _mapCenter = newCenter;
    notifyListeners();
  }

  /// Update zoom level
  void updateZoomLevel(double newZoom) {
    _zoomLevel = newZoom.clamp(1.0, 18.0);
    notifyListeners();
  }

  /// Add emergency location
  void addEmergencyLocation(EmergencyLocation emergency) {
    _emergencyLocations.add(emergency);
    notifyListeners();
  }

  /// Remove emergency location
  void removeEmergencyLocation(String emergencyId) {
    _emergencyLocations.removeWhere((e) => e.id == emergencyId);
    notifyListeners();
  }

  /// Update emergency location
  void updateEmergencyLocation(
    String emergencyId,
    EmergencyLocation updatedEmergency,
  ) {
    final index = _emergencyLocations.indexWhere((e) => e.id == emergencyId);
    if (index != -1) {
      _emergencyLocations[index] = updatedEmergency;
      notifyListeners();
    }
  }

  /// Add mission waypoints
  void addMissionWaypoints(String missionId, List<LatLng> waypoints) {
    _missionWaypoints[missionId] = waypoints;
    notifyListeners();
  }

  /// Remove mission waypoints
  void removeMissionWaypoints(String missionId) {
    _missionWaypoints.remove(missionId);
    notifyListeners();
  }

  /// Add coverage area
  void addCoverageArea(CoverageArea coverage) {
    _coverageAreas.add(coverage);
    notifyListeners();
  }

  /// Remove coverage area
  void removeCoverageArea(String coverageId) {
    _coverageAreas.removeWhere((c) => c.id == coverageId);
    notifyListeners();
  }

  /// Add search zone
  void addSearchZone(SearchZone zone) {
    _searchZones.add(zone);
    notifyListeners();
  }

  /// Remove search zone
  void removeSearchZone(String zoneId) {
    _searchZones.removeWhere((z) => z.id == zoneId);
    notifyListeners();
  }

  /// Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get emergencies by type
  List<EmergencyLocation> getEmergenciesByType(EmergencyType type) {
    return _emergencyLocations.where((e) => e.type == type).toList();
  }

  /// Get emergencies by severity
  List<EmergencyLocation> getEmergenciesBySeverity(EmergencySeverity severity) {
    return _emergencyLocations.where((e) => e.severity == severity).toList();
  }

  /// Get active coverage areas
  List<CoverageArea> getActiveCoverageAreas() {
    return _coverageAreas.where((c) => c.isActive).toList();
  }

  /// Focus on emergency
  void focusOnEmergency(String emergencyId) {
    final emergency = _emergencyLocations.firstWhere(
      (e) => e.id == emergencyId,
      orElse: () => _emergencyLocations.first,
    );

    updateMapCenter(emergency.position);
    updateZoomLevel(15.0);
  }

  /// Focus on coverage area
  void focusOnCoverageArea(String coverageId) {
    final coverage = _coverageAreas.firstWhere(
      (c) => c.id == coverageId,
      orElse: () => _coverageAreas.first,
    );

    updateMapCenter(coverage.center);
    updateZoomLevel(12.0);
  }

  /// Reset map to default view
  void resetMapView() {
    updateMapCenter(const LatLng(28.6139, 77.2090));
    updateZoomLevel(13.0);
  }

  /// Update user location
  void updateUserLocation(LatLng location) {
    _userLocation = location;
    notifyListeners();
  }

  /// Center on user location
  void centerOnUserLocation() {
    if (_userLocation != null) {
      updateMapCenter(_userLocation!);
      updateZoomLevel(15.0);
    }
  }

  /// Toggle geofence display
  void toggleGeofence() {
    _showGeofence = !_showGeofence;
    notifyListeners();
  }

  /// Update geofence radius
  void updateGeofenceRadius(double radius) {
    _geofenceRadius = radius.clamp(100.0, 5000.0);
    notifyListeners();
  }

  /// Select drone
  void selectDrone(Drone drone) {
    _selectedDroneId = drone.id;
    notifyListeners();
  }

  /// Select drone by ID
  void selectDroneById(String droneId) {
    _selectedDroneId = droneId;
    notifyListeners();
  }

  /// Clear selections
  void clearSelections() {
    _selectedDroneId = null;
    notifyListeners();
  }

  /// Add route point
  void addRoutePoint(LatLng point) {
    _routePoints.add(point);
    notifyListeners();
  }

  /// Clear route points
  void clearRoutePoints() {
    _routePoints.clear();
    notifyListeners();
  }

  /// Set route points
  void setRoutePoints(List<LatLng> points) {
    _routePoints = points;
    notifyListeners();
  }

  /// Get geofence polygon
  List<LatLng> getGeofencePolygon() {
    if (_userLocation == null) return [];

    const int sides = 20;
    final List<LatLng> points = [];

    for (int i = 0; i < sides; i++) {
      final double angle = (i * 2 * 3.14159) / sides;
      final double lat =
          _userLocation!.latitude + (_geofenceRadius / 111000) * cos(angle);
      final double lng =
          _userLocation!.longitude +
          (_geofenceRadius /
                  (111000 * cos(_userLocation!.latitude * 3.14159 / 180))) *
              sin(angle);
      points.add(LatLng(lat, lng));
    }

    return points;
  }

  /// Get drone coverage areas
  List<CoverageArea> getDroneCoverageAreas() {
    return _coverageAreas.where((area) => area.isActive).toList();
  }

  /// Get distance to user
  double getDistanceToUser(LatLng position) {
    if (_userLocation == null) return 0.0;

    const double earthRadius = 6371000; // meters
    final double lat1Rad = _userLocation!.latitude * 3.14159 / 180;
    final double lat2Rad = position.latitude * 3.14159 / 180;
    final double deltaLatRad =
        (position.latitude - _userLocation!.latitude) * 3.14159 / 180;
    final double deltaLngRad =
        (position.longitude - _userLocation!.longitude) * 3.14159 / 180;

    final double a =
        sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Get ETA to user
  String getETAToUser(LatLng position, double speed) {
    final double distance = getDistanceToUser(position);
    if (speed <= 0) return "Unknown";

    final double timeInHours = distance / (speed * 1000 / 3600); // speed in m/s
    final int minutes = (timeInHours * 60).round();

    if (minutes < 60) {
      return "${minutes}m";
    } else {
      final int hours = minutes ~/ 60;
      final int remainingMinutes = minutes % 60;
      return "${hours}h ${remainingMinutes}m";
    }
  }

  /// Initialize map provider
  void initialize() {
    _initializeMap();
  }

  /// Start location tracking
  void startLocationTracking() {
    _isTrackingLocation = true;
    notifyListeners();
  }

  /// Stop location tracking
  void stopLocationTracking() {
    _isTrackingLocation = false;
    notifyListeners();
  }

  /// Set geofence radius
  void setGeofenceRadius(double radius) {
    updateGeofenceRadius(radius);
  }

  /// Get drone statistics
  Map<String, dynamic> getDroneStatistics() {
    return {
      'total': _dronesInGeofence.length,
      'active': _dronesInGeofence.length,
      'available': _dronesInGeofence.length,
    };
  }

  /// Get mission statistics
  Map<String, dynamic> getMissionStatistics() {
    return {
      'total': _missionWaypoints.length,
      'active': _missionWaypoints.length,
      'completed': 0,
    };
  }

  /// Toggle GCS stations display
  void toggleGCSStations() {
    _showGCSStations = !_showGCSStations;
    notifyListeners();
  }

  /// Select GCS station
  void selectGCSStation(GCSStation station) {
    _selectedGCSStation = station.id;
    notifyListeners();
  }

  /// Select mission
  void selectMission(Mission mission) {
    _selectedMission = mission;
    notifyListeners();
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Center on India
  void centerOnIndia() {
    updateMapCenter(const LatLng(20.5937, 78.9629)); // Center of India
    updateZoomLevel(5.0);
  }

  /// Set current route
  void setCurrentRoute(List<LatLng> route) {
    _currentRoute = route;
    notifyListeners();
  }

  /// Set mission status filter
  void setMissionStatusFilter(Set<MissionStatus> filter) {
    _missionStatusFilter = filter;
    notifyListeners();
  }

  /// Set priority filter
  void setPriorityFilter(MissionPriority? filter) {
    _priorityFilter = filter;
    notifyListeners();
  }

  /// Update total coverage radius
  void updateTotalCoverageRadius(double radius) {
    _totalCoverageRadius = radius;
    notifyListeners();
  }
}

// Map Layer Model
class MapLayer {
  final String id;
  final String name;
  final bool isVisible;
  final LayerType type;

  const MapLayer({
    required this.id,
    required this.name,
    required this.isVisible,
    required this.type,
  });
}

enum LayerType { drones, emergencies, missions, coverage, routes, searchZones }

// Emergency Location Model
class EmergencyLocation {
  final String id;
  final EmergencyType type;
  final LatLng position;
  final EmergencySeverity severity;
  final String description;
  final DateTime timestamp;
  final EmergencyPriority priority;
  final EmergencyStatus status;

  const EmergencyLocation({
    required this.id,
    required this.type,
    required this.position,
    required this.severity,
    required this.description,
    required this.timestamp,
    this.priority = EmergencyPriority.normal,
    this.status = EmergencyStatus.active,
  });
}

enum EmergencyType { fire, medical, accident, natural, security, search }

enum EmergencySeverity { low, medium, high, critical }

enum EmergencyPriority { low, normal, high, urgent, critical }

enum EmergencyStatus { pending, active, inProgress, resolved, closed }

extension EmergencyStatusExtension on EmergencyStatus {
  String get displayName {
    switch (this) {
      case EmergencyStatus.pending:
        return 'Pending';
      case EmergencyStatus.active:
        return 'Active';
      case EmergencyStatus.inProgress:
        return 'In Progress';
      case EmergencyStatus.resolved:
        return 'Resolved';
      case EmergencyStatus.closed:
        return 'Closed';
    }
  }
}

extension EmergencyPriorityExtension on EmergencyPriority {
  String get displayName {
    switch (this) {
      case EmergencyPriority.low:
        return 'Low';
      case EmergencyPriority.normal:
        return 'Normal';
      case EmergencyPriority.high:
        return 'High';
      case EmergencyPriority.urgent:
        return 'Urgent';
      case EmergencyPriority.critical:
        return 'Critical';
    }
  }
}

// Coverage Area Model
class CoverageArea {
  final String id;
  final String name;
  final LatLng center;
  final double radius;
  final Color color;
  final bool isActive;

  const CoverageArea({
    required this.id,
    required this.name,
    required this.center,
    required this.radius,
    required this.color,
    required this.isActive,
  });
}

// Search Zone Model
class SearchZone {
  final String id;
  final String name;
  final List<LatLng> boundary;
  final SearchZoneType type;
  final String? assignedMissionId;

  const SearchZone({
    required this.id,
    required this.name,
    required this.boundary,
    required this.type,
    this.assignedMissionId,
  });
}

enum SearchZoneType { primary, secondary, restricted, cleared }
