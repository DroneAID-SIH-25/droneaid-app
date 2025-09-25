import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'mission.dart';
import 'user.dart';

/// GPS reading data for real-time tracking
class GPSReading {
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed;
  final double heading;
  final DateTime timestamp;
  final double accuracy;

  const GPSReading({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
    required this.heading,
    required this.timestamp,
    this.accuracy = 5.0,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
    'speed': speed,
    'heading': heading,
    'timestamp': timestamp.toIso8601String(),
    'accuracy': accuracy,
  };

  factory GPSReading.fromJson(Map<String, dynamic> json) => GPSReading(
    latitude: json['latitude']?.toDouble() ?? 0.0,
    longitude: json['longitude']?.toDouble() ?? 0.0,
    altitude: json['altitude']?.toDouble() ?? 0.0,
    speed: json['speed']?.toDouble() ?? 0.0,
    heading: json['heading']?.toDouble() ?? 0.0,
    timestamp: DateTime.parse(json['timestamp']),
    accuracy: json['accuracy']?.toDouble() ?? 5.0,
  );

  GPSReading copyWith({
    double? latitude,
    double? longitude,
    double? altitude,
    double? speed,
    double? heading,
    DateTime? timestamp,
    double? accuracy,
  }) => GPSReading(
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    altitude: altitude ?? this.altitude,
    speed: speed ?? this.speed,
    heading: heading ?? this.heading,
    timestamp: timestamp ?? this.timestamp,
    accuracy: accuracy ?? this.accuracy,
  );

  @override
  String toString() =>
      'GPSReading(lat: $latitude, lng: $longitude, alt: ${altitude}m, speed: ${speed}m/s)';
}

/// Air quality levels for sensor readings
enum AirQualityLevel {
  good,
  moderate,
  unhealthyForSensitive,
  unhealthy,
  veryUnhealthy,
  hazardous;

  String get displayName {
    switch (this) {
      case AirQualityLevel.good:
        return 'Good';
      case AirQualityLevel.moderate:
        return 'Moderate';
      case AirQualityLevel.unhealthyForSensitive:
        return 'Unhealthy for Sensitive';
      case AirQualityLevel.unhealthy:
        return 'Unhealthy';
      case AirQualityLevel.veryUnhealthy:
        return 'Very Unhealthy';
      case AirQualityLevel.hazardous:
        return 'Hazardous';
    }
  }

  Color get color {
    switch (this) {
      case AirQualityLevel.good:
        return const Color(0xFF4CAF50);
      case AirQualityLevel.moderate:
        return const Color(0xFFFFEB3B);
      case AirQualityLevel.unhealthyForSensitive:
        return const Color(0xFFFF9800);
      case AirQualityLevel.unhealthy:
        return const Color(0xFFF44336);
      case AirQualityLevel.veryUnhealthy:
        return const Color(0xFF9C27B0);
      case AirQualityLevel.hazardous:
        return const Color(0xFF795548);
    }
  }

  static AirQualityLevel fromPM25(double pm25) {
    if (pm25 <= 12) return AirQualityLevel.good;
    if (pm25 <= 35) return AirQualityLevel.moderate;
    if (pm25 <= 55) return AirQualityLevel.unhealthyForSensitive;
    if (pm25 <= 150) return AirQualityLevel.unhealthy;
    if (pm25 <= 250) return AirQualityLevel.veryUnhealthy;
    return AirQualityLevel.hazardous;
  }
}

/// Air quality sensor readings
class AirQualityReading {
  final double pm25;
  final double co;
  final double no2;
  final double o3;
  final double so2;
  final DateTime timestamp;

  const AirQualityReading({
    required this.pm25,
    required this.co,
    required this.no2,
    required this.o3,
    required this.so2,
    required this.timestamp,
  });

  AirQualityLevel get level => AirQualityLevel.fromPM25(pm25);

  Map<String, dynamic> toJson() => {
    'pm25': pm25,
    'co': co,
    'no2': no2,
    'o3': o3,
    'so2': so2,
    'timestamp': timestamp.toIso8601String(),
  };

