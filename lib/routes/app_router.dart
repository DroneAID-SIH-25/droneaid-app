import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/welcome_screen.dart';
import '../screens/user_type_selection_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/help_seeker_auth_screen.dart';
import '../screens/auth/gcs_operator_auth_screen.dart';
import '../screens/auth/verification_loading_screen.dart';
import '../screens/help_seeker/help_seeker_dashboard.dart';
import '../screens/help_seeker/request_help_screen.dart';
import '../screens/help_seeker/my_requests_screen.dart';
import '../screens/help_seeker/track_mission_screen.dart';
import '../screens/gcs/gcs_main_screen.dart';
import '../screens/gcs/gcs_dashboard.dart';
import '../screens/gcs/drone_fleet_screen.dart';
import '../screens/gcs/missions_screen.dart';
import '../screens/gcs/ongoing_missions_screen.dart';
import '../screens/gcs/emergency_requests_screen.dart';
import '../screens/gcs/mission_details_screen.dart';
import '../screens/gcs/mission_creation_integrated_screen.dart';
import '../screens/gcs/create_mission_screen.dart';
import '../screens/gcs/create_group_screen.dart';
import '../screens/gcs/gcs_map_screen.dart';
import '../screens/help_seeker/enhanced_map_tracking_screen.dart';
import '../screens/help_seeker/map_tracking_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _helpSeekerShellNavigatorKey = GlobalKey<NavigatorState>();
  static final _gcsShellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/welcome',
    routes: [
      // Welcome and Authentication Routes
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/user-type-selection',
        name: 'userTypeSelection',
        builder: (context, state) => const UserTypeSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) {
          final userType = state.uri.queryParameters['userType'];
          return LoginScreen(userType: userType);
        },
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) {
          final userType = state.uri.queryParameters['userType'];
          return RegisterScreen(userType: userType);
        },
      ),
      GoRoute(
        path: '/help-seeker-auth',
        name: 'helpSeekerAuth',
        builder: (context, state) => const HelpSeekerAuthScreen(),
      ),
      GoRoute(
        path: '/gcs-operator-auth',
        name: 'gcsOperatorAuth',
        builder: (context, state) => const GCSOperatorAuthScreen(),
      ),
      GoRoute(
        path: '/verification',
        name: 'verification',
        builder: (context, state) {
          final verificationType =
              state.uri.queryParameters['type'] ?? 'default';
          return VerificationLoadingScreen(verificationType: verificationType);
        },
      ),

      // Help Seeker Routes with Shell
      ShellRoute(
        navigatorKey: _helpSeekerShellNavigatorKey,
        builder: (context, state, child) {
          return HelpSeekerShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/help-seeker',
            name: 'helpSeekerDashboard',
            builder: (context, state) => const HelpSeekerDashboard(),
            routes: [
              GoRoute(
                path: '/request-help',
                name: 'requestHelp',
                builder: (context, state) => const RequestHelpScreen(),
              ),
              GoRoute(
                path: '/my-requests',
                name: 'myRequests',
                builder: (context, state) => const MyRequestsScreen(),
              ),
              GoRoute(
                path: '/track-mission',
                name: 'trackMission',
                builder: (context, state) => const TrackMissionScreen(),
              ),
              GoRoute(
                path: '/map-tracking',
                name: 'mapTracking',
                builder: (context, state) => const MapTrackingScreen(),
              ),
              GoRoute(
                path: '/enhanced-map-tracking',
                name: 'enhancedMapTracking',
                builder: (context, state) => const EnhancedMapTrackingScreen(),
              ),
            ],
          ),
        ],
      ),

      // GCS Routes with Shell
      ShellRoute(
        navigatorKey: _gcsShellNavigatorKey,
        builder: (context, state, child) {
          return GCSShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/gcs',
            name: 'gcsMain',
            builder: (context, state) => const GCSMainScreen(),
            routes: [
              GoRoute(
                path: '/dashboard',
                name: 'gcsDashboard',
                builder: (context, state) => const GCSDashboard(),
              ),
              GoRoute(
                path: '/drone-fleet',
                name: 'droneFleet',
                builder: (context, state) => const DroneFleetScreen(),
              ),
              GoRoute(
                path: '/missions',
                name: 'missions',
                builder: (context, state) => const MissionsScreen(),
              ),
              GoRoute(
                path: '/ongoing-missions',
                name: 'ongoingMissions',
                builder: (context, state) => const OngoingMissionsScreen(),
              ),
              GoRoute(
                path: '/emergency-requests',
                name: 'emergencyRequests',
                builder: (context, state) => const EmergencyRequestsScreen(),
              ),
              GoRoute(
                path: '/mission-details/:missionId',
                name: 'missionDetails',
                builder: (context, state) {
                  final missionId = state.pathParameters['missionId']!;
                  return MissionDetailsScreen(missionId: missionId);
                },
              ),
              GoRoute(
                path: '/create-mission',
                name: 'createMission',
                builder: (context, state) => const CreateMissionScreen(),
              ),
              GoRoute(
                path: '/mission-creation',
                name: 'missionCreation',
                builder: (context, state) =>
                    const MissionCreationIntegratedScreen(),
              ),
              GoRoute(
                path: '/create-group',
                name: 'createGroup',
                builder: (context, state) => const CreateGroupScreen(),
              ),
              GoRoute(
                path: '/gcs-map',
                name: 'gcsMap',
                builder: (context, state) => const GCSMapScreen(),
              ),
            ],
          ),
        ],
      ),

      // Common Routes
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
    redirect: (context, state) {
      // Add basic auth logic here if needed
      return null;
    },
  );

  // Navigation helpers
  static void goToWelcome() {
    _router.goNamed('welcome');
  }

  static void goToUserTypeSelection() {
    _router.goNamed('userTypeSelection');
  }

  static void goToLogin({String? userType}) {
    _router.goNamed(
      'login',
      queryParameters: userType != null ? {'userType': userType} : {},
    );
  }

  static void goToRegister({String? userType}) {
    _router.goNamed(
      'register',
      queryParameters: userType != null ? {'userType': userType} : {},
    );
  }

  static void goToHelpSeekerDashboard() {
    _router.goNamed('helpSeekerDashboard');
  }

  static void goToGCSMain() {
    _router.goNamed('gcsMain');
  }

  static void goToGCSDashboard() {
    _router.goNamed('gcsDashboard');
  }

  static void goToRequestHelp() {
    _router.goNamed('requestHelp');
  }

  static void goToMyRequests() {
    _router.goNamed('myRequests');
  }

  static void goToTrackMission() {
    _router.goNamed('trackMission');
  }

  static void goToMapTracking() {
    _router.goNamed('mapTracking');
  }

  static void goToEnhancedMapTracking() {
    _router.goNamed('enhancedMapTracking');
  }

  static void goToDroneFleet() {
    _router.goNamed('droneFleet');
  }

  static void goToMissions() {
    _router.goNamed('missions');
  }

  static void goToOngoingMissions() {
    _router.goNamed('ongoingMissions');
  }

  static void goToEmergencyRequests() {
    _router.goNamed('emergencyRequests');
  }

  static void goToMissionDetails(String missionId) {
    _router.goNamed('missionDetails', pathParameters: {'missionId': missionId});
  }

  static void goToCreateMission() {
    _router.goNamed('createMission');
  }

  static void goToMissionCreation() {
    _router.goNamed('missionCreation');
  }

  static void goToCreateGroup() {
    _router.goNamed('createGroup');
  }

  static void goToGCSMap() {
    _router.goNamed('gcsMap');
  }

  static void goToProfile() {
    _router.goNamed('profile');
  }

  static void goToSettings() {
    _router.goNamed('settings');
  }

  static void goToHelpSeekerAuth() {
    _router.goNamed('helpSeekerAuth');
  }

  static void goToGCSOperatorAuth() {
    _router.goNamed('gcsOperatorAuth');
  }

  static void goToVerification({String type = 'default'}) {
    _router.goNamed('verification', queryParameters: {'type': type});
  }

  static void goBack() {
    if (_router.canPop()) {
      _router.pop();
    }
  }

  static void clearAndNavigate(String routeName) {
    while (_router.canPop()) {
      _router.pop();
    }
    _router.goNamed(routeName);
  }
}

