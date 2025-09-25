import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'user.dart';

part 'emergency_request.g.dart';

@JsonSerializable()
class EmergencyRequest {
  final String id;
  final String title;
  final String description;
  final EmergencyType type;
  final EmergencyPriority priority;
  final EmergencyStatus status;
  final String requesterId;
  final String requesterName;
  final String requesterPhone;
  final String? requesterEmail;
  final Location location;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final String? assignedOperatorId;
  final String? assignedMissionId;
  final List<String> attachments;
  final Map<String, dynamic>? additionalInfo;
  final int numberOfPeople;
  final bool hasInjuries;
  final String? injuryDescription;
  final bool needsMedicalSupplies;
  final List<String> requiredSupplies;
  final String? accessibilityInfo;
  final WeatherCondition? weatherCondition;
  final String? landmarkDescription;
  final bool isVerified;
  final String? verifiedBy;
  final DateTime? verificationTime;
  final List<EmergencyUpdate> updates;

  EmergencyRequest({
    String? id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    this.status = EmergencyStatus.pending,
    required this.requesterId,
    required this.requesterName,
    required this.requesterPhone,
    this.requesterEmail,
    required this.location,
    this.address,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.resolvedAt,
    this.assignedOperatorId,
    this.assignedMissionId,
    List<String>? attachments,
    this.additionalInfo,
    this.numberOfPeople = 1,
    this.hasInjuries = false,
    this.injuryDescription,
    this.needsMedicalSupplies = false,
    List<String>? requiredSupplies,
    this.accessibilityInfo,
    this.weatherCondition,
    this.landmarkDescription,
    this.isVerified = false,
    this.verifiedBy,
    this.verificationTime,
    List<EmergencyUpdate>? updates,
  }) : id = id ?? const Uuid().v4(),
       attachments = attachments ?? [],
       requiredSupplies = requiredSupplies ?? [],
       updates = updates ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isActive =>
      status == EmergencyStatus.pending || status == EmergencyStatus.inProgress;

  bool get isResolved =>
      status == EmergencyStatus.resolved || status == EmergencyStatus.cancelled;

  bool get isCritical => priority == EmergencyPriority.critical;

  bool get isHigh => priority == EmergencyPriority.high;

  bool get requiresImmediateResponse =>
      priority == EmergencyPriority.critical ||
      priority == EmergencyPriority.high;

  String get statusDisplay => status.displayName;
  String get priorityDisplay => priority.displayName;
  String get typeDisplay => type.displayName;

  Duration get timeSinceCreated => DateTime.now().difference(createdAt);

  bool get isOverdue {
    switch (priority) {
      case EmergencyPriority.critical:
        return timeSinceCreated.inMinutes > 5;
      case EmergencyPriority.high:
        return timeSinceCreated.inMinutes > 15;
      case EmergencyPriority.medium:
        return timeSinceCreated.inHours > 1;
      case EmergencyPriority.low:
        return timeSinceCreated.inHours > 24;
    }
  }

  String get urgencyLevel {
    if (isCritical) return 'CRITICAL';
    if (isHigh) return 'HIGH';
    return priority.displayName.toUpperCase();
  }

  factory EmergencyRequest.fromJson(Map<String, dynamic> json) =>
      _$EmergencyRequestFromJson(json);

  Map<String, dynamic> toJson() => _$EmergencyRequestToJson(this);

  EmergencyRequest copyWith({
    String? id,
    String? title,
    String? description,
    EmergencyType? type,
    EmergencyPriority? priority,
    EmergencyStatus? status,
    String? requesterId,
    String? requesterName,
    String? requesterPhone,
    String? requesterEmail,
    Location? location,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    String? assignedOperatorId,
    String? assignedMissionId,
    List<String>? attachments,
    Map<String, dynamic>? additionalInfo,
    int? numberOfPeople,
    bool? hasInjuries,
    String? injuryDescription,
    bool? needsMedicalSupplies,
    List<String>? requiredSupplies,
    String? accessibilityInfo,
    WeatherCondition? weatherCondition,
    String? landmarkDescription,
    bool? isVerified,
    String? verifiedBy,
    DateTime? verificationTime,
    List<EmergencyUpdate>? updates,
  }) {
    return EmergencyRequest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterPhone: requesterPhone ?? this.requesterPhone,
      requesterEmail: requesterEmail ?? this.requesterEmail,
      location: location ?? this.location,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      assignedOperatorId: assignedOperatorId ?? this.assignedOperatorId,
      assignedMissionId: assignedMissionId ?? this.assignedMissionId,
      attachments: attachments ?? this.attachments,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      numberOfPeople: numberOfPeople ?? this.numberOfPeople,
      hasInjuries: hasInjuries ?? this.hasInjuries,
      injuryDescription: injuryDescription ?? this.injuryDescription,
      needsMedicalSupplies: needsMedicalSupplies ?? this.needsMedicalSupplies,
      requiredSupplies: requiredSupplies ?? this.requiredSupplies,
      accessibilityInfo: accessibilityInfo ?? this.accessibilityInfo,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      landmarkDescription: landmarkDescription ?? this.landmarkDescription,
      isVerified: isVerified ?? this.isVerified,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verificationTime: verificationTime ?? this.verificationTime,
      updates: updates ?? this.updates,
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
    return 'EmergencyRequest{id: $id, title: $title, type: $type, priority: $priority, status: $status}';
  }
}

