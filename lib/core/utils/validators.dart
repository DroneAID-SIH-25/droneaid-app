class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegExp.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  // Name validation
  static String? validateName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }

    if (value.trim().length > 50) {
      return '$fieldName must not exceed 50 characters';
    }

    final nameRegExp = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegExp.hasMatch(value.trim())) {
      return '$fieldName can only contain letters and spaces';
    }

    return null;
  }

  // Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    // Check for Indian phone numbers (10 digits)
    if (digitsOnly.length == 10 && digitsOnly.startsWith(RegExp(r'[6-9]'))) {
      return null;
    }

    // Check for Indian phone numbers with country code (+91)
    if (digitsOnly.length == 12 &&
        digitsOnly.startsWith('91') &&
        digitsOnly.substring(2).startsWith(RegExp(r'[6-9]'))) {
      return null;
    }

    // Check for international format
    if (digitsOnly.length >= 10 && digitsOnly.length <= 15) {
      return null;
    }

    return 'Please enter a valid phone number';
  }

  // Required field validation
  static String? validateRequired(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Description validation
  static String? validateDescription(
    String? value, {
    String fieldName = 'Description',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (value.trim().length < 10) {
      return '$fieldName must be at least 10 characters';
    }

    if (value.trim().length > 500) {
      return '$fieldName must not exceed 500 characters';
    }

    return null;
  }

  // Address validation
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }

    if (value.trim().length < 10) {
      return 'Please provide a complete address';
    }

    if (value.trim().length > 200) {
      return 'Address is too long';
    }

    return null;
  }

  // Operator ID validation
  static String? validateOperatorId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Operator ID is required';
    }

    // Check format: letters and numbers, 6-20 characters
    final operatorIdRegExp = RegExp(r'^[a-zA-Z0-9]{6,20}$');
    if (!operatorIdRegExp.hasMatch(value.trim())) {
      return 'Operator ID must be 6-20 characters (letters and numbers only)';
    }

    return null;
  }

  // Organization validation
  static String? validateOrganization(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Organization is required';
    }

    if (value.trim().length < 2) {
      return 'Organization name must be at least 2 characters';
    }

    if (value.trim().length > 100) {
      return 'Organization name is too long';
    }

    return null;
  }

  // Designation validation
  static String? validateDesignation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Designation is required';
    }

    if (value.trim().length < 2) {
      return 'Designation must be at least 2 characters';
    }

    if (value.trim().length > 50) {
      return 'Designation is too long';
    }

    return null;
  }

  // Number of people validation
  static String? validateNumberOfPeople(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Number of people is required';
    }

    final number = int.tryParse(value.trim());
    if (number == null || number < 1) {
      return 'Please enter a valid number (minimum 1)';
    }

    if (number > 1000) {
      return 'Number seems too large, please verify';
    }

    return null;
  }

  // Latitude validation
  static String? validateLatitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Latitude is required';
    }

    final latitude = double.tryParse(value.trim());
    if (latitude == null || latitude < -90 || latitude > 90) {
      return 'Please enter a valid latitude (-90 to 90)';
    }

    return null;
  }

  // Longitude validation
  static String? validateLongitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Longitude is required';
    }

    final longitude = double.tryParse(value.trim());
    if (longitude == null || longitude < -180 || longitude > 180) {
      return 'Please enter a valid longitude (-180 to 180)';
    }

    return null;
  }

  // Serial number validation (for drones)
  static String? validateSerialNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Serial number is required';
    }

    if (value.trim().length < 5) {
      return 'Serial number must be at least 5 characters';
    }

    if (value.trim().length > 30) {
      return 'Serial number is too long';
    }

    final serialRegExp = RegExp(r'^[a-zA-Z0-9\-_]+$');
    if (!serialRegExp.hasMatch(value.trim())) {
      return 'Serial number can only contain letters, numbers, hyphens, and underscores';
    }

    return null;
  }

  // Battery level validation
  static String? validateBatteryLevel(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Battery level is required';
    }

    final level = double.tryParse(value.trim());
    if (level == null || level < 0 || level > 100) {
      return 'Battery level must be between 0 and 100';
    }

    return null;
  }

  // Duration validation (in minutes)
  static String? validateDuration(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Duration is required';
    }

    final duration = double.tryParse(value.trim());
    if (duration == null || duration <= 0) {
      return 'Please enter a valid duration';
    }

    if (duration > 600) {
      // 10 hours
      return 'Duration seems too long, please verify';
    }

    return null;
  }

  // Speed validation (in km/h)
  static String? validateSpeed(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Speed is required';
    }

    final speed = double.tryParse(value.trim());
    if (speed == null || speed <= 0) {
      return 'Please enter a valid speed';
    }

    if (speed > 200) {
      // 200 km/h seems reasonable for drones
      return 'Speed seems too high, please verify';
    }

    return null;
  }

  // Weight validation (in kg)
  static String? validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Weight is required';
    }

    final weight = double.tryParse(value.trim());
    if (weight == null || weight <= 0) {
      return 'Please enter a valid weight';
    }

    if (weight > 1000) {
      // 1000 kg seems reasonable for drone payload
      return 'Weight seems too high, please verify';
    }

    return null;
  }

  // URL validation
  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // URL is optional
    }

    final urlRegExp = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegExp.hasMatch(value.trim())) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  // Generic text length validation
  static String? validateTextLength(
    String? value, {
    required String fieldName,
    int minLength = 1,
    int maxLength = 100,
    bool required = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return required ? '$fieldName is required' : null;
    }

    if (value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    if (value.trim().length > maxLength) {
      return '$fieldName must not exceed $maxLength characters';
    }

    return null;
  }

  // Generic number validation
  static String? validateNumber(
    String? value, {
    required String fieldName,
    double? min,
    double? max,
    bool required = true,
    bool allowDecimals = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return required ? '$fieldName is required' : null;
    }

    final number = allowDecimals
        ? double.tryParse(value.trim())
        : int.tryParse(value.trim())?.toDouble();

    if (number == null) {
      return 'Please enter a valid number';
    }

    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }

    if (max != null && number > max) {
      return '$fieldName must not exceed $max';
    }

    return null;
  }

  // Composite validation for multiple validators
  static String? validateMultiple(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  // Clean and format phone number
  static String cleanPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // Add country code if not present and it's an Indian number
    if (digitsOnly.length == 10 && digitsOnly.startsWith(RegExp(r'[6-9]'))) {
      return '+91$digitsOnly';
    } else if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
      return '+$digitsOnly';
    }

    return digitsOnly.isNotEmpty ? '+$digitsOnly' : phoneNumber;
  }

  // Format name (title case)
  static String formatName(String name) {
    return name
        .trim()
        .toLowerCase()
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : word,
        )
        .join(' ');
  }
}
