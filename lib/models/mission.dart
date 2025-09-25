import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'user.dart';
import 'drone.dart';

part 'mission.g.dart';

@JsonSerializable()
class Mission {
  final String id;
  final String title;
  final String description;
  final MissionType type;
  final MissionStatus status;
  final MissionPriority priority;
  final String requesterId;
  final String? assignedOperatorId;
  final String? assignedDroneId;
  final Location startLocation;
  final Location? targetLocation;
  final List<Location> waypoints;
  final DateTime createdAt;
  final DateTime? scheduledStartTime;
  final DateTime? actualStartTime;
  final DateTime? completedAt;
  final DateTime updatedAt;
  final String? emergencyRequestId;
  final double? estimatedDuration; // in minutes
  final double? actualDuration; // in minutes
  final double? estimatedDistance; // in kilometers
  final double? actualDistance; // in kilometers
  final List<String> requiredCapabilities;
  final List<MissionUpdate> updates;
  final Map<String, dynamic>? metadata;
  final List<String> attachments;
  final String? notes;
  final bool isEmergency;
  final String? contactPhoneNumber;
  final String? contactEmail;

  Mission({
    String? id,
    required this.title,
    required this.description,
    required this.type,
    this.status = MissionStatus.pending,
    required this.priority,
    required this.requesterId,
    this.assignedOperatorId,
    this.assignedDroneId,
    required this.startLocation,
    this.targetLocation,
    List<Location>? waypoints,
    DateTime? createdAt,
    this.scheduledStartTime,
    this.actualStartTime,
    this.completedAt,
    DateTime? updatedAt,
    this.emergencyRequestId,
    this.estimatedDuration,
    this.actualDuration,
    this.estimatedDistance,
    this.actualDistance,
    List<String>? requiredCapabilities,
    List<MissionUpdate>? updates,
    this.metadata,
    List<String>? attachments,
    this.notes,
    this.isEmergency = false,
    this.contactPhoneNumber,
    this.contactEmail,
  }) : id = id ?? const Uuid().v4(),
       waypoints = waypoints ?? [],
       requiredCapabilities = requiredCapabilities ?? [],
       updates = updates ?? [],
       attachments = attachments ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isActive =>
      status == MissionStatus.assigned || status == MissionStatus.inProgress;

  bool get isCompleted =>
      status == MissionStatus.completed || status == MissionStatus.cancelled;

  bool get canBeStarted =>
      status == MissionStatus.assigned &&
      assignedOperatorId != null &&
      assignedDroneId != null;

  bool get hasTimeConstraint => scheduledStartTime != null;

  bool get isOverdue =>
      scheduledStartTime != null &&
      scheduledStartTime!.isBefore(DateTime.now()) &&
      status != MissionStatus.completed;

  Duration? get totalDuration {
    if (actualStartTime != null && completedAt != null) {
      return completedAt!.difference(actualStartTime!);
    }
    return null;
  }

  String get statusDisplay => status.displayName;
  String get priorityDisplay => priority.displayName;
  String get typeDisplay => type.displayName;

  double get progressPercentage {
    switch (status) {
      case MissionStatus.pending:
        return 0.0;
      case MissionStatus.assigned:
        return 25.0;
      case MissionStatus.inProgress:
        return 75.0;
      case MissionStatus.completed:
        return 100.0;
      case MissionStatus.cancelled:
        return 0.0;
    }
  }

  factory Mission.fromJson(Map<String, dynamic> json) =>
      _$MissionFromJson(json);

  Map<String, dynamic> toJson() => _$MissionToJson(this);

