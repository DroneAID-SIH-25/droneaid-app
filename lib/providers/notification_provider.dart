import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/mock_data_service.dart';

enum NotificationType {
  emergencyAlert,
  droneApproach,
  systemUpdate,
  weatherAlert,
  disasterAlert,
  missionUpdate,
  maintenanceAlert,
}

enum NotificationPriority { low, normal, high, urgent }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? imageUrl;
  final LocationData? location;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.priority = NotificationPriority.normal,
    DateTime? timestamp,
    this.isRead = false,
    this.data,
    this.imageUrl,
    this.location,
  }) : timestamp = timestamp ?? DateTime.now();

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
    String? imageUrl,
    LocationData? location,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
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
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }

  String get typeText {
    switch (type) {
      case NotificationType.emergencyAlert:
        return 'Emergency Alert';
      case NotificationType.droneApproach:
        return 'Drone Approach';
      case NotificationType.systemUpdate:
        return 'System Update';
      case NotificationType.weatherAlert:
        return 'Weather Alert';
      case NotificationType.disasterAlert:
        return 'Disaster Alert';
      case NotificationType.missionUpdate:
        return 'Mission Update';
      case NotificationType.maintenanceAlert:
        return 'Maintenance Alert';
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
  final MockDataService _mockDataService = MockDataService();

  List<AppNotification> _notifications = [];
  List<AppNotification> _disasterAlerts = [];
  bool _isLoading = false;
  String? _error;
  Timer? _alertTimer;
  bool _notificationsEnabled = true;
  bool _emergencyAlertsEnabled = true;
  bool _droneNotificationsEnabled = true;
  bool _weatherAlertsEnabled = true;

  // Getters
  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get disasterAlerts => _disasterAlerts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get emergencyAlertsEnabled => _emergencyAlertsEnabled;
  bool get droneNotificationsEnabled => _droneNotificationsEnabled;
  bool get weatherAlertsEnabled => _weatherAlertsEnabled;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  int get urgentCount => _notifications
      .where((n) => !n.isRead && n.priority == NotificationPriority.urgent)
      .length;

  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  List<AppNotification> get urgentNotifications => _notifications
      .where((n) => n.priority == NotificationPriority.urgent)
      .toList();

  List<AppNotification> get recentNotifications => _notifications
      .where((n) => DateTime.now().difference(n.timestamp).inHours < 24)
      .toList();

  void initialize() {
    _loadInitialNotifications();
    _startDisasterAlertSimulation();
  }

  Future<void> _loadInitialNotifications() async {
    _setLoading(true);
    try {
      // Load initial notifications and disaster alerts
      _notifications = await _mockDataService.getMockNotifications();
      _disasterAlerts = await _mockDataService.getMockDisasterAlerts();

      // Sort by timestamp (newest first)
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _disasterAlerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      _setError('Failed to load notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _startDisasterAlertSimulation() {
    // Simulate periodic disaster alerts and system notifications
    _alertTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _simulateRandomAlert();
    });

    // Simulate initial welcome notification
    Timer(const Duration(seconds: 3), () {
      addNotification(
        AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Welcome to Drone AID',
          body: 'Your emergency assistance system is now active. Stay safe!',
          type: NotificationType.systemUpdate,
          priority: NotificationPriority.normal,
        ),
      );
    });
  }

  void _simulateRandomAlert() {
    final alerts = [
      // Weather Alerts
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Heavy Rain Alert',
        body:
            'Heavy rainfall expected in your area. Take necessary precautions.',
        type: NotificationType.weatherAlert,
        priority: NotificationPriority.high,
        location: LocationData(latitude: 28.6139, longitude: 77.2090),
      ),
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Cyclone Warning',
        body: 'Cyclone approaching coastal areas. Evacuation advisory issued.',
        type: NotificationType.disasterAlert,
        priority: NotificationPriority.urgent,
      ),
      // System Updates
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'System Maintenance',
        body: 'Scheduled maintenance will occur tonight from 2-4 AM.',
        type: NotificationType.systemUpdate,
        priority: NotificationPriority.normal,
      ),
      // Emergency Alerts
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Emergency Response Update',
        body: 'Emergency services are responding to incidents in your area.',
        type: NotificationType.emergencyAlert,
        priority: NotificationPriority.high,
      ),
    ];

    if (alerts.isNotEmpty) {
      final randomAlert = alerts[DateTime.now().millisecond % alerts.length];
      addNotification(randomAlert);
    }
  }

  void addNotification(AppNotification notification) {
    if (!_shouldShowNotification(notification)) return;

    _notifications.insert(0, notification);

    if (notification.type == NotificationType.disasterAlert) {
      _disasterAlerts.insert(0, notification);
    }

    // Keep only last 100 notifications
    if (_notifications.length > 100) {
      _notifications = _notifications.take(100).toList();
    }

    notifyListeners();
  }

  bool _shouldShowNotification(AppNotification notification) {
    if (!_notificationsEnabled) return false;

    switch (notification.type) {
      case NotificationType.emergencyAlert:
      case NotificationType.disasterAlert:
        return _emergencyAlertsEnabled;
      case NotificationType.droneApproach:
        return _droneNotificationsEnabled;
      case NotificationType.weatherAlert:
        return _weatherAlertsEnabled;
      case NotificationType.systemUpdate:
      case NotificationType.missionUpdate:
      case NotificationType.maintenanceAlert:
        return true;
    }
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
    _disasterAlerts.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  void clearDisasterAlerts() {
    _disasterAlerts.clear();
    _notifications.removeWhere((n) => n.type == NotificationType.disasterAlert);
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

  // Drone approach notification
  void notifyDroneApproach({
    required String droneId,
    required String droneName,
    required double distance,
    required Duration eta,
  }) {
    if (!_droneNotificationsEnabled) return;

    final notification = AppNotification(
      id: 'drone_approach_$droneId',
      title: 'Drone Approaching',
      body:
          '$droneName is ${distance.round()}m away. ETA: ${eta.inMinutes}m ${eta.inSeconds % 60}s',
      type: NotificationType.droneApproach,
      priority: NotificationPriority.high,
      data: {
        'droneId': droneId,
        'droneName': droneName,
        'distance': distance,
        'eta': eta.inSeconds,
      },
    );

    addNotification(notification);
  }

  // Emergency response notification
  void notifyEmergencyUpdate({
    required String requestId,
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.high,
  }) {
    final notification = AppNotification(
      id: 'emergency_$requestId',
      title: title,
      body: message,
      type: NotificationType.emergencyAlert,
      priority: priority,
      data: {'requestId': requestId, 'type': 'emergency_update'},
    );

    addNotification(notification);
  }

  // Mission update notification
  void notifyMissionUpdate({
    required String missionId,
    required String title,
    required String message,
  }) {
    final notification = AppNotification(
      id: 'mission_$missionId',
      title: title,
      body: message,
      type: NotificationType.missionUpdate,
      priority: NotificationPriority.normal,
      data: {'missionId': missionId, 'type': 'mission_update'},
    );

    addNotification(notification);
  }

  // Settings
  void toggleNotifications(bool enabled) {
    _notificationsEnabled = enabled;
    notifyListeners();
  }

  void toggleEmergencyAlerts(bool enabled) {
    _emergencyAlertsEnabled = enabled;
    notifyListeners();
  }

  void toggleDroneNotifications(bool enabled) {
    _droneNotificationsEnabled = enabled;
    notifyListeners();
  }

  void toggleWeatherAlerts(bool enabled) {
    _weatherAlertsEnabled = enabled;
    notifyListeners();
  }

  Map<String, bool> get notificationSettings => {
    'notifications': _notificationsEnabled,
    'emergency_alerts': _emergencyAlertsEnabled,
    'drone_notifications': _droneNotificationsEnabled,
    'weather_alerts': _weatherAlertsEnabled,
  };

  void updateSettings(Map<String, bool> settings) {
    _notificationsEnabled = settings['notifications'] ?? true;
    _emergencyAlertsEnabled = settings['emergency_alerts'] ?? true;
    _droneNotificationsEnabled = settings['drone_notifications'] ?? true;
    _weatherAlertsEnabled = settings['weather_alerts'] ?? true;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    super.dispose();
  }
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.emergencyAlert:
        return 'Emergency Alert';
      case NotificationType.droneApproach:
        return 'Drone Approach';
      case NotificationType.systemUpdate:
        return 'System Update';
      case NotificationType.weatherAlert:
        return 'Weather Alert';
      case NotificationType.disasterAlert:
        return 'Disaster Alert';
      case NotificationType.missionUpdate:
        return 'Mission Update';
      case NotificationType.maintenanceAlert:
        return 'Maintenance Alert';
    }
  }
}

extension NotificationPriorityExtension on NotificationPriority {
  String get displayName {
    switch (this) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.normal:
        return 'Normal';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }
}
