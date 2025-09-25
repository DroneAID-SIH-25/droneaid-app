import 'package:flutter/foundation.dart';
import '../models/mission.dart';
import '../models/emergency_request.dart';
import '../models/drone.dart';
import '../models/user.dart';

// Using MissionType, MissionStatus, and MissionPriority from mission.dart model

class MissionProvider extends ChangeNotifier {
  List<Mission> _missions = [];
  List<EmergencyRequest> _emergencyRequests = [];
  List<Drone> _availableDrones = [];
  Mission? _selectedMission;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Mission> get missions => _missions;
  List<EmergencyRequest> get emergencyRequests => _emergencyRequests;
  List<Drone> get availableDrones => _availableDrones;
  Mission? get selectedMission => _selectedMission;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Filtered getters
  List<Mission> get activeMissions => _missions
      .where(
        (m) =>
            m.status != MissionStatus.completed &&
            m.status != MissionStatus.cancelled,
      )
      .toList();

  List<Mission> get completedMissions =>
      _missions.where((m) => m.status == MissionStatus.completed).toList();

  List<EmergencyRequest> get pendingRequests => _emergencyRequests
      .where((r) => r.status == EmergencyStatus.pending)
      .toList();

  List<Drone> get activeDrones =>
      _availableDrones.where((d) => d.status == DroneStatus.active).toList();

  // Constructor
  MissionProvider() {
    _initializeMockData();
  }

