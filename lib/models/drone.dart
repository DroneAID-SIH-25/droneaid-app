import 'package:uuid/uuid.dart';
import 'user.dart';

class Drone {
  final String id;
  final String name;
  final String model;
  final DroneStatus status;
  final int batteryLevel;
  final LocationData location;
  final List<String> capabilities;
  final int maxFlightTime;
  final double maxRange;
  final double payloadCapacity;
  final String? currentMissionId;
  final DateTime createdAt;
  final DateTime? lastMaintenance;
  final DateTime? nextMaintenance;
  final double operatingHours;
  final String? serialNumber;

  Drone({
    String? id,
    required this.name,
    required this.model,
    this.status = DroneStatus.active,
    this.batteryLevel = 100,
    required this.location,
    List<String>? capabilities,
    required this.maxFlightTime,
    required this.maxRange,
    required this.payloadCapacity,
    this.currentMissionId,
    DateTime? createdAt,
    this.lastMaintenance,
    this.nextMaintenance,
    this.operatingHours = 0.0,
    this.serialNumber,
  }) : id = id ?? const Uuid().v4(),
       capabilities = capabilities ?? [],
       createdAt = createdAt ?? DateTime.now();

  bool get isAvailable =>
      status == DroneStatus.active && currentMissionId == null;

  bool get isDeployed =>
      status == DroneStatus.deployed && currentMissionId != null;

  bool get needsMaintenance =>
      lastMaintenance == null ||
      DateTime.now().difference(lastMaintenance!).inDays > 30 ||
      operatingHours > 500;

  bool get hasLowBattery => batteryLevel < 20;

  bool get isCriticalBattery => batteryLevel < 10;

  bool get isOperational =>
      status != DroneStatus.offline &&
      status != DroneStatus.maintenance &&
      !isCriticalBattery;

  String get statusDisplay => status.displayName;

  String get batteryDisplay => '$batteryLevel%';

  String get rangeDisplay => '${maxRange.toStringAsFixed(1)} km';

  String get flightTimeDisplay => '${maxFlightTime} min';

  String get payloadDisplay => '${payloadCapacity.toStringAsFixed(1)} kg';

  Duration? get timeSinceLastMaintenance {
    if (lastMaintenance != null) {
      return DateTime.now().difference(lastMaintenance!);
    }
    return null;
  }

  Duration? get timeToNextMaintenance {
    if (nextMaintenance != null) {
      return nextMaintenance!.difference(DateTime.now());
    }
    return null;
  }

  bool get isMaintenanceDue {
    if (nextMaintenance != null) {
      return DateTime.now().isAfter(nextMaintenance!);
    }
    return needsMaintenance;
  }

  String get maintenanceStatus {
    if (isMaintenanceDue) {
      return 'Maintenance Due';
    } else if (timeToNextMaintenance != null) {
      final days = timeToNextMaintenance!.inDays;
      return 'Next: ${days}d';
    }
    return 'Good';
  }

  bool hasCapability(String capability) {
    return capabilities.contains(capability);
  }

  factory Drone.fromJson(Map<String, dynamic> json) {
    return Drone(
      id: json['id'] as String?,
      name: json['name'] as String,
      model: json['model'] as String,
      status: DroneStatus.values.firstWhere((e) => e.name == json['status']),
      batteryLevel: json['batteryLevel'] as int,
      location: LocationData.fromJson(json['location'] as Map<String, dynamic>),
      capabilities: (json['capabilities'] as List).cast<String>(),
      maxFlightTime: json['maxFlightTime'] as int,
      maxRange: (json['maxRange'] as num).toDouble(),
      payloadCapacity: (json['payloadCapacity'] as num).toDouble(),
      currentMissionId: json['currentMissionId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastMaintenance: json['lastMaintenance'] != null
          ? DateTime.parse(json['lastMaintenance'] as String)
          : null,
      nextMaintenance: json['nextMaintenance'] != null
          ? DateTime.parse(json['nextMaintenance'] as String)
          : null,
      operatingHours: (json['operatingHours'] as num?)?.toDouble() ?? 0.0,
      serialNumber: json['serialNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'model': model,
      'status': status.name,
      'batteryLevel': batteryLevel,
      'location': location.toJson(),
      'capabilities': capabilities,
      'maxFlightTime': maxFlightTime,
      'maxRange': maxRange,
      'payloadCapacity': payloadCapacity,
      'currentMissionId': currentMissionId,
      'createdAt': createdAt.toIso8601String(),
      'lastMaintenance': lastMaintenance?.toIso8601String(),
      'nextMaintenance': nextMaintenance?.toIso8601String(),
      'operatingHours': operatingHours,
      'serialNumber': serialNumber,
    };
  }

  Drone copyWith({
    String? id,
    String? name,
    String? model,
    DroneStatus? status,
    int? batteryLevel,
    LocationData? location,
    List<String>? capabilities,
    int? maxFlightTime,
    double? maxRange,
    double? payloadCapacity,
    String? currentMissionId,
    DateTime? createdAt,
    DateTime? lastMaintenance,
    DateTime? nextMaintenance,
    double? operatingHours,
    String? serialNumber,
  }) {
    return Drone(
      id: id ?? this.id,
      name: name ?? this.name,
      model: model ?? this.model,
      status: status ?? this.status,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      location: location ?? this.location,
      capabilities: capabilities ?? this.capabilities,
      maxFlightTime: maxFlightTime ?? this.maxFlightTime,
      maxRange: maxRange ?? this.maxRange,
      payloadCapacity: payloadCapacity ?? this.payloadCapacity,
      currentMissionId: currentMissionId ?? this.currentMissionId,
      createdAt: createdAt ?? this.createdAt,
      lastMaintenance: lastMaintenance ?? this.lastMaintenance,
      nextMaintenance: nextMaintenance ?? this.nextMaintenance,
      operatingHours: operatingHours ?? this.operatingHours,
      serialNumber: serialNumber ?? this.serialNumber,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Drone && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Drone{id: $id, name: $name, model: $model, status: $status}';
  }
}

enum DroneType { quadcopter, hexacopter, octocopter, fixedWing, hybrid }

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
        return 'Four-rotor multicopter drone';
      case DroneType.hexacopter:
        return 'Six-rotor multicopter drone';
      case DroneType.octocopter:
        return 'Eight-rotor multicopter drone';
      case DroneType.fixedWing:
        return 'Fixed-wing aircraft drone';
      case DroneType.hybrid:
        return 'Hybrid VTOL drone';
    }
  }
}