  Mission copyWith({
    String? id,
    String? title,
    String? description,
    MissionType? type,
    MissionStatus? status,
    MissionPriority? priority,
    String? requesterId,
    String? assignedOperatorId,
    String? assignedDroneId,
    Location? startLocation,
    Location? targetLocation,
    List<Location>? waypoints,
    DateTime? createdAt,
    DateTime? scheduledStartTime,
    DateTime? actualStartTime,
    DateTime? completedAt,
    DateTime? updatedAt,
    String? emergencyRequestId,
    double? estimatedDuration,
    double? actualDuration,
    double? estimatedDistance,
    double? actualDistance,
    List<String>? requiredCapabilities,
    List<MissionUpdate>? updates,
    Map<String, dynamic>? metadata,
    List<String>? attachments,
    String? notes,
    bool? isEmergency,
    String? contactPhoneNumber,
    String? contactEmail,
  }) {
    return Mission(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      requesterId: requesterId ?? this.requesterId,
      assignedOperatorId: assignedOperatorId ?? this.assignedOperatorId,
      assignedDroneId: assignedDroneId ?? this.assignedDroneId,
      startLocation: startLocation ?? this.startLocation,
      targetLocation: targetLocation ?? this.targetLocation,
      waypoints: waypoints ?? this.waypoints,
      createdAt: createdAt ?? this.createdAt,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      emergencyRequestId: emergencyRequestId ?? this.emergencyRequestId,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
      actualDistance: actualDistance ?? this.actualDistance,
      requiredCapabilities: requiredCapabilities ?? this.requiredCapabilities,
      updates: updates ?? this.updates,
      metadata: metadata ?? this.metadata,
      attachments: attachments ?? this.attachments,
      notes: notes ?? this.notes,
      isEmergency: isEmergency ?? this.isEmergency,
      contactPhoneNumber: contactPhoneNumber ?? this.contactPhoneNumber,
      contactEmail: contactEmail ?? this.contactEmail,
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
    return 'Mission{id: $id, title: $title, type: $type, status: $status, priority: $priority}';
  }
}

@JsonSerializable()
class MissionUpdate {
  final String id;
  final String missionId;
  final String operatorId;
  final MissionStatus status;
  final String message;
  final DateTime timestamp;
  final Location? location;
  final Map<String, dynamic>? data;