  /// Initialize with mock data for demo purposes
  void _initializeMockData() {
    // Mock drones
    _availableDrones = [
      Drone(
        id: 'drone_001',
        name: 'Rescue Hawk 1',
        model: 'DJI Matrice 300 RTK',
        status: DroneStatus.active,
        batteryLevel: 95,
        location: LocationData(
          latitude: 28.6139,
          longitude: 77.2090,
          address: 'Delhi Control Center',
          timestamp: DateTime.now(),
        ),
        capabilities: [
          'Search & Rescue',
          'Medical Supply Drop',
          'Surveillance',
        ],
        maxFlightTime: 45,
        maxRange: 15.0,
        payloadCapacity: 2.7,
      ),
      Drone(
        id: 'drone_002',
        name: 'Emergency Response 2',
        model: 'DJI Phantom 4 Pro',
        status: DroneStatus.maintenance,
        batteryLevel: 80,
        location: LocationData(
          latitude: 28.5355,
          longitude: 77.3910,
          address: 'Noida Base Station',
          timestamp: DateTime.now(),
        ),
        capabilities: ['Surveillance', 'Communication Relay'],
        maxFlightTime: 30,
        maxRange: 7.0,
        payloadCapacity: 1.0,
      ),
    ];

    // Mock emergency requests
    _emergencyRequests = [
      EmergencyRequest(
        id: 'req_001',
        userId: 'user_123',
        emergencyType: EmergencyType.medicalEmergency,
        description:
            'Person trapped in building collapse, needs immediate medical assistance',
        location: LocationData(
          latitude: 28.7041,
          longitude: 77.1025,
          address: 'Red Fort Area, Delhi',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        status: EmergencyStatus.pending,
        priority: Priority.high,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        contactNumber: '+91 9876543210',
      ),
      EmergencyRequest(
        id: 'req_002',
        userId: 'user_456',
        emergencyType: EmergencyType.naturalDisaster,
        description:
            'Flood situation, need evacuation assistance for elderly person',
        location: LocationData(
          latitude: 28.5355,
          longitude: 77.3910,
          address: 'Sector 62, Noida',
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
        status: EmergencyStatus.inProgress,
        priority: Priority.high,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        contactNumber: '+91 9876543211',
      ),
    ];

    // Mock missions
    _missions = [
      Mission(
        id: 'mission_001',
        emergencyRequestId: 'req_002',
        assignedDroneId: 'drone_001',
        assignedOperatorId: 'gcs_123',
        title: 'Flood Evacuation Assistance',
        description:
            'Deploy drone for flood evacuation assessment and coordination',
        status: MissionStatus.inProgress,
        type: MissionType.evacuation,
        priority: MissionPriority.high,
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        actualStartTime: DateTime.now().subtract(const Duration(minutes: 5)),
        estimatedDuration: const Duration(minutes: 30),
        targetLocation: LocationData(
          latitude: 28.5355,
          longitude: 77.3910,
          address: 'Sector 62, Noida',
          timestamp: DateTime.now(),
        ),
        startLocation: LocationData(
          latitude: 28.6139,
          longitude: 77.2090,
          address: 'Delhi Control Center',
          timestamp: DateTime.now(),
        ),
        waypoints: [],
      ),
    ];

    notifyListeners();
  }

  /// Create new emergency request
  Future<bool> createEmergencyRequest({
    required String userId,
    required EmergencyType emergencyType,
    required String description,
    required LocationData location,
    required String contactNumber,
    Priority priority = Priority.medium,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      final request = EmergencyRequest(
        id: 'req_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        emergencyType: emergencyType,
        description: description,
        location: location,
        status: EmergencyStatus.pending,
        priority: priority,
        createdAt: DateTime.now(),
        contactNumber: contactNumber,
      );

      _emergencyRequests.insert(0, request);
      return true;
    } catch (e) {
      _setError('Failed to create emergency request: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Assign drone to emergency request
  Future<bool> assignDroneToRequest({
    required String requestId,
    required String droneId,
    required String operatorId,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Find the emergency request
      final requestIndex = _emergencyRequests.indexWhere(
        (r) => r.id == requestId,
      );
      if (requestIndex == -1) {
        _setError('Emergency request not found');
        return false;
      }

      // Find the drone
      final droneIndex = _availableDrones.indexWhere((d) => d.id == droneId);
      if (droneIndex == -1) {
        _setError('Drone not found');
        return false;
      }

      // Check if drone is available
      if (_availableDrones[droneIndex].status != DroneStatus.active) {
        _setError('Selected drone is not available');
        return false;
      }

      final request = _emergencyRequests[requestIndex];

      // Create mission
      final mission = Mission(
        id: 'mission_${DateTime.now().millisecondsSinceEpoch}',
        emergencyRequestId: requestId,
        assignedDroneId: droneId,
        assignedOperatorId: operatorId,
        title: 'Emergency Response: ${request.emergencyType.name}',
        description: request.description,
        status: MissionStatus.assigned,
        type: MissionType.emergencyResponse,
        priority: MissionPriority.high,
        createdAt: DateTime.now(),
        estimatedDuration: const Duration(minutes: 45), // Default 45 minutes
        targetLocation: request.location,
        startLocation: _availableDrones[droneIndex].location,
        waypoints: [],
      );

      // Update request status
      _emergencyRequests[requestIndex] = EmergencyRequest(
        id: request.id,
        userId: request.userId,
        emergencyType: request.emergencyType,
        description: request.description,
        location: request.location,
        status: EmergencyStatus.assigned,
        priority: request.priority,
        createdAt: request.createdAt,
        contactNumber: request.contactNumber,
        assignedMissionId: mission.id,
      );

      // Update drone status
      _availableDrones[droneIndex] = Drone(
        id: _availableDrones[droneIndex].id,
        name: _availableDrones[droneIndex].name,
        model: _availableDrones[droneIndex].model,
        status: DroneStatus.deployed,
        batteryLevel: _availableDrones[droneIndex].batteryLevel,
        location: _availableDrones[droneIndex].location,
        capabilities: _availableDrones[droneIndex].capabilities,
        maxFlightTime: _availableDrones[droneIndex].maxFlightTime,
        maxRange: _availableDrones[droneIndex].maxRange,
        payloadCapacity: _availableDrones[droneIndex].payloadCapacity,
        currentMissionId: mission.id,
      );

      // Add mission
      _missions.insert(0, mission);

      return true;
    } catch (e) {
      _setError('Failed to assign drone: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Start mission
  Future<bool> startMission(String missionId) async {
    try {
      _setLoading(true);
      _clearError();

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      final missionIndex = _missions.indexWhere((m) => m.id == missionId);
      if (missionIndex == -1) {
        _setError('Mission not found');
        return false;
      }

      final mission = _missions[missionIndex];
      _missions[missionIndex] = Mission(
        id: mission.id,
        emergencyRequestId: mission.emergencyRequestId,
        assignedDroneId: mission.assignedDroneId,
        assignedOperatorId: mission.assignedOperatorId,
        title: mission.title,
        description: mission.description,
        status: MissionStatus.inProgress,
        type: mission.type,
        priority: mission.priority,
        createdAt: mission.createdAt,
        actualStartTime: DateTime.now(),
        estimatedDuration: mission.estimatedDuration,
        targetLocation: mission.targetLocation,
        startLocation: mission.startLocation,
        waypoints: mission.waypoints,
      );

      // Update related emergency request
      final requestIndex = _emergencyRequests.indexWhere(
        (r) => r.id == mission.emergencyRequestId,
      );
      if (requestIndex != -1) {
        final request = _emergencyRequests[requestIndex];
        _emergencyRequests[requestIndex] = EmergencyRequest(
          id: request.id,
          userId: request.userId,
          emergencyType: request.emergencyType,
          description: request.description,
          location: request.location,
          status: EmergencyStatus.inProgress,
          priority: request.priority,
          createdAt: request.createdAt,
          contactNumber: request.contactNumber,
          assignedMissionId: request.assignedMissionId,
        );
      }

      return true;
    } catch (e) {
      _setError('Failed to start mission: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Complete mission
  Future<bool> completeMission(
    String missionId, {
    String? completionNotes,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      final missionIndex = _missions.indexWhere((m) => m.id == missionId);
      if (missionIndex == -1) {
        _setError('Mission not found');
        return false;
      }

      final mission = _missions[missionIndex];
      _missions[missionIndex] = Mission(
        id: mission.id,
        emergencyRequestId: mission.emergencyRequestId,
        assignedDroneId: mission.assignedDroneId,
        assignedOperatorId: mission.assignedOperatorId,
        title: mission.title,
        description: mission.description,
        status: MissionStatus.completed,
        type: mission.type,
        priority: mission.priority,
        createdAt: mission.createdAt,
        actualStartTime: mission.actualStartTime,
        actualEndTime: DateTime.now(),
        estimatedDuration: mission.estimatedDuration,
        startLocation: mission.startLocation,
        targetLocation: mission.targetLocation,
        waypoints: mission.waypoints,
        completionNotes: completionNotes,
      );

      // Update drone status back to active
      final droneIndex = _availableDrones.indexWhere(
        (d) => d.id == mission.assignedDroneId,
      );
      if (droneIndex != -1) {
        _availableDrones[droneIndex] = Drone(
          id: _availableDrones[droneIndex].id,
          name: _availableDrones[droneIndex].name,
          model: _availableDrones[droneIndex].model,
          status: DroneStatus.active,
          batteryLevel:
              _availableDrones[droneIndex].batteryLevel -
              20, // Simulate battery usage
          location: mission.targetLocation, // Update location to mission target
          capabilities: _availableDrones[droneIndex].capabilities,
          maxFlightTime: _availableDrones[droneIndex].maxFlightTime,
          maxRange: _availableDrones[droneIndex].maxRange,
          payloadCapacity: _availableDrones[droneIndex].payloadCapacity,
          currentMissionId: null,
        );
      }

      // Update related emergency request
      final requestIndex = _emergencyRequests.indexWhere(
        (r) => r.id == mission.emergencyRequestId,
      );
      if (requestIndex != -1) {
        final request = _emergencyRequests[requestIndex];
        _emergencyRequests[requestIndex] = EmergencyRequest(
          id: request.id,
          userId: request.userId,
          emergencyType: request.emergencyType,
          description: request.description,
          location: request.location,
          status: EmergencyStatus.resolved,
          priority: request.priority,
          createdAt: request.createdAt,
          contactNumber: request.contactNumber,
          assignedMissionId: request.assignedMissionId,
          resolvedAt: DateTime.now(),
        );
      }

      return true;
    } catch (e) {
      _setError('Failed to complete mission: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cancel mission
  Future<bool> cancelMission(
    String missionId, {
    String? cancellationReason,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final missionIndex = _missions.indexWhere((m) => m.id == missionId);
      if (missionIndex == -1) {
        _setError('Mission not found');
        return false;
      }

      final mission = _missions[missionIndex];
      _missions[missionIndex] = Mission(
        id: mission.id,
        emergencyRequestId: mission.emergencyRequestId,
        assignedDroneId: mission.assignedDroneId,
        assignedOperatorId: mission.assignedOperatorId,
        title: mission.title,
        description: mission.description,
        status: MissionStatus.cancelled,
        type: mission.type,
        priority: mission.priority,
        createdAt: mission.createdAt,
        actualStartTime: mission.actualStartTime,
        estimatedDuration: mission.estimatedDuration,
        startLocation: mission.startLocation,
        targetLocation: mission.targetLocation,
        waypoints: mission.waypoints,
        completionNotes: cancellationReason,
      );

      // Update drone status back to active
      final droneIndex = _availableDrones.indexWhere(
        (d) => d.id == mission.assignedDroneId,
      );
      if (droneIndex != -1) {
        _availableDrones[droneIndex] = Drone(
          id: _availableDrones[droneIndex].id,
          name: _availableDrones[droneIndex].name,
          model: _availableDrones[droneIndex].model,
          status: DroneStatus.active,
          batteryLevel: _availableDrones[droneIndex].batteryLevel,
          location: _availableDrones[droneIndex].location,
          capabilities: _availableDrones[droneIndex].capabilities,
          maxFlightTime: _availableDrones[droneIndex].maxFlightTime,
          maxRange: _availableDrones[droneIndex].maxRange,
          payloadCapacity: _availableDrones[droneIndex].payloadCapacity,
          currentMissionId: null,
        );
      }

      return true;
    } catch (e) {
      _setError('Failed to cancel mission: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Select mission for detailed view
  void selectMission(Mission mission) {
    _selectedMission = mission;
    notifyListeners();
  }

  /// Clear selected mission
  void clearSelectedMission() {
    _selectedMission = null;
    notifyListeners();
  }

  /// Refresh missions and requests
  Future<void> refreshData() async {
    try {
      _setLoading(true);
      _clearError();

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // In a real app, this would fetch fresh data from the server
      // For now, we'll just notify listeners to refresh the UI
      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh data: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Helper methods
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
    notifyListeners();
  }

  /// Get mission by ID
  Mission? getMissionById(String missionId) {
    try {
      return _missions.firstWhere((m) => m.id == missionId);
    } catch (e) {
      return null;
    }
  }

  /// Get emergency request by ID
  EmergencyRequest? getEmergencyRequestById(String requestId) {
    try {
      return _emergencyRequests.firstWhere((r) => r.id == requestId);
    } catch (e) {
      return null;
    }
  }

  /// Get drone by ID
  Drone? getDroneById(String droneId) {
    try {
      return _availableDrones.firstWhere((d) => d.id == droneId);
    } catch (e) {
      return null;
    }
  }
}
