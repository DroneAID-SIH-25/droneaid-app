import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../models/emergency_request.dart';
import '../../providers/emergency_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/notification_provider.dart';
import '../../routes/app_router.dart';

class RequestHelpScreen extends StatefulWidget {
  const RequestHelpScreen({super.key});

  @override
  State<RequestHelpScreen> createState() => _RequestHelpScreenState();
}

class _RequestHelpScreenState extends State<RequestHelpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _contactController = TextEditingController();

  EmergencyType _selectedEmergencyType = EmergencyType.medicalEmergency;
  Priority _selectedPriority = Priority.high;
  bool _isSubmitting = false;
  bool _useCustomLocation = false;

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeForm();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideController.forward();
  }

  void _initializeForm() {
    // Pre-fill contact number if available from user profile
    // In a real app, this would come from user preferences
    _contactController.text = '+91 9876543210';
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final emergencyProvider = context.read<EmergencyProvider>();
      final locationProvider = context.read<LocationProvider>();
      final notificationProvider = context.read<NotificationProvider>();

      // Create emergency request
      final request = await emergencyProvider.createEmergencyRequest(
        userId: 'user_001', // In a real app, get from auth provider
        emergencyType: _selectedEmergencyType,
        description: _descriptionController.text.trim(),
        contactNumber: _contactController.text.trim(),
        priority: _selectedPriority,
        customLocation: _useCustomLocation
            ? locationProvider.currentLocation
            : null,
      );

      // Show success notification
      notificationProvider.notifyEmergencyUpdate(
        requestId: request.id,
        title: 'Emergency Request Submitted',
        message:
            'Your emergency request has been received and is being processed.',
        priority: NotificationPriority.urgent,
      );

      if (mounted) {
        // Show success dialog
        await _showSuccessDialog(request);

        // Navigate to tracking screen
        AppRouter.goToTrackMission();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to submit request: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
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

  Future<void> _showSuccessDialog(EmergencyRequest request) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: AppColors.success, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Request Submitted'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency ID: ${request.emergencyCode}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your emergency request has been submitted successfully. Nearby drones are being dispatched to your location.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Keep your phone accessible for updates.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Track Mission'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Request Emergency Help',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emergency Alert Header
                _buildEmergencyHeader(),
                const SizedBox(height: 24),

                // Quick Emergency Buttons
                _buildQuickEmergencyButtons(),
                const SizedBox(height: 24),

                // Emergency Type Selection
                _buildEmergencyTypeSection(),
                const SizedBox(height: 20),

                // Priority Selection
                _buildPrioritySection(),
                const SizedBox(height: 20),

                // Description
                _buildDescriptionSection(),
                const SizedBox(height: 20),

                // Location Information
                _buildLocationSection(),
                const SizedBox(height: 20),

                // Contact Information
                _buildContactSection(),
                const SizedBox(height: 32),

                // Submit Button
                _buildSubmitButton(),
                const SizedBox(height: 16),

                // Emergency Contacts
                _buildEmergencyContactsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyHeader() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.error, AppColors.error.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.emergency, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Emergency Assistance',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Help is on the way. Provide accurate information for the fastest response.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickEmergencyButtons() {
    final quickEmergencies = [
      {
        'type': EmergencyType.medicalEmergency,
        'icon': MdiIcons.heartPulse,
        'label': 'Medical',
        'color': Colors.red,
      },
      {
        'type': EmergencyType.fireEmergency,
        'icon': MdiIcons.fire,
        'label': 'Fire',
        'color': Colors.orange,
      },
      {
        'type': EmergencyType.accident,
        'icon': Icons.car_crash,
        'label': 'Accident',
        'color': Colors.amber,
      },
      {
        'type': EmergencyType.flooding,
        'icon': Icons.flood,
        'label': 'Flood',
        'color': Colors.blue,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Selection',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: quickEmergencies.length,
          itemBuilder: (context, index) {
            final emergency = quickEmergencies[index];
            final isSelected = _selectedEmergencyType == emergency['type'];

            return Material(
              color: isSelected
                  ? (emergency['color'] as Color).withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: isSelected ? 4 : 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _selectedEmergencyType = emergency['type'] as EmergencyType;
                    _selectedPriority = _selectedEmergencyType.defaultPriority;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(
                            color: emergency['color'] as Color,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        emergency['icon'] as IconData,
                        color: emergency['color'] as Color,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        emergency['label'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? emergency['color'] as Color
                              : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmergencyTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emergency Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<EmergencyType>(
          value: _selectedEmergencyType,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.warning_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          items: EmergencyType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getEmergencyTypeColor(type),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(type.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedEmergencyType = value!;
              _selectedPriority = value.defaultPriority;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPrioritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority Level',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Priority>(
          value: _selectedPriority,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.priority_high_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          items: Priority.values.map((priority) {
            return DropdownMenuItem(
              value: priority,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(priority).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      priority.displayName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getPriorityColor(priority),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(priority.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedPriority = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Describe the emergency situation in detail...',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 60),
              child: Icon(Icons.description_outlined),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please provide a description';
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

  Widget _buildLocationSection() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        final location = locationProvider.locationOrDefault;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: locationProvider.isLocationAvailable
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          locationProvider.isLocationAvailable
                              ? 'Current Location:'
                              : 'Default Location (India):',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (locationProvider.isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    location.address ?? 'India',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  Text(
                    'Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: locationProvider.refreshLocation,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Refresh'),
                      ),
                      const SizedBox(width: 8),
                      if (locationProvider.error != null)
                        TextButton.icon(
                          onPressed: locationProvider.openLocationSettings,
                          icon: const Icon(Icons.settings, size: 16),
                          label: const Text('Settings'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Number',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _contactController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'Enter contact number for updates',
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please provide a contact number';
            }
            if (value.length < 10) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: _isSubmitting ? 0 : 8,
          shadowColor: AppColors.error.withOpacity(0.5),
        ),
        child: _isSubmitting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Submitting Request...', style: TextStyle(fontSize: 16)),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emergency, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'SUBMIT EMERGENCY REQUEST',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmergencyContactsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.info.withOpacity(0.1),
            AppColors.info.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_in_talk, color: AppColors.info, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Emergency Contacts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEmergencyContact('Police', '100', Icons.local_police),
          const SizedBox(height: 8),
          _buildEmergencyContact(
            'Fire Department',
            '101',
            Icons.local_fire_department,
          ),
          const SizedBox(height: 8),
          _buildEmergencyContact('Ambulance', '108', Icons.local_hospital),
          const SizedBox(height: 8),
          _buildEmergencyContact('National Emergency', '112', Icons.emergency),
        ],
      ),
    );
  }

  Widget _buildEmergencyContact(String service, String number, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.info, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            service,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            number,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.info,
            ),
          ),
        ),
      ],
    );
  }

  Color _getEmergencyTypeColor(EmergencyType type) {
    switch (type) {
      case EmergencyType.medicalEmergency:
        return Colors.red;
      case EmergencyType.fireEmergency:
        return Colors.orange;
      case EmergencyType.naturalDisaster:
        return Colors.purple;
      case EmergencyType.accident:
        return Colors.amber;
      case EmergencyType.security:
        return Colors.indigo;
      case EmergencyType.searchAndRescue:
        return Colors.green;
      case EmergencyType.flooding:
        return Colors.blue;
      case EmergencyType.earthquake:
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.critical:
        return AppColors.error;
      case Priority.high:
        return AppColors.warning;
      case Priority.medium:
        return AppColors.info;
      case Priority.low:
        return AppColors.success;
    }
  }
}
