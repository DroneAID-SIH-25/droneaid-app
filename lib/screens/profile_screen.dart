import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../core/constants/app_strings.dart';
import '../providers/auth_provider.dart';
import '../routes/app_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeControllers();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  void _initializeControllers() {
    final authState = ref.read(authProvider);
    if (authState.user != null) {
      _nameController.text = authState.user!.name;
      _phoneController.text = authState.user!.phone;
      _emailController.text = authState.user!.email;
    } else if (authState.gcsOperator != null) {
      _nameController.text = authState.gcsOperator!.fullName;
      _phoneController.text = authState.gcsOperator!.phoneNumber;
      _emailController.text = authState.gcsOperator!.email;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppRouter.goToWelcome();
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                'Save',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Header
              _buildProfileHeader(theme, authState),

              const SizedBox(height: 32),

              // Profile Form
              _buildProfileForm(theme, authState),

              const SizedBox(height: 32),

              // User Type Specific Info
              _buildUserTypeInfo(theme, authState),

              const SizedBox(height: 32),

              // Action Buttons
              _buildActionButtons(theme, authState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, AuthState authState) {
    final isHelpSeeker = authState.userType == AppUserType.helpSeeker;
    final displayName = authState.displayName ?? 'User';
    final email = authState.email ?? '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isHelpSeeker
              ? [Colors.red.shade400, Colors.red.shade600]
              : [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isHelpSeeker ? Colors.red : theme.primaryColor).withOpacity(
              0.3,
            ),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: Icon(
              isHelpSeeker ? Icons.emergency_rounded : Icons.flight_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            displayName,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Email
          Text(
            email,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // User Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              isHelpSeeker ? 'Help Seeker' : 'GCS Operator',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm(ThemeData theme, AuthState authState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 24),

            // Name Field
            _buildFormField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_rounded,
              enabled: _isEditing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
              theme: theme,
            ),

            const SizedBox(height: 20),

            // Phone Field
            _buildFormField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone_rounded,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone number is required';
                }
                return null;
              },
              theme: theme,
            ),

            const SizedBox(height: 20),

            // Email Field
            _buildFormField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email_rounded,
              enabled: false, // Email should not be editable
              keyboardType: TextInputType.emailAddress,
              theme: theme,
            ),

            if (_isEditing) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                        });
                        _initializeControllers(); // Reset to original values
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    required ThemeData theme,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primaryColor, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        labelStyle: TextStyle(
          color: enabled
              ? theme.colorScheme.onSurface.withOpacity(0.7)
              : Colors.grey.shade600,
        ),
      ),
      style: TextStyle(
        color: enabled
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurface.withOpacity(0.7),
      ),
    );
  }

  Widget _buildUserTypeInfo(ThemeData theme, AuthState authState) {
    final isHelpSeeker = authState.userType == AppUserType.helpSeeker;

    List<Map<String, dynamic>> infoItems = [];

    if (isHelpSeeker && authState.user != null) {
      final user = authState.user!;
      infoItems = [
        {
          'icon': Icons.location_on_rounded,
          'title': 'Location',
          'subtitle': user.location.address ?? 'Location data available',
          'color': Colors.green,
        },
        {
          'icon': Icons.access_time_rounded,
          'title': 'Member Since',
          'subtitle': _formatDate(user.createdAt),
          'color': Colors.blue,
        },
        {
          'icon': Icons.security_rounded,
          'title': 'Account Status',
          'subtitle': user.isActive ? 'Active' : 'Inactive',
          'color': user.isActive ? Colors.green : Colors.orange,
        },
      ];
    } else if (!isHelpSeeker && authState.gcsOperator != null) {
      final operator = authState.gcsOperator!;
      infoItems = [
        {
          'icon': Icons.badge_rounded,
          'title': 'Employee ID',
          'subtitle': operator.operatorId,
          'color': Colors.blue,
        },
        {
          'icon': Icons.business_rounded,
          'title': 'Organization',
          'subtitle': operator.organization,
          'color': Colors.purple,
        },
        {
          'icon': Icons.work_rounded,
          'title': 'Designation',
          'subtitle': operator.designation,
          'color': Colors.green,
        },
        {
          'icon': Icons.flight_rounded,
          'title': 'Status',
          'subtitle': operator.isOnDuty ? 'On Duty' : 'Off Duty',
          'color': operator.isOnDuty ? Colors.green : Colors.orange,
        },
      ];
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isHelpSeeker ? 'Account Information' : 'Professional Information',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          ...infoItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: item['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['subtitle'] as String,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, AuthState authState) {
    return Column(
      children: [
        // Change Password Button
        _buildActionButton(
          icon: Icons.lock_rounded,
          title: 'Change Password',
          subtitle: 'Update your account password',
          onTap: _showChangePasswordDialog,
          theme: theme,
          color: Colors.orange,
        ),

        const SizedBox(height: 16),

        // Settings Button
        _buildActionButton(
          icon: Icons.settings_rounded,
          title: 'Settings',
          subtitle: 'App preferences and configuration',
          onTap: () => AppRouter.goToSettings(),
          theme: theme,
          color: Colors.blue,
        ),

        const SizedBox(height: 16),

        // Logout Button
        _buildActionButton(
          icon: Icons.logout_rounded,
          title: 'Logout',
          subtitle: 'Sign out of your account',
          onTap: _showLogoutDialog,
          theme: theme,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeData theme,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authProvider.notifier)
        .updateProfile(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
        );

    if (success) {
      setState(() {
        _isEditing = false;
      });
      _showSuccessMessage('Profile updated successfully');
    } else {
      final error = ref.read(authProvider).errorMessage;
      _showErrorMessage(error ?? 'Failed to update profile');
    }
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text(
          'Password change functionality will be implemented in the next version.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red.shade600),
            const SizedBox(width: 12),
            const Text('Logout'),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout? You will need to login again to access your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authProvider.notifier).logout();
              AppRouter.goToWelcome();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
