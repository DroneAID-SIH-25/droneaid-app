import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/emergency_request.dart';
import '../models/user.dart';
import '../services/mock_data_service.dart';
import 'location_provider.dart';

class EmergencyProvider extends ChangeNotifier {
  final LocationProvider _locationProvider;
  final MockDataService _mockDataService = MockDataService();

  List<EmergencyRequest> _emergencyRequests = [];
  List<EmergencyRequest> _userRequests = [];
  EmergencyRequest? _activeRequest;
  bool _isLoading = false;
  String? _error;

  EmergencyProvider(this._locationProvider);

  // Getters
  List<EmergencyRequest> get emergencyRequests => _emergencyRequests;
  List<EmergencyRequest> get userRequests => _userRequests;
  EmergencyRequest? get activeRequest => _activeRequest;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveRequest =>
      _activeRequest != null && _activeRequest!.isActive;

  Future<void> loadUserRequests(String userId) async {
    _setLoading(true);
    _setError(null);

    try {
      // In a real app, this would fetch from API
      _userRequests = await _mockDataService.getUserEmergencyRequests(userId);

      // Find active request
      _activeRequest =
          _userRequests.where((request) => request.isActive).isNotEmpty
          ? _userRequests.where((request) => request.isActive).first
          : null;

      notifyListeners();
    } catch (e) {
      _setError('Failed to load emergency requests: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<EmergencyRequest> createEmergencyRequest({
    required String userId,
    required EmergencyType emergencyType,
    required String description,
    required String contactNumber,
    Priority priority = Priority.high,
    LocationData? customLocation,
    List<String>? images,
    Map<String, dynamic>? additionalInfo,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // Get user's current location or use custom location
      final location =
          customLocation ??
          _locationProvider.currentLocation ??
          LocationData(
            latitude: 28.6139,
            longitude: 77.2090,
            address: 'New Delhi, India',
          );

      final emergencyRequest = EmergencyRequest(
        userId: userId,
        emergencyType: emergencyType,
        description: description,
        location: location,
        priority: priority,
        contactNumber: contactNumber,
        images: images ?? [],
        additionalInfo: additionalInfo,
      );

      // Add initial update
      final initialUpdate = EmergencyUpdate(
        requestId: emergencyRequest.id,
        updatedBy: 'System',
        message: 'Emergency request created and submitted for processing',
      );

      final updatedRequest = emergencyRequest.copyWith(
        updates: [initialUpdate],
      );

      // In a real app, this would be sent to the server
      await _mockDataService.createEmergencyRequest(updatedRequest);

      // Update local state
      _userRequests.insert(0, updatedRequest);
      _activeRequest = updatedRequest;

      // Simulate automatic assignment after 30 seconds
      _simulateEmergencyProcessing(updatedRequest.id);

      notifyListeners();
      return updatedRequest;
    } catch (e) {
      _setError('Failed to create emergency request: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateEmergencyStatus({
    required String requestId,
    required EmergencyStatus newStatus,
    String? updateMessage,
    String? updatedBy,
  }) async {
    try {
      final requestIndex = _userRequests.indexWhere((r) => r.id == requestId);
      if (requestIndex == -1) return;

      final request = _userRequests[requestIndex];
      final update = EmergencyUpdate(
        requestId: requestId,
        updatedBy: updatedBy ?? 'System',
        message: updateMessage ?? 'Status updated to ${newStatus.displayName}',
        newStatus: newStatus,
      );

      final updatedRequest = request.copyWith(
        status: newStatus,
        updates: [...request.updates, update],
        resolvedAt: newStatus == EmergencyStatus.resolved
            ? DateTime.now()
            : null,
      );

      _userRequests[requestIndex] = updatedRequest;

      if (_activeRequest?.id == requestId) {
        _activeRequest = updatedRequest.isActive ? updatedRequest : null;
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to update emergency status: $e');
    }
  }

  Future<void> cancelEmergencyRequest(String requestId) async {
    await updateEmergencyStatus(
      requestId: requestId,
      newStatus: EmergencyStatus.cancelled,
      updateMessage: 'Emergency request cancelled by user',
      updatedBy: 'User',
    );
  }

  Future<void> addEmergencyUpdate({
    required String requestId,
    required String message,
    String? updatedBy,
    LocationData? location,
    List<String>? images,
  }) async {
    try {
      final requestIndex = _userRequests.indexWhere((r) => r.id == requestId);
      if (requestIndex == -1) return;

      final request = _userRequests[requestIndex];
      final update = EmergencyUpdate(
        requestId: requestId,
        updatedBy: updatedBy ?? 'User',
        message: message,
        location: location,
        images: images ?? [],
      );

      final updatedRequest = request.copyWith(
        updates: [...request.updates, update],
      );

      _userRequests[requestIndex] = updatedRequest;

      if (_activeRequest?.id == requestId) {
        _activeRequest = updatedRequest;
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to add emergency update: $e');
    }
  }

  void _simulateEmergencyProcessing(String requestId) {
    // Simulate realistic emergency response timeline
    Timer(const Duration(seconds: 10), () {
      updateEmergencyStatus(
        requestId: requestId,
        newStatus: EmergencyStatus.assigned,
        updateMessage:
            'Emergency request assigned to drone unit DR-001. Drone is preparing for deployment.',
        updatedBy: 'GCS Operator',
      );
    });

    Timer(const Duration(seconds: 30), () {
      updateEmergencyStatus(
        requestId: requestId,
        newStatus: EmergencyStatus.inProgress,
        updateMessage:
            'Drone DR-001 has taken off and is en route to your location. ETA: 5 minutes.',
        updatedBy: 'Drone System',
      );
    });

    Timer(const Duration(minutes: 2), () {
      addEmergencyUpdate(
        requestId: requestId,
        message:
            'Drone DR-001 is now 500m away from your location. Please stay in a safe, visible area.',
        updatedBy: 'Drone System',
      );
    });

    Timer(const Duration(minutes: 5), () {
      addEmergencyUpdate(
        requestId: requestId,
        message:
            'Drone DR-001 has arrived at your location. Emergency responders have been notified and are on their way.',
        updatedBy: 'Drone System',
      );
    });

    Timer(const Duration(minutes: 8), () {
      updateEmergencyStatus(
        requestId: requestId,
        newStatus: EmergencyStatus.resolved,
        updateMessage:
            'Emergency response completed successfully. Ground units have arrived and taken over. Thank you for using Drone AID.',
        updatedBy: 'Emergency Services',
      );
    });
  }

  List<EmergencyRequest> getRequestsByStatus(EmergencyStatus status) {
    return _userRequests.where((request) => request.status == status).toList();
  }

  List<EmergencyRequest> getRequestsByPriority(Priority priority) {
    return _userRequests
        .where((request) => request.priority == priority)
        .toList();
  }

  List<EmergencyRequest> getRequestsByType(EmergencyType type) {
    return _userRequests
        .where((request) => request.emergencyType == type)
        .toList();
  }

  List<EmergencyRequest> getRecentRequests({int limit = 10}) {
    final sortedRequests = [..._userRequests];
    sortedRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedRequests.take(limit).toList();
  }

  int get totalRequests => _userRequests.length;
  int get activeRequests => _userRequests.where((r) => r.isActive).length;
  int get resolvedRequests => _userRequests.where((r) => r.isResolved).length;
  int get cancelledRequests => _userRequests.where((r) => r.isCancelled).length;

  double get averageResolutionTime {
    final resolvedWithTime = _userRequests
        .where((r) => r.isResolved && r.resolutionTime != null)
        .toList();

    if (resolvedWithTime.isEmpty) return 0.0;

    final totalMinutes = resolvedWithTime
        .map((r) => r.resolutionTime!.inMinutes)
        .reduce((a, b) => a + b);

    return totalMinutes / resolvedWithTime.length;
  }

  Map<EmergencyType, int> get requestsByType {
    final Map<EmergencyType, int> counts = {};
    for (final request in _userRequests) {
      counts[request.emergencyType] = (counts[request.emergencyType] ?? 0) + 1;
    }
    return counts;
  }

  Map<Priority, int> get requestsByPriority {
    final Map<Priority, int> counts = {};
    for (final request in _userRequests) {
      counts[request.priority] = (counts[request.priority] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> refresh() async {
    // In a real app, this would refetch data from the server
    notifyListeners();
  }

  void clearError() {
    _setError(null);
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
    super.dispose();
  }
}
