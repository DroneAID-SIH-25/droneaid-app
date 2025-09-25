import 'dart:async';
import 'dart:math' as math;
import '../models/ongoing_mission.dart';
import '../models/mission.dart';
import '../models/user.dart';

/// Service for real-time mission monitoring and data simulation
class RealTimeMissionService {
  static final RealTimeMissionService _instance =
      RealTimeMissionService._internal();
  factory RealTimeMissionService() => _instance;
  RealTimeMissionService._internal();

  final Map<String, StreamController<OngoingMission>> _missionStreams = {};
  final Map<String, Timer> _missionTimers = {};
  final Map<String, OngoingMission> _activeMissions = {};
  final math.Random _random = math.Random();

  /// Start real-time monitoring for a mission
  Stream<OngoingMission> startMissionMonitoring(String missionId) {
    if (_missionStreams.containsKey(missionId)) {
      return _missionStreams[missionId]!.stream;
    }

    final controller = StreamController<OngoingMission>.broadcast();
    _missionStreams[missionId] = controller;

    // Start periodic updates every 5 seconds
    _missionTimers[missionId] = Timer.periodic(
      const Duration(seconds: 5),
      (timer) => _updateMissionData(missionId),
    );

    return controller.stream;
  }

  /// Stop monitoring a specific mission
  void stopMissionMonitoring(String missionId) {
    _missionTimers[missionId]?.cancel();
    _missionTimers.remove(missionId);

    _missionStreams[missionId]?.close();
    _missionStreams.remove(missionId);

    _activeMissions.remove(missionId);
  }

  /// Add a mission to active monitoring
  void addActiveMission(OngoingMission mission) {
    _activeMissions[mission.id] = mission;
  }

  /// Update mission data with simulated real-time values
  void _updateMissionData(String missionId) {
    final mission = _activeMissions[missionId];
    if (mission == null) return;

    try {
      // Simulate GPS movement towards target
      final updatedGPS = _simulateGPSMovement(mission);

      // Simulate sensor readings with realistic variations
      final updatedSensors = _simulateSensorReadings(mission.sensorReadings);

      // Calculate new progress and ETA
      final updatedProgress = _calculateProgress(mission, updatedGPS);
      final eta = _calculateETA(mission, updatedGPS);

      // Create updated mission
      final updatedMission = mission.copyWith(
        currentGPS: updatedGPS,
        sensorReadings: updatedSensors,
        eta: eta,
        missionProgress: updatedProgress,
        progress: updatedProgress.completionPercentage / 100,
        batteryLevel: math.max(
          0,
          mission.batteryLevel - _random.nextDouble() * 0.5,
        ),
        fuelLevel: math.max(
          0.0,
          mission.fuelLevel - _random.nextDouble() * 0.3,
        ),
      );

      _activeMissions[missionId] = updatedMission;
      _missionStreams[missionId]?.add(updatedMission);

      // Complete mission if it reaches destination
      if (updatedProgress.completionPercentage >= 100) {
        _completeMission(missionId);
      }
    } catch (e) {
      print('Error updating mission data for $missionId: $e');
    }
  }

