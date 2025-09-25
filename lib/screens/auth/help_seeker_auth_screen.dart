import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../core/services/auth_service.dart';

class HelpSeekerAuthScreen extends ConsumerStatefulWidget {
  const HelpSeekerAuthScreen({super.key});

  @override
  ConsumerState<HelpSeekerAuthScreen> createState() =>
      _HelpSeekerAuthScreenState();
}

class _HelpSeekerAuthScreenState extends ConsumerState<HelpSeekerAuthScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _signupFormKey = GlobalKey<FormState>();

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form Controllers - Login
  final TextEditingController _loginPhoneController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();

  // Form Controllers - Signup
  final TextEditingController _signupNameController = TextEditingController();
  final TextEditingController _signupPhoneController = TextEditingController();
  final TextEditingController _signupAadharController = TextEditingController();
  final TextEditingController _signupPasswordController =
      TextEditingController();
  final TextEditingController _signupConfirmPasswordController =
      TextEditingController();
  final TextEditingController _signupEmailController = TextEditingController();

  // State
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isVerifyingAadhar = false;
  bool _isAadharVerified = false;
  String? _aadharError;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    _loginPhoneController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupPhoneController.dispose();
    _signupAadharController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    _signupEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && next.userType == AppUserType.helpSeeker) {
        AppRouter.goToHelpSeekerDashboard();
      } else if (next.errorMessage != null &&
          previous?.errorMessage != next.errorMessage) {
        _showErrorSnackBar(context, next.errorMessage!);
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.primaryColor),
          onPressed: () => AppRouter.goToUserTypeSelection(),
        ),
        title: Text(
          'Help Seeker',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Header Section
              _buildHeader(theme),

              // Toggle Buttons
              _buildToggleButtons(theme),

              const SizedBox(height: 32),

              // Form Section
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _isLogin = index == 0;
                    });
                  },
                  children: [
                    _buildLoginForm(theme, authState),
                    _buildSignupForm(theme, authState),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Emergency Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.red.shade400, Colors.red.shade600],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.emergency_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            _isLogin ? 'Welcome Back' : 'Join Drone AID',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _isLogin
                ? 'Sign in to access emergency services'
                : 'Register to get emergency assistance',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButtons(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _switchToLogin(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isLogin ? theme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Sign In',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _isLogin
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _switchToSignup(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isLogin ? theme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Sign Up',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: !_isLogin
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(ThemeData theme, AuthState authState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Phone Number Field
            _buildTextFormField(
              controller: _loginPhoneController,
              label: 'Phone Number',
              hint: '+91 9876543210',
              prefixIcon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  ref.read(phoneValidationProvider(value ?? '')),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
              ],
              theme: theme,
            ),

            const SizedBox(height: 20),

            // Password Field
            _buildTextFormField(
              controller: _loginPasswordController,
              label: 'Password',
              hint: 'Enter your password',
              prefixIcon: Icons.lock_rounded,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              validator: (value) =>
                  ref.read(passwordValidationProvider(value ?? '')),
              theme: theme,
            ),

            const SizedBox(height: 12),

            // Forgot Password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _handleForgotPassword,
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Login Button
            ElevatedButton(
              onPressed: authState.isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: Colors.red.withOpacity(0.4),
              ),
              child: authState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.login_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Sign In',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 32),

            // Demo Credentials
            _buildDemoCredentials(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupForm(ThemeData theme, AuthState authState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _signupFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Name Field
            _buildTextFormField(
              controller: _signupNameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              prefixIcon: Icons.person_rounded,
              textCapitalization: TextCapitalization.words,
              validator: (value) =>
                  ref.read(nameValidationProvider(value ?? '')),
              theme: theme,
            ),

            const SizedBox(height: 20),

            // Phone Number Field
            _buildTextFormField(
              controller: _signupPhoneController,
              label: 'Phone Number',
              hint: '+91 9876543210',
              prefixIcon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  ref.read(phoneValidationProvider(value ?? '')),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
              ],
              theme: theme,
            ),

            const SizedBox(height: 20),

            // Aadhar Number Field with Verification
            _buildAadharField(theme),

            const SizedBox(height: 20),

            // Email Field (Optional)
            _buildTextFormField(
              controller: _signupEmailController,
              label: 'Email (Optional)',
              hint: 'your.email@example.com',
              prefixIcon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              theme: theme,
            ),

            const SizedBox(height: 20),

            // Password Field
            _buildTextFormField(
              controller: _signupPasswordController,
              label: 'Password',
              hint: 'Create a password',
              prefixIcon: Icons.lock_rounded,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              validator: (value) =>
                  ref.read(passwordValidationProvider(value ?? '')),
              theme: theme,
            ),

            const SizedBox(height: 20),

            // Confirm Password Field
            _buildTextFormField(
              controller: _signupConfirmPasswordController,
              label: 'Confirm Password',
              hint: 'Re-enter your password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              validator: (value) {
                if (value != _signupPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              theme: theme,
            ),

            const SizedBox(height: 32),

            // Location Permission Notice
            _buildLocationNotice(theme),

            const SizedBox(height: 24),

            // Signup Button
            ElevatedButton(
              onPressed: (authState.isLoading || !_isAadharVerified)
                  ? null
                  : _handleSignup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: Colors.red.withOpacity(0.4),
              ),
              child: authState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_add_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Create Account',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    required ThemeData theme,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: theme.primaryColor),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        labelStyle: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildAadharField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _signupAadharController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
            _AadharNumberFormatter(),
          ],
          validator: (value) {
            final error = ref.read(aadharValidationProvider(value ?? ''));
            if (error != null) return error;
            if (!_isAadharVerified && value != null && value.isNotEmpty) {
              return 'Please verify your Aadhar number';
            }
            return null;
          },
          onChanged: (value) {
            if (value.replaceAll('-', '').length == 12 && !_isAadharVerified) {
              setState(() {
                _isAadharVerified = false;
                _aadharError = null;
              });
            }
          },
          decoration: InputDecoration(
            labelText: 'Aadhar Number',
            hintText: '1234-5678-9012',
            prefixIcon: Icon(
              Icons.credit_card_rounded,
              color: theme.primaryColor,
            ),
            suffixIcon: _isVerifyingAadhar
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.primaryColor,
                        ),
                      ),
                    ),
                  )
                : _isAadharVerified
                ? Icon(Icons.verified_rounded, color: Colors.green)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _isAadharVerified
                    ? Colors.green
                    : theme.colorScheme.outline.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.colorScheme.error),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            labelStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Verify Button
        if (_signupAadharController.text.replaceAll('-', '').length == 12 &&
            !_isAadharVerified)
          ElevatedButton.icon(
            onPressed: _isVerifyingAadhar ? null : _verifyAadharNumber,
            icon: _isVerifyingAadhar
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.verified_user_rounded, size: 18),
            label: Text(_isVerifyingAadhar ? 'Verifying...' : 'Verify Aadhar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

        // Verification Status
        if (_aadharError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _aadharError!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
          ),

        if (_isAadharVerified)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Aadhar number verified successfully',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLocationNotice(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_rounded,
            color: Colors.amber.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location Permission Required',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We need your location to provide emergency services and dispatch drones to your area.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoCredentials(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: theme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Demo Credentials',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Phone: +91 9876543210\nPassword: password123',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  void _switchToLogin() {
    if (!_isLogin) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _switchToSignup() {
    if (_isLogin) {
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    final success = await ref
        .read(authProvider.notifier)
        .loginHelpSeeker(
          identifier: _loginPhoneController.text.trim(),
          password: _loginPasswordController.text,
        );

    if (success) {
      // Navigation is handled by the listener
    }
  }

  Future<void> _handleSignup() async {
    if (!_signupFormKey.currentState!.validate()) return;

    if (!_isAadharVerified) {
      _showErrorSnackBar(context, 'Please verify your Aadhar number first');
      return;
    }

    final success = await ref
        .read(authProvider.notifier)
        .registerHelpSeeker(
          name: _signupNameController.text.trim(),
          phone: _signupPhoneController.text.trim(),
          aadharNumber: _signupAadharController.text.trim(),
          password: _signupPasswordController.text,
          email: _signupEmailController.text.trim().isEmpty
              ? null
              : _signupEmailController.text.trim(),
        );

    if (success) {
      // Navigation is handled by the listener
    }
  }

  Future<void> _verifyAadharNumber() async {
    if (_signupAadharController.text.replaceAll('-', '').length != 12) {
      setState(() {
        _aadharError = 'Please enter a valid 12-digit Aadhar number';
      });
      return;
    }

    setState(() {
      _isVerifyingAadhar = true;
      _aadharError = null;
    });

    try {
      final result = await ref
          .read(authProvider.notifier)
          .verifyAadharNumber(_signupAadharController.text.trim());

      setState(() {
        _isVerifyingAadhar = false;
        if (result.success) {
          _isAadharVerified = true;
          _aadharError = null;
        } else {
          _isAadharVerified = false;
          _aadharError = result.message;
        }
      });
    } catch (e) {
      setState(() {
        _isVerifyingAadhar = false;
        _isAadharVerified = false;
        _aadharError = 'Verification failed. Please try again.';
      });
    }
  }

  void _handleForgotPassword() {
    // Show forgot password dialog or navigate to forgot password screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot Password'),
        content: const Text(
          'Password reset functionality will be implemented in the next version. '
          'For demo purposes, use the provided demo credentials.',
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

  void _showErrorSnackBar(BuildContext context, String message) {
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
}

// Custom formatter for Aadhar number
class _AadharNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('-', '');

    if (text.length <= 4) {
      return newValue.copyWith(text: text);
    } else if (text.length <= 8) {
      return newValue.copyWith(
        text: '${text.substring(0, 4)}-${text.substring(4)}',
        selection: TextSelection.collapsed(offset: text.length + 1),
      );
    } else if (text.length <= 12) {
      return newValue.copyWith(
        text:
            '${text.substring(0, 4)}-${text.substring(4, 8)}-${text.substring(8)}',
        selection: TextSelection.collapsed(offset: text.length + 2),
      );
    }

    return oldValue;
  }
}
