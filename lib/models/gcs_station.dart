import 'package:uuid/uuid.dart';
import 'user.dart';

class GCSStation {
  final String id;
  final String name;
  final String code;
  final String location;
  final LocationData coordinates;
  final String? address;
  final List<String> operatorIds;
  final StationStatus status;
  final Map<String, dynamic> equipment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String organizationId;
  final String? description;
  final int maxCapacity;
  final int currentOperators;
  final List<String> certifications;
  final String contactEmail;
  final String contactPhone;
  final String? emergencyContact;
  final Map<String, dynamic>? specifications;
  final List<String> assignedEventIds;
  final StationType type;
  final bool isActive;
  final DateTime? lastMaintenanceDate;
  final DateTime? nextMaintenanceDate;

  GCSStation({
    String? id,
    required this.name,
    required this.code,
    required this.location,
    required this.coordinates,
    this.address,
    List<String>? operatorIds,
    this.status = StationStatus.operational,
    Map<String, dynamic>? equipment,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.organizationId,
    this.description,
    this.maxCapacity = 10,
    this.currentOperators = 0,
    List<String>? certifications,
    required this.contactEmail,
    required this.contactPhone,
    this.emergencyContact,
    this.specifications,
    List<String>? assignedEventIds,
    this.type = StationType.fixed,
    this.isActive = true,
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
  }) : id = id ?? const Uuid().v4(),
       operatorIds = operatorIds ?? [],
       equipment = equipment ?? {},
       assignedEventIds = assignedEventIds ?? [],
       certifications = certifications ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isOperational => status == StationStatus.operational && isActive;

  bool get hasCapacity => currentOperators < maxCapacity;

  double get capacityPercentage =>
      maxCapacity > 0 ? (currentOperators / maxCapacity) * 100 : 0.0;

  bool get needsMaintenance {
    if (nextMaintenanceDate == null) return false;
    return DateTime.now().isAfter(nextMaintenanceDate!) ||
        DateTime.now().isAtSameMomentAs(nextMaintenanceDate!);
  }

  String get statusDisplay => status.displayName;
  String get typeDisplay => type.displayName;

  int get assignedEvents => assignedEventIds.length;

  bool get canAcceptNewEvents =>
      isOperational && hasCapacity && !needsMaintenance;

  factory GCSStation.fromJson(Map<String, dynamic> json) {
    return GCSStation(
      id: json['id'] as String?,
      name: json['name'] as String,
      code: json['code'] as String,
      location: json['location'] as String,
      coordinates: LocationData.fromJson(
        json['coordinates'] as Map<String, dynamic>,
      ),
      address: json['address'] as String?,
      operatorIds: (json['operatorIds'] as List?)?.cast<String>(),
      status: StationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => StationStatus.operational,
      ),
      equipment: json['equipment'] as Map<String, dynamic>? ?? {},
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      organizationId: json['organizationId'] as String,
      description: json['description'] as String?,
      maxCapacity: json['maxCapacity'] as int? ?? 10,
      currentOperators: json['currentOperators'] as int? ?? 0,
      certifications: (json['certifications'] as List?)?.cast<String>(),
      contactEmail: json['contactEmail'] as String,
      contactPhone: json['contactPhone'] as String,
      emergencyContact: json['emergencyContact'] as String?,
      specifications: json['specifications'] as Map<String, dynamic>?,
      assignedEventIds: (json['assignedEventIds'] as List?)?.cast<String>(),
      type: StationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => StationType.fixed,
      ),
      isActive: json['isActive'] as bool? ?? true,
      lastMaintenanceDate: json['lastMaintenanceDate'] != null
          ? DateTime.parse(json['lastMaintenanceDate'] as String)
          : null,
      nextMaintenanceDate: json['nextMaintenanceDate'] != null
          ? DateTime.parse(json['nextMaintenanceDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'location': location,
      'coordinates': coordinates.toJson(),
      'address': address,
      'operatorIds': operatorIds,
      'status': status.name,
      'equipment': equipment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'organizationId': organizationId,
      'description': description,
      'maxCapacity': maxCapacity,
      'currentOperators': currentOperators,
      'certifications': certifications,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'emergencyContact': emergencyContact,
      'specifications': specifications,
      'assignedEventIds': assignedEventIds,
      'type': type.name,
      'isActive': isActive,
      'lastMaintenanceDate': lastMaintenanceDate?.toIso8601String(),
      'nextMaintenanceDate': nextMaintenanceDate?.toIso8601String(),
    };
  }

  GCSStation copyWith({
    String? id,
    String? name,
    String? code,
    String? location,
    LocationData? coordinates,
    String? address,
    List<String>? operatorIds,
    StationStatus? status,
    Map<String, dynamic>? equipment,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? organizationId,
    String? description,
    int? maxCapacity,
    int? currentOperators,
    List<String>? certifications,
    String? contactEmail,
    String? contactPhone,
    String? emergencyContact,
    Map<String, dynamic>? specifications,
    List<String>? assignedEventIds,
    StationType? type,
    bool? isActive,
    DateTime? lastMaintenanceDate,
    DateTime? nextMaintenanceDate,
  }) {
    return GCSStation(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      location: location ?? this.location,
      coordinates: coordinates ?? this.coordinates,
      address: address ?? this.address,
      operatorIds: operatorIds ?? this.operatorIds,
      status: status ?? this.status,
      equipment: equipment ?? this.equipment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      organizationId: organizationId ?? this.organizationId,
      description: description ?? this.description,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      currentOperators: currentOperators ?? this.currentOperators,
      certifications: certifications ?? this.certifications,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      specifications: specifications ?? this.specifications,
      assignedEventIds: assignedEventIds ?? this.assignedEventIds,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
      nextMaintenanceDate: nextMaintenanceDate ?? this.nextMaintenanceDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GCSStation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code;

  @override
  int get hashCode => id.hashCode ^ code.hashCode;

  @override
  String toString() {
    return 'GCSStation{id: $id, name: $name, code: $code, location: $location, status: $status}';
  }
}

enum StationStatus { operational, maintenance, offline, emergency, standby }

extension StationStatusExtension on StationStatus {
  String get displayName {
    switch (this) {
      case StationStatus.operational:
        return 'Operational';
      case StationStatus.maintenance:
        return 'Under Maintenance';
      case StationStatus.offline:
        return 'Offline';
      case StationStatus.emergency:
        return 'Emergency Mode';
      case StationStatus.standby:
        return 'Standby';
    }
  }

  String get description {
    switch (this) {
      case StationStatus.operational:
        return 'Station is fully operational and ready for missions';
      case StationStatus.maintenance:
        return 'Station is undergoing scheduled maintenance';
      case StationStatus.offline:
        return 'Station is currently offline';
      case StationStatus.emergency:
        return 'Station is operating in emergency response mode';
      case StationStatus.standby:
        return 'Station is on standby, ready to be activated';
    }
  }
}

enum StationType { fixed, mobile, temporary, emergency }

extension StationTypeExtension on StationType {
  String get displayName {
    switch (this) {
      case StationType.fixed:
        return 'Fixed Station';
      case StationType.mobile:
        return 'Mobile Station';
      case StationType.temporary:
        return 'Temporary Station';
      case StationType.emergency:
        return 'Emergency Station';
    }
  }

  String get description {
    switch (this) {
      case StationType.fixed:
        return 'Permanent ground control station';
      case StationType.mobile:
        return 'Mobile ground control unit';
      case StationType.temporary:
        return 'Temporary setup for specific events';
      case StationType.emergency:
        return 'Emergency response station';
    }
  }
}
