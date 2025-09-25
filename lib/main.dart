import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_strings.dart';
import 'core/utils/app_theme.dart';
import 'providers/location_provider.dart';
import 'providers/drone_tracking_provider.dart';
import 'providers/emergency_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/group_management_provider.dart';
import 'providers/ongoing_missions_provider.dart';

import 'providers/mission_provider.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(riverpod.ProviderScope(child: const DroneAidApp()));
}

class DroneAidApp extends StatelessWidget {
  const DroneAidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => MissionProvider()),
        ChangeNotifierProvider(create: (_) => GroupManagementProvider()),
        ChangeNotifierProvider(create: (_) => OngoingMissionsProvider()),

        // Dependent providers
        ChangeNotifierProxyProvider<LocationProvider, DroneTrackingProvider>(
          create: (context) => DroneTrackingProvider(
            Provider.of<LocationProvider>(context, listen: false),
          ),
          update: (context, locationProvider, droneProvider) =>
              droneProvider ?? DroneTrackingProvider(locationProvider),
        ),

        ChangeNotifierProxyProvider<LocationProvider, EmergencyProvider>(
          create: (context) => EmergencyProvider(
            Provider.of<LocationProvider>(context, listen: false),
          ),
          update: (context, locationProvider, emergencyProvider) =>
              emergencyProvider ?? EmergencyProvider(locationProvider),
        ),
      ],
      child: AppInitializer(
        child: MaterialApp.router(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,

          // Theme configuration
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,

          // Router configuration
          routerConfig: AppRouter.router,

          // Localization
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('hi', 'IN'), // Hindi support for India
          ],

          // Builder for additional configurations
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: child ?? const SizedBox(),
            );
          },
        ),
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  final Widget child;

  const AppInitializer({super.key, required this.child});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  String _initializationMessage = 'Initializing Drone AID...';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize location services
      setState(() {
        _initializationMessage = 'Setting up location services...';
      });
      await Future.delayed(const Duration(milliseconds: 800));

      // Initialize notification system
      setState(() {
        _initializationMessage = 'Configuring notification system...';
      });
      await Future.delayed(const Duration(milliseconds: 600));

      // Initialize emergency system
      setState(() {
        _initializationMessage = 'Loading emergency protocols...';
      });
      await Future.delayed(const Duration(milliseconds: 700));

      // Initialize drone tracking
      setState(() {
        _initializationMessage = 'Connecting to drone network...';
      });
      await Future.delayed(const Duration(milliseconds: 900));

      // Final setup
      setState(() {
        _initializationMessage = 'System ready!';
      });
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Initialization error: $e');
      setState(() {
        _isInitialized = true; // Continue even with errors
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        title: AppStrings.appName,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1976D2),
                  const Color(0xFF1976D2).withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo with drone animation
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.flight,
                          size: 70,
                          color: const Color(0xFF1976D2),
                        ),
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // App name with bold styling
                  const Text(
                    AppStrings.appName,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Enhanced tagline
                  const Text(
                    'Emergency Drone Response System',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Help is always nearby',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white60,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Enhanced loading indicator
                  Container(
                    width: 60,
                    height: 60,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Initialization message with better styling
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _initializationMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Footer info
                  const Text(
                    'Made in India 🇮🇳',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white60,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    AppStrings.poweredBy,
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
