import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../core/services/auth_service.dart';
import '../models/user.dart';
import '../models/gcs_operator.dart';

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Define UserType enum here to avoid conflicts
enum AppUserType { helpSeeker, gcsOperator }

// Auth State Model
@immutable
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final AppUserType? userType;
  final User? user;
  final GCSOperator? gcsOperator;
  final String? errorMessage;
  final bool isInitialized;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.userType,
    this.user,
    this.gcsOperator,
    this.errorMessage,
    this.isInitialized = false,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    AppUserType? userType,
    User? user,
    GCSOperator? gcsOperator,
    String? errorMessage,
    bool? isInitialized,
    bool clearError = false,
    bool clearUser = false,
    bool clearOperator = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userType: userType ?? this.userType,
      user: clearUser ? null : (user ?? this.user),
      gcsOperator: clearOperator ? null : (gcsOperator ?? this.gcsOperator),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  String? get displayName {
    if (user != null) return user!.displayName;
    if (gcsOperator != null) return gcsOperator!.displayName;
    return null;
  }

  String? get email {
    if (user != null) return user!.email;
    if (gcsOperator != null) return gcsOperator!.email;
    return null;
  }

  String? get phone {
    if (user != null) return user!.phone;
    if (gcsOperator != null) return gcsOperator!.phoneNumber;
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          isAuthenticated == other.isAuthenticated &&
          userType == other.userType &&
          user == other.user &&
          gcsOperator == other.gcsOperator &&
          errorMessage == other.errorMessage &&
          isInitialized == other.isInitialized;

  @override
  int get hashCode =>
      isLoading.hashCode ^
      isAuthenticated.hashCode ^
      userType.hashCode ^
      user.hashCode ^
      gcsOperator.hashCode ^
      errorMessage.hashCode ^
      isInitialized.hashCode;
}

// Auth Notifier
class AuthNotifier extends Notifier<AuthState> {
  late AuthService _authService;

  @override
  AuthState build() {
    _authService = ref.read(authServiceProvider);
    _initializeAuth();
    return const AuthState();
  }

  /// Initialize authentication state
  Future<void> _initializeAuth() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _authService.checkExistingSession();

      if (result.success) {
        AppUserType? appUserType;
        if (result.userType == UserType.helpSeeker) {
          appUserType = AppUserType.helpSeeker;
        } else if (result.userType == UserType.gcsOperator) {
          appUserType = AppUserType.gcsOperator;
        }

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          userType: appUserType,
          user: result.user,
          gcsOperator: result.gcsOperator,
          isInitialized: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          isInitialized: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: 'Failed to initialize authentication',
        isInitialized: true,
      );
    }
  }

  /// Login as Help Seeker
  Future<bool> loginHelpSeeker({
    required String identifier,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _authService.loginHelpSeeker(
        identifier: identifier,
        password: password,
      );

      if (result.success) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          userType: AppUserType.helpSeeker,
          user: result.user,
          clearOperator: true,
        );
        return true;
      } else {
        state = state.copyWith(isLoading: false, errorMessage: result.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Login failed: ${e.toString()}',
      );
      return false;
    }
  }

  /// Register Help Seeker
  Future<bool> registerHelpSeeker({
    required String name,
    required String phone,
    required String aadharNumber,
    required String password,
    String? email,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _authService.registerHelpSeeker(
        name: name,
        phone: phone,
        aadharNumber: aadharNumber,
        password: password,
        email: email,
      );

      if (result.success) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          userType: AppUserType.helpSeeker,
          user: result.user,
          clearOperator: true,
        );
        return true;
      } else {
        state = state.copyWith(isLoading: false, errorMessage: result.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Registration failed: ${e.toString()}',
      );
      return false;
    }
  }

  /// Login as GCS Operator
  Future<bool> loginGCSOperator({
    required String employeeId,
    required String password,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _authService.loginGCSOperator(
        employeeId: employeeId,
        password: password,
        phone: phone,
      );

      if (result.success) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          userType: AppUserType.gcsOperator,
          gcsOperator: result.gcsOperator,
          clearUser: true,
        );
        return true;
      } else {
        state = state.copyWith(isLoading: false, errorMessage: result.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Login failed: ${e.toString()}',
      );
      return false;
    }
  }

  /// Verify Aadhar Number
  Future<VerificationResult> verifyAadharNumber(String aadharNumber) async {
    return await _authService.verifyAadharNumber(aadharNumber);
  }

  /// Update User Profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? email,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _authService.updateUserProfile(
        name: name,
        phone: phone,
        email: email,
      );

      if (result.success) {
        state = state.copyWith(isLoading: false, user: result.user);
        return true;
      } else {
        state = state.copyWith(isLoading: false, errorMessage: result.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update profile: ${e.toString()}',
      );
      return false;
    }
  }

  /// Change Password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (result.success) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(isLoading: false, errorMessage: result.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to change password: ${e.toString()}',
      );
      return false;
    }
  }

  /// Reset Password
  Future<bool> resetPassword({required String identifier}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _authService.resetPassword(identifier: identifier);

      if (result.success) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(isLoading: false, errorMessage: result.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to reset password: ${e.toString()}',
      );
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authService.logout();
      state = const AuthState(isInitialized: true);
    } catch (e) {
      // Even if logout fails, clear the local state
      state = const AuthState(isInitialized: true);
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Refresh user session
  Future<void> refreshSession() async {
    await _initializeAuth();
  }
}

// Auth Provider
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final currentGCSOperatorProvider = Provider<GCSOperator?>((ref) {
  return ref.watch(authProvider).gcsOperator;
});

final userTypeProvider = Provider<AppUserType?>((ref) {
  return ref.watch(authProvider).userType;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).errorMessage;
});

final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

final authInitializedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isInitialized;
});

// Form validation providers
final phoneValidationProvider = Provider.family<String?, String>((ref, phone) {
  if (phone.isEmpty) return 'Phone number is required';

  final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
  final isValidIndian =
      RegExp(r'^\+91[6-9]\d{9}$').hasMatch(cleanPhone) ||
      RegExp(r'^[6-9]\d{9}$').hasMatch(cleanPhone);

  if (!isValidIndian) return 'Please enter a valid Indian mobile number';

  return null;
});

final aadharValidationProvider = Provider.family<String?, String>((
  ref,
  aadhar,
) {
  if (aadhar.isEmpty) return 'Aadhar number is required';

  final cleanAadhar = aadhar.replaceAll(RegExp(r'[^\d]'), '');
  if (cleanAadhar.length != 12) return 'Aadhar number must be 12 digits';

  return null;
});

final nameValidationProvider = Provider.family<String?, String>((ref, name) {
  if (name.isEmpty) return 'Name is required';
  if (name.trim().length < 2) return 'Name must be at least 2 characters';
  if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name.trim())) {
    return 'Name can only contain letters and spaces';
  }
  return null;
});

final passwordValidationProvider = Provider.family<String?, String>((
  ref,
  password,
) {
  if (password.isEmpty) return 'Password is required';
  if (password.length < 6) return 'Password must be at least 6 characters';
  return null;
});

final employeeIdValidationProvider = Provider.family<String?, String>((
  ref,
  employeeId,
) {
  if (employeeId.isEmpty) return 'Employee ID is required';
  if (employeeId.length < 3) return 'Employee ID must be at least 3 characters';
  return null;
});
