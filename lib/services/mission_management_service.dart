import 'dart:async';
import '../models/mission.dart';
import '../models/drone.dart';
import '../models/payload.dart';
import '../models/group_event.dart';
import '../models/user.dart';

class MissionManagementService {
  static final MissionManagementService _instance =
      MissionManagementService._internal();
  factory MissionManagementService() => _instance;
  MissionManagementService._internal();

  final List<Mission> _missions = [];
  final List<Payload> _payloads = [];
  final StreamController<List<Mission>> _missionsController =
      StreamController<List<Mission>>.broadcast();

  Stream<List<Mission>> get missionsStream => _missionsController.stream;
  List<Mission> get missions => List.unmodifiable(_missions);

  /// Generate automated mission name based on priority, event, and drone
  String generateMissionName({
    required MissionPriority priority,
    required EventType eventType,
    required String droneId,
    int? sequenceNumber,
  }) {
    final priorityCode = priority.name.toUpperCase();
    final eventCode = _getEventCode(eventType);
    final droneCode = droneId.toUpperCase().replaceAll(' ', '_');

    String baseName = '${priorityCode}_${eventCode}_$droneCode';

    if (sequenceNumber != null && sequenceNumber > 0) {
      baseName = '${baseName}_${sequenceNumber.toString().padLeft(2, '0')}';
    }

    return baseName;
  }

  /// Get event code for mission naming
  String _getEventCode(EventType eventType) {
    switch (eventType) {
      case EventType.flood:
        return 'FLOOD';
      case EventType.fireIncident:
        return 'FIRE';
      case EventType.earthquake:
        return 'EARTHQUAKE';
      case EventType.hurricane:
        return 'HURRICANE';
      case EventType.tornado:
        return 'TORNADO';
      case EventType.landslide:
        return 'LANDSLIDE';
      case EventType.tsunami:
        return 'TSUNAMI';
      case EventType.volcanicEruption:
        return 'VOLCANIC';
      case EventType.pandemicOutbreak:
        return 'PANDEMIC';
      case EventType.cyberAttack:
        return 'CYBER';
      case EventType.terroristAttack:
        return 'TERROR';
      case EventType.chemicalSpill:
        return 'CHEMICAL';
      case EventType.industrialAccident:
        return 'NUCLEAR';
      case EventType.industrialAccident:
        return 'INDUSTRIAL';
      case EventType.massCasualty:
        return 'CASUALTY';
      case EventType.powerGridFailure:
        return 'INFRA';
      case EventType.buildingCollapse:
        return 'COLLAPSE';
      case EventType.transportationAccident:
        return 'TRANSPORT';
      case EventType.civilUnrest:
        return 'UNREST';
      case EventType.naturalDisaster:
        return 'NATURAL';
      case EventType.other:
        return 'OTHER';
    }
  }

  /// Create a single mission
  Future<Mission> createMission({
    required String groupId,
    required EventType eventType,
    required MissionPriority priority,
    required String description,
    required LocationData targetLocation,
    required String assignedDroneId,
    required String assignedOperatorId,
    required Payload payload,
    DateTime? scheduledStartTime,
    String? specialInstructions,
    LocationData? startLocation,
  }) async {
    final missionName = generateMissionName(
      priority: priority,
      eventType: eventType,
      droneId: assignedDroneId,
    );

    final mission = Mission(
      title: missionName,
      description: description,
      type: _getMissionTypeFromPayload(payload.type),
      priority: priority,
      assignedDroneId: assignedDroneId,
      assignedOperatorId: assignedOperatorId,
      startLocation: startLocation ?? LocationData(latitude: 0, longitude: 0),
      targetLocation: targetLocation,
      scheduledStartTime: scheduledStartTime,
      eventId: groupId,
      payload: payload.description,
      specialInstructions: specialInstructions,
    );

    // Store payload
    _payloads.add(payload);

    // Store mission
    _missions.add(mission);

    // Notify listeners
    _missionsController.add(_missions);

    return mission;
  }

  /// Create bulk missions
  Future<List<Mission>> createBulkMissions({
    required String groupId,
    required EventType eventType,
    required MissionPriority priority,
    required String baseDescription,
    required LocationData targetLocation,
    required List<String> droneIds,
    required String assignedOperatorId,
    required Payload basePayload,
    DateTime? scheduledStartTime,
    String? specialInstructions,
    LocationData? startLocation,
    Duration? missionInterval,
  }) async {
    final createdMissions = <Mission>[];
    final interval = missionInterval ?? const Duration(minutes: 15);

    for (int i = 0; i < droneIds.length; i++) {
      final droneId = droneIds[i];
      final sequenceNumber = i + 1;

      // Create individual payload for each mission
      final missionPayload = basePayload.copyWith(
        description: '${basePayload.description} - Mission ${sequenceNumber}',
      );

      final missionName = generateMissionName(
        priority: priority,
        eventType: eventType,
        droneId: droneId,
        sequenceNumber: sequenceNumber,
      );

      final scheduledTime = scheduledStartTime?.add(
        Duration(minutes: i * interval.inMinutes),
      );

      final mission = Mission(
        title: missionName,
        description: '${baseDescription} - Mission ${sequenceNumber}',
        type: _getMissionTypeFromPayload(basePayload.type),
        priority: priority,
        assignedDroneId: droneId,
        assignedOperatorId: assignedOperatorId,
        startLocation: startLocation ?? LocationData(latitude: 0, longitude: 0),
        targetLocation: targetLocation,
        scheduledStartTime: scheduledTime,
        eventId: groupId,
        payload: missionPayload.description,
        specialInstructions: specialInstructions,
      );

      // Store payload and mission
      _payloads.add(missionPayload);
      _missions.add(mission);
      createdMissions.add(mission);
    }

    // Notify listeners
    _missionsController.add(_missions);

    return createdMissions;
  }

