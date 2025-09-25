import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/ongoing_mission.dart';
import '../models/mission.dart';
import '../services/real_time_mission_service.dart';

/// Provider for managing ongoing missions with real-time updates
class OngoingMissionsProvider extends ChangeNotifier {
  final RealTimeMissionService _realTimeService = RealTimeMissionService();

  List<OngoingMission> _ongoingMissions = [];
  Map<String, StreamSubscription> _missionSubscriptions = {};
  bool _isLoading = false;
  String? _error;

  // Filters
  String _searchQuery = '';
  MissionStatus? _statusFilter;
  MissionPriority? _priorityFilter;
  MissionType? _typeFilter;
  bool _showOnlyActive = true;
  bool _showOnlyCritical = false;

  // Getters
  List<OngoingMission> get ongoingMissions => _ongoingMissions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  MissionStatus? get statusFilter => _statusFilter;
  MissionPriority? get priorityFilter => _priorityFilter;
  MissionType? get typeFilter => _typeFilter;
  bool get showOnlyActive => _showOnlyActive;
  bool get showOnlyCritical => _showOnlyCritical;

  /// Get filtered missions based on current filters
  List<OngoingMission> get filteredMissions {
    var missions = _ongoingMissions;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      missions = missions.where((mission) {
        return mission.title.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            mission.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            mission.assignedDroneId.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            mission.targetLocation.address?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ==
                true;
      }).toList();
    }

    // Apply status filter
    if (_statusFilter != null) {
      missions = missions
          .where((mission) => mission.status == _statusFilter)
          .toList();
    }

    // Apply priority filter
    if (_priorityFilter != null) {
      missions = missions
          .where((mission) => mission.priority == _priorityFilter)
          .toList();
    }

    // Apply type filter
    if (_typeFilter != null) {
      missions = missions
          .where((mission) => mission.type == _typeFilter)
          .toList();
    }

    // Apply active filter
    if (_showOnlyActive) {
      missions = missions.where((mission) => mission.isActive).toList();
    }

    // Apply critical filter
    if (_showOnlyCritical) {
      missions = missions
          .where((mission) => mission.hasCriticalReadings || mission.isCritical)
          .toList();
    }

