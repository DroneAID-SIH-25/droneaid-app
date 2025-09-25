import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'user.dart';

part 'drone.g.dart';

@JsonSerializable()
class Drone {
  final String id;
  final String serialNumber;
  final String model;
  final String manufacturer;
  final DroneType type;
  final DroneStatus status;
  final Location? currentLocation;
  final double batteryLevel;
  final double maxFlightTime; // in minutes
  final double maxSpeed; // in km/h
  final double maxAltitude; // in meters
  final double maxRange; // in kilometers
  final double payloadCapacity; // in kg
  final List<DroneCapability> capabilities;
  final String? assignedOperatorId;
  final String? currentMissionId;
  final DateTime lastMaintenanceDate;
  final DateTime nextMaintenanceDate;
  final int totalFlightHours;
  final int totalMissions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final DroneSpecifications specifications;
  final List<String> sensors;
  final String? imageUrl;

  Drone({
    String? id,
    required this.serialNumber,
    required this.model,
    required this.manufacturer,
    required this.type,
    this.status = DroneStatus.available,
    this.currentLocation,
    this.batteryLevel = 100.0,
    required this.maxFlightTime,
    required this.maxSpeed,
    required this.maxAltitude,
    required this.maxRange,
    required this.payloadCapacity,
    List<DroneCapability>? capabilities,
    this.assignedOperatorId,
    this.currentMissionId,
    DateTime? lastMaintenanceDate,
    DateTime? nextMaintenanceDate,
    this.totalFlightHours = 0,
    this.totalMissions = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
    required this.specifications,
    List<String>? sensors,
    this.imageUrl,
  }) : id = id ?? const Uuid().v4(),
       capabilities = capabilities ?? [],
       lastMaintenanceDate = lastMaintenanceDate ?? DateTime.now(),
       nextMaintenanceDate =
           nextMaintenanceDate ?? DateTime.now().add(const Duration(days: 30)),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       sensors = sensors ?? [];

  String get displayName => '$manufacturer $model';

  bool get isAvailable =>
      status == DroneStatus.available && isActive && batteryLevel > 20.0;

  bool get needsMaintenance => DateTime.now().isAfter(nextMaintenanceDate);

  bool get isOperational =>
      isActive && !needsMaintenance && batteryLevel > 10.0;

  String get statusDisplay => status.displayName;

  double get remainingFlightTime => (batteryLevel / 100) * maxFlightTime;

  bool hasCapability(DroneCapability capability) {
    return capabilities.contains(capability);
  }

  factory Drone.fromJson(Map<String, dynamic> json) => _$DroneFromJson(json);

  Map<String, dynamic> toJson() => _$DroneToJson(this);

