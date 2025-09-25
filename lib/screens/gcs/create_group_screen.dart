import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_theme.dart';
import '../../providers/group_management_provider.dart';
import '../../models/group_event.dart';
import '../../models/gcs_station.dart';
import '../../models/user.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form controllers
  final _eventNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _affectedRadiusController = TextEditingController();
  final _estimatedPeopleController = TextEditingController();

  // Form values
  EventType _selectedEventType = EventType.flood;
  EventSeverity _selectedSeverity = EventSeverity.moderate;
  EventPriority _selectedPriority = EventPriority.medium;
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime? _endDate;
  TimeOfDay? _endTime;
  LocationData? _selectedLocation;
  String? _selectedCoordinatingAgency;
  List<String> _selectedGCSStations = [];
  List<String> _selectedOperators = [];

  bool _isSubmitting = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _affectedRadiusController.text = '5.0';
    _estimatedPeopleController.text = '0';
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _affectedRadiusController.dispose();
    _estimatedPeopleController.dispose();
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
                        _buildEventTypeSection(),
                        const SizedBox(height: 24),
                        _buildLocationSection(),
                        const SizedBox(height: 24),
                        _buildDateTimeSection(),
                        const SizedBox(height: 24),
                        _buildSeverityAndPrioritySection(),
                        const SizedBox(height: 24),
                        _buildContactInfoSection(),
                        const SizedBox(height: 24),
                        _buildResourceAssignmentSection(provider),
                        const SizedBox(height: 24),
                        _buildAdditionalDetailsSection(),
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
              const Icon(Icons.group_add, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Create Event/Group',
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
            'Create and manage emergency events or operational groups',
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
          controller: _eventNameController,
          decoration: const InputDecoration(
            labelText: 'Event Name *',
            hintText: 'Enter event or group name',
            prefixIcon: Icon(Icons.title),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Event name is required';
            }
            if (value.trim().length < 3) {
              return 'Event name must be at least 3 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description *',
            hintText: 'Describe the event or situation',
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
      ],
    );
  }

  Widget _buildEventTypeSection() {
    return _buildSection(
      title: 'Event Type',
      icon: Icons.category,
      children: [
        DropdownButtonFormField<EventType>(
          value: _selectedEventType,
          decoration: const InputDecoration(
            labelText: 'Event Type *',
            prefixIcon: Icon(Icons.event),
          ),
          items: EventType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Row(
                children: [
                  Icon(_getEventTypeIcon(type), size: 20),
                  const SizedBox(width: 8),
                  Text(type.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedEventType = value;
                _selectedSeverity = value.defaultSeverity;
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
                  _selectedEventType.description,
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

  Widget _buildLocationSection() {
    return _buildSection(
      title: 'Location',
      icon: Icons.location_on,
      children: [
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'Location *',
            hintText: 'Enter location or address',
            prefixIcon: const Icon(Icons.place),
            suffixIcon: IconButton(
              onPressed: _selectLocationOnMap,
              icon: const Icon(Icons.map),
              tooltip: 'Select on Map',
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Location is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _affectedRadiusController,
                decoration: const InputDecoration(
                  labelText: 'Affected Radius (km) *',
                  prefixIcon: Icon(Icons.radio_button_unchecked),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  final radius = double.tryParse(value);
                  if (radius == null || radius <= 0) {
                    return 'Invalid radius';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _estimatedPeopleController,
                decoration: const InputDecoration(
                  labelText: 'Est. Affected People',
                  prefixIcon: Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final people = int.tryParse(value);
                    if (people == null || people < 0) {
                      return 'Invalid number';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        if (_selectedLocation != null) ...[
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
                    'Selected: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
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

  Widget _buildDateTimeSection() {
    return _buildSection(
      title: 'Schedule',
      icon: Icons.schedule,
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _selectStartDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Start Date *',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: DateFormat('dd/MM/yyyy').format(_startDate),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: _selectStartTime,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Start Time *',
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    controller: TextEditingController(
                      text: _startTime.format(context),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _selectEndDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'End Date (Optional)',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: _endDate != null
                          ? DateFormat('dd/MM/yyyy').format(_endDate!)
                          : '',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: _endDate != null ? _selectEndTime : null,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'End Time (Optional)',
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    controller: TextEditingController(
                      text: _endTime != null ? _endTime!.format(context) : '',
                    ),
                    enabled: _endDate != null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeverityAndPrioritySection() {
    return _buildSection(
      title: 'Classification',
      icon: Icons.priority_high,
      children: [
        DropdownButtonFormField<EventSeverity>(
          value: _selectedSeverity,
          decoration: const InputDecoration(
            labelText: 'Severity *',
            prefixIcon: Icon(Icons.warning),
          ),
          items: EventSeverity.values.map((severity) {
            return DropdownMenuItem(
              value: severity,
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: _getSeverityColor(severity),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(severity.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedSeverity = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<EventPriority>(
          value: _selectedPriority,
          decoration: const InputDecoration(
            labelText: 'Priority *',
            prefixIcon: Icon(Icons.flag),
          ),
          items: EventPriority.values.map((priority) {
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
                  Text(priority.displayName),
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

  Widget _buildContactInfoSection() {
    return _buildSection(
      title: 'Contact Information',
      icon: Icons.contact_phone,
      children: [
        TextFormField(
          controller: _contactPersonController,
          decoration: const InputDecoration(
            labelText: 'Contact Person',
            hintText: 'Emergency coordinator name',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _contactPhoneController,
          decoration: const InputDecoration(
            labelText: 'Contact Phone',
            hintText: '+91-XXXXXXXXXX',
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _contactEmailController,
          decoration: const InputDecoration(
            labelText: 'Contact Email',
            hintText: 'emergency@example.com',
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Invalid email format';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedCoordinatingAgency,
          decoration: const InputDecoration(
            labelText: 'Coordinating Agency',
            prefixIcon: Icon(Icons.business),
          ),
          hint: const Text('Select agency'),
          items: _getCoordinatingAgencies().map((agency) {
            return DropdownMenuItem(value: agency, child: Text(agency));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCoordinatingAgency = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildResourceAssignmentSection(GroupManagementProvider provider) {
    return _buildSection(
      title: 'Resource Assignment',
      icon: Icons.assignment_ind,
      children: [
        // GCS Stations Assignment
        const Text(
          'Ground Control Stations',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              if (_selectedGCSStations.isEmpty)
                const Text(
                  'No GCS stations assigned',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ...provider.gcsStations.map((station) {
                final isSelected = _selectedGCSStations.contains(station.id);
                return CheckboxListTile(
                  title: Text(station.name),
                  subtitle: Text(
                    '${station.statusDisplay} • ${station.currentOperators}/${station.maxCapacity}',
                  ),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedGCSStations.add(station.id);
                      } else {
                        _selectedGCSStations.remove(station.id);
                      }
                    });
                  },
                  secondary: Icon(
                    Icons.location_city,
                    color: station.isOperational
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Selected: ${_selectedGCSStations.length} station(s)',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            if (_selectedGCSStations.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedGCSStations.clear();
                  });
                },
                child: const Text('Clear All'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalDetailsSection() {
    return _buildSection(
      title: 'Additional Details',
      icon: Icons.more_horiz,
      children: [
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
                'Summary',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text('Event Type: ${_selectedEventType.displayName}'),
              Text('Severity: ${_selectedSeverity.displayName}'),
              Text('Priority: ${_selectedPriority.displayName}'),
              Text(
                'Start: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute))}',
              ),
              if (_endDate != null && _endTime != null)
                Text(
                  'End: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime(_endDate!.year, _endDate!.month, _endDate!.day, _endTime!.hour, _endTime!.minute))}',
                ),
              Text('Assigned Stations: ${_selectedGCSStations.length}'),
              const SizedBox(height: 8),
              const Text(
                'Note: This event will be created and can be modified later from the event management section.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
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
            onPressed: _isSubmitting || provider.isLoading ? null : _submitForm,
            icon: _isSubmitting || provider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(
              _isSubmitting || provider.isLoading
                  ? 'Creating Event...'
                  : 'Create Event',
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

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.flood:
        return Icons.water;
      case EventType.fireIncident:
        return Icons.local_fire_department;
      case EventType.earthquake:
        return Icons.terrain;
      case EventType.hurricane:
        return Icons.storm;
      case EventType.massCasualty:
        return Icons.medical_services;
      case EventType.industrialAccident:
        return Icons.car_crash;
      case EventType.other:
        return Icons.search;
      case EventType.cyberAttack:
        return Icons.visibility;
      default:
        return Icons.event;
    }
  }

  Color _getSeverityColor(EventSeverity severity) {
    switch (severity) {
      case EventSeverity.critical:
        return AppColors.error;
      case EventSeverity.major:
        return Colors.deepOrange;
      case EventSeverity.moderate:
        return AppColors.warning;
      case EventSeverity.minor:
        return AppColors.info;
    }
  }

  Color _getPriorityColor(EventPriority priority) {
    switch (priority) {
      case EventPriority.critical:
        return AppColors.error;
      case EventPriority.high:
        return Colors.deepOrange;
      case EventPriority.medium:
        return AppColors.warning;
      case EventPriority.low:
        return AppColors.success;
    }
  }

  List<String> _getCoordinatingAgencies() {
    return [
      'National Disaster Management Authority (NDMA)',
      'State Disaster Management Authority',
      'District Disaster Management Authority',
      'Indian Navy',
      'Indian Air Force',
      'Coast Guard',
      'Fire Department',
      'Police Department',
      'Medical Emergency Services',
      'Municipal Corporation',
      'Red Cross Society',
      'Other',
    ];
  }

  void _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  void _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (time != null) {
      setState(() {
        _startTime = time;
      });
    }
  }

  void _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
        if (_endTime == null) {
          _endTime = _startTime;
        }
      });
    }
  }

  void _selectEndTime() async {
    if (_endDate == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _endTime ?? _startTime,
    );
    if (time != null) {
      setState(() {
        _endTime = time;
      });
    }
  }

  void _selectLocationOnMap() {
    // In a real implementation, this would open a map picker
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Selection'),
        content: const Text(
          'Map-based location selection would be implemented here. For now, coordinates will be set automatically based on the entered address.',
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
                _selectedLocation = LocationData(
                  latitude: 19.0760 + (DateTime.now().millisecond * 0.0001),
                  longitude: 72.8777 + (DateTime.now().millisecond * 0.0001),
                  address: _locationController.text,
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Set Location'),
          ),
        ],
      ),
    );
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
                _eventNameController.clear();
                _descriptionController.clear();
                _locationController.clear();
                _contactPersonController.clear();
                _contactPhoneController.clear();
                _contactEmailController.clear();
                _affectedRadiusController.text = '5.0';
                _estimatedPeopleController.text = '0';
                _selectedEventType = EventType.flood;
                _selectedSeverity = EventSeverity.moderate;
                _selectedPriority = EventPriority.medium;
                _startDate = DateTime.now();
                _startTime = TimeOfDay.now();
                _endDate = null;
                _endTime = null;
                _selectedLocation = null;
                _selectedCoordinatingAgency = null;
                _selectedGCSStations.clear();
                _selectedOperators.clear();
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

  void _submitForm() async {
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
      final location =
          _selectedLocation ??
          LocationData(
            latitude: 19.0760, // Default coordinates
            longitude: 72.8777,
            address: _locationController.text,
          );

      // Create DateTime objects for start and end times
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      DateTime? endDateTime;
      if (_endDate != null && _endTime != null) {
        endDateTime = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          _endTime!.hour,
          _endTime!.minute,
        );
      }

      // Create the event
      final event = GroupEvent(
        title: _eventNameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedEventType,
        severity: _selectedSeverity,
        priority: _selectedPriority,
        location: location,
        address: _locationController.text.trim(),
        affectedRadius: double.parse(_affectedRadiusController.text),
        estimatedAffectedPeople:
            int.tryParse(_estimatedPeopleController.text) ?? 0,
        startTime: startDateTime,
        endTime: endDateTime,
        createdBy: 'current-user-id', // In real app, get from auth provider
        coordinatingAgency: _selectedCoordinatingAgency,
        contactPerson: _contactPersonController.text.trim().isNotEmpty
            ? _contactPersonController.text.trim()
            : null,
        contactPhone: _contactPhoneController.text.trim().isNotEmpty
            ? _contactPhoneController.text.trim()
            : null,
        contactEmail: _contactEmailController.text.trim().isNotEmpty
            ? _contactEmailController.text.trim()
            : null,
      );

      // Submit the event
      await context.read<GroupManagementProvider>().createEvent(event);

      // Assign GCS stations if selected
      for (final stationId in _selectedGCSStations) {
        await context.read<GroupManagementProvider>().assignStationToEvent(
          event.id,
          stationId,
        );
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event "${event.title}" created successfully!'),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // In real app, navigate to event details
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
            content: Text('Failed to create event: $e'),
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
      _eventNameController.clear();
      _descriptionController.clear();
      _locationController.clear();
      _contactPersonController.clear();
      _contactPhoneController.clear();
      _contactEmailController.clear();
      _affectedRadiusController.text = '5.0';
      _estimatedPeopleController.text = '0';
      _selectedEventType = EventType.flood;
      _selectedSeverity = EventSeverity.moderate;
      _selectedPriority = EventPriority.medium;
      _startDate = DateTime.now();
      _startTime = TimeOfDay.now();
      _endDate = null;
      _endTime = null;
      _selectedLocation = null;
      _selectedCoordinatingAgency = null;
      _selectedGCSStations.clear();
      _selectedOperators.clear();
    });
  }
}
