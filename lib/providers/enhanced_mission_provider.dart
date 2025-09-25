import 'package:flutter/foundation.dart';
import '../models/mission.dart';
import '../models/drone.dart';
import '../models/payload.dart';
import '../models/group_event.dart';
import '../models/user.dart';
import '../services/mission_management_service.dart';

class EnhancedMissionProvider with ChangeNotifier {
  final MissionManagementService _missionService = MissionManagementService();

  // State variables
  List<Mission> _missions = [];
  List<Drone> _availableDrones = [];
  List<Payload> _payloads = [];
  Mission? _selectedMission;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Mission> get missions => List.unmodifiable(_missions);
  List<Drone> get availableDrones => List.unmodifiable(_availableDrones);
  List<Payload> get payloads => List.unmodifiable(_payloads);
  Mission? get selectedMission => _selectedMission;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Filtered mission lists
  List<Mission> get activeMissions =>
      _missions.where((m) => m.isActive).toList();
  List<Mission> get completedMissions =>
      _missions.where((m) => m.isCompleted).toList();
  List<Mission> get pendingMissions =>
      _missions.where((m) => m.isPending).toList();
  List<Mission> get inProgressMissions =>
      _missions.where((m) => m.isInProgress).toList();
  List<Mission> get criticalMissions =>
      _missions.where((m) => m.priority == MissionPriority.critical).toList();

  // Drone filtering
  List<Drone> get operationalDrones =>
      _availableDrones.where((d) => d.isOperational).toList();
  List<Drone> get maintenanceDrones =>
      _availableDrones.where((d) => d.needsMaintenance).toList();
  List<Drone> get unassignedDrones =>
      _availableDrones.where((d) => d.isAvailable).toList();
  List<Drone> get deployedDrones =>
      _availableDrones.where((d) => d.isDeployed).toList();

  EnhancedMissionProvider() {
    _initializeProvider();
  }

  void _initializeProvider() {
    _loadInitialData();
    _listenToMissionUpdates();
  }

  void _loadInitialData() {
    // Initialize with mock data for demonstration
    _loadMockDrones();
    _loadMockMissionsData();
    notifyListeners();
  }

  void _listenToMissionUpdates() {
    _missionService.missionsStream.listen(
      (missions) {
        _missions = missions;
        notifyListeners();
      },
      onError: (error) {
        _setError('Failed to load missions: $error');
      },
    );
  }