  /// Simulate GPS movement towards target
  GPSReading _simulateGPSMovement(OngoingMission mission) {
    final current = mission.currentGPS;
    final target = mission.targetLocation;

    // Calculate distance to target
    final distance = _calculateDistance(
      current.latitude,
      current.longitude,
      target.latitude,
      target.longitude,
    );

    // If very close to target, don't move much
    if (distance < 0.001) {
      return current.copyWith(
        timestamp: DateTime.now(),
        speed: _random.nextDouble() * 2, // Very slow speed near target
      );
    }

    // Calculate movement step (simulate drone speed)
    final baseSpeed = 15.0; // Base speed in m/s
    final speedVariation = _random.nextDouble() * 5 - 2.5; // ±2.5 m/s variation
    final actualSpeed = math.max(5.0, baseSpeed + speedVariation);

    // Calculate step size in degrees (approximate)
    final stepSize = actualSpeed / 111320; // meters to degrees conversion

    // Move towards target
    final latDiff = target.latitude - current.latitude;
    final lonDiff = target.longitude - current.longitude;
    final totalDiff = math.sqrt(latDiff * latDiff + lonDiff * lonDiff);

    final newLat = current.latitude + (latDiff / totalDiff) * stepSize;
    final newLon = current.longitude + (lonDiff / totalDiff) * stepSize;

    // Add some random variation to simulate realistic movement
    final latVariation = (_random.nextDouble() - 0.5) * 0.0001;
    final lonVariation = (_random.nextDouble() - 0.5) * 0.0001;

    return GPSReading(
      latitude: newLat + latVariation,
      longitude: newLon + lonVariation,
      altitude:
          mission.altitude + (_random.nextDouble() - 0.5) * 10, // ±5m variation
      speed: actualSpeed,
      heading: _calculateHeading(
        current.latitude,
        current.longitude,
        newLat,
        newLon,
      ),
      timestamp: DateTime.now(),
      accuracy: 3.0 + _random.nextDouble() * 2, // 3-5m accuracy
    );
  }

  /// Simulate realistic sensor readings
  SensorData _simulateSensorReadings(SensorData current) {
    // Temperature variations
    final tempVariation = (_random.nextDouble() - 0.5) * 2; // ±1°C
    final newTemp = current.temperature + tempVariation;

    // Humidity variations
    final humidityVariation = (_random.nextDouble() - 0.5) * 5; // ±2.5%
    final newHumidity = math.max(
      0.0,
      math.min(100.0, current.humidity + humidityVariation),
    );

    // Pressure variations
    final pressureVariation = (_random.nextDouble() - 0.5) * 5; // ±2.5 hPa
    final newPressure = current.pressure + pressureVariation;

    // Air quality variations
    final airQuality = AirQualityReading(
      pm25: math.max(
        0.0,
        current.airQuality.pm25 + (_random.nextDouble() - 0.5) * 5,
      ),
      co: math.max(
        0.0,
        current.airQuality.co + (_random.nextDouble() - 0.5) * 2,
      ),
      no2: math.max(
        0.0,
        current.airQuality.no2 + (_random.nextDouble() - 0.5) * 3,
      ),
      o3: math.max(
        0.0,
        current.airQuality.o3 + (_random.nextDouble() - 0.5) * 10,
      ),
      so2: math.max(
        0.0,
        current.airQuality.so2 + (_random.nextDouble() - 0.5) * 1,
      ),
      timestamp: DateTime.now(),
    );

    return SensorData(
      temperature: newTemp,
      humidity: newHumidity,
      pressure: newPressure,
      airQuality: airQuality,
      timestamp: DateTime.now(),
    );
  }

  /// Calculate mission progress based on current position
  MissionProgress _calculateProgress(
    OngoingMission mission,
    GPSReading currentGPS,
  ) {
    final startLocation = mission.startLocation;
    final targetLocation = mission.targetLocation;

    // Calculate total distance
    final totalDistance = _calculateDistance(
      startLocation.latitude,
      startLocation.longitude,
      targetLocation.latitude,
      targetLocation.longitude,
    );

    // Calculate distance traveled
    final traveledDistance = _calculateDistance(
      startLocation.latitude,
      startLocation.longitude,
      currentGPS.latitude,
      currentGPS.longitude,
    );

    // Calculate completion percentage
    final completionPercentage = math.min(
      100.0,
      (traveledDistance / totalDistance) * 100,
    );

    // Determine current phase
    String currentPhase;
    if (completionPercentage < 20) {
      currentPhase = 'Departing';
    } else if (completionPercentage < 80) {
      currentPhase = 'In Transit';
    } else if (completionPercentage < 95) {
      currentPhase = 'Approaching Target';
    } else {
      currentPhase = 'Arriving';
    }

    final completedWaypoints = <String>[];
    if (completionPercentage > 25) completedWaypoints.add('Checkpoint 1');
    if (completionPercentage > 50) completedWaypoints.add('Checkpoint 2');
    if (completionPercentage > 75) completedWaypoints.add('Checkpoint 3');

    return MissionProgress(
      completionPercentage: completionPercentage,
      currentPhase: currentPhase,
      completedWaypoints: completedWaypoints,
      nextWaypoint: completionPercentage < 100 ? 'Target Location' : null,
      lastUpdate: DateTime.now(),
    );
  }