    // Sort by priority and creation time
    missions.sort((a, b) {
      // First sort by priority (critical first)
      final priorityComparison = b.priority.index.compareTo(a.priority.index);
      if (priorityComparison != 0) return priorityComparison;

      // Then by creation time (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });

    return missions;
  }

  /// Get mission statistics
  Map<String, int> get missionStats {
    return {
      'total': _ongoingMissions.length,
      'active': _ongoingMissions.where((m) => m.isActive).length,
      'critical': _ongoingMissions.where((m) => m.isCritical).length,
      'completed': _ongoingMissions.where((m) => m.isCompleted).length,
      'withAlerts': _ongoingMissions.where((m) => m.hasCriticalReadings).length,
    };
  }

  /// Initialize provider and load mock data
  Future<void> initialize() async {
    _setLoading(true);
    _setError(null);

    try {
      // Load mock ongoing missions
      final mockMissions = _realTimeService.createMockOngoingMissions();
      _ongoingMissions = mockMissions;

      // Start real-time monitoring for each mission
      for (final mission in mockMissions) {
        await _startMissionMonitoring(mission);
      }

      _setLoading(false);
    } catch (e) {
      _setError('Failed to initialize ongoing missions: $e');
      _setLoading(false);
    }
  }

  /// Start real-time monitoring for a mission
  Future<void> _startMissionMonitoring(OngoingMission mission) async {
    try {
      _realTimeService.addActiveMission(mission);

      final stream = _realTimeService.startMissionMonitoring(mission.id);
      _missionSubscriptions[mission.id] = stream.listen(
        (updatedMission) {
          _updateMission(updatedMission);
        },
        onError: (error) {
          print('Error monitoring mission ${mission.id}: $error');
        },
      );
    } catch (e) {
      print('Failed to start monitoring for mission ${mission.id}: $e');
    }
  }

  /// Update a mission in the list
  void _updateMission(OngoingMission updatedMission) {
    final index = _ongoingMissions.indexWhere((m) => m.id == updatedMission.id);
    if (index != -1) {
      _ongoingMissions[index] = updatedMission;
      notifyListeners();
    }
  }

  /// Add a new ongoing mission
  Future<void> addOngoingMission(OngoingMission mission) async {
    try {
      _ongoingMissions.add(mission);
      await _startMissionMonitoring(mission);
      notifyListeners();
    } catch (e) {
      _setError('Failed to add mission: $e');
    }
  }

  /// Remove a mission from monitoring
  void removeMission(String missionId) {
    _ongoingMissions.removeWhere((m) => m.id == missionId);
    _stopMissionMonitoring(missionId);
    notifyListeners();
  }

  /// Stop monitoring for a specific mission
  void _stopMissionMonitoring(String missionId) {
    _missionSubscriptions[missionId]?.cancel();
    _missionSubscriptions.remove(missionId);
    _realTimeService.stopMissionMonitoring(missionId);
  }

  /// Pause a mission
  Future<void> pauseMission(String missionId) async {
    try {
      final index = _ongoingMissions.indexWhere((m) => m.id == missionId);
      if (index != -1) {
        _ongoingMissions[index] = _ongoingMissions[index].copyWith(
          status: MissionStatus.assigned, // Paused state
        );
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to pause mission: $e');
    }
  }

  /// Resume a mission
  Future<void> resumeMission(String missionId) async {
    try {
      final index = _ongoingMissions.indexWhere((m) => m.id == missionId);
      if (index != -1) {
        _ongoingMissions[index] = _ongoingMissions[index].copyWith(
          status: MissionStatus.inProgress,
        );
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to resume mission: $e');
    }
  }

  /// Abort a mission
  Future<void> abortMission(String missionId, String reason) async {
    try {
      final index = _ongoingMissions.indexWhere((m) => m.id == missionId);
      if (index != -1) {
        _ongoingMissions[index] = _ongoingMissions[index].copyWith(
          status: MissionStatus.cancelled,
        );
        _stopMissionMonitoring(missionId);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to abort mission: $e');
    }
  }

  /// Update search query
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Update status filter
  void updateStatusFilter(MissionStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  /// Update priority filter
  void updatePriorityFilter(MissionPriority? priority) {
    _priorityFilter = priority;
    notifyListeners();
  }

  /// Update type filter
  void updateTypeFilter(MissionType? type) {
    _typeFilter = type;
    notifyListeners();
  }

  /// Toggle active filter
  void toggleActiveFilter() {
    _showOnlyActive = !_showOnlyActive;
    notifyListeners();
  }

  /// Toggle critical filter
  void toggleCriticalFilter() {
    _showOnlyCritical = !_showOnlyCritical;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _statusFilter = null;
    _priorityFilter = null;
    _typeFilter = null;
    _showOnlyActive = true;
    _showOnlyCritical = false;
    notifyListeners();
  }

  /// Refresh missions data
  Future<void> refreshMissions() async {
    _setLoading(true);
    _setError(null);

    try {
      // In a real app, this would fetch from API
      await Future.delayed(const Duration(seconds: 1));
      _setLoading(false);
    } catch (e) {
      _setError('Failed to refresh missions: $e');
      _setLoading(false);
    }
  }

  /// Get mission by ID
  OngoingMission? getMissionById(String missionId) {
    try {
      return _ongoingMissions.firstWhere((m) => m.id == missionId);
    } catch (e) {
      return null;
    }
  }

  /// Get missions with critical alerts
  List<OngoingMission> get missionsWithAlerts {
    return _ongoingMissions.where((m) => m.hasCriticalReadings).toList();
  }

  /// Get missions by status
  List<OngoingMission> getMissionsByStatus(MissionStatus status) {
    return _ongoingMissions.where((m) => m.status == status).toList();
  }

  /// Get missions by priority
  List<OngoingMission> getMissionsByPriority(MissionPriority priority) {
    return _ongoingMissions.where((m) => m.priority == priority).toList();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Set error state
  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Cancel all subscriptions
    for (final subscription in _missionSubscriptions.values) {
      subscription.cancel();
    }
    _missionSubscriptions.clear();

    // Dispose real-time service
    _realTimeService.dispose();

    super.dispose();
  }
}
