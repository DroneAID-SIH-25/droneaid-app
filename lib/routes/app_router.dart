import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/welcome_screen.dart';
import '../screens/user_type_selection_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/help_seeker/help_seeker_dashboard.dart';
import '../screens/help_seeker/request_help_screen.dart';
import '../screens/help_seeker/my_requests_screen.dart';
import '../screens/help_seeker/track_mission_screen.dart';
import '../screens/gcs/gcs_dashboard.dart';
import '../screens/gcs/drone_fleet_screen.dart';
import '../screens/gcs/missions_screen.dart';
import '../screens/gcs/emergency_requests_screen.dart';
import '../screens/gcs/mission_details_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../models/user.dart';

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
                path: '/track-mission/:missionId',
                name: 'trackMission',
                builder: (context, state) {
                  final missionId = state.pathParameters['missionId']!;
                  return TrackMissionScreen(missionId: missionId);
                },
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
            name: 'gcsDashboard',
            builder: (context, state) => const GCSDashboard(),
            routes: [
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
      // Add authentication logic here
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
      queryParameters: userType != null ? {'userType': userType} : null,
    );
  }

  static void goToRegister({String? userType}) {
    _router.goNamed(
      'register',
      queryParameters: userType != null ? {'userType': userType} : null,
    );
  }

  static void goToHelpSeekerDashboard() {
    _router.goNamed('helpSeekerDashboard');
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

  static void goToTrackMission(String missionId) {
    _router.goNamed('trackMission', pathParameters: {'missionId': missionId});
  }

  static void goToDroneFleet() {
    _router.goNamed('droneFleet');
  }

  static void goToMissions() {
    _router.goNamed('missions');
  }

  static void goToEmergencyRequests() {
    _router.goNamed('emergencyRequests');
  }

  static void goToMissionDetails(String missionId) {
    _router.goNamed('missionDetails', pathParameters: {'missionId': missionId});
  }

  static void goToProfile() {
    _router.goNamed('profile');
  }

  static void goToSettings() {
    _router.goNamed('settings');
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
              AppRouter.goToGCSDashboard();
              break;
            case 1:
              AppRouter.goToDroneFleet();
              break;
            case 2:
              AppRouter.goToMissions();
              break;
            case 3:
              AppRouter.goToEmergencyRequests();
              break;
            case 4:
              AppRouter.goToProfile();
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.flight), label: 'Drones'),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Missions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emergency),
            label: 'Requests',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => AppRouter.goToWelcome(),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
