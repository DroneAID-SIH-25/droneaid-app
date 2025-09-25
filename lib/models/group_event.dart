import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'user.dart';
import 'emergency_request.dart';

part 'group_event.g.dart';

@JsonSerializable()
class GroupEvent {
  final String id;
  final String title;
  final String description;
  final EventType type;
  final EventStatus status;
  final EventSeverity severity;
  final Location location;
  final String? address;
  final double affectedRadius; // in kilometers
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startTime;
  final DateTime? endTime;
  final String createdBy;
  final List<String> assignedOperators;
  final List<String> emergencyRequestIds;
  final List<String> missionIds;
  final List<String> affectedAreas;
  final int estimatedAffectedPeople;
  final Map<String, dynamic>? metadata;
  final List<EventUpdate> updates;
  final List<String> resources;
  final String? weatherCondition;
  final bool isActive;
  final EventPriority priority;
  final String? coordinatingAgency;
  final String? contactPerson;
  final String? contactPhone;
  final String? contactEmail;
  final List<String> relatedEvents;
  final Map<String, dynamic>? statistics;

  GroupEvent({
    String? id,
    required this.title,
    required this.description,
    required this.type,
    this.status = EventStatus.active,
    required this.severity,
    required this.location,
    this.address,
    this.affectedRadius = 1.0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.startTime,
    this.endTime,
    required this.createdBy,
    List<String>? assignedOperators,
    List<String>? emergencyRequestIds,
    List<String>? missionIds,
    List<String>? affectedAreas,
    this.estimatedAffectedPeople = 0,
    this.metadata,
    List<EventUpdate>? updates,
    List<String>? resources,
    this.weatherCondition,
    this.isActive = true,
    this.priority = EventPriority.medium,
    this.coordinatingAgency,
    this.contactPerson,
    this.contactPhone,
    this.contactEmail,
    List<String>? relatedEvents,
    this.statistics,
  }) : id = id ?? const Uuid().v4(),
       assignedOperators = assignedOperators ?? [],
       emergencyRequestIds = emergencyRequestIds ?? [],
       missionIds = missionIds ?? [],
       affectedAreas = affectedAreas ?? [],
       updates = updates ?? [],
       resources = resources ?? [],
       relatedEvents = relatedEvents ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isOngoing =>
      status == EventStatus.active &&
      isActive &&
      (endTime == null || DateTime.now().isBefore(endTime!));

  bool get isResolved =>
      status == EventStatus.resolved || status == EventStatus.closed;

  bool get isCritical => severity == EventSeverity.critical;

  bool get requiresImmediateAttention =>
      severity == EventSeverity.critical || severity == EventSeverity.major;

  String get statusDisplay => status.displayName;
  String get severityDisplay => severity.displayName;
  String get typeDisplay => type.displayName;
  String get priorityDisplay => priority.displayName;

  Duration? get duration {
    if (startTime != null) {
      final end = endTime ?? DateTime.now();
      return end.difference(startTime!);
    }
    return null;
  }

  int get totalEmergencyRequests => emergencyRequestIds.length;
  int get totalMissions => missionIds.length;
  int get totalAssignedOperators => assignedOperators.length;

  double get completionPercentage {
    if (totalMissions == 0) return 0.0;

    // This would need to be calculated based on actual mission statuses
    // For now, return a simple calculation based on event status
    switch (status) {
      case EventStatus.active:
        return 25.0;
      case EventStatus.inProgress:
        return 60.0;
      case EventStatus.resolved:
        return 100.0;
      case EventStatus.closed:
        return 100.0;
      case EventStatus.cancelled:
        return 0.0;
    }
  }

  factory GroupEvent.fromJson(Map<String, dynamic> json) =>
      _$GroupEventFromJson(json);

  Map<String, dynamic> toJson() => _$GroupEventToJson(this);

