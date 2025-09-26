import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import 'location_provider.dart';

class DroneTrackingProvider extends ChangeNotifier {
  final LocationProvider _locationProvider;

  DroneTrackingProvider(this._locationProvider);

  // Drone tracking state
  List<DroneInfo> _activeDrones = [];
  List<DroneInfo> get activeDrones => _activeDrones;

  bool _isTrackingActive = false;
  bool get isTrackingActive => _isTrackingActive;

  String? _selectedDroneId;
  String? get selectedDroneId => _selectedDroneId;

  DroneInfo? get selectedDrone {
    if (_selectedDroneId == null) return null;
    try {
      return _activeDrones.firstWhere((drone) => drone.id == _selectedDroneId);
    } catch (e) {
      return null;
    }
  }

  // Mission tracking
  Map<String, List<LatLng>> _flightPaths = {};
  Map<String, List<LatLng>> get flightPaths => _flightPaths;

  // Real-time updates simulation
  bool _isSimulatingMovement = false;
  bool get isSimulatingMovement => _isSimulatingMovement;

  // Additional tracking state for help seeker dashboard
  bool _isTracking = false;
  bool get isTracking => _isTracking;

  List<DroneInfo> _nearbyDrones = [];
  List<DroneInfo> get nearbyDrones => _nearbyDrones;

  List<DroneInfo> _dronesInGeofence = [];
  List<DroneInfo> get dronesInGeofence => _dronesInGeofence;

  /// Initialize drone tracking with mock data
  void initializeDroneTracking() {
    _loadMockDrones();
    _isTrackingActive = true;
    notifyListeners();
  }

  /// Start tracking for help seeker
  void startTracking() {
    _isTracking = true;
    _updateNearbyDrones();
    _updateGeofenceDrones();
    notifyListeners();
  }

  /// Stop tracking for help seeker
  void stopTracking() {
    _isTracking = false;
    notifyListeners();
  }

  /// Refresh tracking data
  void refresh() {
    _updateNearbyDrones();
    _updateGeofenceDrones();
    notifyListeners();
  }

  /// Load mock drone data
  void _loadMockDrones() {
    _activeDrones = [
      DroneInfo(
        id: 'DRONE_001',
        name: 'Rescue Alpha',
        type: DroneType.rescue,
        status: DroneStatus.active,
        position: const LatLng(28.6139, 77.2090), // New Delhi
        altitude: 120.0,
        batteryLevel: 85.0,
        speed: 15.2,
        assignedMission: 'MISSION_001',
        lastUpdate: DateTime.now(),
        serialNumber: 'SN-001234',
      ),
      DroneInfo(
        id: 'DRONE_002',
        name: 'Survey Beta',
        type: DroneType.surveillance,
        status: DroneStatus.active,
        position: const LatLng(28.6129, 77.2295), // Near India Gate
        altitude: 95.0,
        batteryLevel: 72.0,
        speed: 12.8,
        assignedMission: 'MISSION_002',
        lastUpdate: DateTime.now(),
        serialNumber: 'SN-001235',
      ),
      DroneInfo(
        id: 'DRONE_003',
        name: 'Medical Gamma',
        type: DroneType.medical,
        status: DroneStatus.standby,
        position: const LatLng(28.5355, 77.3910), // Noida
        altitude: 0.0,
        batteryLevel: 95.0,
        speed: 0.0,
        assignedMission: null,
        lastUpdate: DateTime.now(),
        serialNumber: 'SN-001236',
      ),
      DroneInfo(
        id: 'DRONE_004',
        name: 'Search Delta',
        type: DroneType.search,
        status: DroneStatus.active,
        position: const LatLng(28.7041, 77.1025), // North Delhi
        altitude: 150.0,
        batteryLevel: 58.0,
        speed: 18.5,
        assignedMission: 'MISSION_003',
        lastUpdate: DateTime.now(),
        serialNumber: 'SN-001237',
      ),
    ];

    // Initialize flight paths
    for (var drone in _activeDrones) {
      _flightPaths[drone.id] = [drone.position];
    }
  }