  factory AirQualityReading.fromJson(Map<String, dynamic> json) =>
      AirQualityReading(
        pm25: json['pm25']?.toDouble() ?? 0.0,
        co: json['co']?.toDouble() ?? 0.0,
        no2: json['no2']?.toDouble() ?? 0.0,
        o3: json['o3']?.toDouble() ?? 0.0,
        so2: json['so2']?.toDouble() ?? 0.0,
        timestamp: DateTime.parse(json['timestamp']),
      );

  AirQualityReading copyWith({
    double? pm25,
    double? co,
    double? no2,
    double? o3,
    double? so2,
    DateTime? timestamp,
  }) => AirQualityReading(
    pm25: pm25 ?? this.pm25,
    co: co ?? this.co,
    no2: no2 ?? this.no2,
    o3: o3 ?? this.o3,
    so2: so2 ?? this.so2,
    timestamp: timestamp ?? this.timestamp,
  );

  @override
  String toString() => 'AirQuality(PM2.5: $pm25, CO: $co, NO2: $no2)';
}

/// Comprehensive sensor data from drone
class SensorData {
  final double temperature;
  final double humidity;
  final double pressure;
  final AirQualityReading airQuality;
  final DateTime timestamp;

  const SensorData({
    required this.temperature,
    required this.humidity,
    required this.pressure,
    required this.airQuality,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'humidity': humidity,
    'pressure': pressure,
    'airQuality': airQuality.toJson(),
    'timestamp': timestamp.toIso8601String(),
  };

  factory SensorData.fromJson(Map<String, dynamic> json) => SensorData(
    temperature: json['temperature']?.toDouble() ?? 0.0,
    humidity: json['humidity']?.toDouble() ?? 0.0,
    pressure: json['pressure']?.toDouble() ?? 0.0,
    airQuality: AirQualityReading.fromJson(json['airQuality']),
    timestamp: DateTime.parse(json['timestamp']),
  );

  SensorData copyWith({
    double? temperature,
    double? humidity,
    double? pressure,
    AirQualityReading? airQuality,
    DateTime? timestamp,
  }) => SensorData(
    temperature: temperature ?? this.temperature,
    humidity: humidity ?? this.humidity,
    pressure: pressure ?? this.pressure,
    airQuality: airQuality ?? this.airQuality,
    timestamp: timestamp ?? this.timestamp,
  );

  @override
  String toString() =>
      'SensorData(temp: ${temperature}°C, humidity: $humidity%, pressure: ${pressure}hPa)';
}

/// Mission progress tracking
class MissionProgress {
  final double completionPercentage;
  final String currentPhase;
  final List<String> completedWaypoints;
  final String? nextWaypoint;
  final DateTime lastUpdate;

  const MissionProgress({
    required this.completionPercentage,
    required this.currentPhase,
    required this.completedWaypoints,
    this.nextWaypoint,
    required this.lastUpdate,
  });

  Map<String, dynamic> toJson() => {
    'completionPercentage': completionPercentage,
    'currentPhase': currentPhase,
    'completedWaypoints': completedWaypoints,
    'nextWaypoint': nextWaypoint,
    'lastUpdate': lastUpdate.toIso8601String(),
  };

  factory MissionProgress.fromJson(Map<String, dynamic> json) =>
      MissionProgress(
        completionPercentage: json['completionPercentage']?.toDouble() ?? 0.0,
        currentPhase: json['currentPhase'] ?? 'Unknown',
        completedWaypoints: List<String>.from(json['completedWaypoints'] ?? []),
        nextWaypoint: json['nextWaypoint'],
        lastUpdate: DateTime.parse(json['lastUpdate']),
      );

  MissionProgress copyWith({
    double? completionPercentage,
    String? currentPhase,
    List<String>? completedWaypoints,
    String? nextWaypoint,
    DateTime? lastUpdate,
  }) => MissionProgress(
    completionPercentage: completionPercentage ?? this.completionPercentage,
    currentPhase: currentPhase ?? this.currentPhase,
    completedWaypoints: completedWaypoints ?? this.completedWaypoints,
    nextWaypoint: nextWaypoint ?? this.nextWaypoint,
    lastUpdate: lastUpdate ?? this.lastUpdate,
  );
}

/// Enhanced mission class for ongoing missions with real-time data
class OngoingMission extends Mission {
  final GPSReading currentGPS;
  final SensorData sensorReadings;
  final String eta;
  final MissionProgress missionProgress;
  final bool isRealTimeEnabled;