enum DroneStatus { active, deployed, maintenance, offline, charging, emergency }

extension DroneStatusExtension on DroneStatus {
  String get displayName {
    switch (this) {
      case DroneStatus.active:
        return 'Active';
      case DroneStatus.deployed:
        return 'Deployed';
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
      case DroneStatus.active:
        return 'Ready for deployment';
      case DroneStatus.deployed:
        return 'Currently on a mission';
      case DroneStatus.maintenance:
        return 'Undergoing maintenance';
      case DroneStatus.offline:
        return 'Not operational';
      case DroneStatus.charging:
        return 'Battery charging';
      case DroneStatus.emergency:
        return 'Emergency landing or issue';
    }
  }

  bool get isOperational {
    return this == DroneStatus.active || this == DroneStatus.deployed;
  }

  bool get isAvailable {
    return this == DroneStatus.active;
  }
}

enum DroneCapability {
  search,
  rescue,
  medicalDelivery,
  surveillance,
  thermalImaging,
  nightVision,
  livestreaming,
  cargoTransport,
  weatherMonitoring,
  firefighting,
  mapping,
  inspection,
}

extension DroneCapabilityExtension on DroneCapability {
  String get displayName {
    switch (this) {
      case DroneCapability.search:
        return 'Search';
      case DroneCapability.rescue:
        return 'Rescue';
      case DroneCapability.medicalDelivery:
        return 'Medical Delivery';
      case DroneCapability.surveillance:
        return 'Surveillance';
      case DroneCapability.thermalImaging:
        return 'Thermal Imaging';
      case DroneCapability.nightVision:
        return 'Night Vision';
      case DroneCapability.livestreaming:
        return 'Live Streaming';
      case DroneCapability.cargoTransport:
        return 'Cargo Transport';
      case DroneCapability.weatherMonitoring:
        return 'Weather Monitoring';
      case DroneCapability.firefighting:
        return 'Firefighting';
      case DroneCapability.mapping:
        return 'Mapping';
      case DroneCapability.inspection:
        return 'Inspection';
    }
  }

  String get description {
    switch (this) {
      case DroneCapability.search:
        return 'Search operations and area scanning';
      case DroneCapability.rescue:
        return 'Rescue operations support';
      case DroneCapability.medicalDelivery:
        return 'Emergency medical supply delivery';
      case DroneCapability.surveillance:
        return 'Real-time surveillance and monitoring';
      case DroneCapability.thermalImaging:
        return 'Thermal imaging for heat detection';
      case DroneCapability.nightVision:
        return 'Night vision capabilities';
      case DroneCapability.livestreaming:
        return 'Live video streaming';
      case DroneCapability.cargoTransport:
        return 'Cargo and supply transport';
      case DroneCapability.weatherMonitoring:
        return 'Weather condition monitoring';
      case DroneCapability.firefighting:
        return 'Fire suppression support';
      case DroneCapability.mapping:
        return '3D mapping and surveying';
      case DroneCapability.inspection:
        return 'Infrastructure inspection';
    }
  }
}