  MissionUpdate({
    String? id,
    required this.missionId,
    required this.operatorId,
    required this.status,
    required this.message,
    DateTime? timestamp,
    this.location,
    this.data,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  factory MissionUpdate.fromJson(Map<String, dynamic> json) =>
      _$MissionUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$MissionUpdateToJson(this);

  @override
  String toString() {
    return 'MissionUpdate{id: $id, status: $status, message: $message, timestamp: $timestamp}';
  }
}

enum MissionType {
  @JsonValue('medical_emergency')
  medicalEmergency,
  @JsonValue('fire_emergency')
  fireEmergency,
  @JsonValue('flood_response')
  floodResponse,
  @JsonValue('earthquake_response')
  earthquakeResponse,
  @JsonValue('accident_response')
  accidentResponse,
  @JsonValue('search_rescue')
  searchRescue,
  @JsonValue('surveillance')
  surveillance,
  @JsonValue('delivery')
  delivery,
  @JsonValue('inspection')
  inspection,
  @JsonValue('mapping')
  mapping,
  @JsonValue('monitoring')
  monitoring,
  @JsonValue('other')
  other,
}

extension MissionTypeExtension on MissionType {
  String get displayName {
    switch (this) {
      case MissionType.medicalEmergency:
        return 'Medical Emergency';
      case MissionType.fireEmergency:
        return 'Fire Emergency';
      case MissionType.floodResponse:
        return 'Flood Response';
      case MissionType.earthquakeResponse:
        return 'Earthquake Response';
      case MissionType.accidentResponse:
        return 'Accident Response';
      case MissionType.searchRescue:
        return 'Search & Rescue';
      case MissionType.surveillance:
        return 'Surveillance';
      case MissionType.delivery:
        return 'Delivery';
      case MissionType.inspection:
        return 'Inspection';
      case MissionType.mapping:
        return 'Mapping';
      case MissionType.monitoring:
        return 'Monitoring';
      case MissionType.other:
        return 'Other';
    }
  }

  String get description {
    switch (this) {
      case MissionType.medicalEmergency:
        return 'Emergency medical assistance and supply delivery';
      case MissionType.fireEmergency:
        return 'Fire detection, monitoring, and response support';
      case MissionType.floodResponse:
        return 'Flood monitoring and rescue operations';
      case MissionType.earthquakeResponse:
        return 'Earthquake damage assessment and rescue';
      case MissionType.accidentResponse:
        return 'Accident site monitoring and assistance';
      case MissionType.searchRescue:
        return 'Search and rescue operations';
      case MissionType.surveillance:
        return 'Area surveillance and monitoring';
      case MissionType.delivery:
        return 'Supply and equipment delivery';
      case MissionType.inspection:
        return 'Infrastructure and area inspection';
      case MissionType.mapping:
        return '3D mapping and surveying';
      case MissionType.monitoring:
        return 'Environmental and situational monitoring';
      case MissionType.other:
        return 'Other specialized missions';
    }
  }

  List<DroneCapability> get requiredCapabilities {
    switch (this) {
      case MissionType.medicalEmergency:
        return [DroneCapability.medicalDelivery, DroneCapability.liveStreaming];
      case MissionType.fireEmergency:
        return [DroneCapability.thermalImaging, DroneCapability.surveillance];
      case MissionType.floodResponse:
        return [DroneCapability.surveillance, DroneCapability.searchRescue];
      case MissionType.earthquakeResponse:
        return [DroneCapability.thermalImaging, DroneCapability.searchRescue];
      case MissionType.accidentResponse:
        return [DroneCapability.surveillance, DroneCapability.liveStreaming];
      case MissionType.searchRescue:
        return [DroneCapability.searchRescue, DroneCapability.thermalImaging];
      case MissionType.surveillance:
        return [DroneCapability.surveillance, DroneCapability.liveStreaming];
      case MissionType.delivery:
        return [DroneCapability.cargoTransport];
      case MissionType.inspection:
        return [DroneCapability.surveillance, DroneCapability.mapping];
      case MissionType.mapping:
        return [DroneCapability.mapping];
      case MissionType.monitoring:
        return [
          DroneCapability.environmentalMonitoring,
          DroneCapability.surveillance,
        ];
      case MissionType.other:
        return [];
    }
  }
}

enum MissionStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('assigned')
  assigned,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}

extension MissionStatusExtension on MissionStatus {
  String get displayName {
    switch (this) {
      case MissionStatus.pending:
        return 'Pending';
      case MissionStatus.assigned:
        return 'Assigned';
      case MissionStatus.inProgress:
        return 'In Progress';
      case MissionStatus.completed:
        return 'Completed';
      case MissionStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get description {
    switch (this) {
      case MissionStatus.pending:
        return 'Waiting for operator and drone assignment';
      case MissionStatus.assigned:
        return 'Assigned to operator and drone, ready to start';
      case MissionStatus.inProgress:
        return 'Mission is currently being executed';
      case MissionStatus.completed:
        return 'Mission completed successfully';
      case MissionStatus.cancelled:
        return 'Mission was cancelled';
    }
  }
}

enum MissionPriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('critical')
  critical,
}

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

  String get description {
    switch (this) {
      case MissionPriority.low:
        return 'Non-urgent mission, can be scheduled flexibly';
      case MissionPriority.medium:
        return 'Moderate priority, should be addressed promptly';
      case MissionPriority.high:
        return 'High priority, requires immediate attention';
      case MissionPriority.critical:
        return 'Critical emergency, requires immediate response';
    }
  }

  int get weight {
    switch (this) {
      case MissionPriority.low:
        return 1;
      case MissionPriority.medium:
        return 2;
      case MissionPriority.high:
        return 3;
      case MissionPriority.critical:
        return 4;
    }
  }
}