  OngoingMission({
    required super.id,
    super.emergencyRequestId,
    required super.assignedDroneId,
    required super.assignedOperatorId,
    required super.title,
    required super.description,
    required super.type,
    super.status = MissionStatus.inProgress,
    super.priority = MissionPriority.medium,
    super.createdAt,
    super.actualStartTime,
    super.actualEndTime,
    super.scheduledStartTime,
    super.estimatedDuration,
    required super.startLocation,
    required super.targetLocation,
    super.waypoints,
    super.completionNotes,
    super.updates,
    super.eventId,
    super.progress = 0.0,
    super.payload = '',
    super.weatherConditions = '',
    super.fuelLevel = 100.0,
    super.batteryLevel = 100.0,
    super.altitude = 0.0,
    super.speed = 0.0,
    super.distance = 0.0,
    super.maxAltitude,
    super.maxSpeed,
    super.specialInstructions,
    super.equipment,
    super.isRecurring = false,
    required this.currentGPS,
    required this.sensorReadings,
    required this.eta,
    required this.missionProgress,
    this.isRealTimeEnabled = true,
  });

  /// Calculate distance to target in kilometers
  double get distanceToTarget {
    return _calculateDistance(
      currentGPS.latitude,
      currentGPS.longitude,
      targetLocation.latitude,
      targetLocation.longitude,
    );
  }

  /// Calculate estimated time of arrival
  String get calculatedETA {
    if (currentGPS.speed <= 0) return eta;

    final distance = distanceToTarget;
    final timeInHours =
        distance / (currentGPS.speed * 3.6); // Convert m/s to km/h
    final etaTime = DateTime.now().add(Duration(hours: timeInHours.round()));

    return _formatETA(etaTime);
  }

  /// Check if any sensor readings are critical
  bool get hasCriticalReadings {
    return sensorReadings.temperature > 45 ||
        sensorReadings.temperature < -10 ||
        sensorReadings.humidity > 90 ||
        sensorReadings.airQuality.level.index >= 3; // Unhealthy or worse
  }

  /// Get list of critical sensor alerts
  List<String> get criticalAlerts {
    final alerts = <String>[];

    if (sensorReadings.temperature > 45) {
      alerts.add(
        'High temperature: ${sensorReadings.temperature.toStringAsFixed(1)}°C',
      );
    } else if (sensorReadings.temperature < -10) {
      alerts.add(
        'Low temperature: ${sensorReadings.temperature.toStringAsFixed(1)}°C',
      );
    }

    if (sensorReadings.humidity > 90) {
      alerts.add(
        'High humidity: ${sensorReadings.humidity.toStringAsFixed(1)}%',
      );
    }

    if (sensorReadings.airQuality.level.index >= 3) {
      alerts.add(
        'Poor air quality: ${sensorReadings.airQuality.level.displayName}',
      );
    }

    if (batteryLevel < 20) {
      alerts.add('Low battery: ${batteryLevel.toStringAsFixed(1)}%');
    }

    return alerts;
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'currentGPS': currentGPS.toJson(),
      'sensorReadings': sensorReadings.toJson(),
      'eta': eta,
      'missionProgress': missionProgress.toJson(),
      'isRealTimeEnabled': isRealTimeEnabled,
    });
    return json;
  }