  /// Select a specific drone for detailed tracking
  void selectDrone(String droneId) {
    _selectedDroneId = droneId;
    notifyListeners();
  }

  /// Clear drone selection
  void clearSelection() {
    _selectedDroneId = null;
    notifyListeners();
  }

  /// Update drone position (simulated)
  void updateDronePosition(
    String droneId,
    LatLng newPosition, {
    double? altitude,
    double? speed,
    double? batteryLevel,
  }) {
    final droneIndex = _activeDrones.indexWhere((d) => d.id == droneId);
    if (droneIndex == -1) return;

    final drone = _activeDrones[droneIndex];
    _activeDrones[droneIndex] = drone.copyWith(
      position: newPosition,
      altitude: altitude ?? drone.altitude,
      speed: speed ?? drone.speed,
      batteryLevel: batteryLevel ?? drone.batteryLevel,
      lastUpdate: DateTime.now(),
    );

    // Update flight path
    if (_flightPaths[droneId] != null) {
      _flightPaths[droneId]!.add(newPosition);
      // Keep only last 50 positions to avoid memory issues
      if (_flightPaths[droneId]!.length > 50) {
        _flightPaths[droneId] = _flightPaths[droneId]!.sublist(
          _flightPaths[droneId]!.length - 50,
        );
      }
    }

    notifyListeners();
  }

  /// Start simulating drone movement for demo purposes
  void startMovementSimulation() {
    if (_isSimulatingMovement) return;

    _isSimulatingMovement = true;
    _simulateMovement();
  }

  /// Stop movement simulation
  void stopMovementSimulation() {
    _isSimulatingMovement = false;
    notifyListeners();
  }

  /// Simulate realistic drone movement
  void _simulateMovement() async {
    while (_isSimulatingMovement) {
      await Future.delayed(const Duration(seconds: 3));

      for (var drone in _activeDrones) {
        if (drone.status == DroneStatus.active) {
          // Simulate small movement (realistic drone patrol)
          final random = DateTime.now().millisecondsSinceEpoch % 100;
          final latOffset = (random % 20 - 10) * 0.001; // Small lat change
          final lngOffset =
              ((random * 7) % 20 - 10) * 0.001; // Small lng change

          final newPosition = LatLng(
            drone.position.latitude + latOffset,
            drone.position.longitude + lngOffset,
          );

          // Simulate battery drain
          final newBattery = (drone.batteryLevel - 0.1).clamp(0.0, 100.0);

          // Simulate speed variation
          final newSpeed = drone.speed + (random % 6 - 3) * 0.5;

          updateDronePosition(
            drone.id,
            newPosition,
            batteryLevel: newBattery,
            speed: newSpeed.clamp(0.0, 25.0),
          );
        }
      }
    }
  }

  /// Add new drone to tracking
  void addDrone(DroneInfo drone) {
    _activeDrones.add(drone);
    _flightPaths[drone.id] = [drone.position];
    notifyListeners();
  }

  /// Remove drone from tracking
  void removeDrone(String droneId) {
    _activeDrones.removeWhere((drone) => drone.id == droneId);
    _flightPaths.remove(droneId);

    if (_selectedDroneId == droneId) {
      _selectedDroneId = null;
    }

    notifyListeners();
  }

  /// Update drone status
  void updateDroneStatus(String droneId, DroneStatus newStatus) {
    final droneIndex = _activeDrones.indexWhere((d) => d.id == droneId);
    if (droneIndex == -1) return;

    final drone = _activeDrones[droneIndex];
    _activeDrones[droneIndex] = drone.copyWith(
      status: newStatus,
      lastUpdate: DateTime.now(),
    );

    notifyListeners();
  }

  /// Get drones by mission ID
  List<DroneInfo> getDronesByMission(String missionId) {
    return _activeDrones
        .where((drone) => drone.assignedMission == missionId)
        .toList();
  }

