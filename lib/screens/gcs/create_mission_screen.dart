import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_theme.dart';
import '../../providers/group_management_provider.dart';
import '../../models/group_event.dart';
import '../../models/mission.dart';
import '../../models/user.dart';

class CreateMissionScreen extends StatefulWidget {
  const CreateMissionScreen({super.key});

  @override
  State<CreateMissionScreen> createState() => _CreateMissionScreenState();
}

class _CreateMissionScreenState extends State<CreateMissionScreen>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form controllers
  final _missionTitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startLocationController = TextEditingController();
  final _targetLocationController = TextEditingController();
  final _payloadController = TextEditingController();
  final _specialInstructionsController = TextEditingController();
  final _estimatedDurationController = TextEditingController();
  final _maxAltitudeController = TextEditingController();
  final _maxSpeedController = TextEditingController();

  // Form values
  MissionType _selectedMissionType = MissionType.surveillance;
  MissionPriority _selectedPriority = MissionPriority.medium;
  String? _selectedEventId;
  String? _selectedDroneId;
  String? _selectedOperatorId;
  LocationData? _startLocation;
  LocationData? _targetLocation;
  DateTime _scheduledStartTime = DateTime.now().add(const Duration(hours: 1));
  List<String> _selectedEquipment = [];
  Map<String, dynamic> _missionParameters = {};
  bool _isRecurring = false;
  String _weatherRequirement = 'Any';

  bool _isSubmitting = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _estimatedDurationController.text = '60';
    _maxAltitudeController.text = '150';
    _maxSpeedController.text = '50';
  }

  @override
  void dispose() {
    _missionTitleController.dispose();
    _descriptionController.dispose();
    _startLocationController.dispose();
    _targetLocationController.dispose();
    _payloadController.dispose();
    _specialInstructionsController.dispose();
    _estimatedDurationController.dispose();
    _maxAltitudeController.dispose();
    _maxSpeedController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Consumer<GroupManagementProvider>(
        builder: (context, provider, child) {
          return Form(
            key: _formKey,
            child: Column(
              children: [
                _buildFormHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBasicInfoSection(),
                        const SizedBox(height: 24),
                        _buildMissionTypeSection(),
                        const SizedBox(height: 24),
                        _buildEventAssignmentSection(provider),
                        const SizedBox(height: 24),
                        _buildResourceAssignmentSection(),
                        const SizedBox(height: 24),
                        _buildLocationSection(),
                        const SizedBox(height: 24),
                        _buildScheduleSection(),
                        const SizedBox(height: 24),
                        _buildMissionParametersSection(),
                        const SizedBox(height: 24),
                        _buildEquipmentSection(),
                        const SizedBox(height: 24),
                        _buildAdvancedOptionsSection(),
                        const SizedBox(height: 32),
                        _buildSubmitButton(provider),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.add_task, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Create Mission',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: _clearForm,
                icon: const Icon(Icons.refresh),
                tooltip: 'Reset Form',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Assign new missions to drones and operators',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'Basic Information',
      icon: Icons.info_outline,
      children: [
        TextFormField(
          controller: _missionTitleController,
          decoration: const InputDecoration(
            labelText: 'Mission Title *',
            hintText: 'Enter mission name',
            prefixIcon: Icon(Icons.title),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Mission title is required';
            }
            if (value.trim().length < 3) {
              return 'Mission title must be at least 3 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description *',
            hintText: 'Describe the mission objectives',
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Description is required';
            }
            if (value.trim().length < 10) {
              return 'Description must be at least 10 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<MissionPriority>(
          value: _selectedPriority,
          decoration: const InputDecoration(
            labelText: 'Priority *',
            prefixIcon: Icon(Icons.flag),
          ),
          items: MissionPriority.values.map((priority) {
            return DropdownMenuItem(
              value: priority,
              child: Row(
                children: [
                  Icon(
                    Icons.flag,
                    color: _getPriorityColor(priority),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(priority.toString().split('.').last.toUpperCase()),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedPriority = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildMissionTypeSection() {
    return _buildSection(
      title: 'Mission Type',
      icon: Icons.category,
      children: [
        DropdownButtonFormField<MissionType>(
          value: _selectedMissionType,
          decoration: const InputDecoration(
            labelText: 'Mission Type *',
            prefixIcon: Icon(Icons.assignment),
          ),
          items: MissionType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Row(
                children: [
                  Icon(_getMissionTypeIcon(type), size: 20),
                  const SizedBox(width: 8),
                  Text(_getMissionTypeDisplayName(type)),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedMissionType = value;
                _updateMissionDefaults(value);
              });
            }
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getMissionTypeDescription(_selectedMissionType),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.info.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventAssignmentSection(GroupManagementProvider provider) {
    return _buildSection(
      title: 'Event Assignment',
      icon: Icons.event,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedEventId,
          decoration: const InputDecoration(
            labelText: 'Related Event (Optional)',
            prefixIcon: Icon(Icons.event),
          ),
          hint: const Text('Select an event'),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('No related event'),
            ),
            ...provider.activeEvents.map((event) {
              return DropdownMenuItem<String>(
                value: event.id,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${event.typeDisplay} • ${event.severityDisplay}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
          onChanged: (value) {
            setState(() {
              _selectedEventId = value;
            });
          },
        ),
        if (_selectedEventId != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mission will be associated with selected event',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResourceAssignmentSection() {
    return _buildSection(
      title: 'Resource Assignment',
      icon: Icons.assignment_ind,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedDroneId,
          decoration: const InputDecoration(
            labelText: 'Assigned Drone *',
            prefixIcon: Icon(Icons.flight),
          ),
          hint: const Text('Select a drone'),
          items: _getAvailableDrones().map((drone) {
            return DropdownMenuItem<String>(
              value: drone['id'],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    drone['name'],
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${drone['type']} • Battery: ${drone['battery']}%',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }).toList(),
          validator: (value) {
            if (value == null) {
              return 'Please select a drone';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _selectedDroneId = value;
            });
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedOperatorId,
          decoration: const InputDecoration(
            labelText: 'Assigned Operator *',
            prefixIcon: Icon(Icons.person),
          ),
          hint: const Text('Select an operator'),
          items: _getAvailableOperators().map((operator) {
            return DropdownMenuItem<String>(
              value: operator['id'],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    operator['name'],
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${operator['role']} • Rating: ${operator['rating']}/5',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }).toList(),
          validator: (value) {
            if (value == null) {
              return 'Please select an operator';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _selectedOperatorId = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return _buildSection(
      title: 'Mission Locations',
      icon: Icons.location_on,
      children: [
        TextFormField(
          controller: _startLocationController,
          decoration: InputDecoration(
            labelText: 'Start Location *',
            hintText: 'Base or launch location',
            prefixIcon: const Icon(Icons.flight_takeoff),
            suffixIcon: IconButton(
              onPressed: () => _selectLocationOnMap(true),
              icon: const Icon(Icons.map),
              tooltip: 'Select on Map',
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Start location is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _targetLocationController,
          decoration: InputDecoration(
            labelText: 'Target Location *',
            hintText: 'Mission destination',
            prefixIcon: const Icon(Icons.flight_land),
            suffixIcon: IconButton(
              onPressed: () => _selectLocationOnMap(false),
              icon: const Icon(Icons.map),
              tooltip: 'Select on Map',
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Target location is required';
            }
            return null;
          },
        ),
        if (_startLocation != null || _targetLocation != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Coordinates',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                if (_startLocation != null)
                  Text(
                    'Start: ${_startLocation!.latitude.toStringAsFixed(6)}, ${_startLocation!.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                if (_targetLocation != null)
                  Text(
                    'Target: ${_targetLocation!.latitude.toStringAsFixed(6)}, ${_targetLocation!.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScheduleSection() {
    return _buildSection(
      title: 'Schedule',
      icon: Icons.schedule,
      children: [
        GestureDetector(
          onTap: _selectScheduledTime,
          child: AbsorbPointer(
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Scheduled Start Time *',
                prefixIcon: Icon(Icons.access_time),
              ),
              controller: TextEditingController(
                text: DateFormat(
                  'dd/MM/yyyy HH:mm',
                ).format(_scheduledStartTime),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _estimatedDurationController,
          decoration: const InputDecoration(
            labelText: 'Estimated Duration (minutes) *',
            prefixIcon: Icon(Icons.timer),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Duration is required';
            }
            final duration = int.tryParse(value);
            if (duration == null || duration <= 0) {
              return 'Invalid duration';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('Recurring Mission'),
          subtitle: const Text('Mission will repeat automatically'),
          value: _isRecurring,
          onChanged: (value) {
            setState(() {
              _isRecurring = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildMissionParametersSection() {
    return _buildSection(
      title: 'Mission Parameters',
      icon: Icons.settings,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _maxAltitudeController,
                decoration: const InputDecoration(
                  labelText: 'Max Altitude (m) *',
                  prefixIcon: Icon(Icons.height),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  final altitude = double.tryParse(value);
                  if (altitude == null || altitude <= 0) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _maxSpeedController,
                decoration: const InputDecoration(
                  labelText: 'Max Speed (km/h) *',
                  prefixIcon: Icon(Icons.speed),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  final speed = double.tryParse(value);
                  if (speed == null || speed <= 0) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _weatherRequirement,
          decoration: const InputDecoration(
            labelText: 'Weather Requirement',
            prefixIcon: Icon(Icons.wb_sunny),
          ),
          items: ['Any', 'Clear', 'Light Wind', 'No Rain', 'Good Visibility']
              .map((weather) {
                return DropdownMenuItem<String>(
                  value: weather,
                  child: Text(weather),
                );
              })
              .toList(),
          onChanged: (value) {
            setState(() {
              _weatherRequirement = value ?? 'Any';
            });
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _payloadController,
          decoration: const InputDecoration(
            labelText: 'Payload Description',
            hintText: 'Describe equipment or cargo',
            prefixIcon: Icon(Icons.inventory),
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentSection() {
    return _buildSection(
      title: 'Equipment & Sensors',
      icon: Icons.build,
      children: [
        const Text(
          'Select required equipment:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _getAvailableEquipment().map((equipment) {
            final isSelected = _selectedEquipment.contains(equipment);
            return FilterChip(
              label: Text(equipment),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedEquipment.add(equipment);
                  } else {
                    _selectedEquipment.remove(equipment);
                  }
                });
              },
            );
          }).toList(),
        ),
        if (_selectedEquipment.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Selected: ${_selectedEquipment.join(', ')}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancedOptionsSection() {
    return _buildSection(
      title: 'Additional Instructions',
      icon: Icons.note,
      children: [
        TextFormField(
          controller: _specialInstructionsController,
          decoration: const InputDecoration(
            labelText: 'Special Instructions',
            hintText: 'Any special requirements or notes',
            prefixIcon: Icon(Icons.note_alt),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mission Summary',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text('Type: ${_getMissionTypeDisplayName(_selectedMissionType)}'),
              Text(
                'Priority: ${_selectedPriority.toString().split('.').last.toUpperCase()}',
              ),
              if (_selectedDroneId != null)
                Text('Drone: ${_getDroneName(_selectedDroneId!)}'),
              if (_selectedOperatorId != null)
                Text('Operator: ${_getOperatorName(_selectedOperatorId!)}'),
              Text(
                'Scheduled: ${DateFormat('dd/MM/yyyy HH:mm').format(_scheduledStartTime)}',
              ),
              Text('Duration: ${_estimatedDurationController.text} minutes'),
              if (_selectedEquipment.isNotEmpty)
                Text('Equipment: ${_selectedEquipment.length} items'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(GroupManagementProvider provider) {
    return Column(
      children: [
        if (provider.error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider.error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
                TextButton(
                  onPressed: () => provider.clearError(),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting || provider.isLoading
                ? null
                : _submitMission,
            icon: _isSubmitting || provider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.send),
            label: Text(
              _isSubmitting || provider.isLoading
                  ? 'Creating Mission...'
                  : 'Create Mission',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Color _getPriorityColor(MissionPriority priority) {
    switch (priority) {
      case MissionPriority.critical:
        return AppColors.error;
      case MissionPriority.high:
        return Colors.deepOrange;
      case MissionPriority.medium:
        return AppColors.warning;
      case MissionPriority.low:
        return AppColors.success;
    }
  }

  IconData _getMissionTypeIcon(MissionType type) {
    switch (type) {
      case MissionType.surveillance:
        return Icons.visibility;
      case MissionType.delivery:
        return Icons.local_shipping;
      case MissionType.searchAndRescue:
        return Icons.search;
      case MissionType.medical:
        return Icons.medical_services;
      case MissionType.mapping:
        return Icons.map;
      case MissionType.inspection:
        return Icons.assignment_turned_in;
      case MissionType.patrol:
        return Icons.security;
      default:
        return Icons.flight;
    }
  }

  String _getMissionTypeDisplayName(MissionType type) {
    switch (type) {
      case MissionType.surveillance:
        return 'Surveillance';
      case MissionType.delivery:
        return 'Delivery';
      case MissionType.searchAndRescue:
        return 'Search & Rescue';
      case MissionType.medical:
        return 'Medical Emergency';
      case MissionType.mapping:
        return 'Mapping';
      case MissionType.inspection:
        return 'Inspection';
      case MissionType.patrol:
        return 'Patrol';
      default:
        return type.toString().split('.').last;
    }
  }

  String _getMissionTypeDescription(MissionType type) {
    switch (type) {
      case MissionType.surveillance:
        return 'Monitor and observe specified areas or targets';
      case MissionType.delivery:
        return 'Transport supplies or equipment to designated locations';
      case MissionType.searchAndRescue:
        return 'Locate and assist missing persons or emergency situations';
      case MissionType.medical:
        return 'Provide medical support and emergency response';
      case MissionType.mapping:
        return 'Create detailed maps and surveys of areas';
      case MissionType.inspection:
        return 'Inspect infrastructure, equipment, or damage assessment';
      case MissionType.patrol:
        return 'Regular monitoring and security patrol operations';
      default:
        return 'Standard mission operations';
    }
  }

  void _updateMissionDefaults(MissionType type) {
    switch (type) {
      case MissionType.surveillance:
        _estimatedDurationController.text = '120';
        _maxAltitudeController.text = '200';
        _maxSpeedController.text = '40';
        _weatherRequirement = 'Good Visibility';
        break;
      case MissionType.delivery:
        _estimatedDurationController.text = '90';
        _maxAltitudeController.text = '150';
        _maxSpeedController.text = '60';
        _weatherRequirement = 'No Rain';
        break;
      case MissionType.searchAndRescue:
        _estimatedDurationController.text = '180';
        _maxAltitudeController.text = '100';
        _maxSpeedController.text = '45';
        _weatherRequirement = 'Clear';
        break;
      case MissionType.medical:
        _estimatedDurationController.text = '60';
        _maxAltitudeController.text = '120';
        _maxSpeedController.text = '70';
        _weatherRequirement = 'Any';
        break;
      default:
        break;
    }
  }

  List<Map<String, dynamic>> _getAvailableDrones() {
    // Mock drone data - in real app would come from drone provider
    return [
      {
        'id': 'DRN-001',
        'name': 'Medical Drone Alpha',
        'type': 'Medical',
        'battery': 95,
        'status': 'Available',
      },
      {
        'id': 'DRN-002',
        'name': 'Surveillance Hawk',
        'type': 'Surveillance',
        'battery': 87,
        'status': 'Available',
      },
      {
        'id': 'DRN-003',
        'name': 'Rescue Eagle',
        'type': 'Search & Rescue',
        'battery': 92,
        'status': 'Available',
      },
      {
        'id': 'DRN-004',
        'name': 'Delivery Falcon',
        'type': 'Delivery',
        'battery': 78,
        'status': 'Available',
      },
      {
        'id': 'DRN-005',
        'name': 'Survey Phantom',
        'type': 'Mapping',
        'battery': 85,
        'status': 'Available',
      },
    ];
  }

  List<Map<String, dynamic>> _getAvailableOperators() {
    // Mock operator data - in real app would come from operator provider
    return [
      {
        'id': 'OP-001',
        'name': 'John Smith',
        'role': 'Senior Pilot',
        'rating': 4.9,
        'status': 'Available',
      },
      {
        'id': 'OP-002',
        'name': 'Sarah Johnson',
        'role': 'Emergency Specialist',
        'rating': 4.8,
        'status': 'Available',
      },
      {
        'id': 'OP-003',
        'name': 'Mike Chen',
        'role': 'Search & Rescue',
        'rating': 4.7,
        'status': 'Available',
      },
      {
        'id': 'OP-004',
        'name': 'Emma Davis',
        'role': 'Medical Response',
        'rating': 4.9,
        'status': 'Available',
      },
      {
        'id': 'OP-005',
        'name': 'Alex Kumar',
        'role': 'Surveillance Expert',
        'rating': 4.6,
        'status': 'Available',
      },
    ];
  }

  List<String> _getAvailableEquipment() {
    return [
      'High-res Camera',
      'Thermal Imaging',
      'Medical Kit',
      'Life Preserver',
      'Communication Radio',
      'GPS Tracker',
      'Emergency Beacon',
      'Sample Collection Kit',
      'Water Quality Sensors',
      'Air Quality Monitor',
      'Loudspeaker',
      'Spotlight',
      'Cargo Container',
      'Parachute System',
    ];
  }

  String _getDroneName(String droneId) {
    final drone = _getAvailableDrones().firstWhere(
      (d) => d['id'] == droneId,
      orElse: () => {'name': 'Unknown Drone'},
    );
    return drone['name'];
  }

  String _getOperatorName(String operatorId) {
    final operator = _getAvailableOperators().firstWhere(
      (o) => o['id'] == operatorId,
      orElse: () => {'name': 'Unknown Operator'},
    );
    return operator['name'];
  }

  void _selectLocationOnMap(bool isStartLocation) {
    // In a real implementation, this would open a map picker
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isStartLocation ? 'Select Start Location' : 'Select Target Location',
        ),
        content: const Text(
          'Map-based location selection would be implemented here. For now, coordinates will be set automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Mock coordinates for demonstration
                final location = LocationData(
                  latitude: 19.0760 + (DateTime.now().millisecond * 0.0001),
                  longitude: 72.8777 + (DateTime.now().millisecond * 0.0001),
                  address: isStartLocation
                      ? _startLocationController.text
                      : _targetLocationController.text,
                );

                if (isStartLocation) {
                  _startLocation = location;
                } else {
                  _targetLocation = location;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Set Location'),
          ),
        ],
      ),
    );
  }

  void _selectScheduledTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledStartTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledStartTime),
      );

      if (time != null) {
        setState(() {
          _scheduledStartTime = DateTime(
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

  void _clearForm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Form'),
        content: const Text('Are you sure you want to clear all form data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _missionTitleController.clear();
                _descriptionController.clear();
                _startLocationController.clear();
                _targetLocationController.clear();
                _payloadController.clear();
                _specialInstructionsController.clear();
                _estimatedDurationController.text = '60';
                _maxAltitudeController.text = '150';
                _maxSpeedController.text = '50';
                _selectedMissionType = MissionType.surveillance;
                _selectedPriority = MissionPriority.medium;
                _selectedEventId = null;
                _selectedDroneId = null;
                _selectedOperatorId = null;
                _startLocation = null;
                _targetLocation = null;
                _scheduledStartTime = DateTime.now().add(
                  const Duration(hours: 1),
                );
                _selectedEquipment.clear();
                _missionParameters.clear();
                _isRecurring = false;
                _weatherRequirement = 'Any';
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _submitMission() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors in the form'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create location data
      final startLocation =
          _startLocation ??
          LocationData(
            latitude: 19.0760, // Default coordinates
            longitude: 72.8777,
            address: _startLocationController.text,
          );

      final targetLocation =
          _targetLocation ??
          LocationData(
            latitude: 19.1136, // Default target coordinates
            longitude: 72.8697,
            address: _targetLocationController.text,
          );

      // Create the mission
      final mission = Mission(
        title: _missionTitleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedMissionType,
        priority: _selectedPriority,
        assignedDroneId: _selectedDroneId!,
        assignedOperatorId: _selectedOperatorId!,
        eventId: _selectedEventId,
        startLocation: startLocation,
        targetLocation: targetLocation,
        scheduledStartTime: _scheduledStartTime,
        estimatedDuration: Duration(
          minutes: int.parse(_estimatedDurationController.text),
        ),
        payload: _payloadController.text.trim(),
        weatherConditions: _weatherRequirement,
        maxAltitude: double.parse(_maxAltitudeController.text),
        maxSpeed: double.parse(_maxSpeedController.text),
        specialInstructions: _specialInstructionsController.text.trim(),
        equipment: _selectedEquipment,
        isRecurring: _isRecurring,
      );

      // In real implementation, would submit to mission provider
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mission "${mission.title}" created successfully!'),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // In real app, navigate to mission details
              },
            ),
          ),
        );

        // Clear form after successful submission
        _clearFormAfterSubmission();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create mission: $e'),
            backgroundColor: AppColors.error,
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

  void _clearFormAfterSubmission() {
    setState(() {
      _missionTitleController.clear();
      _descriptionController.clear();
      _startLocationController.clear();
      _targetLocationController.clear();
      _payloadController.clear();
      _specialInstructionsController.clear();
      _estimatedDurationController.text = '60';
      _maxAltitudeController.text = '150';
      _maxSpeedController.text = '50';
      _selectedMissionType = MissionType.surveillance;
      _selectedPriority = MissionPriority.medium;
      _selectedEventId = null;
      _selectedDroneId = null;
      _selectedOperatorId = null;
      _startLocation = null;
      _targetLocation = null;
      _scheduledStartTime = DateTime.now().add(const Duration(hours: 1));
      _selectedEquipment.clear();
      _missionParameters.clear();
      _isRecurring = false;
      _weatherRequirement = 'Any';
    });
  }
}
