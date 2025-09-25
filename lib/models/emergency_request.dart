import 'package:uuid/uuid.dart';
import 'user.dart';

class EmergencyRequest {
  final String id;
  final String userId;
  final EmergencyType emergencyType;
  final String description;
  final LocationData location;
  final EmergencyStatus status;
  final Priority priority;
  final DateTime createdAt;
  final String contactNumber;
  final String? assignedMissionId;
  final DateTime? resolvedAt;
  final List<EmergencyUpdate> updates;
  final List<String> images;
  final Map<String, dynamic>? additionalInfo;
  final List<String> witnesses;

  EmergencyRequest({
    String? id,
    required this.userId,
    required this.emergencyType,
    required this.description,
    required this.location,
    this.status = EmergencyStatus.pending,
    this.priority = Priority.medium,
    DateTime? createdAt,
    required this.contactNumber,
    this.assignedMissionId,
    this.resolvedAt,
    List<EmergencyUpdate>? updates,
    List<String>? images,
    this.additionalInfo,
    List<String>? witnesses,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updates = updates ?? [],
       images = images ?? [],
       witnesses = witnesses ?? [];

  bool get isActive =>
      status == EmergencyStatus.pending ||
      status == EmergencyStatus.assigned ||
      status == EmergencyStatus.inProgress;

  bool get isResolved => status == EmergencyStatus.resolved;

  bool get isCancelled => status == EmergencyStatus.cancelled;

  bool get isHighPriority =>
      priority == Priority.high || priority == Priority.critical;

  bool get isCritical => priority == Priority.critical;

  bool get hasUpdates => updates.isNotEmpty;

  bool get hasImages => images.isNotEmpty;

  bool get hasWitnesses => witnesses.isNotEmpty;

  Duration get timeSinceCreated => DateTime.now().difference(createdAt);

  Duration? get resolutionTime {
    if (resolvedAt != null) {
      return resolvedAt!.difference(createdAt);
    }
    return null;
  }

  String get statusDisplay => status.displayName;

  String get priorityDisplay => priority.displayName;

  String get typeDisplay => emergencyType.displayName;

  String get priorityCode {
    switch (priority) {
      case Priority.low:
        return 'L';
      case Priority.medium:
        return 'M';
      case Priority.high:
        return 'H';
      case Priority.critical:
        return 'C';
    }
  }

  String get emergencyCode =>
      '${emergencyType.code}-${priorityCode}-${id.substring(0, 6)}';

  String get urgencyLevel {
    return priority.displayName.toUpperCase();
  }

  factory EmergencyRequest.fromJson(Map<String, dynamic> json) {
    return EmergencyRequest(
      id: json['id'] as String?,
      userId: json['userId'] as String,
      emergencyType: EmergencyType.values.firstWhere(
        (e) => e.name == json['emergencyType'],
      ),
      description: json['description'] as String,
      location: LocationData.fromJson(json['location'] as Map<String, dynamic>),
      status: EmergencyStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      priority: Priority.values.firstWhere((e) => e.name == json['priority']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      contactNumber: json['contactNumber'] as String,
      assignedMissionId: json['assignedMissionId'] as String?,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      updates: (json['updates'] as List?)
          ?.map((e) => EmergencyUpdate.fromJson(e as Map<String, dynamic>))
          .toList(),
      images: (json['images'] as List?)?.cast<String>(),
      additionalInfo: json['additionalInfo'] as Map<String, dynamic>?,
      witnesses: (json['witnesses'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'emergencyType': emergencyType.name,
      'description': description,
      'location': location.toJson(),
      'status': status.name,
      'priority': priority.name,
      'createdAt': createdAt.toIso8601String(),
      'contactNumber': contactNumber,
      'assignedMissionId': assignedMissionId,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'updates': updates.map((e) => e.toJson()).toList(),
      'images': images,
      'additionalInfo': additionalInfo,
      'witnesses': witnesses,
    };
  }

  EmergencyRequest copyWith({
    String? id,
    String? userId,
    EmergencyType? emergencyType,
    String? description,
    LocationData? location,
    EmergencyStatus? status,
    Priority? priority,
    DateTime? createdAt,
    String? contactNumber,
    String? assignedMissionId,
    DateTime? resolvedAt,
    List<EmergencyUpdate>? updates,
    List<String>? images,
    Map<String, dynamic>? additionalInfo,
    List<String>? witnesses,
  }) {
    return EmergencyRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      emergencyType: emergencyType ?? this.emergencyType,
      description: description ?? this.description,
      location: location ?? this.location,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      contactNumber: contactNumber ?? this.contactNumber,
      assignedMissionId: assignedMissionId ?? this.assignedMissionId,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      updates: updates ?? this.updates,
      images: images ?? this.images,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      witnesses: witnesses ?? this.witnesses,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmergencyRequest &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'EmergencyRequest{id: $id, type: $emergencyType, status: $status, priority: $priority}';
  }
}

class EmergencyUpdate {
  final String id;
  final String requestId;
  final String updatedBy;
  final String message;
  final EmergencyStatus? newStatus;
  final DateTime timestamp;
  final LocationData? location;
  final List<String> images;

  EmergencyUpdate({
    String? id,
    required this.requestId,
    required this.updatedBy,
    required this.message,
    this.newStatus,
    DateTime? timestamp,
    this.location,
    List<String>? images,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now(),
       images = images ?? [];

  factory EmergencyUpdate.fromJson(Map<String, dynamic> json) {
    return EmergencyUpdate(
      id: json['id'] as String?,
      requestId: json['requestId'] as String,
      updatedBy: json['updatedBy'] as String,
      message: json['message'] as String,
      newStatus: json['newStatus'] != null
          ? EmergencyStatus.values.firstWhere(
              (e) => e.name == json['newStatus'],
            )
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      location: json['location'] != null
          ? LocationData.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      images: (json['images'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestId': requestId,
      'updatedBy': updatedBy,
      'message': message,
      'newStatus': newStatus?.name,
      'timestamp': timestamp.toIso8601String(),
      'location': location?.toJson(),
      'images': images,
    };
  }

  @override
  String toString() {
    return 'EmergencyUpdate{id: $id, message: $message, timestamp: $timestamp}';
  }
}

enum EmergencyType {
  medicalEmergency,
  fireEmergency,
  naturalDisaster,
  accident,
  security,
  searchAndRescue,
  chemicalSpill,
  structuralCollapse,
  flooding,
  earthquake,
  storm,
  evacuation,
  other,
}

extension EmergencyTypeExtension on EmergencyType {
  String get displayName {
    switch (this) {
      case EmergencyType.medicalEmergency:
        return 'Medical Emergency';
      case EmergencyType.fireEmergency:
        return 'Fire Emergency';
      case EmergencyType.naturalDisaster:
        return 'Natural Disaster';
      case EmergencyType.accident:
        return 'Accident';
      case EmergencyType.security:
        return 'Security Incident';
      case EmergencyType.searchAndRescue:
        return 'Search & Rescue';
      case EmergencyType.chemicalSpill:
        return 'Chemical Spill';
      case EmergencyType.structuralCollapse:
        return 'Structural Collapse';
      case EmergencyType.flooding:
        return 'Flooding';
      case EmergencyType.earthquake:
        return 'Earthquake';
      case EmergencyType.storm:
        return 'Storm';
      case EmergencyType.evacuation:
        return 'Evacuation';
      case EmergencyType.other:
        return 'Other';
    }
  }

  String get description {
    switch (this) {
      case EmergencyType.medicalEmergency:
        return 'Medical emergency requiring immediate assistance';
      case EmergencyType.fireEmergency:
        return 'Fire incident requiring fire department response';
      case EmergencyType.naturalDisaster:
        return 'Natural disaster event requiring emergency response';
      case EmergencyType.accident:
        return 'Accident requiring emergency services';
      case EmergencyType.security:
        return 'Security incident requiring law enforcement';
      case EmergencyType.searchAndRescue:
        return 'Search and rescue operation needed';
      case EmergencyType.chemicalSpill:
        return 'Hazardous chemical spill requiring specialized response';
      case EmergencyType.structuralCollapse:
        return 'Building or structure collapse emergency';
      case EmergencyType.flooding:
        return 'Flood emergency requiring evacuation or rescue';
      case EmergencyType.earthquake:
        return 'Earthquake emergency requiring immediate response';
      case EmergencyType.storm:
        return 'Severe weather emergency';
      case EmergencyType.evacuation:
        return 'Evacuation required due to imminent danger';
      case EmergencyType.other:
        return 'Other type of emergency';
    }
  }

  String get code {
    switch (this) {
      case EmergencyType.medicalEmergency:
        return 'MED';
      case EmergencyType.fireEmergency:
        return 'FIRE';
      case EmergencyType.naturalDisaster:
        return 'NAT';
      case EmergencyType.accident:
        return 'ACC';
      case EmergencyType.security:
        return 'SEC';
      case EmergencyType.searchAndRescue:
        return 'SAR';
      case EmergencyType.chemicalSpill:
        return 'CHEM';
      case EmergencyType.structuralCollapse:
        return 'COL';
      case EmergencyType.flooding:
        return 'FLOOD';
      case EmergencyType.earthquake:
        return 'EQ';
      case EmergencyType.storm:
        return 'STORM';
      case EmergencyType.evacuation:
        return 'EVAC';
      case EmergencyType.other:
        return 'OTHER';
    }
  }

  Priority get defaultPriority {
    switch (this) {
      case EmergencyType.medicalEmergency:
      case EmergencyType.fireEmergency:
      case EmergencyType.structuralCollapse:
      case EmergencyType.earthquake:
        return Priority.critical;
      case EmergencyType.naturalDisaster:
      case EmergencyType.searchAndRescue:
      case EmergencyType.chemicalSpill:
      case EmergencyType.flooding:
        return Priority.high;
      case EmergencyType.accident:
      case EmergencyType.security:
      case EmergencyType.storm:
      case EmergencyType.evacuation:
        return Priority.medium;
      case EmergencyType.other:
        return Priority.low;
    }
  }
}

enum Priority { low, medium, high, critical }

extension PriorityExtension on Priority {
  String get displayName {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
      case Priority.critical:
        return 'Critical';
    }
  }

  String get description {
    switch (this) {
      case Priority.low:
        return 'Low priority - routine response';
      case Priority.medium:
        return 'Medium priority - standard response time';
      case Priority.high:
        return 'High priority - expedited response required';
      case Priority.critical:
        return 'Critical priority - immediate response required';
    }
  }

  int get weight {
    switch (this) {
      case Priority.low:
        return 1;
      case Priority.medium:
        return 2;
      case Priority.high:
        return 3;
      case Priority.critical:
        return 4;
    }
  }
}

enum EmergencyStatus { pending, assigned, inProgress, resolved, cancelled }

extension EmergencyStatusExtension on EmergencyStatus {
  String get displayName {
    switch (this) {
      case EmergencyStatus.pending:
        return 'Pending';
      case EmergencyStatus.assigned:
        return 'Assigned';
      case EmergencyStatus.inProgress:
        return 'In Progress';
      case EmergencyStatus.resolved:
        return 'Resolved';
      case EmergencyStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get description {
    switch (this) {
      case EmergencyStatus.pending:
        return 'Emergency request is pending assignment';
      case EmergencyStatus.assigned:
        return 'Emergency request has been assigned to a drone';
      case EmergencyStatus.inProgress:
        return 'Emergency response is in progress';
      case EmergencyStatus.resolved:
        return 'Emergency has been resolved';
      case EmergencyStatus.cancelled:
        return 'Emergency request was cancelled';
    }
  }

  bool get isActive {
    return this == EmergencyStatus.pending ||
        this == EmergencyStatus.assigned ||
        this == EmergencyStatus.inProgress;
  }

  bool get isCompleted {
    return this == EmergencyStatus.resolved ||
        this == EmergencyStatus.cancelled;
  }
}