  /// Get drones by type
  List<DroneInfo> getDronesByType(DroneType type) {
    return _activeDrones.where((drone) => drone.type == type).toList();
  }

  /// Get available drones (not assigned to missions)
  List<DroneInfo> getAvailableDrones() {
    return _activeDrones
        .where(
          (drone) =>
              drone.assignedMission == null &&
              drone.status != DroneStatus.maintenance &&
              drone.batteryLevel > 20.0,
        )
        .toList();
  }

  /// Assign drone to mission
  void assignDroneToMission(String droneId, String missionId) {
    final droneIndex = _activeDrones.indexWhere((d) => d.id == droneId);
    if (droneIndex == -1) return;

    final drone = _activeDrones[droneIndex];
    _activeDrones[droneIndex] = drone.copyWith(
      assignedMission: missionId,
      status: DroneStatus.active,
      lastUpdate: DateTime.now(),
    );

    notifyListeners();
  }

  /// Unassign drone from mission
  void unassignDroneFromMission(String droneId) {
    final droneIndex = _activeDrones.indexWhere((d) => d.id == droneId);
    if (droneIndex == -1) return;

    final drone = _activeDrones[droneIndex];
    _activeDrones[droneIndex] = drone.copyWith(
      assignedMission: null,
      status: DroneStatus.standby,
      lastUpdate: DateTime.now(),
    );

    notifyListeners();
  }

  /// Get flight path for specific drone
  List<LatLng> getDroneFlightPath(String droneId) {
    return _flightPaths[droneId] ?? [];
  }

  /// Clear flight path for drone
  void clearDroneFlightPath(String droneId) {
    _flightPaths[droneId] = [];
    notifyListeners();
  }

  /// Update nearby drones based on user location
  void _updateNearbyDrones() {
    // Simulate nearby drones calculation
    _nearbyDrones = _activeDrones
        .where((drone) {
          // Simple distance check - in real app would use proper geolocation
          return drone.status == DroneStatus.active;
        })
        .take(3)
        .toList();
  }

  /// Update drones in geofence
  void _updateGeofenceDrones() {
    // Simulate geofence check
    _dronesInGeofence = _activeDrones
        .where((drone) {
          return drone.status == DroneStatus.active;
        })
        .take(2)
        .toList();
  }

  /// Get drone tracking information
  Map<String, dynamic> getDroneTrackingInfo(String droneId) {
    final drone = _activeDrones.firstWhere(
      (d) => d.id == droneId,
      orElse: () => _activeDrones.first,
    );

    // Calculate distance and ETA if user location is available
    final userLat = 28.6139; // Default Delhi location
    final userLng = 77.2090;
    final distance = _calculateDistance(
      userLat,
      userLng,
      drone.position.latitude,
      drone.position.longitude,
    );
    final eta = _calculateETA(distance, drone.speed);

    return {
      'id': drone.id,
      'name': drone.name,
      'status': drone.status.displayName,
      'batteryLevel': drone.batteryLevel,
      'altitude': drone.altitude,
      'speed': drone.speed,
      'lastUpdate': drone.lastUpdate.toIso8601String(),
      'formattedDistance': '${distance.toStringAsFixed(1)} km',
      'formattedETA': eta,
    };
  }