@JsonSerializable()
class EmergencyUpdate {
  final String id;
  final String requestId;
  final String updatedBy;
  final EmergencyStatus status;
  final String message;
  final DateTime timestamp;
  final Location? location;
  final Map<String, dynamic>? data;

  EmergencyUpdate({
    String? id,
    required this.requestId,
    required this.updatedBy,
    required this.status,
    required this.message,
    DateTime? timestamp,
    this.location,
    this.data,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  factory EmergencyUpdate.fromJson(Map<String, dynamic> json) =>
      _$EmergencyUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$EmergencyUpdateToJson(this);

  @override
  String toString() {
    return 'EmergencyUpdate{id: $id, status: $status, message: $message, timestamp: $timestamp}';
  }
}

enum EmergencyType {
  @JsonValue('medical_emergency')
  medicalEmergency,
  @JsonValue('fire')
  fire,
  @JsonValue('flood')
  flood,
  @JsonValue('earthquake')
  earthquake,
  @JsonValue('accident')
  accident,
  @JsonValue('search_rescue')
  searchRescue,
  @JsonValue('building_collapse')
  buildingCollapse,
  @JsonValue('landslide')
  landslide,
  @JsonValue('gas_leak')
  gasLeak,
  @JsonValue('chemical_spill')
  chemicalSpill,
  @JsonValue('power_outage')
  powerOutage,
  @JsonValue('missing_person')
  missingPerson,
  @JsonValue('animal_attack')
  animalAttack,
  @JsonValue('other')
  other,
}

extension EmergencyTypeExtension on EmergencyType {
  String get displayName {
    switch (this) {
      case EmergencyType.medicalEmergency:
        return 'Medical Emergency';
      case EmergencyType.fire:
        return 'Fire';
      case EmergencyType.flood:
        return 'Flood';
      case EmergencyType.earthquake:
        return 'Earthquake';
      case EmergencyType.accident:
        return 'Accident';
      case EmergencyType.searchRescue:
        return 'Search & Rescue';
      case EmergencyType.buildingCollapse:
        return 'Building Collapse';
      case EmergencyType.landslide:
        return 'Landslide';
      case EmergencyType.gasLeak:
        return 'Gas Leak';
      case EmergencyType.chemicalSpill:
        return 'Chemical Spill';
      case EmergencyType.powerOutage:
        return 'Power Outage';
      case EmergencyType.missingPerson:
        return 'Missing Person';
      case EmergencyType.animalAttack:
        return 'Animal Attack';
      case EmergencyType.other:
        return 'Other';
    }
  }

  String get description {
    switch (this) {
      case EmergencyType.medicalEmergency:
        return 'Medical emergency requiring immediate assistance';
      case EmergencyType.fire:
        return 'Fire incident requiring firefighting response';
      case EmergencyType.flood:
        return 'Flooding situation requiring rescue or assistance';
      case EmergencyType.earthquake:
        return 'Earthquake-related emergency';
      case EmergencyType.accident:
        return 'Vehicle or other accident requiring emergency response';
      case EmergencyType.searchRescue:
        return 'Search and rescue operation needed';
      case EmergencyType.buildingCollapse:
        return 'Building structural collapse emergency';
      case EmergencyType.landslide:
        return 'Landslide emergency requiring immediate response';
      case EmergencyType.gasLeak:
        return 'Gas leak emergency requiring specialized response';
      case EmergencyType.chemicalSpill:
        return 'Hazardous chemical spill requiring specialized cleanup';
      case EmergencyType.powerOutage:
        return 'Critical power outage affecting safety';
      case EmergencyType.missingPerson:
        return 'Missing person requiring search operation';
      case EmergencyType.animalAttack:
        return 'Animal attack incident requiring medical assistance';
      case EmergencyType.other:
        return 'Other emergency situation';
    }
  }

  EmergencyPriority get defaultPriority {
    switch (this) {
      case EmergencyType.medicalEmergency:
      case EmergencyType.fire:
      case EmergencyType.buildingCollapse:
      case EmergencyType.gasLeak:
      case EmergencyType.chemicalSpill:
        return EmergencyPriority.critical;
      case EmergencyType.accident:
      case EmergencyType.earthquake:
      case EmergencyType.landslide:
      case EmergencyType.animalAttack:
        return EmergencyPriority.high;
      case EmergencyType.flood:
      case EmergencyType.searchRescue:
      case EmergencyType.missingPerson:
        return EmergencyPriority.medium;
      case EmergencyType.powerOutage:
      case EmergencyType.other:
        return EmergencyPriority.low;
    }
  }
}

enum EmergencyPriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('critical')
  critical,
}

extension EmergencyPriorityExtension on EmergencyPriority {
  String get displayName {
    switch (this) {
      case EmergencyPriority.low:
        return 'Low';
      case EmergencyPriority.medium:
        return 'Medium';
      case EmergencyPriority.high:
        return 'High';
      case EmergencyPriority.critical:
        return 'Critical';
    }
  }