  /// Calculate ETA based on current position and speed
  String _calculateETA(OngoingMission mission, GPSReading currentGPS) {
    final distance = _calculateDistance(
      currentGPS.latitude,
      currentGPS.longitude,
      mission.targetLocation.latitude,
      mission.targetLocation.longitude,
    );

    final speed = math.max(1.0, currentGPS.speed); // Avoid division by zero
    final timeInSeconds = (distance * 1000) / speed; // Convert km to meters
    final eta = DateTime.now().add(Duration(seconds: timeInSeconds.round()));

    return _formatETA(eta);
  }

  /// Complete a mission
  void _completeMission(String missionId) {
    final mission = _activeMissions[missionId];
    if (mission != null) {
      final completedMission = mission.copyWith(
        status: MissionStatus.completed,
        missionProgress: MissionProgress(
          completionPercentage: 100,
          currentPhase: 'Completed',
          completedWaypoints: [
            'Checkpoint 1',
            'Checkpoint 2',
            'Checkpoint 3',
            'Target',
          ],
          nextWaypoint: null,
          lastUpdate: DateTime.now(),
        ),
      );

      _missionStreams[missionId]?.add(completedMission);

      // Stop monitoring after a delay
      Timer(
        const Duration(seconds: 10),
        () => stopMissionMonitoring(missionId),
      );
    }
  }

  /// Calculate distance between two points in kilometers
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Calculate heading between two points
  double _calculateHeading(double lat1, double lon1, double lat2, double lon2) {
    final dLon = _degreesToRadians(lon2 - lon1);
    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);

