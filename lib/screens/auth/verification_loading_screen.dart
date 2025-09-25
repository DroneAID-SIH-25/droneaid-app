import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';

class VerificationLoadingScreen extends ConsumerStatefulWidget {
  final String verificationType;
  final Map<String, dynamic>? userData;

  const VerificationLoadingScreen({
    super.key,
    required this.verificationType,
    this.userData,
  });

  @override
  ConsumerState<VerificationLoadingScreen> createState() =>
      _VerificationLoadingScreenState();
}

class _VerificationLoadingScreenState
    extends ConsumerState<VerificationLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;

  int _currentStepIndex = 0;
  final List<VerificationStep> _verificationSteps = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupVerificationSteps();
    _startVerificationProcess();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
    _fadeController.forward();
  }

  void _setupVerificationSteps() {
    switch (widget.verificationType) {
      case 'aadhar':
        _verificationSteps.addAll([
          VerificationStep(
            title: 'Connecting to UIDAI',
            description: 'Establishing secure connection...',
            icon: Icons.wifi_rounded,
            duration: 2,
          ),
          VerificationStep(
            title: 'Validating Aadhar Number',
            description: 'Checking number format and checksum...',
            icon: Icons.credit_card_rounded,
            duration: 3,
          ),
          VerificationStep(
            title: 'Biometric Verification',
            description: 'Simulating biometric validation...',
            icon: Icons.fingerprint_rounded,
            duration: 4,
          ),
          VerificationStep(
            title: 'Final Verification',
            description: 'Completing verification process...',
            icon: Icons.verified_user_rounded,
            duration: 2,
          ),
        ]);
        break;

      case 'location':
        _verificationSteps.addAll([
          VerificationStep(
            title: 'Requesting Location Access',
            description: 'Requesting device location permissions...',
            icon: Icons.location_searching_rounded,
            duration: 2,
          ),
          VerificationStep(
            title: 'Acquiring GPS Signal',
            description: 'Connecting to GPS satellites...',
            icon: Icons.gps_fixed_rounded,
            duration: 3,
          ),
          VerificationStep(
            title: 'Determining Location',
            description: 'Calculating precise coordinates...',
            icon: Icons.location_on_rounded,
            duration: 3,
          ),
          VerificationStep(
            title: 'Verifying Coverage Area',
            description: 'Checking service availability...',
            icon: Icons.network_check_rounded,
            duration: 2,
          ),
        ]);
        break;

      case 'registration':
        _verificationSteps.addAll([
          VerificationStep(
            title: 'Validating Information',
            description: 'Checking provided details...',
            icon: Icons.fact_check_rounded,
            duration: 2,
          ),
          VerificationStep(
            title: 'Creating Account',
            description: 'Setting up your profile...',
            icon: Icons.person_add_rounded,
            duration: 3,
          ),
          VerificationStep(
            title: 'Configuring Services',
            description: 'Activating emergency features...',
            icon: Icons.settings_rounded,
            duration: 2,
          ),
          VerificationStep(
            title: 'Final Setup',
            description: 'Completing registration...',
            icon: Icons.check_circle_rounded,
            duration: 2,
          ),
        ]);
        break;

      default:
        _verificationSteps.addAll([
          VerificationStep(
            title: 'Processing Request',
            description: 'Validating your information...',
            icon: Icons.hourglass_empty_rounded,
            duration: 3,
          ),
          VerificationStep(
            title: 'Completing Verification',
            description: 'Finalizing the process...',
            icon: Icons.done_all_rounded,
            duration: 2,
          ),
        ]);
    }
  }

  void _startVerificationProcess() {
    Future.delayed(const Duration(seconds: 1), () {
      _processNextStep();
    });
  }

  void _processNextStep() {
    if (_currentStepIndex < _verificationSteps.length) {
      setState(() {
        // Current step index will be used to show progress
      });

      final currentStep = _verificationSteps[_currentStepIndex];

      Future.delayed(Duration(seconds: currentStep.duration), () {
        setState(() {
          _currentStepIndex++;
        });

        if (_currentStepIndex < _verificationSteps.length) {
          _processNextStep();
        } else {
          _completeVerification();
        }
      });
    }
  }

  void _completeVerification() {
    final authState = ref.read(authProvider);

    // Simulate random success/failure for demo
    final isSuccess = DateTime.now().millisecondsSinceEpoch % 3 != 0;

    Future.delayed(const Duration(seconds: 1), () {
      if (isSuccess) {
        if (authState.isAuthenticated) {
          if (authState.userType == AppUserType.helpSeeker) {
            AppRouter.goToHelpSeekerDashboard();
          } else {
            AppRouter.goToGCSDashboard();
          }
        } else {
          AppRouter.goToUserTypeSelection();
        }
      } else {
        _showVerificationError();
      }
    });
  }

  void _showVerificationError() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_rounded, color: Colors.red.shade600, size: 28),
            const SizedBox(width: 12),
            const Text('Verification Failed'),
          ],
        ),
        content: Text(
          'The verification process could not be completed. Please check your information and try again.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              AppRouter.goBack();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.primaryColor.withOpacity(0.1),
              theme.primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'Verification in Progress',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please wait while we verify your information',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Main Animation Area
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Icon
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: AnimatedBuilder(
                                animation: _rotationAnimation,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle:
                                        _rotationAnimation.value * 2 * 3.14159,
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            theme.primaryColor,
                                            theme.primaryColor.withOpacity(0.8),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.primaryColor
                                                .withOpacity(0.3),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        _currentStepIndex <
                                                _verificationSteps.length
                                            ? _verificationSteps[_currentStepIndex]
                                                  .icon
                                            : Icons.check_circle_rounded,
                                        size: 60,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 40),

                        // Current Step Info
                        if (_currentStepIndex < _verificationSteps.length) ...[
                          Text(
                            _verificationSteps[_currentStepIndex].title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _verificationSteps[_currentStepIndex].description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ] else ...[
                          Text(
                            'Verification Complete',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Redirecting to dashboard...',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],

                        const SizedBox(height: 40),

                        // Loading Indicator
                        SpinKitWave(color: theme.primaryColor, size: 40),
                      ],
                    ),
                  ),
                ),

                // Progress Steps
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Progress Bar
                        Container(
                          width: double.infinity,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor:
                                (_currentStepIndex + 1) /
                                _verificationSteps.length,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.primaryColor,
                                    theme.primaryColor.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'Step ${_currentStepIndex + 1} of ${_verificationSteps.length}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Step List
                        Expanded(
                          child: ListView.builder(
                            itemCount: _verificationSteps.length,
                            itemBuilder: (context, index) {
                              final step = _verificationSteps[index];
                              final isCompleted = index < _currentStepIndex;
                              final isCurrent = index == _currentStepIndex;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? Colors.green.shade50
                                      : isCurrent
                                      ? theme.primaryColor.withOpacity(0.1)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isCompleted
                                        ? Colors.green.shade200
                                        : isCurrent
                                        ? theme.primaryColor.withOpacity(0.3)
                                        : Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isCompleted
                                            ? Colors.green.shade500
                                            : isCurrent
                                            ? theme.primaryColor
                                            : Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        isCompleted
                                            ? Icons.check_rounded
                                            : isCurrent
                                            ? step.icon
                                            : Icons.pending_rounded,
                                        size: 18,
                                        color: isCompleted || isCurrent
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            step.title,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: isCompleted
                                                      ? Colors.green.shade700
                                                      : isCurrent
                                                      ? theme.primaryColor
                                                      : Colors.grey.shade600,
                                                ),
                                          ),
                                          if (isCurrent)
                                            Text(
                                              step.description,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.7),
                                                  ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (isCurrent)
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                theme.primaryColor,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VerificationStep {
  final String title;
  final String description;
  final IconData icon;
  final int duration;

  VerificationStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.duration,
  });
}
