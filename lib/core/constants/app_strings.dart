class AppStrings {
  // App Related
  static const String appName = 'Drone AID';
  static const String appTagline = 'Emergency Response Made Swift';
  static const String teamName = 'Drone AID Team';
  static const String poweredBy = 'Powered by Drone AID Team';

  // Welcome & Onboarding
  static const String welcome = 'Welcome to Drone AID';
  static const String welcomeSubtitle = 'Your emergency response companion';
  static const String getStarted = 'Get Started';
  static const String selectUserType = 'Select User Type';
  static const String selectUserTypeSubtitle =
      'Choose how you want to use Drone AID';

  // User Types
  static const String helpSeeker = 'Help Seeker';
  static const String helpSeekerDescription = 'Request emergency assistance';
  static const String gcsOperator = 'GCS Operator';
  static const String gcsOperatorDescription = 'Manage drone operations';

  // Authentication
  static const String login = 'Login';
  static const String register = 'Register';
  static const String signUp = 'Sign Up';
  static const String signIn = 'Sign In';
  static const String logout = 'Logout';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String changePassword = 'Change Password';
  static const String confirmPassword = 'Confirm Password';
  static const String createAccount = 'Create Account';
  static const String haveAccount = 'Already have an account?';
  static const String noAccount = "Don't have an account?";

  // Form Fields
  static const String email = 'Email';
  static const String password = 'Password';
  static const String fullName = 'Full Name';
  static const String firstName = 'First Name';
  static const String lastName = 'Last Name';
  static const String phoneNumber = 'Phone Number';
  static const String address = 'Address';
  static const String organization = 'Organization';
  static const String designation = 'Designation';
  static const String operatorId = 'Operator ID';

  // Navigation
  static const String home = 'Home';
  static const String profile = 'Profile';
  static const String settings = 'Settings';
  static const String notifications = 'Notifications';
  static const String history = 'History';
  static const String help = 'Help';
  static const String about = 'About';
  static const String dashboard = 'Dashboard';

  // Emergency Request
  static const String requestHelp = 'Request Help';
  static const String emergencyType = 'Emergency Type';
  static const String emergencyDescription = 'Description';
  static const String urgencyLevel = 'Urgency Level';
  static const String location = 'Location';
  static const String currentLocation = 'Current Location';
  static const String selectLocation = 'Select Location';
  static const String contactInfo = 'Contact Information';
  static const String additionalInfo = 'Additional Information';
  static const String submitRequest = 'Submit Request';

  // Emergency Types
  static const String medicalEmergency = 'Medical Emergency';
  static const String fire = 'Fire';
  static const String flood = 'Flood';
  static const String earthquake = 'Earthquake';
  static const String accident = 'Accident';
  static const String searchRescue = 'Search and Rescue';
  static const String other = 'Other';

  // Priority Levels
  static const String low = 'Low';
  static const String medium = 'Medium';
  static const String high = 'High';
  static const String critical = 'Critical';

  // Mission Status
  static const String pending = 'Pending';
  static const String assigned = 'Assigned';
  static const String inProgress = 'In Progress';
  static const String completed = 'Completed';
  static const String cancelled = 'Cancelled';

  // Drone Status
  static const String available = 'Available';
  static const String busy = 'Busy';
  static const String maintenance = 'Maintenance';
  static const String offline = 'Offline';

  // GCS Operator Screens
  static const String droneFleet = 'Drone Fleet';
  static const String missions = 'Missions';
  static const String emergencyRequests = 'Emergency Requests';
  static const String assignMission = 'Assign Mission';
  static const String missionDetails = 'Mission Details';
  static const String droneDetails = 'Drone Details';
  static const String operatorDashboard = 'Operator Dashboard';

  // Help Seeker Screens
  static const String myRequests = 'My Requests';
  static const String requestStatus = 'Request Status';
  static const String trackMission = 'Track Mission';

  // Actions
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String view = 'View';
  static const String update = 'Update';
  static const String refresh = 'Refresh';
  static const String retry = 'Retry';
  static const String confirm = 'Confirm';
  static const String ok = 'OK';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String close = 'Close';
  static const String next = 'Next';
  static const String previous = 'Previous';
  static const String finish = 'Finish';
  static const String skip = 'Skip';

  // Status Messages
  static const String success = 'Success';
  static const String error = 'Error';
  static const String warning = 'Warning';
  static const String info = 'Information';
  static const String loading = 'Loading...';
  static const String pleaseWait = 'Please wait...';
  static const String noData = 'No data available';
  static const String noInternet = 'No internet connection';
  static const String tryAgain = 'Try again';

  // Validation Messages
  static const String fieldRequired = 'This field is required';
  static const String emailInvalid = 'Please enter a valid email';
  static const String passwordTooShort =
      'Password must be at least 6 characters';
  static const String passwordMismatch = 'Passwords do not match';
  static const String phoneInvalid = 'Please enter a valid phone number';
  static const String nameInvalid = 'Please enter a valid name';

  // Success Messages
  static const String loginSuccess = 'Login successful';
  static const String registrationSuccess = 'Registration successful';
  static const String requestSubmitted =
      'Emergency request submitted successfully';
  static const String profileUpdated = 'Profile updated successfully';
  static const String passwordChanged = 'Password changed successfully';

  // Error Messages
  static const String loginFailed =
      'Login failed. Please check your credentials';
  static const String registrationFailed =
      'Registration failed. Please try again';
  static const String networkError =
      'Network error. Please check your connection';
  static const String serverError = 'Server error. Please try again later';
  static const String unexpectedError = 'An unexpected error occurred';
  static const String locationPermissionDenied = 'Location permission denied';
  static const String locationServiceDisabled = 'Location service is disabled';

  // Time & Date
  static const String today = 'Today';
  static const String yesterday = 'Yesterday';
  static const String thisWeek = 'This Week';
  static const String thisMonth = 'This Month';
  static const String lastUpdated = 'Last updated';
  static const String createdAt = 'Created at';

  // Units
  static const String meters = 'm';
  static const String kilometers = 'km';
  static const String minutes = 'min';
  static const String hours = 'hr';
  static const String seconds = 'sec';

  // Map Related
  static const String map = 'Map';
  static const String satellite = 'Satellite';
  static const String terrain = 'Terrain';
  static const String hybrid = 'Hybrid';
  static const String myLocation = 'My Location';
  static const String searchLocation = 'Search location...';
  static const String getDirections = 'Get Directions';
  static const String estimatedTime = 'Estimated Time';
  static const String distance = 'Distance';

  // Permissions
  static const String permissionsRequired = 'Permissions Required';
  static const String locationPermissionTitle = 'Location Permission';
  static const String locationPermissionMessage =
      'This app needs location permission to provide emergency services';
  static const String cameraPermissionTitle = 'Camera Permission';
  static const String cameraPermissionMessage =
      'This app needs camera permission to capture photos';
  static const String storagePermissionTitle = 'Storage Permission';
  static const String storagePermissionMessage =
      'This app needs storage permission to save files';
  static const String grantPermission = 'Grant Permission';
  static const String openSettings = 'Open Settings';

  // Notifications
  static const String newMissionAssigned = 'New mission assigned';
  static const String missionStatusUpdated = 'Mission status updated';
  static const String emergencyRequestReceived = 'Emergency request received';
  static const String droneStatusChanged = 'Drone status changed';

  // Empty States
  static const String noMissions = 'No missions found';
  static const String noRequests = 'No requests found';
  static const String noDrones = 'No drones available';
  static const String noNotifications = 'No notifications';
  static const String noHistory = 'No history available';

  // Search & Filter
  static const String search = 'Search';
  static const String filter = 'Filter';
  static const String sortBy = 'Sort By';
  static const String filterBy = 'Filter By';
  static const String clearFilters = 'Clear Filters';
  static const String applyFilters = 'Apply Filters';
  static const String searchResults = 'Search Results';
  static const String noResults = 'No results found';

  // Settings
  static const String general = 'General';
  static const String account = 'Account';
  static const String privacy = 'Privacy';
  static const String security = 'Security';
  static const String language = 'Language';
  static const String theme = 'Theme';
  static const String notifications_settings = 'Notifications';
  static const String version = 'Version';
  static const String termsConditions = 'Terms & Conditions';
  static const String privacyPolicy = 'Privacy Policy';

  // Theme
  static const String lightTheme = 'Light';
  static const String darkTheme = 'Dark';
  static const String systemTheme = 'System';

  // Contact
  static const String contactUs = 'Contact Us';
  static const String support = 'Support';
  static const String feedback = 'Feedback';
  static const String reportBug = 'Report Bug';
  static const String sendFeedback = 'Send Feedback';
}
