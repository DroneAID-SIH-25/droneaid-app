import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/mission.dart';
import '../models/drone.dart';
import '../models/payload.dart';
import '../models/group_event.dart';
import '../models/user.dart';
import '../providers/group_management_provider.dart';
import '../providers/mission_provider.dart';
import '../services/mission_management_service.dart';
import 'drone_selection_widget.dart';

class MissionCreationForm extends StatefulWidget {
  final VoidCallback? onMissionCreated;
  final bool showBulkOption;

  const MissionCreationForm({
    super.key,
    this.onMissionCreated,
    this.showBulkOption = true,
  });

  @override
  State<MissionCreationForm> createState() => _MissionCreationFormState();
}

class _MissionCreationFormState extends State<MissionCreationForm>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // Services
  final _missionService = MissionManagementService();

  // Current step
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Form controllers
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _payloadDescriptionController = TextEditingController();
  final _payloadWeightController = TextEditingController();
  final _specialInstructionsController = TextEditingController();

  // Form data
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

  // Validation state
  String? _validationError;

  // Generated mission name
  String _generatedName = '';

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _updateProgress();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _payloadDescriptionController.dispose();
    _payloadWeightController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    final progress = (_currentStep + 1) / _totalSteps;
    _progressController.animateTo(progress);
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

      setState(() {
        _generatedName = _missionService.generateMissionName(
          priority: _priority,
          eventType: group.type,
          droneId: _selectedDroneId!,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildProgressHeader(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                  _updateProgress();
                });
              },
              children: [
                _buildGroupSelectionStep(),
                _buildMissionDetailsStep(),
                _buildPayloadConfigurationStep(),
                _buildDroneSelectionStep(),
              ],
            ),
          ),
          _buildNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create Mission',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
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
        ],
      ),
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

  Widget _buildGroupSelectionStep() {
    return Consumer<GroupManagementProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepHeader(
                  'Select Event Group',
                  'Choose the emergency event for this mission',
                ),
                const SizedBox(height: 24),
                _buildGroupDropdown(provider),
                if (_selectedGroupId != null) ...[
                  const SizedBox(height: 24),
                  _buildGroupPreview(provider),
                ],
                if (widget.showBulkOption) ...[
                  const SizedBox(height: 24),
                  _buildBulkCreationOption(),
                ],
                if (_validationError != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorMessage(_validationError!),
                ],
              ],
            ),
          ),
        );
      },
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
            'Configure priority, location, and scheduling',
          ),
          const SizedBox(height: 24),
          _buildPrioritySelector(),
          const SizedBox(height: 24),
          _buildLocationInput(),
          const SizedBox(height: 24),
          _buildDescriptionInput(),
          const SizedBox(height: 24),
          _buildScheduleSelector(),
          if (_generatedName.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildMissionNamePreview(),
          ],
          if (_validationError != null) ...[
            const SizedBox(height: 16),
            _buildErrorMessage(_validationError!),
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
          ),
          const SizedBox(height: 24),
          _buildPayloadTypeSelector(),
          if (_payloadType != null) ...[
            const SizedBox(height: 24),
            _buildPayloadSpecifications(),
            const SizedBox(height: 24),
            _buildPayloadRequirements(),
          ],
          if (_validationError != null) ...[
            const SizedBox(height: 16),
            _buildErrorMessage(_validationError!),
          ],
        ],
      ),
    );
  }

  Widget _buildDroneSelectionStep() {
    return Consumer<MissionProvider>(
      builder: (context, provider, child) {
        final availableDrones = _getAvailableDrones(provider);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepHeader(
                'Drone Assignment',
                'Select the best drone for this mission',
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
              if (_validationError != null) ...[
                const SizedBox(height: 16),
                _buildErrorMessage(_validationError!),
              ],
            ],
          ),
        );
      },
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
              'Event Group',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedGroupId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select event group',
              ),
              validator: (value) => value == null ? 'Group is required' : null,
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
              TextFormField(
                initialValue: _bulkQuantity.toString(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Number of missions',
                  hintText: 'Enter quantity (1-10)',
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

  Widget _buildPrioritySelector() {
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
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInput() {
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
                hintText: 'Enter coordinates or address',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: _getCurrentLocation,
                ),
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Location is required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionInput() {
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
                hintText: 'Describe the mission objectives...',
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Description is required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSelector() {
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
              title: const Text('Scheduled Time'),
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

  Widget _buildPayloadTypeSelector() {
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
              ),
              validator: (value) =>
                  value == null ? 'Payload type is required' : null,
              items: PayloadType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Text(type.icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(type.displayName),
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
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _payloadWeightController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Weight (kg)',
                      hintText: '0.0',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final weight = double.tryParse(value ?? '');
                      if (weight == null || weight <= 0) {
                        return 'Valid weight required';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _payloadWeight = double.tryParse(value) ?? 0.0;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _payloadDescriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Package Description',
                hintText: 'Describe the payload contents...',
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Description is required' : null,
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
            if (_payloadType != null)
              _buildInfoRow('Payload', _payloadType!.displayName),
            _buildInfoRow('Weight', '${_payloadWeight.toStringAsFixed(1)} kg'),
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
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.red[700])),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
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
              onPressed: _currentStep < _totalSteps - 1
                  ? _nextStep
                  : _submitMission,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(
                _currentStep < _totalSteps - 1
                    ? 'Next'
                    : _isBulkCreation
                    ? 'Create ${_bulkQuantity} Missions'
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
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    setState(() => _validationError = null);

    switch (_currentStep) {
      case 0:
        if (_selectedGroupId == null) {
          setState(() => _validationError = 'Please select an event group');
          return false;
        }
        break;
      case 1:
        if (_locationController.text.isEmpty) {
          setState(() => _validationError = 'Please enter target location');
          return false;
        }
        if (_descriptionController.text.isEmpty) {
          setState(() => _validationError = 'Please enter mission description');
          return false;
        }
        break;
      case 2:
        if (_payloadType == null) {
          setState(() => _validationError = 'Please select payload type');
          return false;
        }
        if (_payloadWeight <= 0) {
          setState(
            () => _validationError = 'Please enter valid payload weight',
          );
          return false;
        }
        if (_payloadDescriptionController.text.isEmpty) {
          setState(() => _validationError = 'Please describe the payload');
          return false;
        }
        break;
      case 3:
        if (_selectedDroneId == null) {
          setState(() => _validationError = 'Please select a drone');
          return false;
        }
        break;
    }

    return true;
  }

  Future<void> _submitMission() async {
    if (!_validateAllSteps()) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Creating mission...'),
            ],
          ),
        ),
      );

      // Create payload
      final payload = Payload(
        type: _payloadType!,
        weight: _payloadWeight,
        description: _payloadDescriptionController.text,
        specialRequirements: _payloadRequirements,
        handlingInstructions: _specialInstructionsController.text,
      );

      // Create mission(s)
      if (_isBulkCreation) {
        await _createBulkMissions(payload);
      } else {
        await _createSingleMission(payload);
      }

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isBulkCreation
                  ? '$_bulkQuantity missions created successfully!'
                  : 'Mission created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Call callback
        widget.onMissionCreated?.call();

        // Navigate back
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating mission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createSingleMission(Payload payload) async {
    final groupProvider = Provider.of<GroupManagementProvider>(
      context,
      listen: false,
    );

    final group = groupProvider.events.firstWhere(
      (g) => g.id == _selectedGroupId,
    );

    await _missionService.createMission(
      groupId: _selectedGroupId!,
      eventType: group.type,
      priority: _priority,
      description: _descriptionController.text,
      targetLocation: _targetLocation!,
      assignedDroneId: _selectedDroneId!,
      assignedOperatorId: 'current_user', // TODO: Get current user
      payload: payload,
      scheduledStartTime: _scheduledTime,
      specialInstructions: _specialInstructionsController.text.isEmpty
          ? null
          : _specialInstructionsController.text,
    );
  }

  Future<void> _createBulkMissions(Payload payload) async {
    final groupProvider = Provider.of<GroupManagementProvider>(
      context,
      listen: false,
    );
    final missionProvider = Provider.of<MissionProvider>(
      context,
      listen: false,
    );

    final group = groupProvider.events.firstWhere(
      (g) => g.id == _selectedGroupId,
    );

    // Get additional available drones for bulk creation
    final availableDrones = _getAvailableDrones(missionProvider);
    final droneIds = availableDrones
        .take(_bulkQuantity)
        .map((d) => d.id)
        .toList();

    if (droneIds.length < _bulkQuantity) {
      throw Exception(
        'Not enough available drones. Found ${droneIds.length}, need $_bulkQuantity',
      );
    }

    await _missionService.createBulkMissions(
      groupId: _selectedGroupId!,
      eventType: group.type,
      priority: _priority,
      baseDescription: _descriptionController.text,
      targetLocation: _targetLocation!,
      droneIds: droneIds,
      assignedOperatorId: 'current_user', // TODO: Get current user
      basePayload: payload,
      scheduledStartTime: _scheduledTime,
      specialInstructions: _specialInstructionsController.text.isEmpty
          ? null
          : _specialInstructionsController.text,
    );
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
    return _missionService.getAvailableDrones(
      provider.availableDrones,
      minBatteryLevel: 20.0,
      minPayloadCapacity: _payloadWeight,
    );
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

  void _getCurrentLocation() {
    // TODO: Implement current location functionality
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

    if (date != null && mounted) {
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