  String get description {
    switch (this) {
      case EmergencyPriority.low:
        return 'Low priority, can be addressed within 24 hours';
      case EmergencyPriority.medium:
        return 'Medium priority, should be addressed within 1 hour';
      case EmergencyPriority.high:
        return 'High priority, requires immediate attention within 15 minutes';
      case EmergencyPriority.critical:
        return 'Critical emergency, requires immediate response within 5 minutes';
    }
  }

  Duration get responseTime {
    switch (this) {
      case EmergencyPriority.low:
        return const Duration(hours: 24);
      case EmergencyPriority.medium:
        return const Duration(hours: 1);
      case EmergencyPriority.high:
        return const Duration(minutes: 15);
      case EmergencyPriority.critical:
        return const Duration(minutes: 5);
    }
  }

  int get weight {
    switch (this) {
      case EmergencyPriority.low:
        return 1;
      case EmergencyPriority.medium:
        return 2;
      case EmergencyPriority.high:
        return 3;
      case EmergencyPriority.critical:
        return 4;
    }
  }
}

enum EmergencyStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('acknowledged')
  acknowledged,
  @JsonValue('assigned')
  assigned,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('resolved')
  resolved,
  @JsonValue('cancelled')
  cancelled,
}

extension EmergencyStatusExtension on EmergencyStatus {
  String get displayName {
    switch (this) {
      case EmergencyStatus.pending:
        return 'Pending';
      case EmergencyStatus.acknowledged:
        return 'Acknowledged';
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
        return 'Emergency request received, awaiting acknowledgment';
      case EmergencyStatus.acknowledged:
        return 'Emergency acknowledged by control center';
      case EmergencyStatus.assigned:
        return 'Emergency assigned to operator and resources';
      case EmergencyStatus.inProgress:
        return 'Emergency response is currently in progress';
      case EmergencyStatus.resolved:
        return 'Emergency has been resolved successfully';
      case EmergencyStatus.cancelled:
        return 'Emergency request was cancelled';
    }
  }
}

enum WeatherCondition {
  @JsonValue('clear')
  clear,
  @JsonValue('cloudy')
  cloudy,
  @JsonValue('rainy')
  rainy,
  @JsonValue('stormy')
  stormy,
  @JsonValue('foggy')
  foggy,
  @JsonValue('snowy')
  snowy,
  @JsonValue('windy')
  windy,
  @JsonValue('unknown')
  unknown,
}

extension WeatherConditionExtension on WeatherCondition {
  String get displayName {
    switch (this) {
      case WeatherCondition.clear:
        return 'Clear';
      case WeatherCondition.cloudy:
        return 'Cloudy';
      case WeatherCondition.rainy:
        return 'Rainy';
      case WeatherCondition.stormy:
        return 'Stormy';
      case WeatherCondition.foggy:
        return 'Foggy';
      case WeatherCondition.snowy:
        return 'Snowy';
      case WeatherCondition.windy:
        return 'Windy';
      case WeatherCondition.unknown:
        return 'Unknown';
    }
  }

  bool get isDroneOperationSafe {
    switch (this) {
      case WeatherCondition.clear:
      case WeatherCondition.cloudy:
        return true;
      case WeatherCondition.rainy:
      case WeatherCondition.foggy:
      case WeatherCondition.windy:
        return false; // Depends on severity
      case WeatherCondition.stormy:
      case WeatherCondition.snowy:
        return false;
      case WeatherCondition.unknown:
        return false; // Better to be safe
    }
  }
}
