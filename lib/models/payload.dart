import 'package:uuid/uuid.dart';

class Payload {
  final String id;
  final PayloadType type;
  final double weight;
  final String description;
  final List<String> specialRequirements;
  final Map<String, dynamic> specifications;
  final DateTime createdAt;
  final String? packageId;
  final bool isFragile;
  final bool requiresTemperatureControl;
  final double? temperatureRange;
  final String? handlingInstructions;

  Payload({
    String? id,
    required this.type,
    required this.weight,
    required this.description,
    List<String>? specialRequirements,
    Map<String, dynamic>? specifications,
    DateTime? createdAt,
    this.packageId,
    this.isFragile = false,
    this.requiresTemperatureControl = false,
    this.temperatureRange,
    this.handlingInstructions,
  }) : id = id ?? const Uuid().v4(),
       specialRequirements = specialRequirements ?? [],
       specifications = specifications ?? {},
       createdAt = createdAt ?? DateTime.now();

  String get typeDisplay => type.displayName;
  String get weightDisplay => '${weight.toStringAsFixed(1)} kg';

  bool get hasSpecialRequirements => specialRequirements.isNotEmpty;

  bool get requiresSpecialHandling =>
      isFragile || requiresTemperatureControl || hasSpecialRequirements;

  factory Payload.fromJson(Map<String, dynamic> json) {
    return Payload(
      id: json['id'] as String?,
      type: PayloadType.values.firstWhere((e) => e.name == json['type']),
      weight: (json['weight'] as num).toDouble(),
      description: json['description'] as String,
      specialRequirements: (json['specialRequirements'] as List?)
          ?.cast<String>(),
      specifications: json['specifications'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      packageId: json['packageId'] as String?,
      isFragile: json['isFragile'] as bool? ?? false,
      requiresTemperatureControl:
          json['requiresTemperatureControl'] as bool? ?? false,
      temperatureRange: (json['temperatureRange'] as num?)?.toDouble(),
      handlingInstructions: json['handlingInstructions'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'weight': weight,
      'description': description,
      'specialRequirements': specialRequirements,
      'specifications': specifications,
      'createdAt': createdAt.toIso8601String(),
      'packageId': packageId,
      'isFragile': isFragile,
      'requiresTemperatureControl': requiresTemperatureControl,
      'temperatureRange': temperatureRange,
      'handlingInstructions': handlingInstructions,
    };
  }

  Payload copyWith({
    String? id,
    PayloadType? type,
    double? weight,
    String? description,
    List<String>? specialRequirements,
    Map<String, dynamic>? specifications,
    DateTime? createdAt,
    String? packageId,
    bool? isFragile,
    bool? requiresTemperatureControl,
    double? temperatureRange,
    String? handlingInstructions,
  }) {
    return Payload(
      id: id ?? this.id,
      type: type ?? this.type,
      weight: weight ?? this.weight,
      description: description ?? this.description,
      specialRequirements: specialRequirements ?? this.specialRequirements,
      specifications: specifications ?? this.specifications,
      createdAt: createdAt ?? this.createdAt,
      packageId: packageId ?? this.packageId,
      isFragile: isFragile ?? this.isFragile,
      requiresTemperatureControl:
          requiresTemperatureControl ?? this.requiresTemperatureControl,
      temperatureRange: temperatureRange ?? this.temperatureRange,
      handlingInstructions: handlingInstructions ?? this.handlingInstructions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Payload && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Payload{id: $id, type: $type, weight: $weight, description: $description}';
  }
}

enum PayloadType {
  medical,
  food,
  lifeSavingEquipment,
  water,
  medication,
  firstAid,
  communicationDevice,
  emergency,
  rescue,
  other,
}

extension PayloadTypeExtension on PayloadType {
  String get displayName {
    switch (this) {
      case PayloadType.medical:
        return 'Medical Supplies';
      case PayloadType.food:
        return 'Food & Nutrition';
      case PayloadType.lifeSavingEquipment:
        return 'Life-saving Equipment';
      case PayloadType.water:
        return 'Water & Hydration';
      case PayloadType.medication:
        return 'Medication';
      case PayloadType.firstAid:
        return 'First Aid Kit';
      case PayloadType.communicationDevice:
        return 'Communication Device';
      case PayloadType.emergency:
        return 'Emergency Supplies';
      case PayloadType.rescue:
        return 'Rescue Equipment';
      case PayloadType.other:
        return 'Other';
    }
  }

  String get description {
    switch (this) {
      case PayloadType.medical:
        return 'Medical supplies and equipment for emergency care';
      case PayloadType.food:
        return 'Emergency food rations and nutrition supplies';
      case PayloadType.lifeSavingEquipment:
        return 'Life jackets, masks, flotation devices, safety equipment';
      case PayloadType.water:
        return 'Clean water and hydration supplies';
      case PayloadType.medication:
        return 'Essential medications and pharmaceutical supplies';
      case PayloadType.firstAid:
        return 'First aid kits and basic medical supplies';
      case PayloadType.communicationDevice:
        return 'Communication devices for emergency coordination';
      case PayloadType.emergency:
        return 'General emergency supplies and equipment';
      case PayloadType.rescue:
        return 'Specialized rescue equipment and tools';
      case PayloadType.other:
        return 'Other specialized payload types';
    }
  }

  String get icon {
    switch (this) {
      case PayloadType.medical:
        return '🏥';
      case PayloadType.food:
        return '🥫';
      case PayloadType.lifeSavingEquipment:
        return '🦺';
      case PayloadType.water:
        return '💧';
      case PayloadType.medication:
        return '💊';
      case PayloadType.firstAid:
        return '🩹';
      case PayloadType.communicationDevice:
        return '📡';
      case PayloadType.emergency:
        return '🚨';
      case PayloadType.rescue:
        return '⛑️';
      case PayloadType.other:
        return '📦';
    }
  }

  List<String> get commonRequirements {
    switch (this) {
      case PayloadType.medical:
        return [
          'Temperature controlled',
          'Sterile packaging',
          'Quick delivery',
        ];
      case PayloadType.food:
        return [
          'Temperature controlled',
          'Sealed packaging',
          'Expiration tracking',
        ];
      case PayloadType.lifeSavingEquipment:
        return ['Impact resistant', 'Weatherproof', 'Quick deployment'];
      case PayloadType.water:
        return [
          'Sealed containers',
          'Contamination prevention',
          'Volume tracking',
        ];
      case PayloadType.medication:
        return [
          'Temperature controlled',
          'Light protected',
          'Expiration critical',
        ];
      case PayloadType.firstAid:
        return ['Sterile packaging', 'Organization maintained', 'Quick access'];
      case PayloadType.communicationDevice:
        return ['Shock resistant', 'Weatherproof', 'Battery protected'];
      case PayloadType.emergency:
        return ['Weather resistant', 'Quick deployment', 'Organized packaging'];
      case PayloadType.rescue:
        return ['Impact resistant', 'Quick deployment', 'Operational ready'];
      case PayloadType.other:
        return ['Handle with care', 'Secure packaging'];
    }
  }

  double get defaultWeight {
    switch (this) {
      case PayloadType.medical:
        return 2.0;
      case PayloadType.food:
        return 5.0;
      case PayloadType.lifeSavingEquipment:
        return 3.0;
      case PayloadType.water:
        return 8.0;
      case PayloadType.medication:
        return 0.5;
      case PayloadType.firstAid:
        return 1.5;
      case PayloadType.communicationDevice:
        return 1.0;
      case PayloadType.emergency:
        return 4.0;
      case PayloadType.rescue:
        return 6.0;
      case PayloadType.other:
        return 2.5;
    }
  }
}

class PayloadConfiguration {
  final PayloadType type;
  final double maxWeight;
  final List<String> compatibleDrones;
  final List<String> requiredCapabilities;
  final bool requiresSpecialHandling;
  final Map<String, dynamic> constraints;

  PayloadConfiguration({
    required this.type,
    required this.maxWeight,
    List<String>? compatibleDrones,
    List<String>? requiredCapabilities,
    this.requiresSpecialHandling = false,
    Map<String, dynamic>? constraints,
  }) : compatibleDrones = compatibleDrones ?? [],
       requiredCapabilities = requiredCapabilities ?? [],
       constraints = constraints ?? {};

  bool isDroneCompatible(String droneId) {
    return compatibleDrones.isEmpty || compatibleDrones.contains(droneId);
  }

  bool hasRequiredCapabilities(List<String> droneCapabilities) {
    return requiredCapabilities.every(
      (capability) => droneCapabilities.contains(capability),
    );
  }
}
