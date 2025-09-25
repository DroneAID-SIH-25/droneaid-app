import 'package:uuid/uuid.dart';
import 'user.dart';
import 'drone.dart';
import 'emergency_request.dart';

class Mission {
  final String id;
  final String? emergencyRequestId;
  final String assignedDroneId;
  final String assignedOperatorId;
  final String title;
  final String description;
  final MissionType type;
  final MissionStatus status;
  final MissionPriority priority;
  final DateTime createdAt;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final DateTime? scheduledStartTime;
  final Duration? estimatedDuration;
  final LocationData startLocation;
  final LocationData targetLocation;
  final List<LocationData> waypoints;
  final String? completionNotes;
  final List<MissionUpdate> updates;
  final String? eventId;
  final double progress;
  final String payload;
  final String weatherConditions;
  final double fuelLevel;
  final double batteryLevel;
  final double altitude;
  final double speed;
  final double distance;
  final double? maxAltitude;
  final double? maxSpeed;
  final String? specialInstructions;
  final List<String>? equipment;
  final bool isRecurring;

  Mission({
    String? id,
    this.emergencyRequestId,
    required this.assignedDroneId,
    required this.assignedOperatorId,
    required this.title,
    required this.description,
    required this.type,
    this.status = MissionStatus.assigned,
    this.priority = MissionPriority.medium,
    DateTime? createdAt,
    this.actualStartTime,
    this.actualEndTime,
    this.scheduledStartTime,
    this.estimatedDuration,
    required this.startLocation,
    required this.targetLocation,
    List<LocationData>? waypoints,
    this.completionNotes,
    List<MissionUpdate>? updates,
    this.eventId,
    this.progress = 0.0,
    this.payload = '',
    this.weatherConditions = '',
    this.fuelLevel = 100.0,
    this.batteryLevel = 100.0,
    this.altitude = 0.0,
    this.speed = 0.0,
    this.distance = 0.0,
    this.maxAltitude,
    this.maxSpeed,
    this.specialInstructions,
    this.equipment,
    this.isRecurring = false,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       waypoints = waypoints ?? [],
       updates = updates ?? [];

  bool get isActive =>
      status == MissionStatus.assigned || status == MissionStatus.inProgress;

  bool get isCompleted =>
      status == MissionStatus.completed ||
      status == MissionStatus.cancelled ||
      status == MissionStatus.failed;

  bool get isPending => status == MissionStatus.assigned;

  bool get isInProgress => status == MissionStatus.inProgress;

  bool get isSuccessful => status == MissionStatus.completed;

  bool get isCancelled => status == MissionStatus.cancelled;

  bool get isFailed => status == MissionStatus.failed;

  bool get isHighPriority =>
      priority == MissionPriority.high || priority == MissionPriority.critical;

  bool get isCritical => priority == MissionPriority.critical;

  Duration get timeSinceCreated => DateTime.now().difference(createdAt);

  Duration? get actualDuration {
    if (actualStartTime != null && actualEndTime != null) {
      return actualEndTime!.difference(actualStartTime!);
    }
    return null;
  }

  Duration? get timeSinceStarted {
    if (actualStartTime != null) {
      return DateTime.now().difference(actualStartTime!);
    }
    return null;
  }

  String get statusDisplay => status.displayName;

  String get priorityDisplay => priority.displayName;

  String get durationDisplay {
    final duration = actualDuration;
    if (duration != null) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (hours > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${minutes}m';
    }
    return 'N/A';
  }

  String get estimatedDurationDisplay {
    if (estimatedDuration != null) {
      final hours = estimatedDuration!.inHours;
      final minutes = estimatedDuration!.inMinutes % 60;
      if (hours > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${minutes}m';
    }
    return 'N/A';
  }

  String get missionCode {
    final statusCode = status == MissionStatus.completed
        ? 'C'
        : status == MissionStatus.inProgress
        ? 'P'
        : status == MissionStatus.cancelled
        ? 'X'
        : status == MissionStatus.failed
        ? 'F'
        : 'A';
    final priorityCode = priority == MissionPriority.critical
        ? 'C'
        : priority == MissionPriority.high
        ? 'H'
        : priority == MissionPriority.medium
        ? 'M'
        : 'L';
    return 'M-$statusCode$priorityCode-${id.substring(0, 6)}';
  }

  double? get completionPercentage {
    if (status == MissionStatus.inProgress) {
      return progress * 100;
    }
    switch (status) {
      case MissionStatus.assigned:
        return 0.0;
      case MissionStatus.inProgress:
        return progress * 100;
      case MissionStatus.completed:
        return 100.0;
      case MissionStatus.cancelled:
        return 0.0;
      case MissionStatus.failed:
        return 0.0;
      case MissionStatus.paused:
        return progress * 100;
    }
  }

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] as String?,
      emergencyRequestId: json['emergencyRequestId'] as String?,
      assignedDroneId: json['assignedDroneId'] as String,
      assignedOperatorId: json['assignedOperatorId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: MissionType.values.firstWhere((e) => e.name == json['type']),
      status: MissionStatus.values.firstWhere((e) => e.name == json['status']),
      priority: MissionPriority.values.firstWhere(
        (e) => e.name == json['priority'],
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      actualStartTime: json['actualStartTime'] != null
          ? DateTime.parse(json['actualStartTime'] as String)
          : null,
      actualEndTime: json['actualEndTime'] != null
          ? DateTime.parse(json['actualEndTime'] as String)
          : null,
      scheduledStartTime: json['scheduledStartTime'] != null
          ? DateTime.parse(json['scheduledStartTime'] as String)
          : null,
      estimatedDuration: json['estimatedDuration'] != null
          ? Duration(minutes: json['estimatedDuration'] as int)
          : null,
      startLocation: LocationData.fromJson(
        json['startLocation'] as Map<String, dynamic>,
      ),
      targetLocation: LocationData.fromJson(
        json['targetLocation'] as Map<String, dynamic>,
      ),
      waypoints: (json['waypoints'] as List?)
          ?.map((e) => LocationData.fromJson(e as Map<String, dynamic>))
          .toList(),
      completionNotes: json['completionNotes'] as String?,
      updates: (json['updates'] as List?)
          ?.map((e) => MissionUpdate.fromJson(e as Map<String, dynamic>))
          .toList(),
      eventId: json['eventId'] as String?,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      payload: json['payload'] as String? ?? '',
      weatherConditions: json['weatherConditions'] as String? ?? '',
      fuelLevel: (json['fuelLevel'] as num?)?.toDouble() ?? 100.0,
      batteryLevel: (json['batteryLevel'] as num?)?.toDouble() ?? 100.0,
      altitude: (json['altitude'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      maxAltitude: (json['maxAltitude'] as num?)?.toDouble(),
      maxSpeed: (json['maxSpeed'] as num?)?.toDouble(),
      specialInstructions: json['specialInstructions'] as String?,
      equipment: (json['equipment'] as List?)?.cast<String>(),
      isRecurring: json['isRecurring'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emergencyRequestId': emergencyRequestId,
      'assignedDroneId': assignedDroneId,
      'assignedOperatorId': assignedOperatorId,
      'title': title,
      'description': description,
      'type': type.name,
      'status': status.name,
      'priority': priority.name,
      'createdAt': createdAt.toIso8601String(),
      'actualStartTime': actualStartTime?.toIso8601String(),
      'actualEndTime': actualEndTime?.toIso8601String(),
      'scheduledStartTime': scheduledStartTime?.toIso8601String(),
      'estimatedDuration': estimatedDuration?.inMinutes,
      'startLocation': startLocation.toJson(),
      'targetLocation': targetLocation.toJson(),
      'waypoints': waypoints.map((e) => e.toJson()).toList(),
      'completionNotes': completionNotes,
      'updates': updates.map((e) => e.toJson()).toList(),
      'eventId': eventId,
      'progress': progress,
      'payload': payload,
      'weatherConditions': weatherConditions,
      'fuelLevel': fuelLevel,
      'batteryLevel': batteryLevel,
      'altitude': altitude,
      'speed': speed,
      'distance': distance,
      'maxAltitude': maxAltitude,
      'maxSpeed': maxSpeed,
      'specialInstructions': specialInstructions,
      'equipment': equipment,
      'isRecurring': isRecurring,
    };
  }

  Mission copyWith({
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
  }) {
    return Mission(
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
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Mission && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Mission{id: $id, title: $title, status: $status, priority: $priority}';
  }
}

class MissionUpdate {
  final String id;
  final String missionId;
  final String updatedBy;
  final String message;
  final MissionStatus? newStatus;
  final DateTime timestamp;
  final LocationData? location;
  final Map<String, dynamic>? data;

  MissionUpdate({
    String? id,
    required this.missionId,
    required this.updatedBy,
    required this.message,
    this.newStatus,
    DateTime? timestamp,
    this.location,
    this.data,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  factory MissionUpdate.fromJson(Map<String, dynamic> json) {
    return MissionUpdate(
      id: json['id'] as String?,
      missionId: json['missionId'] as String,
      updatedBy: json['updatedBy'] as String,
      message: json['message'] as String,
      newStatus: json['newStatus'] != null
          ? MissionStatus.values.firstWhere((e) => e.name == json['newStatus'])
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      location: json['location'] != null
          ? LocationData.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'missionId': missionId,
      'updatedBy': updatedBy,
      'message': message,
      'newStatus': newStatus?.name,
      'timestamp': timestamp.toIso8601String(),
      'location': location?.toJson(),
      'data': data,
    };
  }

  @override
  String toString() {
    return 'MissionUpdate{id: $id, message: $message, timestamp: $timestamp}';
  }
}

enum MissionType {
  search,
  rescue,
  medical,
  surveillance,
  delivery,
  reconnaissance,
  firefighting,
  emergencyResponse,
  evacuation,
  assessment,
  monitoring,
  other,
  searchAndRescue,
  mapping,
  inspection,
  patrol,
}

extension MissionTypeExtension on MissionType {
  String get displayName {
    switch (this) {
      case MissionType.search:
        return 'Search';
      case MissionType.rescue:
        return 'Rescue';
      case MissionType.medical:
        return 'Medical';
      case MissionType.surveillance:
        return 'Surveillance';
      case MissionType.delivery:
        return 'Delivery';
      case MissionType.reconnaissance:
        return 'Reconnaissance';
      case MissionType.firefighting:
        return 'Firefighting';
      case MissionType.emergencyResponse:
        return 'Emergency Response';
      case MissionType.evacuation:
        return 'Evacuation';
      case MissionType.assessment:
        return 'Assessment';
      case MissionType.monitoring:
        return 'Monitoring';
      case MissionType.other:
        return 'Other';
      case MissionType.searchAndRescue:
        return 'Search & Rescue';
      case MissionType.mapping:
        return 'Mapping';
      case MissionType.inspection:
        return 'Inspection';
      case MissionType.patrol:
        return 'Patrol';
    }
  }

  String get description {
    switch (this) {
      case MissionType.search:
        return 'Search operation using drone surveillance';
      case MissionType.rescue:
        return 'Rescue mission with drone assistance';
      case MissionType.medical:
        return 'Medical emergency response or supply delivery';
      case MissionType.surveillance:
        return 'Area surveillance and monitoring';
      case MissionType.delivery:
        return 'Emergency supply or equipment delivery';
      case MissionType.reconnaissance:
        return 'Reconnaissance and data gathering';
      case MissionType.firefighting:
        return 'Fire suppression or fire monitoring support';
      case MissionType.emergencyResponse:
        return 'General emergency response mission';
      case MissionType.evacuation:
        return 'Evacuation assistance and coordination';
      case MissionType.assessment:
        return 'Damage or situation assessment';
      case MissionType.monitoring:
        return 'Ongoing monitoring of situation';
      case MissionType.other:
        return 'Other specialized mission type';
      case MissionType.searchAndRescue:
        return 'Combined search and rescue operations';
      case MissionType.mapping:
        return 'Aerial mapping and surveying';
      case MissionType.inspection:
        return 'Infrastructure inspection and assessment';
      case MissionType.patrol:
        return 'Security patrol and monitoring';
    }
  }
}

enum MissionStatus {
  assigned,
  inProgress,
  completed,
  cancelled,
  failed,
  paused,
}

enum MissionPriority { low, medium, high, critical }

extension MissionPriorityExtension on MissionPriority {
  String get displayName {
    switch (this) {
      case MissionPriority.low:
        return 'Low';
      case MissionPriority.medium:
        return 'Medium';
      case MissionPriority.high:
        return 'High';
      case MissionPriority.critical:
        return 'Critical';
    }
  }
}

extension MissionStatusExtension on MissionStatus {
  String get displayName {
    switch (this) {
      case MissionStatus.assigned:
        return 'Assigned';
      case MissionStatus.inProgress:
        return 'In Progress';
      case MissionStatus.completed:
        return 'Completed';
      case MissionStatus.cancelled:
        return 'Cancelled';
      case MissionStatus.failed:
        return 'Failed';
      case MissionStatus.paused:
        return 'Paused';
    }
  }

  String get description {
    switch (this) {
      case MissionStatus.assigned:
        return 'Mission has been assigned to a drone';
      case MissionStatus.inProgress:
        return 'Mission is currently in progress';
      case MissionStatus.completed:
        return 'Mission completed successfully';
      case MissionStatus.cancelled:
        return 'Mission was cancelled';
      case MissionStatus.failed:
        return 'Mission failed to complete';
      case MissionStatus.paused:
        return 'Mission is temporarily paused';
    }
  }

  bool get isActive {
    return this == MissionStatus.assigned || this == MissionStatus.inProgress;
  }

  bool get isCompleted {
    return this == MissionStatus.completed ||
        this == MissionStatus.cancelled ||
        this == MissionStatus.failed;
  }

  bool get isSuccessful {
    return this == MissionStatus.completed;
  }
}
