import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../core/constants/app_strings.dart';
import '../core/constants/app_constants.dart';
import '../routes/app_router.dart';
import '../providers/auth_provider.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _slideController.forward();
    });

    // Check authentication status after animations
    Future.delayed(const Duration(seconds: 2), () {
      _checkAuthenticationStatus();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _checkAuthenticationStatus() {
    final authState = ref.read(authProvider);

    if (authState.isInitialized) {
      if (authState.isAuthenticated) {
        // Navigate based on user type
        if (authState.userType == AppUserType.helpSeeker) {
          AppRouter.goToHelpSeekerDashboard();
        } else if (authState.userType == AppUserType.gcsOperator) {
          AppRouter.goToGCSMain();
        }
      } else {
        // Navigate to user type selection after a delay
        Future.delayed(const Duration(milliseconds: 1000), () {
          AppRouter.goToUserTypeSelection();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isInitialized && previous?.isInitialized != true) {
        _checkAuthenticationStatus();
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor,
              theme.primaryColor.withOpacity(0.8),
              theme.colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo Container
                          Hero(
                            tag: 'drone_aid_logo',
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.flight_takeoff_rounded,
                                    size: 60,
                                    color: theme.primaryColor,
                                  ),
                                  const SizedBox(height: 4),
                                  Icon(
                                    Icons.emergency,
                                    size: 30,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // App Name
                          Text(
                            AppStrings.appName,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 42,
                              letterSpacing: 1.2,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Tagline
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              AppStrings.appTagline,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ),

                          const SizedBox(height: 60),

                          // Loading Indicator
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                SpinKitPulse(color: Colors.white, size: 40),
                                const SizedBox(height: 16),
                                Text(
                                  'Initializing Emergency Response System...',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Features Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFeatureItem(
                          icon: Icons.speed,
                          label: 'Fast Response',
                          theme: theme,
                        ),
                        _buildFeatureItem(
                          icon: Icons.location_on,
                          label: 'Real-time Tracking',
                          theme: theme,
                        ),
                        _buildFeatureItem(
                          icon: Icons.security,
                          label: 'Secure & Reliable',
                          theme: theme,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Skip Button (appears after delay)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: TextButton(
                        onPressed: () {
                          AppRouter.goToUserTypeSelection();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withOpacity(0.8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Skip',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Team Credit
                    Text(
                      AppStrings.poweredBy,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Version
                    Text(
                      'Version ${AppConstants.appVersion}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