  GroupEvent copyWith({
    String? id,
    String? title,
    String? description,
    EventType? type,
    EventStatus? status,
    EventSeverity? severity,
    Location? location,
    String? address,
    double? affectedRadius,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startTime,
    DateTime? endTime,
    String? createdBy,
    List<String>? assignedOperators,
    List<String>? emergencyRequestIds,
    List<String>? missionIds,
    List<String>? affectedAreas,
    int? estimatedAffectedPeople,
    Map<String, dynamic>? metadata,
    List<EventUpdate>? updates,
    List<String>? resources,
    String? weatherCondition,
    bool? isActive,
    EventPriority? priority,
    String? coordinatingAgency,
    String? contactPerson,
    String? contactPhone,
    String? contactEmail,
    List<String>? relatedEvents,
    Map<String, dynamic>? statistics,
  }) {
    return GroupEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      severity: severity ?? this.severity,
      location: location ?? this.location,
      address: address ?? this.address,
      affectedRadius: affectedRadius ?? this.affectedRadius,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdBy: createdBy ?? this.createdBy,
      assignedOperators: assignedOperators ?? this.assignedOperators,
      emergencyRequestIds: emergencyRequestIds ?? this.emergencyRequestIds,
      missionIds: missionIds ?? this.missionIds,
      affectedAreas: affectedAreas ?? this.affectedAreas,
      estimatedAffectedPeople:
          estimatedAffectedPeople ?? this.estimatedAffectedPeople,
      metadata: metadata ?? this.metadata,
      updates: updates ?? this.updates,
      resources: resources ?? this.resources,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      coordinatingAgency: coordinatingAgency ?? this.coordinatingAgency,
      contactPerson: contactPerson ?? this.contactPerson,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      relatedEvents: relatedEvents ?? this.relatedEvents,
      statistics: statistics ?? this.statistics,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupEvent && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GroupEvent{id: $id, title: $title, type: $type, severity: $severity, status: $status}';
  }
}

@JsonSerializable()
class EventUpdate {
  final String id;
  final String eventId;
  final String updatedBy;
  final String message;
  final EventStatus? newStatus;
  final DateTime timestamp;
  final Location? location;
  final Map<String, dynamic>? data;
  final List<String> attachments;

  EventUpdate({
    String? id,
    required this.eventId,
    required this.updatedBy,
    required this.message,
    this.newStatus,
    DateTime? timestamp,
    this.location,
    this.data,
    List<String>? attachments,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now(),
       attachments = attachments ?? [];

  factory EventUpdate.fromJson(Map<String, dynamic> json) =>
      _$EventUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$EventUpdateToJson(this);

  @override
  String toString() {
    return 'EventUpdate{id: $id, message: $message, timestamp: $timestamp}';
  }
}

enum EventType {
  @JsonValue('natural_disaster')
  naturalDisaster,
  @JsonValue('fire_incident')
  fireIncident,
  @JsonValue('flood')
  flood,
  @JsonValue('earthquake')
  earthquake,
  @JsonValue('hurricane')
  hurricane,
  @JsonValue('tornado')
  tornado,
  @JsonValue('landslide')
  landslide,
  @JsonValue('tsunami')
  tsunami,
  @JsonValue('volcanic_eruption')
  volcanicEruption,
  @JsonValue('industrial_accident')
  industrialAccident,
  @JsonValue('chemical_spill')
  chemicalSpill,
  @JsonValue('building_collapse')
  buildingCollapse,
  @JsonValue('mass_casualty')
  massCasualty,
  @JsonValue('pandemic_outbreak')
  pandemicOutbreak,
  @JsonValue('terrorist_attack')
  terroristAttack,
  @JsonValue('civil_unrest')
  civilUnrest,
  @JsonValue('cyber_attack')
  cyberAttack,
  @JsonValue('power_grid_failure')
  powerGridFailure,
  @JsonValue('transportation_accident')
  transportationAccident,
  @JsonValue('other')
  other,
}

extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.naturalDisaster:
        return 'Natural Disaster';
      case EventType.fireIncident:
        return 'Fire Incident';
      case EventType.flood:
        return 'Flood';
      case EventType.earthquake:
        return 'Earthquake';
      case EventType.hurricane:
        return 'Hurricane';
      case EventType.tornado:
        return 'Tornado';
      case EventType.landslide:
        return 'Landslide';
      case EventType.tsunami:
        return 'Tsunami';
      case EventType.volcanicEruption:
        return 'Volcanic Eruption';
      case EventType.industrialAccident:
        return 'Industrial Accident';
      case EventType.chemicalSpill:
        return 'Chemical Spill';
      case EventType.buildingCollapse:
        return 'Building Collapse';
      case EventType.massCasualty:
        return 'Mass Casualty';
      case EventType.pandemicOutbreak:
        return 'Pandemic Outbreak';
      case EventType.terroristAttack:
        return 'Terrorist Attack';
      case EventType.civilUnrest:
        return 'Civil Unrest';
      case EventType.cyberAttack:
        return 'Cyber Attack';
      case EventType.powerGridFailure:
        return 'Power Grid Failure';
      case EventType.transportationAccident:
        return 'Transportation Accident';
      case EventType.other:
        return 'Other';
    }
  }

  String get description {
    switch (this) {
      case EventType.naturalDisaster:
        return 'Large-scale natural disaster event';
      case EventType.fireIncident:
        return 'Fire emergency requiring coordinated response';
      case EventType.flood:
        return 'Flooding event affecting multiple areas';
      case EventType.earthquake:
        return 'Seismic event requiring emergency response';
      case EventType.hurricane:
        return 'Hurricane or tropical cyclone event';
      case EventType.tornado:
        return 'Tornado emergency event';
      case EventType.landslide:
        return 'Landslide or mudslide emergency';
      case EventType.tsunami:
        return 'Tsunami warning or event';
      case EventType.volcanicEruption:
        return 'Volcanic eruption emergency';
      case EventType.industrialAccident:
        return 'Industrial facility accident';
      case EventType.chemicalSpill:
        return 'Hazardous chemical spill event';
      case EventType.buildingCollapse:
        return 'Structural collapse emergency';
      case EventType.massCasualty:
        return 'Mass casualty incident';
      case EventType.pandemicOutbreak:
        return 'Disease outbreak or pandemic';
      case EventType.terroristAttack:
        return 'Terrorist attack or security threat';
      case EventType.civilUnrest:
        return 'Civil unrest or riot situation';
      case EventType.cyberAttack:
        return 'Cyber security attack on infrastructure';
      case EventType.powerGridFailure:
        return 'Widespread power grid failure';
      case EventType.transportationAccident:
        return 'Major transportation accident';
      case EventType.other:
        return 'Other emergency event type';
    }
  }

  EventSeverity get defaultSeverity {
    switch (this) {
      case EventType.earthquake:
      case EventType.hurricane:
      case EventType.tsunami:
      case EventType.volcanicEruption:
      case EventType.terroristAttack:
        return EventSeverity.critical;
      case EventType.tornado:
      case EventType.buildingCollapse:
      case EventType.massCasualty:
      case EventType.industrialAccident:
        return EventSeverity.major;
      case EventType.fireIncident:
      case EventType.flood:
      case EventType.landslide:
      case EventType.chemicalSpill:
        return EventSeverity.moderate;
      default:
        return EventSeverity.minor;
    }
  }
}

