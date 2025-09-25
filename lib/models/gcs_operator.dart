import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'user.dart';

part 'gcs_operator.g.dart';

@JsonSerializable()
class GCSOperator {
  final String id;
  final String operatorId;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String organization;
  final String designation;
  final OperatorRole role;
  final List<String> authorizedDroneIds;
  final List<String> certifications;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isOnDuty;
  final String? profileImageUrl;
  final Location? currentLocation;
  final int experienceYears;
  final int totalMissionsCompleted;
  final double rating;

  GCSOperator({
    String? id,
    required this.operatorId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.organization,
    required this.designation,
    this.role = OperatorRole.operator,
    List<String>? authorizedDroneIds,
    List<String>? certifications,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
    this.isOnDuty = false,
    this.profileImageUrl,
    this.currentLocation,
    this.experienceYears = 0,
    this.totalMissionsCompleted = 0,
    this.rating = 5.0,
  }) : id = id ?? const Uuid().v4(),
       authorizedDroneIds = authorizedDroneIds ?? [],
       certifications = certifications ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  String get fullName => '$firstName $lastName';

  String get displayName => fullName.isNotEmpty ? fullName : email;

  bool get canOperateDrone =>
      authorizedDroneIds.isNotEmpty && isActive && isOnDuty;

  String get statusDisplay => isOnDuty ? 'On Duty' : 'Off Duty';

  factory GCSOperator.fromJson(Map<String, dynamic> json) =>
      _$GCSOperatorFromJson(json);

  Map<String, dynamic> toJson() => _$GCSOperatorToJson(this);

  GCSOperator copyWith({
    String? id,
    String? operatorId,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? organization,
    String? designation,
    OperatorRole? role,
    List<String>? authorizedDroneIds,
    List<String>? certifications,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isOnDuty,
    String? profileImageUrl,
    Location? currentLocation,
    int? experienceYears,
    int? totalMissionsCompleted,
    double? rating,
  }) {
    return GCSOperator(
      id: id ?? this.id,
      operatorId: operatorId ?? this.operatorId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      organization: organization ?? this.organization,
      designation: designation ?? this.designation,
      role: role ?? this.role,
      authorizedDroneIds: authorizedDroneIds ?? this.authorizedDroneIds,
      certifications: certifications ?? this.certifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isOnDuty: isOnDuty ?? this.isOnDuty,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      currentLocation: currentLocation ?? this.currentLocation,
      experienceYears: experienceYears ?? this.experienceYears,
      totalMissionsCompleted:
          totalMissionsCompleted ?? this.totalMissionsCompleted,
      rating: rating ?? this.rating,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GCSOperator &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          operatorId == other.operatorId;

  @override
  int get hashCode => id.hashCode ^ operatorId.hashCode;

  @override
  String toString() {
    return 'GCSOperator{id: $id, operatorId: $operatorId, fullName: $fullName, organization: $organization}';
  }
}

enum OperatorRole {
  @JsonValue('operator')
  operator,
  @JsonValue('supervisor')
  supervisor,
  @JsonValue('administrator')
  administrator,
  @JsonValue('field_coordinator')
  fieldCoordinator,
}

extension OperatorRoleExtension on OperatorRole {
  String get displayName {
    switch (this) {
      case OperatorRole.operator:
        return 'Operator';
      case OperatorRole.supervisor:
        return 'Supervisor';
      case OperatorRole.administrator:
        return 'Administrator';
      case OperatorRole.fieldCoordinator:
        return 'Field Coordinator';
    }
  }

  String get description {
    switch (this) {
      case OperatorRole.operator:
        return 'Basic drone operation and mission execution';
      case OperatorRole.supervisor:
        return 'Supervise operations and approve missions';
      case OperatorRole.administrator:
        return 'Full system administration and user management';
      case OperatorRole.fieldCoordinator:
        return 'Coordinate field operations and emergency response';
    }
  }

  List<String> get permissions {
    switch (this) {
      case OperatorRole.operator:
        return ['operate_drone', 'view_missions', 'update_mission_status'];
      case OperatorRole.supervisor:
        return [
          'operate_drone',
          'view_missions',
          'update_mission_status',
          'assign_missions',
          'approve_missions',
          'view_all_operators',
        ];
      case OperatorRole.administrator:
        return [
          'operate_drone',
          'view_missions',
          'update_mission_status',
          'assign_missions',
          'approve_missions',
          'view_all_operators',
          'manage_users',
          'manage_drones',
          'system_configuration',
        ];
      case OperatorRole.fieldCoordinator:
        return [
          'view_missions',
          'assign_missions',
          'coordinate_response',
          'communicate_agencies',
          'manage_resources',
        ];
    }
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }
}
