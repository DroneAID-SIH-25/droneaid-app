import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/gcs_operator.dart';
import '../core/services/location_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

enum UserType { helpSeeker, gcsOperator }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  UserType? _userType;
  User? _currentUser;
  GCSOperator? _currentGCSOperator;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  AuthStatus get status => _status;
  UserType? get userType => _userType;
  User? get currentUser => _currentUser;
  GCSOperator? get currentGCSOperator => _currentGCSOperator;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // Constructor
  AuthProvider() {
    _initializeAuth();
  }

  /// Initialize authentication state from stored preferences
  Future<void> _initializeAuth() async {
    try {
      _setLoading(true);
      final prefs = await SharedPreferences.getInstance();

      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final storedUserType = prefs.getString('userType');

      if (isLoggedIn && storedUserType != null) {
        _userType = storedUserType == 'helpSeeker'
            ? UserType.helpSeeker
            : UserType.gcsOperator;

        // Load user data based on type
        if (_userType == UserType.helpSeeker) {
          await _loadUserData();
        } else {
          await _loadGCSOperatorData();
        }

        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      _status = AuthStatus.unauthenticated;
    } finally {
      _setLoading(false);
    }
  }

  /// Load user data from stored preferences
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('userData');

      if (userJson != null) {
        // This would normally deserialize from JSON
        // For now, create a mock user
        _currentUser = User(
          id: prefs.getString('userId') ?? 'user_123',
          name: prefs.getString('userName') ?? 'Help Seeker',
          email: prefs.getString('userEmail') ?? 'helpseeker@example.com',
          phone: prefs.getString('userPhone') ?? '+91 9876543210',
          location: LocationData(
            latitude: 28.6139,
            longitude: 77.2090,
            address: 'Delhi, India',
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  /// Load GCS operator data from stored preferences
  Future<void> _loadGCSOperatorData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final operatorJson = prefs.getString('gcsOperatorData');

      if (operatorJson != null) {
        // This would normally deserialize from JSON
        // For now, create a mock GCS operator
        _currentGCSOperator = GCSOperator(
          id: prefs.getString('gcsOperatorId') ?? 'gcs_123',
          operatorId: prefs.getString('operatorLicense') ?? 'LIC123456',
          firstName: prefs.getString('gcsOperatorName')?.split(' ')[0] ?? 'GCS',
          lastName:
              (prefs.getString('gcsOperatorName')?.split(' ').length ?? 0) > 1
              ? prefs.getString('gcsOperatorName')!.split(' ')[1]
              : 'Operator',
          email: prefs.getString('gcsOperatorEmail') ?? 'operator@example.com',
          phoneNumber: prefs.getString('gcsOperatorPhone') ?? '+91 9876543210',
          organization: prefs.getString('department') ?? 'Emergency Response',
          designation: prefs.getString('rank') ?? 'Senior Operator',
          isActive: prefs.getBool('isActive') ?? true,
        );
      }
    } catch (e) {
      debugPrint('Error loading GCS operator data: $e');
    }
  }

  /// Login as Help Seeker
  Future<bool> loginAsHelpSeeker({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Mock validation - in real app, this would call an API
      if (email.isNotEmpty && password.length >= 6) {
        // Get current location
        final locationService = LocationService();
        LocationData currentLocation;

        try {
          final location = await locationService.getCurrentLocation();
          currentLocation =
              location ??
              LocationData(
                latitude: 28.6139,
                longitude: 77.2090,
                address: 'Delhi, India',
                timestamp: DateTime.now(),
              );
        } catch (e) {
          // Use default location if location access fails
          currentLocation = LocationData(
            latitude: 28.6139,
            longitude: 77.2090,
            address: 'Delhi, India',
            timestamp: DateTime.now(),
          );
        }

        _currentUser = User(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          name: email.split('@')[0], // Use email prefix as name
          email: email,
          phone: '+91 9876543210', // Mock phone
          location: currentLocation,
        );

        _userType = UserType.helpSeeker;
        _status = AuthStatus.authenticated;

        // Save to preferences
        await _saveAuthState();

        return true;
      } else {
        _setError('Invalid email or password');
        return false;
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Login as GCS Operator
  Future<bool> loginAsGCSOperator({
    required String email,
    required String password,
    required String operatorLicense,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Mock validation - in real app, this would call an API
      if (email.isNotEmpty &&
          password.length >= 6 &&
          operatorLicense.isNotEmpty) {
        _currentGCSOperator = GCSOperator(
          id: 'gcs_${DateTime.now().millisecondsSinceEpoch}',
          operatorId: operatorLicense,
          firstName: email.split('@')[0], // Use email prefix as name
          lastName: 'Operator',
          email: email,
          phoneNumber: '+91 9876543210', // Mock phone
          organization: 'Emergency Response',
          designation: 'Senior Operator',
          isActive: true,
        );

        _userType = UserType.gcsOperator;
        _status = AuthStatus.authenticated;

        // Save to preferences
        await _saveAuthState();

        return true;
      } else {
        _setError('Invalid credentials or operator license');
        return false;
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Register new Help Seeker
  Future<bool> registerHelpSeeker({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Mock validation - in real app, this would call an API
      if (name.isNotEmpty &&
          email.isNotEmpty &&
          phone.isNotEmpty &&
          password.length >= 6) {
        // Get current location
        final locationService = LocationService();
        LocationData currentLocation;

        try {
          final location = await locationService.getCurrentLocation();
          currentLocation =
              location ??
              LocationData(
                latitude: 28.6139,
                longitude: 77.2090,
                address: 'Delhi, India',
                timestamp: DateTime.now(),
              );
        } catch (e) {
          // Use default location if location access fails
          currentLocation = LocationData(
            latitude: 28.6139,
            longitude: 77.2090,
            address: 'Delhi, India',
            timestamp: DateTime.now(),
          );
        }

        _currentUser = User(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          email: email,
          phone: phone,
          location: currentLocation,
        );

        _userType = UserType.helpSeeker;
        _status = AuthStatus.authenticated;

        // Save to preferences
        await _saveAuthState();

        return true;
      } else {
        _setError('Please fill all required fields');
        return false;
      }
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Register new GCS Operator
  Future<bool> registerGCSOperator({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String operatorLicense,
    required String department,
    String? rank,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Mock validation - in real app, this would call an API
      if (name.isNotEmpty &&
          email.isNotEmpty &&
          phone.isNotEmpty &&
          password.length >= 6 &&
          operatorLicense.isNotEmpty &&
          department.isNotEmpty) {
        _currentGCSOperator = GCSOperator(
          id: 'gcs_${DateTime.now().millisecondsSinceEpoch}',
          operatorId: operatorLicense,
          firstName: name.split(' ')[0],
          lastName: name.split(' ').length > 1 ? name.split(' ')[1] : '',
          email: email,
          phoneNumber: phone,
          organization: department,
          designation: rank ?? 'Operator',
          isActive: true,
        );

        _userType = UserType.gcsOperator;
        _status = AuthStatus.authenticated;

        // Save to preferences
        await _saveAuthState();

        return true;
      } else {
        _setError('Please fill all required fields');
        return false;
      }
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      _setLoading(true);

      // Clear stored authentication data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Reset state
      _status = AuthStatus.unauthenticated;
      _userType = null;
      _currentUser = null;
      _currentGCSOperator = null;
      _clearError();
    } catch (e) {
      debugPrint('Error during logout: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Save authentication state to preferences
  Future<void> _saveAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('isLoggedIn', true);
      await prefs.setString(
        'userType',
        _userType == UserType.helpSeeker ? 'helpSeeker' : 'gcsOperator',
      );

      if (_currentUser != null) {
        await prefs.setString('userId', _currentUser!.id);
        await prefs.setString('userName', _currentUser!.name);
        await prefs.setString('userEmail', _currentUser!.email);
        await prefs.setString('userPhone', _currentUser!.phone);
      }

      if (_currentGCSOperator != null) {
        await prefs.setString('gcsOperatorId', _currentGCSOperator!.id);
        await prefs.setString('gcsOperatorName', _currentGCSOperator!.fullName);
        await prefs.setString('gcsOperatorEmail', _currentGCSOperator!.email);
        await prefs.setString(
          'gcsOperatorPhone',
          _currentGCSOperator!.phoneNumber,
        );
        await prefs.setString(
          'operatorLicense',
          _currentGCSOperator!.operatorId,
        );
        await prefs.setString('department', _currentGCSOperator!.organization);
        await prefs.setString('rank', _currentGCSOperator!.designation);
        await prefs.setBool('isActive', _currentGCSOperator!.isActive);
      }
    } catch (e) {
      debugPrint('Error saving auth state: $e');
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile({
    required String name,
    required String phone,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      if (_userType == UserType.helpSeeker && _currentUser != null) {
        _currentUser = User(
          id: _currentUser!.id,
          name: name,
          email: _currentUser!.email,
          phone: phone,
          location: _currentUser!.location,
        );
      } else if (_userType == UserType.gcsOperator &&
          _currentGCSOperator != null) {
        _currentGCSOperator = GCSOperator(
          id: _currentGCSOperator!.id,
          operatorId: _currentGCSOperator!.operatorId,
          firstName: name.split(' ')[0],
          lastName: name.split(' ').length > 1 ? name.split(' ')[1] : '',
          email: _currentGCSOperator!.email,
          phoneNumber: phone,
          organization: _currentGCSOperator!.organization,
          designation: _currentGCSOperator!.designation,
          isActive: _currentGCSOperator!.isActive,
        );
      }

      await _saveAuthState();
      return true;
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