// Shell widgets for bottom navigation
class HelpSeekerShell extends StatefulWidget {
  final Widget child;

  const HelpSeekerShell({super.key, required this.child});

  @override
  State<HelpSeekerShell> createState() => _HelpSeekerShellState();
}

class _HelpSeekerShellState extends State<HelpSeekerShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          switch (index) {
            case 0:
              AppRouter.goToHelpSeekerDashboard();
              break;
            case 1:
              AppRouter.goToRequestHelp();
              break;
            case 2:
              AppRouter.goToMyRequests();
              break;
            case 3:
              AppRouter.goToProfile();
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emergency),
            label: 'Request Help',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'My Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class GCSShell extends StatefulWidget {
  final Widget child;

  const GCSShell({super.key, required this.child});

  @override
  State<GCSShell> createState() => _GCSShellState();
}

class _GCSShellState extends State<GCSShell> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: widget.child, drawer: _buildGCSDrawer(context));
  }

  Widget _buildGCSDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  child: Icon(Icons.person, size: 40),
                ),
                const SizedBox(height: 10),
                const Text(
                  'GCS Operator',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'operator@droneaid.com',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.of(context).pop();
              AppRouter.goToGCSDashboard();
            },
          ),
          ListTile(
            leading: const Icon(Icons.flight),
            title: const Text('Drone Fleet'),
            onTap: () {
              Navigator.of(context).pop();
              AppRouter.goToDroneFleet();
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Missions'),
            onTap: () {
              Navigator.of(context).pop();
              AppRouter.goToMissions();
            },
          ),
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('Ongoing Missions'),
            onTap: () {
              Navigator.of(context).pop();
              AppRouter.goToOngoingMissions();
            },
          ),
          ListTile(
            leading: const Icon(Icons.emergency),
            title: const Text('Emergency Requests'),
            onTap: () {
              Navigator.of(context).pop();
              AppRouter.goToEmergencyRequests();
            },
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Map View'),
            onTap: () {
              Navigator.of(context).pop();
              AppRouter.goToGCSMap();
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_box),
            title: const Text('Create Mission'),
            onTap: () {
              Navigator.of(context).pop();
              AppRouter.goToMissionCreation();
            },
          ),
          ListTile(
            leading: const Icon(Icons.group_add),
            title: const Text('Create Group'),
            onTap: () {
              Navigator.of(context).pop();
              AppRouter.goToCreateGroup();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.of(context).pop();
              AppRouter.goToProfile();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.of(context).pop();
              AppRouter.goToSettings();
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.of(context).pop();
              // Add logout logic here
            },
          ),
        ],
      ),
    );
  }
}

// Error screen
class ErrorScreen extends StatelessWidget {
  final Exception? error;

  const ErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  error?.toString() ?? 'Unknown error occurred',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => AppRouter.goToWelcome(),
                icon: const Icon(Icons.home),
                label: const Text('Go to Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => AppRouter.goBack(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