  // Mission Creation Methods
  Future<Mission> createMission({
    required String groupId,
    required EventType eventType,
    required MissionPriority priority,
    required String description,
    required LocationData targetLocation,
    required String assignedDroneId,
    required Payload payload,
    DateTime? scheduledStartTime,
    String? specialInstructions,
    LocationData? startLocation,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Validate drone availability
      final drone = _availableDrones.firstWhere(
        (d) => d.id == assignedDroneId,
        orElse: () => throw Exception('Drone not found'),
      );

      if (!drone.isAvailable) {
        throw Exception('Selected drone is not available');
      }

      // Validate mission requirements
      final validation = _missionService.validateMissionRequirements(
        payload: payload,
        drone: drone,
        priority: priority,
      );

      if (!validation.isValid) {
        throw Exception(
          'Mission validation failed: ${validation.errors.join(', ')}',
        );
      }

      // Show warnings if any
      if (validation.hasWarnings) {
        debugPrint('Mission warnings: ${validation.warnings.join(', ')}');
      }

      // Create the mission
      final mission = await _missionService.createMission(
        groupId: groupId,
        eventType: eventType,
        priority: priority,
        description: description,
        targetLocation: targetLocation,
        assignedDroneId: assignedDroneId,
        assignedOperatorId: 'current_user', // TODO: Get from auth
        payload: payload,
        scheduledStartTime: scheduledStartTime,
        specialInstructions: specialInstructions,
        startLocation: startLocation,
      );

      // Update drone status
      await _updateDroneStatus(
        assignedDroneId,
        DroneStatus.deployed,
        mission.id,
      );

      // Add to local list and notify
      _missions.add(mission);
      _payloads.add(payload);
      notifyListeners();

      return mission;
    } catch (e) {
      _setError('Failed to create mission: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Mission>> createBulkMissions({
    required String groupId,
    required EventType eventType,
    required MissionPriority priority,
    required String baseDescription,
    required LocationData targetLocation,
    required int quantity,
    required Payload basePayload,
    DateTime? scheduledStartTime,
    String? specialInstructions,
    LocationData? startLocation,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Get available drones for bulk creation
      final availableDrones = _missionService.getAvailableDrones(
        _availableDrones,
        minBatteryLevel: 20.0,
        minPayloadCapacity: basePayload.weight,
      );

      if (availableDrones.length < quantity) {
        throw Exception(
          'Not enough available drones. Found ${availableDrones.length}, need $quantity',
        );
      }

      final droneIds = availableDrones.take(quantity).map((d) => d.id).toList();

      // Create bulk missions
      final missions = await _missionService.createBulkMissions(
        groupId: groupId,
        eventType: eventType,
        priority: priority,
        baseDescription: baseDescription,
        targetLocation: targetLocation,
        droneIds: droneIds,
        assignedOperatorId: 'current_user',
        basePayload: basePayload,
        scheduledStartTime: scheduledStartTime,
        specialInstructions: specialInstructions,
        startLocation: startLocation,
      );

      // Update drone statuses
      for (int i = 0; i < droneIds.length; i++) {
        await _updateDroneStatus(
          droneIds[i],
          DroneStatus.deployed,
          missions[i].id,
        );
      }

      // Add to local lists
      _missions.addAll(missions);
      notifyListeners();

      return missions;
    } catch (e) {
      _setError('Failed to create bulk missions: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Mission Management Methods
  Future<bool> updateMissionStatus(
    String missionId,
    MissionStatus newStatus,
  ) async {
    _setLoading(true);
    try {
      final success = await _missionService.updateMissionStatus(
        missionId,
        newStatus,
      );

      if (success) {
        final missionIndex = _missions.indexWhere((m) => m.id == missionId);
        if (missionIndex != -1) {
          final mission = _missions[missionIndex];

          // Update drone status based on mission status
          if (newStatus == MissionStatus.completed ||
              newStatus == MissionStatus.cancelled ||
              newStatus == MissionStatus.failed) {
            await _updateDroneStatus(
              mission.assignedDroneId,
              DroneStatus.active,
              null,
            );
          }

          // Update local mission
          _missions[missionIndex] = mission.copyWith(status: newStatus);
          notifyListeners();
        }
      }

      return success;
    } catch (e) {
      _setError('Failed to update mission status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> assignDroneToMission(String missionId, String droneId) async {
    _setLoading(true);
    try {
      final success = await _missionService.assignDroneToMission(
        missionId,
        droneId,
      );

      if (success) {
        await _updateDroneStatus(droneId, DroneStatus.deployed, missionId);
        notifyListeners();
      }

      return success;
    } catch (e) {
      _setError('Failed to assign drone: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> startMission(String missionId) async {
    await updateMissionStatus(missionId, MissionStatus.inProgress);
  }

  Future<void> completeMission(
    String missionId, {
    String? completionNotes,
  }) async {
    final mission = _missions.firstWhere((m) => m.id == missionId);
    final updatedMission = mission.copyWith(
      status: MissionStatus.completed,
      completionNotes: completionNotes,
      actualEndTime: DateTime.now(),
    );

    final index = _missions.indexWhere((m) => m.id == missionId);
    _missions[index] = updatedMission;

    // Free up the drone
    await _updateDroneStatus(mission.assignedDroneId, DroneStatus.active, null);

    notifyListeners();
  }

  Future<void> cancelMission(String missionId, {String? reason}) async {
    final mission = _missions.firstWhere((m) => m.id == missionId);
    final updatedMission = mission.copyWith(
      status: MissionStatus.cancelled,
      completionNotes: reason,
    );

    final index = _missions.indexWhere((m) => m.id == missionId);
    _missions[index] = updatedMission;

    // Free up the drone
    await _updateDroneStatus(mission.assignedDroneId, DroneStatus.active, null);

    notifyListeners();
  }

  // Drone Management Methods
  List<Drone> getOptimalDronesForPayload(Payload payload) {
    return _missionService.getAvailableDrones(
      _availableDrones,
      minPayloadCapacity: payload.weight,
      requiredCapabilities: payload.specialRequirements,
    );
  }

  Drone? suggestBestDrone(Payload payload, LocationData targetLocation) {
    return _missionService.selectOptimalDrone(
      _availableDrones,
      payload,
      targetLocation,
    );
  }

  Future<void> _updateDroneStatus(
    String droneId,
    DroneStatus status,
    String? missionId,
  ) async {
    final droneIndex = _availableDrones.indexWhere((d) => d.id == droneId);
    if (droneIndex != -1) {
      _availableDrones[droneIndex] = _availableDrones[droneIndex].copyWith(
        status: status,
        currentMissionId: missionId,
      );
    }
  }

  // Query Methods
  List<Mission> getMissionsByDroneId(String droneId) {
    return _missionService.getMissionsByDroneId(droneId);
  }

  List<Mission> getMissionsByStatus(MissionStatus status) {
    return _missionService.getMissionsByStatus(status);
  }

  List<Mission> getMissionsByPriority(MissionPriority priority) {
    return _missionService.getMissionsByPriority(priority);
  }

  Mission? getMissionById(String missionId) {
    return _missionService.getMissionById(missionId);
  }

  Payload? getPayloadById(String payloadId) {
    return _missionService.getPayloadById(payloadId);
  }

  // Selection Methods
  void selectMission(String? missionId) {
    _selectedMission = missionId != null ? getMissionById(missionId) : null;
    notifyListeners();
  }

  void clearSelectedMission() {
    _selectedMission = null;
    notifyListeners();
  }

  // Statistics and Analytics
  Map<String, int> getMissionStatistics() {
    return {
      'total': _missions.length,
      'active': activeMissions.length,
      'completed': completedMissions.length,
      'pending': pendingMissions.length,
      'inProgress': inProgressMissions.length,
      'critical': criticalMissions.length,
    };
  }

  Map<String, int> getDroneStatistics() {
    return {
      'total': _availableDrones.length,
      'operational': operationalDrones.length,
      'maintenance': maintenanceDrones.length,
      'unassigned': unassignedDrones.length,
      'deployed': deployedDrones.length,
    };
  }

  double getAverageMissionDuration() {
    final completedWithDuration = completedMissions
        .where((m) => m.actualStartTime != null && m.actualEndTime != null)
        .toList();

    if (completedWithDuration.isEmpty) return 0.0;

    final totalMinutes = completedWithDuration
        .map((m) => m.actualEndTime!.difference(m.actualStartTime!).inMinutes)
        .reduce((a, b) => a + b);

    return totalMinutes / completedWithDuration.length;
  }

  // Utility Methods
  Duration estimateMissionDuration(
    LocationData startLocation,
    LocationData targetLocation,
    PayloadType payloadType,
  ) {
    final distance = _calculateDistance(startLocation, targetLocation);
    return _missionService.estimateMissionDuration(
      distance: distance,
      droneSpeed: 15.0, // Average drone speed in m/s
      payloadType: payloadType,
    );
  }

  double _calculateDistance(LocationData start, LocationData end) {
    // Simple distance calculation (in meters)
    // In a real app, you'd use a proper geolocation library
    const double earthRadius = 6371000; // meters
    final double lat1Rad = start.latitude * (3.14159265359 / 180);
    final double lat2Rad = end.latitude * (3.14159265359 / 180);
    final double deltaLatRad =
        (end.latitude - start.latitude) * (3.14159265359 / 180);
    final double deltaLngRad =
        (end.longitude - start.longitude) * (3.14159265359 / 180);

    final double a =
        (deltaLatRad / 2).abs() * (deltaLatRad / 2).abs() +
        (lat1Rad).abs() *
            (lat2Rad).abs() *
            (deltaLngRad / 2).abs() *
            (deltaLngRad / 2).abs();
        final double c = 2 * (a.abs().toString().length).toDouble();
    return earthRadius * c;
  }

  // Error handling
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }



  // Mock data for development
  void _loadMockDrones() {
    _availableDrones = [
      Drone(
        name: 'RESCUE-001',
        model: 'DJI Matrice 300',
        location: LocationData(latitude: 37.7749, longitude: -122.4194),
        maxFlightTime: 120,
        maxRange: 15.0,
        payloadCapacity: 5.5,
        capabilities: ['search', 'rescue', 'thermal_imaging', 'night_vision'],
        lastMaintenance: DateTime.now().subtract(const Duration(days: 15)),
        batteryLevel: 95,
      ),
      Drone(
        name: 'MEDICAL-002',
        model: 'DJI Mavic 3',
        location: LocationData(latitude: 37.7849, longitude: -122.4094),
        maxFlightTime: 90,
        maxRange: 12.0,
        payloadCapacity: 3.0,
        capabilities: ['medical_delivery', 'precision_drop', 'live_streaming'],
        lastMaintenance: DateTime.now().subtract(const Duration(days: 8)),
        batteryLevel: 88,
      ),
      Drone(
        name: 'CARGO-003',
        model: 'Autel EVO Max 4T',
        location: LocationData(latitude: 37.7649, longitude: -122.4294),
        maxFlightTime: 150,
        maxRange: 20.0,
        payloadCapacity: 8.0,
        capabilities: ['cargo_transport', 'heavy_lift', 'weather_resistant'],
        lastMaintenance: DateTime.now().subtract(const Duration(days: 22)),
        batteryLevel: 76,
      ),
      Drone(
        name: 'SURVEY-004',
        model: 'Parrot ANAFI Ai',
        location: LocationData(latitude: 37.7549, longitude: -122.4394),
        maxFlightTime: 75,
        maxRange: 8.0,
        payloadCapacity: 2.0,
        capabilities: ['surveillance', 'mapping', '4k_camera', 'zoom'],
        lastMaintenance: DateTime.now().subtract(const Duration(days: 5)),
        batteryLevel: 92,
      ),
      Drone(
        name: 'EMERGENCY-005',
        model: 'DJI M30T',
        location: LocationData(latitude: 37.7449, longitude: -122.4494),
        maxFlightTime: 110,
        maxRange: 18.0,
        payloadCapacity: 4.5,
        capabilities: [
          'emergency_response',
          'thermal_imaging',
          'flood_light',
          'speaker',
        ],
        lastMaintenance: DateTime.now().subtract(const Duration(days: 12)),
        batteryLevel: 85,
        status: DroneStatus.maintenance, // This one is in maintenance
      ),
    ];
  }

  void _loadMockMissionsData() {
    _missions = [
      Mission(
        title: 'CRITICAL_FLOOD_RESCUE-001',
        description: 'Emergency flood rescue mission in downtown area',
        type: MissionType.rescue,
        priority: MissionPriority.critical,
        assignedDroneId: 'RESCUE-001',
        assignedOperatorId: 'operator_001',
        startLocation: LocationData(latitude: 37.7749, longitude: -122.4194),
        targetLocation: LocationData(latitude: 37.7850, longitude: -122.4100),
        status: MissionStatus.inProgress,
        actualStartTime: DateTime.now().subtract(const Duration(minutes: 45)),
        scheduledStartTime: DateTime.now().subtract(const Duration(hours: 1)),
        eventId: 'flood_event_001',
        payload: 'Life jackets and emergency supplies',
        progress: 65.0,
      ),
      Mission(
        title: 'HIGH_FIRE_MEDICAL-002',
        description: 'Medical supply delivery to fire evacuation center',
        type: MissionType.medical,
        priority: MissionPriority.high,
        assignedDroneId: 'MEDICAL-002',
        assignedOperatorId: 'operator_002',
        startLocation: LocationData(latitude: 37.7849, longitude: -122.4094),
        targetLocation: LocationData(latitude: 37.7950, longitude: -122.4000),
        status: MissionStatus.assigned,
        scheduledStartTime: DateTime.now().add(const Duration(minutes: 30)),
        eventId: 'fire_event_001',
        payload: 'Emergency medications and first aid supplies',
      ),
      Mission(
        title: 'MEDIUM_EARTHQUAKE_CARGO-003',
        description: 'Food and water delivery to earthquake affected area',
        type: MissionType.delivery,
        priority: MissionPriority.medium,
        assignedDroneId: 'CARGO-003',
        assignedOperatorId: 'operator_003',
        startLocation: LocationData(latitude: 37.7649, longitude: -122.4294),
        targetLocation: LocationData(latitude: 37.7750, longitude: -122.4200),
        status: MissionStatus.completed,
        actualStartTime: DateTime.now().subtract(const Duration(hours: 3)),
        actualEndTime: DateTime.now().subtract(const Duration(hours: 2)),
        scheduledStartTime: DateTime.now().subtract(
          const Duration(hours: 3, minutes: 15),
        ),
        eventId: 'earthquake_event_001',
        payload: 'Emergency food rations and water bottles',
        completionNotes: 'Successfully delivered supplies to evacuation center',
      ),
    ];
  }

  // Cleanup
  @override
  void dispose() {
    _missionService.dispose();
    super.dispose();
  }
}
