import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';

import '../../providers/group_management_provider.dart';
import '../../providers/mission_provider.dart';
import '../../models/group_event.dart';
import '../../models/mission.dart';
import '../../models/drone.dart';
import '../../models/payload.dart';
import '../../models/user.dart';
import '../../models/emergency_request.dart';

class EnhancedCreateMissionScreen extends StatefulWidget {
  const EnhancedCreateMissionScreen({super.key});

  @override
  State<EnhancedCreateMissionScreen> createState() =>
      _EnhancedCreateMissionScreenState();
}

class _EnhancedCreateMissionScreenState
    extends State<EnhancedCreateMissionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _missionDescriptionController = TextEditingController();
  final _targetLocationController = TextEditingController();
  final _payloadDescriptionController = TextEditingController();
  final _payloadWeightController = TextEditingController();
  final _specialInstructionsController = TextEditingController();

  // Form values
  String? _selectedGroupId;
  MissionPriority _selectedPriority = MissionPriority.medium;
  LocationData? _targetLocation;
  PayloadType? _selectedPayloadType;
  double _payloadWeight = 0.0;
  List<String> _payloadRequirements = [];
  String? _selectedDroneId;
  DateTime _scheduledTime = DateTime.now().add(const Duration(hours: 1));
  bool _isSubmitting = false;
  bool _isBulkCreation = false;
  int _bulkQuantity = 1;

  // Mission naming
  String _generatedMissionName = '';

  // Map related
  final MapController _mapController = MapController();
  LatLng? _selectedMapLocation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _updateMissionName();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _missionDescriptionController.dispose();
    _targetLocationController.dispose();
    _payloadDescriptionController.dispose();
    _payloadWeightController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {
      _currentStep = _tabController.index;
    });
  }

  void _updateMissionName() {
    if (_selectedGroupId != null && _selectedDroneId != null) {
      final groupProvider = Provider.of<GroupManagementProvider>(
        context,
        listen: false,
      );
      final group = groupProvider.events.firstWhere(
        (g) => g.id == _selectedGroupId,
        orElse: () => GroupEvent(
          title: 'UNKNOWN',
          description: 'Unknown event',
          type: EventType.other,
          severity: EventSeverity.minor,
          location: LocationData(latitude: 0, longitude: 0),
          createdBy: 'system',
        ),
      );

      final priority = _selectedPriority.name.toUpperCase();
      final event = group.type.name.toUpperCase();
      final droneId = _selectedDroneId!.toUpperCase();

      _generatedMissionName = '${priority}_${event}_$droneId';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Mission'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Column(
            children: [
              _buildProgressIndicator(),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'Group'),
                  Tab(text: 'Mission'),
                  Tab(text: 'Payload'),
                  Tab(text: 'Drone'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Consumer2<GroupManagementProvider, MissionProvider>(
        builder: (context, groupProvider, missionProvider, child) {
          return Form(
            key: _formKey,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGroupSelectionStep(groupProvider),
                _buildMissionDetailsStep(),
                _buildPayloadConfigurationStep(),
                _buildDroneSelectionStep(missionProvider),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LinearProgressIndicator(
        value: (_currentStep + 1) / 4,
        backgroundColor: Colors.white24,
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  Widget _buildGroupSelectionStep(GroupManagementProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Group Selection',
            'Select the event group for this mission',
          ),
          const SizedBox(height: 24),
          _buildGroupDropdown(provider),
          if (_selectedGroupId != null) ...[
            const SizedBox(height: 24),
            _buildGroupPreview(provider),
          ],
          const SizedBox(height: 24),
          _buildBulkCreationToggle(),
        ],
      ),
    );
  }

  Widget _buildMissionDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Mission Details',
            'Configure mission priority and location',
          ),
          const SizedBox(height: 24),
          _buildPrioritySelection(),
          const SizedBox(height: 24),
          _buildLocationSection(),
          const SizedBox(height: 24),
          _buildMissionDescription(),
          const SizedBox(height: 24),
          _buildScheduleSection(),
          if (_generatedMissionName.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildMissionNamePreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildPayloadConfigurationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Payload Configuration',
            'Configure the mission payload details',
          ),
          const SizedBox(height: 24),
          _buildPayloadTypeSelection(),
          if (_selectedPayloadType != null) ...[
            const SizedBox(height: 24),
            _buildPayloadDetails(),
          ],
        ],
      ),
    );
  }

  Widget _buildDroneSelectionStep(MissionProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Drone Selection',
            'Select an available drone for this mission',
          ),
          const SizedBox(height: 24),
          _buildDroneDropdown(provider),
          if (_selectedDroneId != null) ...[
            const SizedBox(height: 24),
            _buildDroneDetails(provider),
          ],
          const SizedBox(height: 24),
          _buildMissionSummary(),
        ],
      ),
    );
  }

  Widget _buildStepHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildGroupDropdown(GroupManagementProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Event Group',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedGroupId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Choose event group',
              ),
              validator: (value) {
                if (value == null) {
                  return 'Please select an event group';
                }
                return null;
              },
              items: provider.events.map((group) {
                return DropdownMenuItem(
                  value: group.id,
                  child: Text(
                    '${group.title} - ${group.type.displayName}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGroupId = value;
                  _updateMissionName();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupPreview(GroupManagementProvider provider) {
    final group = provider.events.firstWhere((g) => g.id == _selectedGroupId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Group Preview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Name', group.title),
            _buildInfoRow('Type', group.type.displayName),
            _buildInfoRow('Status', group.status.displayName),
            _buildInfoRow('Severity', group.severity.displayName),
            _buildInfoRow('Priority', group.priority.displayName),
            _buildInfoRow(
              'Location',
              '${group.location.latitude.toStringAsFixed(4)}, ${group.location.longitude.toStringAsFixed(4)}',
            ),
            if (group.description.isNotEmpty)
              _buildInfoRow('Description', group.description),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkCreationToggle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Switch(
                  value: _isBulkCreation,
                  onChanged: (value) {
                    setState(() {
                      _isBulkCreation = value;
                    });
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  'Bulk Mission Creation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (_isBulkCreation) ...[
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _bulkQuantity.toString(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Number of missions',
                  hintText: 'Enter quantity',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  final quantity = int.tryParse(value);
                  if (quantity == null || quantity < 1 || quantity > 10) {
                    return 'Quantity must be between 1 and 10';
                  }
                  return null;
                },
                onChanged: (value) {
                  _bulkQuantity = int.tryParse(value) ?? 1;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mission Priority',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: MissionPriority.values.map((priority) {
                return ChoiceChip(
                  label: Text(priority.displayName),
                  selected: _selectedPriority == priority,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedPriority = priority;
                        _updateMissionName();
                      });
                    }
                  },
                  backgroundColor: _getPriorityColor(priority).withOpacity(0.1),
                  selectedColor: _getPriorityColor(priority),
                  labelStyle: TextStyle(
                    color: _selectedPriority == priority
                        ? Colors.white
                        : _getPriorityColor(priority),
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Target Location',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _targetLocationController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Location',
                hintText: 'Enter target location',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.map),
                      onPressed: _showLocationPicker,
                    ),
                    IconButton(
                      icon: const Icon(Icons.my_location),
                      onPressed: _useCurrentLocation,
                    ),
                  ],
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter target location';
                }
                return null;
              },
            ),
            if (_targetLocation != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      'Latitude',
                      _targetLocation!.latitude.toStringAsFixed(6),
                    ),
                    _buildInfoRow(
                      'Longitude',
                      _targetLocation!.longitude.toStringAsFixed(6),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMissionDescription() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mission Description',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _missionDescriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Describe the mission objectives...',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter mission description';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Scheduled Start Time'),
              subtitle: Text(
                DateFormat('MMM dd, yyyy - HH:mm').format(_scheduledTime),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _selectScheduledTime,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionNamePreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generated Mission Name',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tag, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _generatedMissionName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayloadTypeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payload Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PayloadType>(
              value: _selectedPayloadType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select payload type',
              ),
              validator: (value) {
                if (value == null) {
                  return 'Please select payload type';
                }
                return null;
              },
              items: PayloadType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Text(type.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(type.displayName)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPayloadType = value;
                  if (value != null) {
                    _payloadWeight = value.defaultWeight;
                    _payloadWeightController.text = _payloadWeight.toString();
                    _payloadRequirements = List.from(value.commonRequirements);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayloadDetails() {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payload Specifications',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _payloadWeightController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Weight (kg)',
                    hintText: 'Enter payload weight',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter payload weight';
                    }
                    final weight = double.tryParse(value);
                    if (weight == null || weight <= 0 || weight > 50) {
                      return 'Weight must be between 0.1 and 50 kg';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _payloadWeight = double.tryParse(value) ?? 0.0;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _payloadDescriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Package Description',
                    hintText: 'Describe the package contents...',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please describe the package';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Special Requirements',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (_selectedPayloadType != null) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedPayloadType!.commonRequirements.map((
                      requirement,
                    ) {
                      final isSelected = _payloadRequirements.contains(
                        requirement,
                      );
                      return FilterChip(
                        label: Text(requirement),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _payloadRequirements.add(requirement);
                            } else {
                              _payloadRequirements.remove(requirement);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _specialInstructionsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Special Handling Instructions',
                    hintText: 'Any special handling requirements...',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDroneDropdown(MissionProvider provider) {
    final availableDrones = provider.availableDrones
        .where(
          (drone) =>
              drone.status == DroneStatus.active &&
              drone.currentMissionId == null &&
              !drone.needsMaintenance &&
              drone.batteryLevel > 20,
        )
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Drones',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (availableDrones.isEmpty)
              const Text(
                'No drones available for assignment',
                style: TextStyle(color: Colors.red),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedDroneId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select drone',
                ),
                validator: (value) {
                  if (value == null) {
                    return 'Please select a drone';
                  }
                  return null;
                },
                items: availableDrones.map((drone) {
                  return DropdownMenuItem(
                    value: drone.id,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${drone.name} - ${drone.model}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Battery: ${drone.batteryLevel}% | Range: ${drone.rangeDisplay}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDroneId = value;
                    _updateMissionName();
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDroneDetails(MissionProvider provider) {
    final drone = provider.availableDrones.firstWhere(
      (d) => d.id == _selectedDroneId,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Drone Specifications',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Model', drone.model),
            _buildInfoRow('Battery Level', drone.batteryDisplay),
            _buildInfoRow('Max Range', drone.rangeDisplay),
            _buildInfoRow('Flight Time', drone.flightTimeDisplay),
            _buildInfoRow('Payload Capacity', drone.payloadDisplay),
            _buildInfoRow('Status', drone.statusDisplay),
            _buildInfoRow(
              'Location',
              '${drone.location.latitude.toStringAsFixed(4)}, ${drone.location.longitude.toStringAsFixed(4)}',
            ),
            if (drone.lastMaintenance != null)
              _buildInfoRow(
                'Last Maintenance',
                DateFormat('MMM dd, yyyy').format(drone.lastMaintenance!),
              ),
            const SizedBox(height: 12),
            const Text(
              'Capabilities',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: drone.capabilities.map((capability) {
                return Chip(
                  label: Text(capability, style: const TextStyle(fontSize: 10)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mission Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (_generatedMissionName.isNotEmpty)
              _buildInfoRow('Mission Name', _generatedMissionName),
            _buildInfoRow('Priority', _selectedPriority.displayName),
            if (_selectedPayloadType != null) ...[
              _buildInfoRow('Payload Type', _selectedPayloadType!.displayName),
              _buildInfoRow(
                'Payload Weight',
                '${_payloadWeight.toStringAsFixed(1)} kg',
              ),
            ],
            _buildInfoRow(
              'Scheduled Time',
              DateFormat('MMM dd, yyyy - HH:mm').format(_scheduledTime),
            ),
            if (_isBulkCreation)
              _buildInfoRow('Quantity', '$_bulkQuantity missions'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Previous'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : (_currentStep < 3 ? _nextStep : _submitMission),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _currentStep < 3
                          ? 'Next'
                          : (_isBulkCreation
                                ? 'Create ${_bulkQuantity} Missions'
                                : 'Create Mission'),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _tabController.animateTo(_currentStep - 1);
    }
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < 3) {
        _tabController.animateTo(_currentStep + 1);
      }
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _selectedGroupId != null;
      case 1:
        return _targetLocationController.text.isNotEmpty &&
            _missionDescriptionController.text.isNotEmpty;
      case 2:
        return _selectedPayloadType != null &&
            _payloadWeight > 0 &&
            _payloadDescriptionController.text.isNotEmpty;
      case 3:
        return _selectedDroneId != null;
      default:
        return false;
    }
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Location',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_selectedMapLocation != null) {
                        setState(() {
                          _targetLocation = LocationData(
                            latitude: _selectedMapLocation!.latitude,
                            longitude: _selectedMapLocation!.longitude,
                          );
                          _targetLocationController.text =
                              '${_selectedMapLocation!.latitude.toStringAsFixed(6)}, ${_selectedMapLocation!.longitude.toStringAsFixed(6)}';
                        });
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(37.7749, -122.4194), // Default to SF
                  initialZoom: 13.0,
                  onTap: (tapPosition, point) {
                    setState(() {
                      _selectedMapLocation = point;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.drone_aid',
                  ),
                  if (_selectedMapLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedMapLocation!,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _useCurrentLocation() async {
    // TODO: Implement current location functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Current location feature coming soon')),
    );
  }

  void _selectScheduledTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledTime),
      );

      if (time != null) {
        setState(() {
          _scheduledTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Color _getPriorityColor(MissionPriority priority) {
    switch (priority) {
      case MissionPriority.low:
        return Colors.green;
      case MissionPriority.medium:
        return Colors.orange;
      case MissionPriority.high:
        return Colors.red;
      case MissionPriority.critical:
        return Colors.purple;
    }
  }

  Future<void> _submitMission() async {
    if (!_formKey.currentState!.validate() || !_validateAllSteps()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final missionProvider = Provider.of<MissionProvider>(
        context,
        listen: false,
      );

      if (_isBulkCreation) {
        for (int i = 0; i < _bulkQuantity; i++) {
          await _createSingleMission(missionProvider, i);
        }
      } else {
        await _createSingleMission(missionProvider, 0);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isBulkCreation
                  ? '$_bulkQuantity missions created successfully'
                  : 'Mission created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating mission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _createSingleMission(MissionProvider provider, int index) async {
    final missionName = _isBulkCreation && index > 0
        ? '${_generatedMissionName}_${(index + 1).toString().padLeft(2, '0')}'
        : _generatedMissionName;

    final mission = Mission(
      title: missionName,
      description: _missionDescriptionController.text,
      type: _getMissionTypeFromPayload(),
      priority: _selectedPriority,
      assignedDroneId: _selectedDroneId!,
      assignedOperatorId: 'current_user', // TODO: Get current user ID
      startLocation: LocationData(
        latitude: 0,
        longitude: 0,
      ), // TODO: Get GCS location
      targetLocation: _targetLocation!,
      scheduledStartTime: _scheduledTime.add(Duration(minutes: index * 15)),
      eventId: _selectedGroupId,
      payload: _payloadDescriptionController.text,
      specialInstructions: _specialInstructionsController.text,
    );

    // Create payload object (for demonstration)
    // final payload = Payload(
    //   type: _selectedPayloadType!,
    //   weight: _payloadWeight,
    //   description: _payloadDescriptionController.text,
    //   specialRequirements: _payloadRequirements,
    //   handlingInstructions: _specialInstructionsController.text,
    // );

    // TODO: Save payload and associate with mission
    // await provider.createMissionWithPayload(mission, payload);

    // For now, just create an emergency request as demonstration
    await provider.createEmergencyRequest(
      description: mission.description,
      location: mission.targetLocation,
      contactNumber: '+1234567890',
      emergencyType: EmergencyType.medicalEmergency,
      userId: 'current_user',
    );
  }

  MissionType _getMissionTypeFromPayload() {
    switch (_selectedPayloadType) {
      case PayloadType.medical:
      case PayloadType.medication:
      case PayloadType.firstAid:
        return MissionType.medical;
      case PayloadType.food:
      case PayloadType.water:
        return MissionType.delivery;
      case PayloadType.lifeSavingEquipment:
      case PayloadType.rescue:
        return MissionType.rescue;
      case PayloadType.communicationDevice:
        return MissionType.surveillance;
      case PayloadType.emergency:
        return MissionType.emergencyResponse;
      default:
        return MissionType.delivery;
    }
  }

  bool _validateAllSteps() {
    return _selectedGroupId != null &&
        _targetLocation != null &&
        _missionDescriptionController.text.isNotEmpty &&
        _selectedPayloadType != null &&
        _payloadWeight > 0 &&
        _payloadDescriptionController.text.isNotEmpty &&
        _selectedDroneId != null;
  }
}
