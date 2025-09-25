import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../../models/user.dart';
import '../../models/gcs_operator.dart';
import '../constants/app_constants.dart';
import 'location_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final LocationService _locationService = LocationService();

  // Mock data storage
  static final List<MockHelpSeeker> _mockHelpSeekers = [
    MockHelpSeeker(
      name: 'Raj Kumar',
      phone: '+91 9876543210',
      aadharNumber: '1234-5678-9012',
      email: 'raj@example.com',
      password: 'password123',
    ),
    MockHelpSeeker(
      name: 'Priya Sharma',
      phone: '+91 9876543211',
      aadharNumber: '1234-5678-9013',
      email: 'priya@example.com',
      password: 'password123',
    ),
    MockHelpSeeker(
      name: 'Amit Singh',
      phone: '+91 9876543212',
      aadharNumber: '1234-5678-9014',
      email: 'amit@example.com',
      password: 'password123',
    ),
  ];

  static final List<MockGCSOperator> _mockGCSOperators = [
    MockGCSOperator(
      name: 'Captain Arjun Mehta',
      phone: '+91 9876543220',
      employeeId: 'GCS001',
      email: 'arjun.mehta@droneaid.gov.in',
      password: 'operator123',
      department: 'Emergency Response',
      rank: 'Captain',
      experience: 8,
    ),
    MockGCSOperator(
      name: 'Lieutenant Sarah Khan',
      phone: '+91 9876543221',
      employeeId: 'GCS002',
      email: 'sarah.khan@droneaid.gov.in',
      password: 'operator123',
      department: 'Search and Rescue',
      rank: 'Lieutenant',
      experience: 5,
    ),
    MockGCSOperator(
      name: 'Major Vikram Gupta',
      phone: '+91 9876543222',
      employeeId: 'GCS003',
      email: 'vikram.gupta@droneaid.gov.in',
      password: 'operator123',
      department: 'Disaster Management',
      rank: 'Major',
      experience: 12,
    ),
  ];

  // Mock locations in India
  static final List<LocationData> _mockIndianLocations = [
    LocationData(
      latitude: 28.6139,
      longitude: 77.2090,
      address: 'New Delhi, Delhi',
      timestamp: DateTime.now(),
    ),
    LocationData(
      latitude: 19.0760,
      longitude: 72.8777,
      address: 'Mumbai, Maharashtra',
      timestamp: DateTime.now(),
    ),
    LocationData(
      latitude: 13.0827,
      longitude: 80.2707,
      address: 'Chennai, Tamil Nadu',
      timestamp: DateTime.now(),
    ),
    LocationData(
      latitude: 12.9716,
      longitude: 77.5946,
      address: 'Bangalore, Karnataka',
      timestamp: DateTime.now(),
    ),
    LocationData(
      latitude: 22.5726,
      longitude: 88.3639,
      address: 'Kolkata, West Bengal',
      timestamp: DateTime.now(),
    ),
  ];

  /// Help Seeker Authentication
  Future<AuthResult> loginHelpSeeker({
    required String identifier, // Can be phone or email
    required String password,
  }) async {
    try {
      await _simulateNetworkDelay();

      final mockUser = _mockHelpSeekers.firstWhere(
        (user) => user.phone == identifier || user.email == identifier,
        orElse: () => throw AuthException('User not found'),
      );

      if (mockUser.password != password) {
        throw AuthException('Invalid password');
      }

      // Get current location or use random Indian location
      LocationData location;
      try {
        location =
            await _locationService.getCurrentLocation() ??
            _getRandomIndianLocation();
      } catch (e) {
        location = _getRandomIndianLocation();
      }

      final user = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: mockUser.name,
        email: mockUser.email,
        phone: mockUser.phone,
        location: location,
      );

      await _saveUserSession(user, UserType.helpSeeker);

      return AuthResult.success(
        user: user,
        userType: UserType.helpSeeker,
        message: 'Login successful',
      );
    } catch (e) {
      return AuthResult.error(
        message: e is AuthException ? e.message : 'Login failed',
      );
    }
  }

  /// Help Seeker Registration
  Future<AuthResult> registerHelpSeeker({
    required String name,
    required String phone,
    required String aadharNumber,
    required String password,
    String? email,
  }) async {
    try {
      await _simulateNetworkDelay();

      // Validate input
      if (!_validateName(name)) {
        throw AuthException('Please enter a valid name');
      }

      if (!_validatePhone(phone)) {
        throw AuthException('Please enter a valid phone number');
      }

      if (!_validateAadharNumber(aadharNumber)) {
        throw AuthException('Please enter a valid Aadhar number');
      }

      if (!_validatePassword(password)) {
        throw AuthException('Password must be at least 6 characters long');
      }

      // Check if user already exists
      final existingUser = _mockHelpSeekers.where(
        (user) =>
            user.phone == phone ||
            user.aadharNumber == aadharNumber ||
            (email != null && user.email == email),
      );

      if (existingUser.isNotEmpty) {
        throw AuthException(
          'User already exists with this phone/Aadhar number',
        );
      }

      // Request location permission and get current location
      LocationData location;
      try {
        location =
            await _locationService.getCurrentLocation() ??
            _getRandomIndianLocation();
      } catch (e) {
        throw AuthException(
          'Location permission is required for emergency services',
        );
      }

      // Create new user
      final user = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email:
            email ??
            '${phone.replaceAll('+91', '').replaceAll(' ', '')}@helpseeker.droneaid.com',
        phone: phone,
        location: location,
      );

      // Add to mock data (in real app, this would be saved to backend)
      _mockHelpSeekers.add(
        MockHelpSeeker(
          name: name,
          phone: phone,
          aadharNumber: aadharNumber,
          email: user.email,
          password: password,
        ),
      );

      await _saveUserSession(user, UserType.helpSeeker);

      return AuthResult.success(
        user: user,
        userType: UserType.helpSeeker,
        message: 'Registration successful',
      );
    } catch (e) {
      return AuthResult.error(
        message: e is AuthException ? e.message : 'Registration failed',
      );
    }
  }

  /// GCS Operator Authentication
  Future<AuthResult> loginGCSOperator({
    required String employeeId,
    required String password,
    String? phone,
  }) async {
    try {
      await _simulateNetworkDelay();

      final mockOperator = _mockGCSOperators.firstWhere(
        (operator) =>
            operator.employeeId == employeeId &&
            (phone == null || operator.phone == phone),
        orElse: () => throw AuthException('Invalid employee ID or credentials'),
      );

      if (mockOperator.password != password) {
        throw AuthException('Invalid password');
      }

      // Get current location or use random Indian location
      LocationData location;
      try {
        location =
            await _locationService.getCurrentLocation() ??
            _getRandomIndianLocation();
      } catch (e) {
        location = _getRandomIndianLocation();
      }

      final operator = GCSOperator(
        id: 'gcs_${DateTime.now().millisecondsSinceEpoch}',
        operatorId: mockOperator.employeeId,
        firstName: mockOperator.name.split(' ')[0],
        lastName: mockOperator.name.split(' ').length > 1
            ? mockOperator.name.split(' ').sublist(1).join(' ')
            : '',
        email: mockOperator.email,
        phoneNumber: mockOperator.phone,
        organization: mockOperator.department,
        designation: mockOperator.rank,
        currentLocation: location,
        experienceYears: mockOperator.experience,
        isActive: true,
        isOnDuty: true,
        authorizedDroneIds: ['DRONE_001', 'DRONE_002', 'DRONE_003'],
        certifications: [
          'Commercial Drone License',
          'Emergency Response',
          'Search and Rescue',
        ],
      );

      await _saveOperatorSession(operator);

      return AuthResult.success(
        gcsOperator: operator,
        userType: UserType.gcsOperator,
        message: 'Login successful',
      );
    } catch (e) {
      return AuthResult.error(
        message: e is AuthException ? e.message : 'Login failed',
      );
    }
  }

  /// Verify Aadhar Number (Mock)
  Future<VerificationResult> verifyAadharNumber(String aadharNumber) async {
    try {
      await _simulateNetworkDelay(duration: Duration(seconds: 3));

      if (!_validateAadharNumber(aadharNumber)) {
        return VerificationResult.error('Invalid Aadhar number format');
      }

      // Mock verification - all numbers ending with even digits are "verified"
      final lastDigit =
          int.tryParse(aadharNumber.replaceAll('-', '').substring(11, 12)) ?? 0;
      final isVerified = lastDigit % 2 == 0;

      if (isVerified) {
        return VerificationResult.success(
          'Aadhar number verified successfully',
        );
      } else {
        return VerificationResult.error('Aadhar number verification failed');
      }
    } catch (e) {
      return VerificationResult.error('Verification service unavailable');
    }
  }

  /// Check if user session exists
  Future<AuthResult> checkExistingSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;

      if (!isLoggedIn) {
        return AuthResult.error(message: 'No active session');
      }

      final userTypeString = prefs.getString(AppConstants.keyUserType);
      if (userTypeString == null) {
        return AuthResult.error(message: 'Invalid session');
      }

      final userType = userTypeString == 'helpSeeker'
          ? UserType.helpSeeker
          : UserType.gcsOperator;

      if (userType == UserType.helpSeeker) {
        final userData = prefs.getString(AppConstants.keyUserData);
        if (userData != null) {
          final userJson = jsonDecode(userData);
          final user = User.fromJson(userJson);
          return AuthResult.success(
            user: user,
            userType: UserType.helpSeeker,
            message: 'Session restored',
          );
        }
      } else {
        final operatorData = prefs.getString('gcs_operator_data');
        if (operatorData != null) {
          final operatorJson = jsonDecode(operatorData);
          final operator = GCSOperator.fromJson(operatorJson);
          return AuthResult.success(
            gcsOperator: operator,
            userType: UserType.gcsOperator,
            message: 'Session restored',
          );
        }
      }

      return AuthResult.error(message: 'Invalid session data');
    } catch (e) {
      return AuthResult.error(message: 'Failed to restore session');
    }
  }

  /// Logout current user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Update user profile
  Future<AuthResult> updateUserProfile({
    String? name,
    String? phone,
    String? email,
  }) async {
    try {
      await _simulateNetworkDelay();

      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(AppConstants.keyUserData);

      if (userData == null) {
        throw AuthException('No active session');
      }

      final userJson = jsonDecode(userData);
      final currentUser = User.fromJson(userJson);

      final updatedUser = currentUser.copyWith(
        name: name ?? currentUser.name,
        phone: phone ?? currentUser.phone,
        email: email ?? currentUser.email,
      );

      await _saveUserSession(updatedUser, UserType.helpSeeker);

      return AuthResult.success(
        user: updatedUser,
        userType: UserType.helpSeeker,
        message: 'Profile updated successfully',
      );
    } catch (e) {
      return AuthResult.error(
        message: e is AuthException ? e.message : 'Failed to update profile',
      );
    }
  }

  /// Change password
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _simulateNetworkDelay();

      if (!_validatePassword(newPassword)) {
        throw AuthException('New password must be at least 6 characters long');
      }

      // In a real app, this would verify the current password
      // and update it in the backend
      return AuthResult.success(message: 'Password changed successfully');
    } catch (e) {
      return AuthResult.error(
        message: e is AuthException ? e.message : 'Failed to change password',
      );
    }
  }

  /// Reset password
  Future<AuthResult> resetPassword({
    required String identifier, // phone or email
  }) async {
    try {
      await _simulateNetworkDelay();

      // Check if user exists
      final userExists =
          _mockHelpSeekers.any(
            (user) => user.phone == identifier || user.email == identifier,
          ) ||
          _mockGCSOperators.any(
            (operator) =>
                operator.phone == identifier || operator.email == identifier,
          );

      if (!userExists) {
        throw AuthException('User not found');
      }

      // In a real app, this would send a reset link/OTP
      return AuthResult.success(
        message: 'Password reset instructions sent to your phone/email',
      );
    } catch (e) {
      return AuthResult.error(
        message: e is AuthException ? e.message : 'Failed to reset password',
      );
    }
  }

  /// Private helper methods

  Future<void> _saveUserSession(User user, UserType userType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsLoggedIn, true);
    await prefs.setString(
      AppConstants.keyUserType,
      userType == UserType.helpSeeker ? 'helpSeeker' : 'gcsOperator',
    );
    await prefs.setString(AppConstants.keyUserData, jsonEncode(user.toJson()));
  }

  Future<void> _saveOperatorSession(GCSOperator operator) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsLoggedIn, true);
    await prefs.setString(AppConstants.keyUserType, 'gcsOperator');
    await prefs.setString('gcs_operator_data', jsonEncode(operator.toJson()));
  }

  LocationData _getRandomIndianLocation() {
    final randomIndex =
        DateTime.now().millisecondsSinceEpoch % _mockIndianLocations.length;
    return _mockIndianLocations[randomIndex];
  }

  Future<void> _simulateNetworkDelay({Duration? duration}) async {
    await Future.delayed(
      duration ??
          Duration(
            milliseconds: 1000 + (DateTime.now().millisecondsSinceEpoch % 2000),
          ),
    );
  }

  bool _validateName(String name) {
    return name.trim().length >= 2 &&
        RegExp(r'^[a-zA-Z\s]+$').hasMatch(name.trim());
  }

  bool _validatePhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    return RegExp(r'^\+91[6-9]\d{9}$').hasMatch(cleanPhone) ||
        RegExp(r'^[6-9]\d{9}$').hasMatch(cleanPhone);
  }

  bool _validateAadharNumber(String aadhar) {
    final cleanAadhar = aadhar.replaceAll('-', '').replaceAll(' ', '');
    return RegExp(r'^\d{12}$').hasMatch(cleanAadhar);
  }

  bool _validatePassword(String password) {
    return password.length >= 6;
  }
}