  /// Get available drones for mission assignment
  List<Drone> getAvailableDrones(
    List<Drone> allDrones, {
    double? minBatteryLevel,
    double? minPayloadCapacity,
    List<String>? requiredCapabilities,
  }) {
    return allDrones.where((drone) {
      // Check basic availability
      if (!drone.isAvailable) return false;

      // Check battery level
      if (minBatteryLevel != null && drone.batteryLevel < minBatteryLevel) {
        return false;
      }

      // Check payload capacity
      if (minPayloadCapacity != null &&
          drone.payloadCapacity < minPayloadCapacity) {
        return false;
      }

      // Check required capabilities
      if (requiredCapabilities != null) {
        for (final capability in requiredCapabilities) {
          if (!drone.hasCapability(capability)) return false;
        }
      }

      // Check maintenance status
      if (drone.needsMaintenance || drone.isMaintenanceDue) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Select best drone for a mission
  Drone? selectOptimalDrone(
    List<Drone> availableDrones,
    Payload payload,
    LocationData targetLocation, {
    MissionPriority priority = MissionPriority.medium,
  }) {
    if (availableDrones.isEmpty) return null;

    // Filter drones that can handle the payload
    final compatibleDrones = availableDrones.where((drone) {
      return drone.payloadCapacity >= payload.weight;
    }).toList();

    if (compatibleDrones.isEmpty) return null;

    // Score drones based on various factors
    compatibleDrones.sort((a, b) {
      final scoreA = _calculateDroneScore(a, payload, targetLocation, priority);
      final scoreB = _calculateDroneScore(b, payload, targetLocation, priority);
      return scoreB.compareTo(scoreA); // Higher score is better
    });

    return compatibleDrones.first;
  }

  /// Calculate drone suitability score
  double _calculateDroneScore(
    Drone drone,
    Payload payload,
    LocationData targetLocation,
    MissionPriority priority,
  ) {
    double score = 0;

    // Battery level (30% weight)
    score += (drone.batteryLevel / 100) * 30;

    // Payload capacity utilization (20% weight)
    final payloadUtilization = payload.weight / drone.payloadCapacity;
    score +=
        (1 - payloadUtilization) *
        20; // Less utilization is better for flexibility

    // Flight time (20% weight)
    score += (drone.maxFlightTime / 120) * 20; // Normalize to 2 hours

    // Range capacity (15% weight)
    score += (drone.maxRange / 50) * 15; // Normalize to 50km

    // Maintenance status (10% weight)
    if (!drone.needsMaintenance) {
      score += 10;
    } else {
      score += 5;
    }

    // Operating hours (lower is better) (5% weight)
    final hoursScore = Math.max(0, (1000 - drone.operatingHours) / 1000);
    score += hoursScore * 5;

    return score;
  }

  /// Assign drone to mission
  Future<bool> assignDroneToMission(String missionId, String droneId) async {
    final missionIndex = _missions.indexWhere((m) => m.id == missionId);
    if (missionIndex == -1) return false;

    final mission = _missions[missionIndex];
    final updatedMission = mission.copyWith(
      assignedDroneId: droneId,
      status: MissionStatus.assigned,
    );

    _missions[missionIndex] = updatedMission;
    _missionsController.add(_missions);

    return true;
  }

  /// Update mission status
  Future<bool> updateMissionStatus(
    String missionId,
    MissionStatus newStatus,
  ) async {
    final missionIndex = _missions.indexWhere((m) => m.id == missionId);
    if (missionIndex == -1) return false;

    final mission = _missions[missionIndex];
    var updatedMission = mission.copyWith(status: newStatus);

    if (newStatus == MissionStatus.inProgress &&
        mission.actualStartTime == null) {
      updatedMission = updatedMission.copyWith(actualStartTime: DateTime.now());
    } else if ((newStatus == MissionStatus.completed ||
            newStatus == MissionStatus.failed ||
            newStatus == MissionStatus.cancelled) &&
        mission.actualEndTime == null) {
      updatedMission = updatedMission.copyWith(actualEndTime: DateTime.now());
    }

    _missions[missionIndex] = updatedMission;
    _missionsController.add(_missions);

    return true;
  }

  /// Get mission by ID
  Mission? getMissionById(String missionId) {
    try {
      return _missions.firstWhere((m) => m.id == missionId);
    } catch (e) {
      return null;
    }
  }

  /// Get payload by ID
  Payload? getPayloadById(String payloadId) {
    try {
      return _payloads.firstWhere((p) => p.id == payloadId);
    } catch (e) {
      return null;
    }
  }

  /// Get missions by drone ID
  List<Mission> getMissionsByDroneId(String droneId) {
    return _missions.where((m) => m.assignedDroneId == droneId).toList();
  }

  /// Get missions by status
  List<Mission> getMissionsByStatus(MissionStatus status) {
    return _missions.where((m) => m.status == status).toList();
  }

  /// Get missions by priority
  List<Mission> getMissionsByPriority(MissionPriority priority) {
    return _missions.where((m) => m.priority == priority).toList();
  }

  /// Get active missions
  List<Mission> getActiveMissions() {
    return _missions.where((m) => m.isActive).toList();
  }

  /// Get completed missions
  List<Mission> getCompletedMissions() {
    return _missions.where((m) => m.isCompleted).toList();
  }

  /// Validate mission requirements
  ValidationResult validateMissionRequirements({
    required Payload payload,
    required Drone drone,
    required MissionPriority priority,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // Check payload capacity
    if (drone.payloadCapacity < payload.weight) {
      errors.add(
        'Drone payload capacity (${drone.payloadDisplay}) is insufficient for payload weight (${payload.weightDisplay})',
      );
    }

    // Check battery level
    if (drone.batteryLevel < 30) {
      if (priority == MissionPriority.critical) {
        warnings.add(
          'Drone battery level is low (${drone.batteryLevel}%) but mission is critical',
        );
      } else {
        errors.add(
          'Drone battery level too low (${drone.batteryLevel}%) for mission',
        );
      }
    }

    // Check maintenance status
    if (drone.needsMaintenance) {
      if (priority == MissionPriority.critical) {
        warnings.add('Drone needs maintenance but mission is critical');
      } else {
        errors.add('Drone requires maintenance before mission assignment');
      }
    }

    // Check special payload requirements
    if (payload.requiresTemperatureControl &&
        !drone.hasCapability('temperatureControl')) {
      errors.add(
        'Payload requires temperature control but drone lacks this capability',
      );
    }

    if (payload.isFragile && !drone.hasCapability('stabilization')) {
      warnings.add('Fragile payload but drone may lack advanced stabilization');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Convert payload type to mission type
  MissionType _getMissionTypeFromPayload(PayloadType payloadType) {
    switch (payloadType) {
      case PayloadType.medical:
      case PayloadType.medication:
      case PayloadType.firstAid:
        return MissionType.medical;
      case PayloadType.food:
      case PayloadType.water:
        return MissionType.delivery;
      case PayloadType.lifeSavingEquipment:
      case PayloadType.rescue:
        return MissionType.rescue;
      case PayloadType.communicationDevice:
        return MissionType.surveillance;
      case PayloadType.emergency:
        return MissionType.emergencyResponse;
      case PayloadType.other:
        return MissionType.other;
    }
  }

  /// Generate mission route
  List<LocationData> generateMissionRoute({
    required LocationData startLocation,
    required LocationData targetLocation,
    List<LocationData>? waypoints,
  }) {
    final route = <LocationData>[startLocation];

    if (waypoints != null && waypoints.isNotEmpty) {
      route.addAll(waypoints);
    }

    route.add(targetLocation);
    return route;
  }

  /// Estimate mission duration
  Duration estimateMissionDuration({
    required double distance,
    required double droneSpeed,
    required PayloadType payloadType,
    int? additionalWaypoints,
  }) {
    // Base flight time calculation
    double flightTimeMinutes = (distance / droneSpeed) * 60;

    // Add time for takeoff and landing
    flightTimeMinutes += 10;

    // Add time for waypoints
    if (additionalWaypoints != null) {
      flightTimeMinutes += additionalWaypoints * 5; // 5 minutes per waypoint
    }

    // Add payload-specific time
    switch (payloadType) {
      case PayloadType.medical:
      case PayloadType.medication:
        flightTimeMinutes += 15; // Extra time for precision delivery
        break;
      case PayloadType.rescue:
        flightTimeMinutes += 20; // Extra time for rescue operations
        break;
      case PayloadType.lifeSavingEquipment:
        flightTimeMinutes += 10; // Extra time for careful deployment
        break;
      default:
        flightTimeMinutes += 5; // Standard deployment time
    }

    return Duration(minutes: flightTimeMinutes.round());
  }

  /// Clear all missions and payloads
  void clearAll() {
    _missions.clear();
    _payloads.clear();
    _missionsController.add(_missions);
  }

  /// Dispose resources
  void dispose() {
    _missionsController.close();
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
}

// Math utility for dart:math alternative
class Math {
  static double max(double a, double b) => a > b ? a : b;
  static double min(double a, double b) => a < b ? a : b;
}
