import 'package:uuid/uuid.dart';
import 'user.dart';
import 'drone.dart';
import 'emergency_request.dart';

class Mission {
  final String id;
  final String emergencyRequestId;
  final String droneId;
  final String operatorId;
  final String title;
  final String description;
  final MissionStatus status;
  final Priority priority;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int estimatedDuration; // in minutes
  final LocationData targetLocation;
  final List<LocationData> waypoints;
  final String? completionNotes;
  final List<MissionUpdate> updates;

  Mission({
    String? id,
    required this.emergencyRequestId,
    required this.droneId,
    required this.operatorId,
    required this.title,
    required this.description,
    this.status = MissionStatus.pending,
    this.priority = Priority.medium,
    DateTime? createdAt,
    this.startedAt,
    this.completedAt,
    required this.estimatedDuration,
    required this.targetLocation,
    List<LocationData>? waypoints,
    this.completionNotes,
    List<MissionUpdate>? updates,
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

  bool get isPending => status == MissionStatus.pending;

  bool get isInProgress => status == MissionStatus.inProgress;

  bool get isSuccessful => status == MissionStatus.completed;

  bool get isCancelled => status == MissionStatus.cancelled;

  bool get isFailed => status == MissionStatus.failed;

  bool get isHighPriority =>
      priority == Priority.high || priority == Priority.critical;

  bool get isCritical => priority == Priority.critical;

  Duration get timeSinceCreated => DateTime.now().difference(createdAt);

  Duration? get actualDuration {
    if (startedAt != null && completedAt != null) {
      return completedAt!.difference(startedAt!);
    }
    return null;
  }

  Duration? get timeSinceStarted {
    if (startedAt != null) {
      return DateTime.now().difference(startedAt!);
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
    final hours = estimatedDuration ~/ 60;
    final minutes = estimatedDuration % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
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
    final priorityCode = priority == Priority.critical
        ? 'C'
        : priority == Priority.high
        ? 'H'
        : priority == Priority.medium
        ? 'M'
        : 'L';
    return 'M-$statusCode$priorityCode-${id.substring(0, 6)}';
  }

  double? get completionPercentage {
    switch (status) {
      case MissionStatus.pending:
        return 0.0;
      case MissionStatus.assigned:
        return 20.0;
      case MissionStatus.inProgress:
        return 60.0;
      case MissionStatus.completed:
        return 100.0;
      case MissionStatus.cancelled:
        return 0.0;
      case MissionStatus.failed:
        return 0.0;
    }
  }

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] as String?,
      emergencyRequestId: json['emergencyRequestId'] as String,
      droneId: json['droneId'] as String,
      operatorId: json['operatorId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: MissionStatus.values.firstWhere((e) => e.name == json['status']),
      priority: Priority.values.firstWhere((e) => e.name == json['priority']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      estimatedDuration: json['estimatedDuration'] as int,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emergencyRequestId': emergencyRequestId,
      'droneId': droneId,
      'operatorId': operatorId,
      'title': title,
      'description': description,
      'status': status.name,
      'priority': priority.name,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'estimatedDuration': estimatedDuration,
      'targetLocation': targetLocation.toJson(),
      'waypoints': waypoints.map((e) => e.toJson()).toList(),
      'completionNotes': completionNotes,
      'updates': updates.map((e) => e.toJson()).toList(),
    };
  }

  Mission copyWith({
    String? id,
    String? emergencyRequestId,
    String? droneId,
    String? operatorId,
    String? title,
    String? description,
    MissionStatus? status,
    Priority? priority,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    int? estimatedDuration,
    LocationData? targetLocation,
    List<LocationData>? waypoints,
    String? completionNotes,
    List<MissionUpdate>? updates,
  }) {
    return Mission(
      id: id ?? this.id,
      emergencyRequestId: emergencyRequestId ?? this.emergencyRequestId,
      droneId: droneId ?? this.droneId,
      operatorId: operatorId ?? this.operatorId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      targetLocation: targetLocation ?? this.targetLocation,
      waypoints: waypoints ?? this.waypoints,
      completionNotes: completionNotes ?? this.completionNotes,
      updates: updates ?? this.updates,
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
    }
  }
}

enum MissionStatus {
  pending,
  assigned,
  inProgress,
  completed,
  cancelled,
  failed,
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
      case MissionStatus.failed:
        return 'Failed';
    }
  }

  String get description {
    switch (this) {
      case MissionStatus.pending:
        return 'Mission is pending assignment';
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