enum EventStatus {
  @JsonValue('active')
  active,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('resolved')
  resolved,
  @JsonValue('closed')
  closed,
  @JsonValue('cancelled')
  cancelled,
}

extension EventStatusExtension on EventStatus {
  String get displayName {
    switch (this) {
      case EventStatus.active:
        return 'Active';
      case EventStatus.inProgress:
        return 'In Progress';
      case EventStatus.resolved:
        return 'Resolved';
      case EventStatus.closed:
        return 'Closed';
      case EventStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get description {
    switch (this) {
      case EventStatus.active:
        return 'Event is active and requires response';
      case EventStatus.inProgress:
        return 'Response operations are in progress';
      case EventStatus.resolved:
        return 'Event has been resolved';
      case EventStatus.closed:
        return 'Event is closed and archived';
      case EventStatus.cancelled:
        return 'Event was cancelled or false alarm';
    }
  }
}

enum EventSeverity {
  @JsonValue('minor')
  minor,
  @JsonValue('moderate')
  moderate,
  @JsonValue('major')
  major,
  @JsonValue('critical')
  critical,
}

extension EventSeverityExtension on EventSeverity {
  String get displayName {
    switch (this) {
      case EventSeverity.minor:
        return 'Minor';
      case EventSeverity.moderate:
        return 'Moderate';
      case EventSeverity.major:
        return 'Major';
      case EventSeverity.critical:
        return 'Critical';
    }
  }

  String get description {
    switch (this) {
      case EventSeverity.minor:
        return 'Minor impact, limited response required';
      case EventSeverity.moderate:
        return 'Moderate impact, standard response protocols';
      case EventSeverity.major:
        return 'Major impact, significant resources required';
      case EventSeverity.critical:
        return 'Critical impact, maximum response effort needed';
    }
  }

  int get weight {
    switch (this) {
      case EventSeverity.minor:
        return 1;
      case EventSeverity.moderate:
        return 2;
      case EventSeverity.major:
        return 3;
      case EventSeverity.critical:
        return 4;
    }
  }
}

enum EventPriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('critical')
  critical,
}

extension EventPriorityExtension on EventPriority {
  String get displayName {
    switch (this) {
      case EventPriority.low:
        return 'Low';
      case EventPriority.medium:
        return 'Medium';
      case EventPriority.high:
        return 'High';
      case EventPriority.critical:
        return 'Critical';
    }
  }

  String get description {
    switch (this) {
      case EventPriority.low:
        return 'Low priority event';
      case EventPriority.medium:
        return 'Medium priority event';
      case EventPriority.high:
        return 'High priority event';
      case EventPriority.critical:
        return 'Critical priority event requiring immediate attention';
    }
  }

  int get weight {
    switch (this) {
      case EventPriority.low:
        return 1;
      case EventPriority.medium:
        return 2;
      case EventPriority.high:
        return 3;
      case EventPriority.critical:
        return 4;
    }
  }
}