  factory OngoingMission.fromMission(
    Mission mission, {
    required GPSReading currentGPS,
    required SensorData sensorReadings,
    required String eta,
    required MissionProgress missionProgress,
    bool isRealTimeEnabled = true,
  }) => OngoingMission(
    id: mission.id,
    emergencyRequestId: mission.emergencyRequestId,
    assignedDroneId: mission.assignedDroneId,
    assignedOperatorId: mission.assignedOperatorId,
    title: mission.title,
    description: mission.description,
    type: mission.type,
    status: mission.status,
    priority: mission.priority,
    createdAt: mission.createdAt,
    actualStartTime: mission.actualStartTime,
    actualEndTime: mission.actualEndTime,
    scheduledStartTime: mission.scheduledStartTime,
    estimatedDuration: mission.estimatedDuration,
    startLocation: mission.startLocation,
    targetLocation: mission.targetLocation,
    waypoints: mission.waypoints,
    completionNotes: mission.completionNotes,
    updates: mission.updates,
    eventId: mission.eventId,
    progress: mission.progress,
    payload: mission.payload,
    weatherConditions: mission.weatherConditions,
    fuelLevel: mission.fuelLevel,
    batteryLevel: mission.batteryLevel,
    altitude: mission.altitude,
    speed: mission.speed,
    distance: mission.distance,
    maxAltitude: mission.maxAltitude,
    maxSpeed: mission.maxSpeed,
    specialInstructions: mission.specialInstructions,
    equipment: mission.equipment,
    isRecurring: mission.isRecurring,
    currentGPS: currentGPS,
    sensorReadings: sensorReadings,
    eta: eta,
    missionProgress: missionProgress,
    isRealTimeEnabled: isRealTimeEnabled,
  );

  @override
  OngoingMission copyWith({
    String? id,
    String? emergencyRequestId,
    String? assignedDroneId,
    String? assignedOperatorId,
    String? title,
    String? description,
    MissionType? type,
    MissionStatus? status,
    MissionPriority? priority,
    DateTime? createdAt,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    DateTime? scheduledStartTime,
    Duration? estimatedDuration,
    LocationData? startLocation,
    LocationData? targetLocation,
    List<LocationData>? waypoints,
    String? completionNotes,
    List<MissionUpdate>? updates,
    String? eventId,
    double? progress,
    String? payload,
    String? weatherConditions,
    double? fuelLevel,
    double? batteryLevel,
    double? altitude,
    double? speed,
    double? distance,
    double? maxAltitude,
    double? maxSpeed,
    String? specialInstructions,
    List<String>? equipment,
    bool? isRecurring,
    GPSReading? currentGPS,
    SensorData? sensorReadings,
    String? eta,
    MissionProgress? missionProgress,
    bool? isRealTimeEnabled,
  }) => OngoingMission(
    id: id ?? this.id,
    emergencyRequestId: emergencyRequestId ?? this.emergencyRequestId,
    assignedDroneId: assignedDroneId ?? this.assignedDroneId,
    assignedOperatorId: assignedOperatorId ?? this.assignedOperatorId,
    title: title ?? this.title,
    description: description ?? this.description,
    type: type ?? this.type,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    createdAt: createdAt ?? this.createdAt,
    actualStartTime: actualStartTime ?? this.actualStartTime,
    actualEndTime: actualEndTime ?? this.actualEndTime,
    scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
    estimatedDuration: estimatedDuration ?? this.estimatedDuration,
    startLocation: startLocation ?? this.startLocation,
    targetLocation: targetLocation ?? this.targetLocation,
    waypoints: waypoints ?? this.waypoints,
    completionNotes: completionNotes ?? this.completionNotes,
    updates: updates ?? this.updates,
    eventId: eventId ?? this.eventId,
    progress: progress ?? this.progress,
    payload: payload ?? this.payload,
    weatherConditions: weatherConditions ?? this.weatherConditions,
    fuelLevel: fuelLevel ?? this.fuelLevel,
    batteryLevel: batteryLevel ?? this.batteryLevel,
    altitude: altitude ?? this.altitude,
    speed: speed ?? this.speed,
    distance: distance ?? this.distance,
    maxAltitude: maxAltitude ?? this.maxAltitude,
    maxSpeed: maxSpeed ?? this.maxSpeed,
    specialInstructions: specialInstructions ?? this.specialInstructions,
    equipment: equipment ?? this.equipment,
    isRecurring: isRecurring ?? this.isRecurring,
    currentGPS: currentGPS ?? this.currentGPS,
    sensorReadings: sensorReadings ?? this.sensorReadings,
    eta: eta ?? this.eta,
    missionProgress: missionProgress ?? this.missionProgress,
    isRealTimeEnabled: isRealTimeEnabled ?? this.isRealTimeEnabled,
  );

  // Utility methods
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

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

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

  @override
  String toString() =>
      'OngoingMission(${title}, ETA: $eta, GPS: ${currentGPS.latitude},${currentGPS.longitude})';
}
