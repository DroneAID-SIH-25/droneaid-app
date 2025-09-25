class AppConstants {
  // App Information
  static const String appName = 'Drone AID';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Drone-based disaster management system';

  // Team Information
  static const String teamName = 'Drone AID Team';

  // User Types
  static const String userTypeHelpSeeker = 'help_seeker';
  static const String userTypeGCS = 'gcs_operator';

  // Default Location (India)
  static const double defaultLatitude = 20.5937;
  static const double defaultLongitude = 78.9629;
  static const String defaultCountry = 'India';

  // Emergency Types
  static const List<String> emergencyTypes = [
    'Medical Emergency',
    'Fire',
    'Flood',
    'Earthquake',
    'Accident',
    'Search and Rescue',
    'Other',
  ];

  // Priority Levels
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';
  static const String priorityCritical = 'critical';

  // Mission Status
  static const String missionStatusPending = 'pending';
  static const String missionStatusAssigned = 'assigned';
  static const String missionStatusInProgress = 'in_progress';
  static const String missionStatusCompleted = 'completed';
  static const String missionStatusCancelled = 'cancelled';

  // Drone Status
  static const String droneStatusAvailable = 'available';
  static const String droneStatusBusy = 'busy';
  static const String droneStatusMaintenance = 'maintenance';
  static const String droneStatusOffline = 'offline';

  // Storage Keys
  static const String keyUserData = 'user_data';
  static const String keyUserType = 'user_type';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyAuthToken = 'auth_token';
  static const String keyLastLocation = 'last_location';

  // API Endpoints (Mock)
  static const String baseUrl = 'https://api.droneaid.com';
  static const String apiVersion = '/v1';

  // Validation Constants
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;

  // Map Constants
  static const double defaultZoom = 10.0;
  static const double maxZoom = 20.0;
  static const double minZoom = 3.0;

  // Timeout Constants
  static const int connectionTimeout = 30; // seconds
  static const int receiveTimeout = 30; // seconds

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;
}