  Drone copyWith({
    String? id,
    String? serialNumber,
    String? model,
    String? manufacturer,
    DroneType? type,
    DroneStatus? status,
    Location? currentLocation,
    double? batteryLevel,
    double? maxFlightTime,
    double? maxSpeed,
    double? maxAltitude,
    double? maxRange,
    double? payloadCapacity,
    List<DroneCapability>? capabilities,
    String? assignedOperatorId,
    String? currentMissionId,
    DateTime? lastMaintenanceDate,
    DateTime? nextMaintenanceDate,
    int? totalFlightHours,
    int? totalMissions,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    DroneSpecifications? specifications,
    List<String>? sensors,
    String? imageUrl,
  }) {
    return Drone(
      id: id ?? this.id,
      serialNumber: serialNumber ?? this.serialNumber,
      model: model ?? this.model,
      manufacturer: manufacturer ?? this.manufacturer,
      type: type ?? this.type,
      status: status ?? this.status,
      currentLocation: currentLocation ?? this.currentLocation,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      maxFlightTime: maxFlightTime ?? this.maxFlightTime,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      maxAltitude: maxAltitude ?? this.maxAltitude,
      maxRange: maxRange ?? this.maxRange,
      payloadCapacity: payloadCapacity ?? this.payloadCapacity,
      capabilities: capabilities ?? this.capabilities,
      assignedOperatorId: assignedOperatorId ?? this.assignedOperatorId,
      currentMissionId: currentMissionId ?? this.currentMissionId,
      lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
      nextMaintenanceDate: nextMaintenanceDate ?? this.nextMaintenanceDate,
      totalFlightHours: totalFlightHours ?? this.totalFlightHours,
      totalMissions: totalMissions ?? this.totalMissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      specifications: specifications ?? this.specifications,
      sensors: sensors ?? this.sensors,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Drone &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          serialNumber == other.serialNumber;

  @override
  int get hashCode => id.hashCode ^ serialNumber.hashCode;

  @override
  String toString() {
    return 'Drone{id: $id, serialNumber: $serialNumber, model: $displayName, status: $status}';
  }
}

@JsonSerializable()
class DroneSpecifications {
  final double weight; // in kg
  final double wingspan; // in meters
  final double length; // in meters
  final double height; // in meters
  final String propulsionType;
  final int numberOfRotors;
  final String cameraResolution;
  final bool hasGimbal;
  final bool hasNightVision;
  final bool hasThermalCamera;
  final String communicationRange; // in km
  final String operatingTemperature;
  final String windResistance;
  final String gpsAccuracy;

  DroneSpecifications({
    required this.weight,
    required this.wingspan,
    required this.length,
    required this.height,
    required this.propulsionType,
    required this.numberOfRotors,
    required this.cameraResolution,
    this.hasGimbal = false,
    this.hasNightVision = false,
    this.hasThermalCamera = false,
    required this.communicationRange,
    required this.operatingTemperature,
    required this.windResistance,
    required this.gpsAccuracy,
  });

  factory DroneSpecifications.fromJson(Map<String, dynamic> json) =>
      _$DroneSpecificationsFromJson(json);

  Map<String, dynamic> toJson() => _$DroneSpecificationsToJson(this);
}

enum DroneType {
  @JsonValue('quadcopter')
  quadcopter,
  @JsonValue('hexacopter')
  hexacopter,
  @JsonValue('octocopter')
  octocopter,
  @JsonValue('fixed_wing')
  fixedWing,
  @JsonValue('hybrid')
  hybrid,
}

extension DroneTypeExtension on DroneType {
  String get displayName {
    switch (this) {
      case DroneType.quadcopter:
        return 'Quadcopter';
      case DroneType.hexacopter:
        return 'Hexacopter';
      case DroneType.octocopter:
        return 'Octocopter';
      case DroneType.fixedWing:
        return 'Fixed Wing';
      case DroneType.hybrid:
        return 'Hybrid';
    }
  }

  String get description {
    switch (this) {
      case DroneType.quadcopter:
        return 'Four-rotor multicopter, versatile and maneuverable';
      case DroneType.hexacopter:
        return 'Six-rotor multicopter, more stable with redundancy';
      case DroneType.octocopter:
        return 'Eight-rotor multicopter, high payload capacity';
      case DroneType.fixedWing:
        return 'Airplane-style drone, long range and endurance';
      case DroneType.hybrid:
        return 'Combines vertical takeoff with fixed-wing efficiency';
    }
  }
}

enum DroneStatus {
  @JsonValue('available')
  available,
  @JsonValue('busy')
  busy,
  @JsonValue('maintenance')
  maintenance,
  @JsonValue('offline')
  offline,
  @JsonValue('charging')
  charging,
  @JsonValue('emergency')
  emergency,
}

extension DroneStatusExtension on DroneStatus {
  String get displayName {
    switch (this) {
      case DroneStatus.available:
        return 'Available';
      case DroneStatus.busy:
        return 'Busy';
      case DroneStatus.maintenance:
        return 'Maintenance';
      case DroneStatus.offline:
        return 'Offline';
      case DroneStatus.charging:
        return 'Charging';
      case DroneStatus.emergency:
        return 'Emergency';
    }
  }

  String get description {
    switch (this) {
      case DroneStatus.available:
        return 'Ready for mission assignment';
      case DroneStatus.busy:
        return 'Currently on a mission';
      case DroneStatus.maintenance:
        return 'Under maintenance or repair';
      case DroneStatus.offline:
        return 'Not connected or powered off';
      case DroneStatus.charging:
        return 'Battery charging';
      case DroneStatus.emergency:
        return 'Emergency situation, requires attention';
    }
  }
}

enum DroneCapability {
  @JsonValue('surveillance')
  surveillance,
  @JsonValue('search_rescue')
  searchRescue,
  @JsonValue('medical_delivery')
  medicalDelivery,
  @JsonValue('thermal_imaging')
  thermalImaging,
  @JsonValue('night_vision')
  nightVision,
  @JsonValue('live_streaming')
  liveStreaming,
  @JsonValue('cargo_transport')
  cargoTransport,
  @JsonValue('mapping')
  mapping,
  @JsonValue('environmental_monitoring')
  environmentalMonitoring,
}

extension DroneCapabilityExtension on DroneCapability {
  String get displayName {
    switch (this) {
      case DroneCapability.surveillance:
        return 'Surveillance';
      case DroneCapability.searchRescue:
        return 'Search & Rescue';
      case DroneCapability.medicalDelivery:
        return 'Medical Delivery';
      case DroneCapability.thermalImaging:
        return 'Thermal Imaging';
      case DroneCapability.nightVision:
        return 'Night Vision';
      case DroneCapability.liveStreaming:
        return 'Live Streaming';
      case DroneCapability.cargoTransport:
        return 'Cargo Transport';
      case DroneCapability.mapping:
        return 'Mapping';
      case DroneCapability.environmentalMonitoring:
        return 'Environmental Monitoring';
    }
  }

  String get description {
    switch (this) {
      case DroneCapability.surveillance:
        return 'Area monitoring and reconnaissance';
      case DroneCapability.searchRescue:
        return 'Search and rescue operations';
      case DroneCapability.medicalDelivery:
        return 'Emergency medical supply delivery';
      case DroneCapability.thermalImaging:
        return 'Heat signature detection';
      case DroneCapability.nightVision:
        return 'Low-light and night operations';
      case DroneCapability.liveStreaming:
        return 'Real-time video transmission';
      case DroneCapability.cargoTransport:
        return 'Payload delivery and transport';
      case DroneCapability.mapping:
        return '3D mapping and surveying';
      case DroneCapability.environmentalMonitoring:
        return 'Environmental data collection';
    }
  }
}