    final y = math.sin(dLon) * math.cos(lat2Rad);
    final x =
        math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);

    final heading = math.atan2(y, x);
    return (heading * 180 / math.pi + 360) % 360;
  }

  /// Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Format ETA time
  String _formatETA(DateTime etaTime) {
    final now = DateTime.now();
    final difference = etaTime.difference(now);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      return '${hours}h ${minutes}m';
    }
  }

  /// Get all active missions
  List<OngoingMission> get activeMissions => _activeMissions.values.toList();

  /// Check if mission is being monitored
  bool isMissionMonitored(String missionId) =>
      _missionStreams.containsKey(missionId);

  /// Dispose all resources
  void dispose() {
    for (final timer in _missionTimers.values) {
      timer.cancel();
    }
    _missionTimers.clear();

    for (final controller in _missionStreams.values) {
      controller.close();
    }
    _missionStreams.clear();

    _activeMissions.clear();
  }

  /// Create mock ongoing missions for testing
  List<OngoingMission> createMockOngoingMissions() {
    final now = DateTime.now();

    return [
      OngoingMission(
        id: 'mission-001',
        assignedDroneId: 'DRN-MED-001',
        assignedOperatorId: 'OP-001',
        title: 'Medical Supply Delivery',
        description: 'Urgent medical supplies to flood-affected area',
        type: MissionType.medical,
        status: MissionStatus.inProgress,
        priority: MissionPriority.critical,
        startLocation: LocationData(
          latitude: 19.0760,
          longitude: 72.8777,
          address: 'Mumbai Central, Maharashtra',
        ),
        targetLocation: LocationData(
          latitude: 19.1136,
          longitude: 72.8697,
          address: 'Dharavi, Mumbai, Maharashtra',
        ),
        currentGPS: GPSReading(
          latitude: 19.0890,
          longitude: 72.8737,
          altitude: 120,
          speed: 15.5,
          heading: 45,
          timestamp: now,
        ),
        sensorReadings: SensorData(
          temperature: 28.5,
          humidity: 65.0,
          pressure: 1013.2,
          airQuality: AirQualityReading(
            pm25: 45,
            co: 12,
            no2: 8,
            o3: 85,
            so2: 3,
            timestamp: now,
          ),
          timestamp: now,
        ),
        eta: '15m',
        missionProgress: MissionProgress(
          completionPercentage: 60,
          currentPhase: 'In Transit',
          completedWaypoints: ['Checkpoint 1', 'Checkpoint 2'],
          nextWaypoint: 'Target Location',
          lastUpdate: now,
        ),
        payload: 'Medical Supplies',
        actualStartTime: now.subtract(const Duration(minutes: 10)),
        progress: 0.6,
        batteryLevel: 85.0,
        fuelLevel: 75.0,
      ),

      OngoingMission(
        id: 'mission-002',
        assignedDroneId: 'DRN-RESCUE-002',
        assignedOperatorId: 'OP-002',
        title: 'Search and Rescue',
        description: 'Missing person search in forest area',
        type: MissionType.rescue,
        status: MissionStatus.inProgress,
        priority: MissionPriority.high,
        startLocation: LocationData(
          latitude: 18.5204,
          longitude: 73.8567,
          address: 'Pune, Maharashtra',
        ),
        targetLocation: LocationData(
          latitude: 18.4648,
          longitude: 73.8677,
          address: 'Katraj Forest, Pune',
        ),
        currentGPS: GPSReading(
          latitude: 18.4900,
          longitude: 73.8620,
          altitude: 200,
          speed: 12.0,
          heading: 180,
          timestamp: now,
        ),
        sensorReadings: SensorData(
          temperature: 32.0,
          humidity: 72.0,
          pressure: 1010.5,
          airQuality: AirQualityReading(
            pm25: 25,
            co: 8,
            no2: 5,
            o3: 95,
            so2: 2,
            timestamp: now,
          ),
          timestamp: now,
        ),
        eta: '25m',
        missionProgress: MissionProgress(
          completionPercentage: 35,
          currentPhase: 'In Transit',
          completedWaypoints: ['Checkpoint 1'],
          nextWaypoint: 'Search Zone Alpha',
          lastUpdate: now,
        ),
        payload: 'Search Equipment',
        actualStartTime: now.subtract(const Duration(minutes: 20)),
        progress: 0.35,
        batteryLevel: 92.0,
        fuelLevel: 88.0,
      ),

      OngoingMission(
        id: 'mission-003',
        assignedDroneId: 'DRN-SURV-003',
        assignedOperatorId: 'OP-003',
        title: 'Disaster Assessment',
        description: 'Post-earthquake damage assessment',
        type: MissionType.surveillance,
        status: MissionStatus.inProgress,
        priority: MissionPriority.medium,
        startLocation: LocationData(
          latitude: 28.6139,
          longitude: 77.2090,
          address: 'Delhi, India',
        ),
        targetLocation: LocationData(
          latitude: 28.5355,
          longitude: 77.3910,
          address: 'Noida, UP',
        ),
        currentGPS: GPSReading(
          latitude: 28.5800,
          longitude: 77.2500,
          altitude: 150,
          speed: 18.0,
          heading: 90,
          timestamp: now,
        ),
        sensorReadings: SensorData(
          temperature: 24.0,
          humidity: 55.0,
          pressure: 1015.8,
          airQuality: AirQualityReading(
            pm25: 85,
            co: 15,
            no2: 12,
            o3: 70,
            so2: 5,
            timestamp: now,
          ),
          timestamp: now,
        ),
        eta: '40m',
        missionProgress: MissionProgress(
          completionPercentage: 80,
          currentPhase: 'Approaching Target',
          completedWaypoints: ['Checkpoint 1', 'Checkpoint 2', 'Checkpoint 3'],
          nextWaypoint: 'Assessment Zone',
          lastUpdate: now,
        ),
        payload: 'Survey Equipment',
        actualStartTime: now.subtract(const Duration(minutes: 35)),
        progress: 0.8,
        batteryLevel: 65.0,
        fuelLevel: 55.0,
      ),
    ];
  }
}
