import 'dart:async';
import 'package:flutter/foundation.dart';

enum NotificationType {
  info,
  success,
  warning,
  error,
  emergency,
  missionUpdate,
  droneStatus,
  weatherAlert,
}

enum NotificationPriority { low, normal, high, critical }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.priority = NotificationPriority.normal,
    this.isRead = false,
    this.data,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  String get priorityText {
    switch (priority) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.normal:
        return 'Normal';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.critical:
        return 'Critical';
    }
  }

  String get typeText {
    switch (type) {
      case NotificationType.info:
        return 'Info';
      case NotificationType.success:
        return 'Success';
      case NotificationType.warning:
        return 'Warning';
      case NotificationType.error:
        return 'Error';
      case NotificationType.emergency:
        return 'Emergency';
      case NotificationType.missionUpdate:
        return 'Mission Update';
      case NotificationType.droneStatus:
        return 'Drone Status';
      case NotificationType.weatherAlert:
        return 'Weather Alert';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  Timer? _alertTimer;
  bool _notificationsEnabled = true;
  bool _emergencyAlertsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  // Getters
  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get emergencyAlertsEnabled => _emergencyAlertsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  int get criticalCount => _notifications
      .where((n) => !n.isRead && n.priority == NotificationPriority.critical)
      .length;

  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  List<AppNotification> get criticalNotifications => _notifications
      .where((n) => n.priority == NotificationPriority.critical)
      .toList();

  List<AppNotification> get recentNotifications => _notifications
      .where((n) => DateTime.now().difference(n.timestamp).inHours < 24)
      .toList();

  void initialize() {
    _loadInitialNotifications();
    _startPeriodicNotifications();
  }

  /// Notify emergency update
  void notifyEmergencyUpdate({
    required String requestId,
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.critical,
  }) {
    final notification = AppNotification(
      id: 'emergency_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      type: NotificationType.emergency,
      priority: priority,
      timestamp: DateTime.now(),
      data: {'requestId': requestId},
    );

    addNotification(notification);
  }

  void _loadInitialNotifications() {
    _setLoading(true);
    try {
      // Add welcome notification
      final welcomeNotification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Welcome to Drone AID',
        message: 'Your emergency drone response system is ready.',
        type: NotificationType.info,
        priority: NotificationPriority.normal,
        timestamp: DateTime.now(),
      );

      _notifications.add(welcomeNotification);

      // Add system status notification
      final statusNotification = AppNotification(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        title: 'System Status',
        message: 'All drone units are operational and ready for deployment.',
        type: NotificationType.success,
        priority: NotificationPriority.normal,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      _notifications.add(statusNotification);

      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      _setError('Failed to load notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _startPeriodicNotifications() {
    // Simulate periodic notifications for demo
    _alertTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _simulateRandomNotification();
    });
  }

  void _simulateRandomNotification() {
    final notifications = [
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Weather Update',
        message:
            'Clear skies reported in your area. Optimal flying conditions.',
        type: NotificationType.weatherAlert,
        priority: NotificationPriority.normal,
        timestamp: DateTime.now(),
      ),
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Drone Maintenance',
        message: 'Scheduled maintenance completed for Drone Alpha-001.',
        type: NotificationType.droneStatus,
        priority: NotificationPriority.normal,
        timestamp: DateTime.now(),
      ),
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'System Update',
        message: 'New features available. Update recommended.',
        type: NotificationType.info,
        priority: NotificationPriority.low,
        timestamp: DateTime.now(),
      ),
    ];

    if (notifications.isNotEmpty) {
      final randomNotification =
          notifications[DateTime.now().millisecond % notifications.length];
      addNotification(randomNotification);
    }
  }

  void addNotification(AppNotification notification) {
    if (!_shouldShowNotification(notification)) return;

    _notifications.insert(0, notification);

    // Keep only last 100 notifications
    if (_notifications.length > 100) {
      _notifications = _notifications.take(100).toList();
    }

    notifyListeners();

    if (kDebugMode) {
      print(
        'New notification: ${notification.title} - ${notification.message}',
      );
    }
  }

  bool _shouldShowNotification(AppNotification notification) {
    if (!_notificationsEnabled) return false;

    switch (notification.type) {
      case NotificationType.emergency:
        return _emergencyAlertsEnabled;
      case NotificationType.info:
      case NotificationType.success:
      case NotificationType.warning:
      case NotificationType.error:
      case NotificationType.missionUpdate:
      case NotificationType.droneStatus:
      case NotificationType.weatherAlert:
        return true;
    }
  }

  void addInfo(String title, String message) {
    addNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: NotificationType.info,
        priority: NotificationPriority.normal,
        timestamp: DateTime.now(),
      ),
    );
  }

  void addSuccess(String title, String message) {
    addNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: NotificationType.success,
        priority: NotificationPriority.normal,
        timestamp: DateTime.now(),
      ),
    );
  }

  void addWarning(String title, String message) {
    addNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: NotificationType.warning,
        priority: NotificationPriority.high,
        timestamp: DateTime.now(),
      ),
    );
  }

  void addError(String title, String message) {
    addNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: NotificationType.error,
        priority: NotificationPriority.high,
        timestamp: DateTime.now(),
      ),
    );
  }

  void addEmergency(String title, String message) {
    addNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: NotificationType.emergency,
        priority: NotificationPriority.critical,
        timestamp: DateTime.now(),
      ),
    );
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllAsRead() {
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    notifyListeners();
  }

  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  void clearReadNotifications() {
    _notifications.removeWhere((n) => n.isRead);
    notifyListeners();
  }

  List<AppNotification> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  List<AppNotification> getNotificationsByPriority(
    NotificationPriority priority,
  ) {
    return _notifications.where((n) => n.priority == priority).toList();
  }

  List<AppNotification> searchNotifications(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _notifications.where((notification) {
      return notification.title.toLowerCase().contains(lowercaseQuery) ||
          notification.message.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Settings
  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
    notifyListeners();
  }

  void toggleEmergencyAlerts() {
    _emergencyAlertsEnabled = !_emergencyAlertsEnabled;
    notifyListeners();
  }

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    notifyListeners();
  }

  void toggleVibration() {
    _vibrationEnabled = !_vibrationEnabled;
    notifyListeners();
  }

  void updateSettings({
    bool? notifications,
    bool? emergencyAlerts,
    bool? sound,
    bool? vibration,
  }) {
    _notificationsEnabled = notifications ?? _notificationsEnabled;
    _emergencyAlertsEnabled = emergencyAlerts ?? _emergencyAlertsEnabled;
    _soundEnabled = sound ?? _soundEnabled;
    _vibrationEnabled = vibration ?? _vibrationEnabled;
    notifyListeners();
  }

  Map<String, bool> get settings => {
    'notifications': _notificationsEnabled,
    'emergencyAlerts': _emergencyAlertsEnabled,
    'sound': _soundEnabled,
    'vibration': _vibrationEnabled,
  };

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    super.dispose();
  }
}
