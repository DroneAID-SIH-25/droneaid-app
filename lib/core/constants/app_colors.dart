import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF42A5F5);

  // Secondary Colors
  static const Color secondary = Color(0xFFFF6B35);
  static const Color secondaryDark = Color(0xFFE65100);
  static const Color secondaryLight = Color(0xFFFF8A65);

  // Background Colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textHint = Color(0xFFBDBDBD);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Emergency Priority Colors
  static const Color priorityLow = Color(0xFF4CAF50);
  static const Color priorityMedium = Color(0xFFFF9800);
  static const Color priorityHigh = Color(0xFFFF5722);
  static const Color priorityCritical = Color(0xFFE91E63);

  // Drone Status Colors
  static const Color droneAvailable = Color(0xFF4CAF50);
  static const Color droneBusy = Color(0xFFFF9800);
  static const Color droneMaintenance = Color(0xFF9E9E9E);
  static const Color droneOffline = Color(0xFF757575);

  // Mission Status Colors
  static const Color missionPending = Color(0xFF2196F3);
  static const Color missionAssigned = Color(0xFFFF9800);
  static const Color missionInProgress = Color(0xFF3F51B5);
  static const Color missionCompleted = Color(0xFF4CAF50);
  static const Color missionCancelled = Color(0xFFE91E63);

  // Map Colors
  static const Color mapMarker = Color(0xFFF44336);
  static const Color mapRoute = Color(0xFF2196F3);
  static const Color mapGeofence = Color(0xFF9C27B0);

  // Utility Colors
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFBDBDBD);
  static const Color shadow = Color(0x1F000000);
  static const Color overlay = Color(0x66000000);

  // Card Colors
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardElevated = Color(0xFFF8F9FA);

  // Button Colors
  static const Color buttonDisabled = Color(0xFFE0E0E0);
  static const Color buttonTextDisabled = Color(0xFF9E9E9E);

  // Input Colors
  static const Color inputBorder = Color(0xFFE0E0E0);
  static const Color inputFocusBorder = Color(0xFF1976D2);
  static const Color inputErrorBorder = Color(0xFFF44336);
  static const Color inputFill = Color(0xFFFAFAFA);

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF1976D2),
    Color(0xFF42A5F5),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFFFF6B35),
    Color(0xFFFF8A65),
  ];

  static const List<Color> emergencyGradient = [
    Color(0xFFE91E63),
    Color(0xFFF44336),
  ];

  // Helper Methods
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslLight.toColor();
  }
}