// Data models for mock data
class MockHelpSeeker {
  final String name;
  final String phone;
  final String aadharNumber;
  final String email;
  final String password;

  MockHelpSeeker({
    required this.name,
    required this.phone,
    required this.aadharNumber,
    required this.email,
    required this.password,
  });
}

class MockGCSOperator {
  final String name;
  final String phone;
  final String employeeId;
  final String email;
  final String password;
  final String department;
  final String rank;
  final int experience;

  MockGCSOperator({
    required this.name,
    required this.phone,
    required this.employeeId,
    required this.email,
    required this.password,
    required this.department,
    required this.rank,
    required this.experience,
  });
}

// Result classes
class AuthResult {
  final bool success;
  final String message;
  final User? user;
  final GCSOperator? gcsOperator;
  final UserType? userType;

  AuthResult._({
    required this.success,
    required this.message,
    this.user,
    this.gcsOperator,
    this.userType,
  });

  factory AuthResult.success({
    User? user,
    GCSOperator? gcsOperator,
    UserType? userType,
    required String message,
  }) {
    return AuthResult._(
      success: true,
      message: message,
      user: user,
      gcsOperator: gcsOperator,
      userType: userType,
    );
  }

  factory AuthResult.error({required String message}) {
    return AuthResult._(success: false, message: message);
  }
}

class VerificationResult {
  final bool success;
  final String message;

  VerificationResult._({required this.success, required this.message});

  factory VerificationResult.success(String message) {
    return VerificationResult._(success: true, message: message);
  }

  factory VerificationResult.error(String message) {
    return VerificationResult._(success: false, message: message);
  }
}

// Exception classes
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
