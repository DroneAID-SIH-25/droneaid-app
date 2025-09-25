import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/group_management_provider.dart';
import '../../providers/mission_provider.dart';
import '../../models/group_event.dart';
import '../../models/mission.dart';
import '../../models/drone.dart';
import '../../models/payload.dart';
import '../../models/user.dart';
import '../../widgets/drone_selection_widget.dart';

class MissionCreationIntegratedScreen extends StatefulWidget {
  const MissionCreationIntegratedScreen({super.key});

  @override
  State<MissionCreationIntegratedScreen> createState() =>
      _MissionCreationIntegratedScreenState();
}

class _MissionCreationIntegratedScreenState
    extends State<MissionCreationIntegratedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Form Controllers
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _payloadDescriptionController = TextEditingController();
  final _payloadWeightController = TextEditingController();
  final _specialInstructionsController = TextEditingController();

  // Form Data
  String? _selectedGroupId;
  MissionPriority _priority = MissionPriority.medium;
  LocationData? _targetLocation;
  PayloadType? _payloadType;
  double _payloadWeight = 0.0;
  List<String> _payloadRequirements = [];
  String? _selectedDroneId;
  DateTime _scheduledTime = DateTime.now().add(const Duration(hours: 1));
  bool _isBulkCreation = false;
  int _bulkQuantity = 1;
  bool _isSubmitting = false;

  // Generated Mission Name
  String _generatedName = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _totalSteps, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentStep = _tabController.index;
      });
    });
    _updateMissionName();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _payloadDescriptionController.dispose();
    _payloadWeightController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
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

      final priority = _priority.name.toUpperCase();
      final event = _getEventCode(group.type);
      final droneId = _selectedDroneId!.toUpperCase().replaceAll(' ', '_');

      setState(() {
        _generatedName = '${priority}_${event}_$droneId';
      });
    }
  }

  String _getEventCode(EventType eventType) {
    switch (eventType) {
      case EventType.flood:
        return 'FLOOD';
      case EventType.fireIncident:
        return 'FIRE';
      case EventType.earthquake:
        return 'EARTHQUAKE';
      case EventType.hurricane:
        return 'HURRICANE';
      case EventType.tornado:
        return 'TORNADO';
      case EventType.landslide:
        return 'LANDSLIDE';
      case EventType.tsunami:
        return 'TSUNAMI';
      case EventType.volcanicEruption:
        return 'VOLCANIC';
      case EventType.pandemicOutbreak:
        return 'PANDEMIC';
      case EventType.cyberAttack:
        return 'CYBER';
      case EventType.terroristAttack:
        return 'TERROR';
      case EventType.chemicalSpill:
        return 'CHEMICAL';
      case EventType.industrialAccident:
        return 'INDUSTRIAL';
      case EventType.massCasualty:
        return 'CASUALTY';
      case EventType.buildingCollapse:
        return 'COLLAPSE';
      case EventType.transportationAccident:
        return 'TRANSPORT';
      case EventType.civilUnrest:
        return 'UNREST';
      case EventType.naturalDisaster:
        return 'NATURAL';
      case EventType.powerGridFailure:
        return 'POWER';
      default:
        return 'OTHER';
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
          preferredSize: const Size.fromHeight(80),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / _totalSteps,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step ${_currentStep + 1} of $_totalSteps',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      _getStepTitle(_currentStep),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontSize: 12),
                tabs: const [
                  Tab(text: 'Group', icon: Icon(Icons.group, size: 16)),
                  Tab(text: 'Mission', icon: Icon(Icons.assignment, size: 16)),
                  Tab(text: 'Payload', icon: Icon(Icons.inventory, size: 16)),
                  Tab(text: 'Drone', icon: Icon(Icons.flight, size: 16)),
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

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Group Selection';
      case 1:
        return 'Mission Details';
      case 2:
        return 'Payload Configuration';
      case 3:
        return 'Drone Assignment';
      default:
        return '';
    }
  }

  Widget _buildGroupSelectionStep(GroupManagementProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Select Event Group',
            'Choose the emergency event for this mission',
            Icons.group,
          ),
          const SizedBox(height: 24),
          _buildGroupDropdown(provider),
          if (_selectedGroupId != null) ...[
            const SizedBox(height: 24),
            _buildGroupPreview(provider),
          ],
          const SizedBox(height: 24),
          _buildBulkCreationOption(),
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
            'Configure priority, location, and description',
            Icons.assignment,
          ),
          const SizedBox(height: 24),
          _buildPrioritySelection(),
          const SizedBox(height: 24),
          _buildLocationSection(),
          const SizedBox(height: 24),
          _buildDescriptionSection(),
          const SizedBox(height: 24),
          _buildScheduleSection(),
          if (_generatedName.isNotEmpty) ...[
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
            'Specify what the drone will carry',
            Icons.inventory,
          ),
          const SizedBox(height: 24),
          _buildPayloadTypeSelection(),
          if (_payloadType != null) ...[
            const SizedBox(height: 24),
            _buildPayloadSpecifications(),
            const SizedBox(height: 24),
            _buildPayloadRequirements(),
          ],
        ],
      ),
    );
  }

  Widget _buildDroneSelectionStep(MissionProvider provider) {
    final availableDrones = _getAvailableDrones(provider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Drone Assignment',
            'Select the optimal drone for this mission',
            Icons.flight,
          ),
          const SizedBox(height: 24),
          DroneSelectionWidget(
            availableDrones: availableDrones,
            selectedDroneId: _selectedDroneId,
            onDroneSelected: (droneId) {
              setState(() {
                _selectedDroneId = droneId;
                _updateMissionName();
              });
            },
            showDetailedInfo: true,
          ),
          if (_selectedDroneId != null) ...[
            const SizedBox(height: 24),
            _buildMissionSummary(provider),
          ],
        ],
      ),
    );
  }

  Widget _buildStepHeader(String title, String subtitle, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildGroupDropdown(GroupManagementProvider provider) {
    return Card(
      elevation: 2,
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
                prefixIcon: Icon(Icons.event),
              ),
              validator: (value) =>
                  value == null ? 'Please select an event group' : null,
              items: provider.events.map((group) {
                return DropdownMenuItem(
                  value: group.id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        group.title,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${group.type.displayName} - ${group.severity.displayName}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
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
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Group Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Title', group.title),
            _buildInfoRow('Type', group.type.displayName),
            _buildInfoRow('Status', group.status.displayName),
            _buildInfoRow('Severity', group.severity.displayName),
            _buildInfoRow('Priority', group.priority.displayName),
            if (group.description.isNotEmpty)
              _buildInfoRow('Description', group.description),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkCreationOption() {
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
                  onChanged: (value) => setState(() => _isBulkCreation = value),
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
              const Text(
                'Create multiple missions with sequential drone assignment',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _bulkQuantity.toString(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Number of missions',
                  hintText: 'Enter quantity (1-10)',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final quantity = int.tryParse(value ?? '');
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
                  selected: _priority == priority,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _priority = priority;
                        _updateMissionName();
                      });
                    }
                  },
                  selectedColor: _getPriorityColor(priority),
                  backgroundColor: _getPriorityColor(priority).withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: _priority == priority
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
              controller: _locationController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Location',
                hintText: 'Enter coordinates or address',
                prefixIcon: const Icon(Icons.location_on),
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
              validator: (value) => value?.isEmpty == true
                  ? 'Please enter target location'
                  : null,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _targetLocation = LocationData(latitude: 0, longitude: 0);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
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
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Describe the mission objectives and requirements...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.description),
                ),
              ),
              validator: (value) => value?.isEmpty == true
                  ? 'Please enter mission description'
                  : null,
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
              'Mission Schedule',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Scheduled Start Time'),
              subtitle: Text(
                DateFormat('MMM dd, yyyy - HH:mm').format(_scheduledTime),
              ),
              trailing: const Icon(Icons.edit),
              onTap: _selectScheduledTime,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionNamePreview() {
    return Card(
      color: AppColors.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.tag, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Generated Mission Name',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _generatedName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
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
              value: _payloadType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select payload type',
                prefixIcon: Icon(Icons.inventory_2),
              ),
              validator: (value) =>
                  value == null ? 'Please select payload type' : null,
              items: PayloadType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Text(type.icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(type.displayName)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _payloadType = value;
                  if (value != null) {
                    _payloadWeight = value.defaultWeight;
                    _payloadWeightController.text = _payloadWeight.toString();
                    _payloadRequirements = List.from(value.commonRequirements);
                  }
                });
              },
            ),
            if (_payloadType != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _payloadType!.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPayloadSpecifications() {
    return Card(
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
                hintText: '0.0',
                prefixIcon: Icon(Icons.fitness_center),
                suffixText: 'kg',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                final weight = double.tryParse(value ?? '');
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
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.description),
                ),
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Please describe the package' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayloadRequirements() {
    return Card(
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
            if (_payloadType != null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _payloadType!.commonRequirements.map((requirement) {
                  final isSelected = _payloadRequirements.contains(requirement);
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
            TextFormField(
              controller: _specialInstructionsController,
              maxLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Special Instructions',
                hintText: 'Any additional handling requirements...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.warning),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionSummary(MissionProvider provider) {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  'Mission Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Mission Name', _generatedName),
            _buildInfoRow('Priority', _priority.displayName),
            if (_payloadType != null) ...[
              _buildInfoRow('Payload Type', _payloadType!.displayName),
              _buildInfoRow(
                'Weight',
                '${_payloadWeight.toStringAsFixed(1)} kg',
              ),
            ],
            _buildInfoRow(
              'Scheduled',
              DateFormat('MMM dd, HH:mm').format(_scheduledTime),
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                  : (_currentStep < _totalSteps - 1
                        ? _nextStep
                        : _submitMission),
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
                      _currentStep < _totalSteps - 1
                          ? 'Next'
                          : _isBulkCreation
                          ? 'Create $_bulkQuantity Missions'
                          : 'Create Mission',
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
      if (_currentStep < _totalSteps - 1) {
        _tabController.animateTo(_currentStep + 1);
      }
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _selectedGroupId != null;
      case 1:
        return _locationController.text.isNotEmpty &&
            _descriptionController.text.isNotEmpty;
      case 2:
        return _payloadType != null &&
            _payloadWeight > 0 &&
            _payloadDescriptionController.text.isNotEmpty;
      case 3:
        return _selectedDroneId != null;
      default:
        return false;
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
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isBulkCreation
                  ? '$_bulkQuantity missions created successfully!'
                  : 'Mission "$_generatedName" created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
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

  bool _validateAllSteps() {
    return _selectedGroupId != null &&
        _locationController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty &&
        _payloadType != null &&
        _payloadWeight > 0 &&
        _payloadDescriptionController.text.isNotEmpty &&
        _selectedDroneId != null;
  }

  List<Drone> _getAvailableDrones(MissionProvider provider) {
    return provider.availableDrones.where((drone) {
      return drone.status == DroneStatus.active &&
          drone.currentMissionId == null &&
          !drone.needsMaintenance &&
          drone.batteryLevel > 20 &&
          (_payloadWeight == 0 || drone.payloadCapacity >= _payloadWeight);
    }).toList();
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

  void _showLocationPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Picker'),
        content: const Text('Map integration coming soon...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _useCurrentLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Current location feature coming soon')),
    );
  }

  Future<void> _selectScheduledTime() async {
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
}