  /// Calculate distance between two points
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km
    final double dLat = (lat2 - lat1) * (3.14159 / 180);
    final double dLon = (lon2 - lon1) * (3.14159 / 180);
    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (3.14159 / 180)) *
            cos(lat2 * (3.14159 / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Calculate ETA
  String _calculateETA(double distance, double speed) {
    if (speed <= 0) return 'Unknown';
    final double timeInHours = distance / speed;
    final int minutes = (timeInHours * 60).round();
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final int hours = minutes ~/ 60;
      final int remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
  }

  /// Get distance to user method
  double getDistanceToUser(LatLng position) {
    if (_locationProvider.currentLocation == null) return 0.0;

    const double earthRadius = 6371000; // meters
    final double lat1Rad =
        _locationProvider.currentLocation!.latitude * 3.14159 / 180;
    final double lat2Rad = position.latitude * 3.14159 / 180;
    final double deltaLatRad =
        (position.latitude - _locationProvider.currentLocation!.latitude) *
        3.14159 /
        180;
    final double deltaLngRad =
        (position.longitude - _locationProvider.currentLocation!.longitude) *
        3.14159 /
        180;

    final double a =
        sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Get geofence radius
  double get geofenceRadius => 1000.0; // 1km default

  /// Get all drones
  List<DroneInfo> get allDrones => _activeDrones;

  /// Dispose resources
  @override
  void dispose() {
    _isSimulatingMovement = false;
    super.dispose();
  }
}

// Drone Information Model
class DroneInfo {
  final String id;
  final String name;
  final DroneType type;
  final DroneStatus status;
  final LatLng position;
  final double altitude; // in meters
  final double batteryLevel; // percentage
  final double speed; // km/h
  final String? assignedMission;
  final DateTime lastUpdate;
  final String serialNumber;

  const DroneInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.position,
    required this.altitude,
    required this.batteryLevel,
    required this.speed,
    this.assignedMission,
    required this.lastUpdate,
    String? serialNumber,
  }) : serialNumber = serialNumber ?? 'SN-000000';

  DroneInfo copyWith({
    String? id,
    String? name,
    DroneType? type,
    DroneStatus? status,
    LatLng? position,
    double? altitude,
    double? batteryLevel,
    double? speed,
    String? assignedMission,
    DateTime? lastUpdate,
    String? serialNumber,
  }) {
    return DroneInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      position: position ?? this.position,
      altitude: altitude ?? this.altitude,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      speed: speed ?? this.speed,
      assignedMission: assignedMission ?? this.assignedMission,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      serialNumber: serialNumber ?? this.serialNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'status': status.name,
      'position': {
        'latitude': position.latitude,
        'longitude': position.longitude,
      },
      'altitude': altitude,
      'batteryLevel': batteryLevel,
      'speed': speed,
      'assignedMission': assignedMission,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }
}

// Drone Type Enumeration
enum DroneType {
  rescue,
  surveillance,
  medical,
  search,
  delivery,
  reconnaissance,
}

extension DroneTypeExtension on DroneType {
  String get displayName {
    switch (this) {
      case DroneType.rescue:
        return 'Rescue';
      case DroneType.surveillance:
        return 'Surveillance';
      case DroneType.medical:
        return 'Medical';
      case DroneType.search:
        return 'Search & Rescue';
      case DroneType.delivery:
        return 'Delivery';
      case DroneType.reconnaissance:
        return 'Reconnaissance';
    }
  }

  String get icon {
    switch (this) {
      case DroneType.rescue:
        return '🚁';
      case DroneType.surveillance:
        return '📹';
      case DroneType.medical:
        return '🏥';
      case DroneType.search:
        return '🔍';
      case DroneType.delivery:
        return '📦';
      case DroneType.reconnaissance:
        return '🛰️';
    }
  }
}

// Drone Status Enumeration
enum DroneStatus { active, standby, maintenance, charging, offline }

extension DroneStatusExtension on DroneStatus {
  String get displayName {
    switch (this) {
      case DroneStatus.active:
        return 'Active';
      case DroneStatus.standby:
        return 'Standby';
      case DroneStatus.maintenance:
        return 'Maintenance';
      case DroneStatus.charging:
        return 'Charging';
      case DroneStatus.offline:
        return 'Offline';
    }
  }

  bool get isAvailable {
    return this == DroneStatus.active || this == DroneStatus.standby;
  }
}

extension DroneInfoExtension on DroneInfo {
  bool get isAvailable => status.isAvailable;
  bool get isDeployed => assignedMission != null;
}

// Add missing getters directly to DroneInfo class
extension DroneInfoHelpers on DroneInfo {
  bool get isOperational => status == DroneStatus.active;
  bool get needsMaintenance => batteryLevel < 20.0;
  String get statusDisplayName => status.displayName;
  String get typeDisplayName => type.displayName;
}
