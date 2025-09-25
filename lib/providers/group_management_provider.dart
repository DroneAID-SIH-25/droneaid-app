import 'package:flutter/material.dart';
import '../models/group_event.dart';
import '../models/gcs_station.dart';
import '../models/user.dart';

class GroupManagementProvider extends ChangeNotifier {
  List<GroupEvent> _events = [];
  List<GCSStation> _gcsStations = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<GroupEvent> get events => List.unmodifiable(_events);
  List<GCSStation> get gcsStations => List.unmodifiable(_gcsStations);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered getters
  List<GroupEvent> get activeEvents =>
      _events.where((event) => event.isOngoing).toList();

  List<GroupEvent> get criticalEvents =>
      _events.where((event) => event.isCritical).toList();

  List<GCSStation> get operationalStations =>
      _gcsStations.where((station) => station.isOperational).toList();

  List<GCSStation> get availableStations =>
      _gcsStations.where((station) => station.canAcceptNewEvents).toList();

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Initialize with mock data
  void initializeMockData() {
    _setLoading(true);

    // Mock GCS Stations
    _gcsStations = [
      GCSStation(
        name: 'Mumbai Central GCS',
        code: 'MUM-GCS-01',
        location: 'Mumbai, Maharashtra',
        coordinates: LocationData(
          latitude: 19.0760,
          longitude: 72.8777,
          address: 'Mumbai Central, Maharashtra, India',
        ),
        organizationId: 'org-001',
        contactEmail: 'mumbai.gcs@droneaid.com',
        contactPhone: '+91-22-12345678',
        maxCapacity: 15,
        currentOperators: 8,
        status: StationStatus.operational,
        certifications: ['CAT-A', 'EMERGENCY-OPS', 'MEDICAL-RESPONSE'],
        equipment: {
          'communication_systems': ['VHF', 'UHF', 'Satellite'],
          'radar_systems': ['Primary', 'Secondary'],
          'computing_power': 'High Performance',
          'drone_bays': 10,
          'maintenance_facility': true,
        },
      ),
      GCSStation(
        name: 'Delhi North GCS',
        code: 'DEL-GCS-02',
        location: 'New Delhi, Delhi',
        coordinates: LocationData(
          latitude: 28.7041,
          longitude: 77.1025,
          address: 'New Delhi, Delhi, India',
        ),
        organizationId: 'org-002',
        contactEmail: 'delhi.gcs@droneaid.com',
        contactPhone: '+91-11-87654321',
        maxCapacity: 20,
        currentOperators: 12,
        status: StationStatus.operational,
        certifications: ['CAT-A', 'CAT-B', 'FIRE-RESPONSE'],
        equipment: {
          'communication_systems': ['VHF', 'UHF', 'Digital'],
          'radar_systems': ['Advanced AESA'],
          'computing_power': 'Ultra High Performance',
          'drone_bays': 15,
          'maintenance_facility': true,
        },
      ),
      GCSStation(
        name: 'Bangalore Tech GCS',
        code: 'BLR-GCS-03',
        location: 'Bangalore, Karnataka',
        coordinates: LocationData(
          latitude: 12.9716,
          longitude: 77.5946,
          address: 'Bangalore, Karnataka, India',
        ),
        organizationId: 'org-003',
        contactEmail: 'bangalore.gcs@droneaid.com',
        contactPhone: '+91-80-11223344',
        maxCapacity: 12,
        currentOperators: 6,
        status: StationStatus.operational,
        certifications: ['CAT-A', 'TECH-OPS', 'R&D'],
        equipment: {
          'communication_systems': ['5G', 'Satellite', 'Mesh Network'],
          'radar_systems': ['Next-Gen AESA', 'AI-Enhanced'],
          'computing_power': 'Quantum Enhanced',
          'drone_bays': 8,
          'maintenance_facility': true,
        },
      ),
      GCSStation(
        name: 'Chennai Coastal GCS',
        code: 'CHE-GCS-04',
        location: 'Chennai, Tamil Nadu',
        coordinates: LocationData(
          latitude: 13.0827,
          longitude: 80.2707,
          address: 'Chennai, Tamil Nadu, India',
        ),
        organizationId: 'org-004',
        contactEmail: 'chennai.gcs@droneaid.com',
        contactPhone: '+91-44-55667788',
        maxCapacity: 10,
        currentOperators: 4,
        status: StationStatus.standby,
        certifications: ['CAT-A', 'MARITIME-OPS', 'CYCLONE-RESPONSE'],
        equipment: {
          'communication_systems': ['Marine Radio', 'Satellite'],
          'radar_systems': ['Maritime Surveillance'],
          'computing_power': 'High Performance',
          'drone_bays': 12,
          'maintenance_facility': false,
        },
      ),
      GCSStation(
        name: 'Kolkata Emergency GCS',
        code: 'KOL-GCS-05',
        location: 'Kolkata, West Bengal',
        coordinates: LocationData(
          latitude: 22.5726,
          longitude: 88.3639,
          address: 'Kolkata, West Bengal, India',
        ),
        organizationId: 'org-005',
        contactEmail: 'kolkata.gcs@droneaid.com',
        contactPhone: '+91-33-99887766',
        maxCapacity: 8,
        currentOperators: 8,
        status: StationStatus.operational,
        certifications: ['CAT-A', 'FLOOD-RESPONSE', 'MEDICAL-OPS'],
        equipment: {
          'communication_systems': ['VHF', 'Digital Trunking'],
          'radar_systems': ['Weather Radar', 'Surveillance'],
          'computing_power': 'Standard',
          'drone_bays': 6,
          'maintenance_facility': true,
        },
      ),
    ];

    // Mock Group Events
    _events = [
      GroupEvent(
        title: 'Mumbai Monsoon Flooding',
        description:
            'Severe flooding in Mumbai suburbs due to heavy monsoon rains',
        type: EventType.flood,
        severity: EventSeverity.major,
        priority: EventPriority.high,
        location: LocationData(
          latitude: 19.0760,
          longitude: 72.8777,
          address: 'Mumbai, Maharashtra, India',
        ),
        createdBy: 'user-001',
        status: EventStatus.active,
        affectedRadius: 15.0,
        estimatedAffectedPeople: 50000,
        assignedOperators: ['op-001', 'op-002', 'op-003'],
        coordinatingAgency: 'Mumbai Disaster Management Authority',
        contactPerson: 'Dr. Rajesh Kumar',
        contactPhone: '+91-22-24567890',
        contactEmail: 'emergency@mumbai.gov.in',
      ),
      GroupEvent(
        title: 'Delhi Fire Incident',
        description:
            'Major fire outbreak in industrial area requiring immediate response',
        type: EventType.fireIncident,
        severity: EventSeverity.critical,
        priority: EventPriority.critical,
        location: LocationData(
          latitude: 28.6139,
          longitude: 77.2090,
          address: 'Industrial Area, Delhi, India',
        ),
        createdBy: 'user-002',
        status: EventStatus.active,
        affectedRadius: 5.0,
        estimatedAffectedPeople: 5000,
        assignedOperators: ['op-004', 'op-005'],
        coordinatingAgency: 'Delhi Fire Services',
        contactPerson: 'Chief Officer Sharma',
        contactPhone: '+91-11-23456789',
        contactEmail: 'fire@delhi.gov.in',
      ),
      GroupEvent(
        title: 'Earthquake Response - Gujarat',
        description: 'Post-earthquake assessment and rescue operations',
        type: EventType.earthquake,
        severity: EventSeverity.major,
        priority: EventPriority.high,
        location: LocationData(
          latitude: 23.0225,
          longitude: 72.5714,
          address: 'Ahmedabad, Gujarat, India',
        ),
        createdBy: 'user-003',
        status: EventStatus.resolved,
        affectedRadius: 25.0,
        estimatedAffectedPeople: 100000,
        assignedOperators: ['op-006', 'op-007', 'op-008', 'op-009'],
        coordinatingAgency: 'Gujarat State Disaster Management Authority',
        contactPerson: 'Director R.K. Patel',
        contactPhone: '+91-79-12345678',
        contactEmail: 'disaster@gujarat.gov.in',
        endTime: DateTime.now().subtract(const Duration(days: 2)),
      ),
      GroupEvent(
        title: 'Cyclone Monitoring - Odisha',
        description:
            'Monitoring approaching cyclone and coordinating evacuation efforts',
        type: EventType.hurricane,
        severity: EventSeverity.major,
        priority: EventPriority.high,
        location: LocationData(
          latitude: 20.9517,
          longitude: 85.0985,
          address: 'Bhubaneswar, Odisha, India',
        ),
        createdBy: 'user-004',
        status: EventStatus.active,
        affectedRadius: 50.0,
        estimatedAffectedPeople: 200000,
        assignedOperators: ['op-010', 'op-011'],
        coordinatingAgency: 'Odisha State Disaster Management Authority',
        contactPerson: 'Special Relief Commissioner',
        contactPhone: '+91-674-2345678',
        contactEmail: 'cyclone@odisha.gov.in',
        startTime: DateTime.now().add(const Duration(hours: 12)),
      ),
      GroupEvent(
        title: 'Medical Emergency - Kerala',
        description: 'Mass casualty incident requiring medical drone support',
        type: EventType.massCasualty,
        severity: EventSeverity.critical,
        priority: EventPriority.critical,
        location: LocationData(
          latitude: 10.8505,
          longitude: 76.2711,
          address: 'Kochi, Kerala, India',
        ),
        createdBy: 'user-005',
        status: EventStatus.active,
        affectedRadius: 3.0,
        estimatedAffectedPeople: 500,
        assignedOperators: ['op-012', 'op-013'],
        coordinatingAgency: 'Kerala Health Services',
        contactPerson: 'Dr. Priya Nair',
        contactPhone: '+91-484-1234567',
        contactEmail: 'emergency@kerala.health.gov.in',
      ),
    ];

    _setLoading(false);
    notifyListeners();
  }

  // Event Management Methods
  Future<void> createEvent(GroupEvent event) async {
    try {
      _setLoading(true);
      _setError(null);

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      _events.insert(0, event);
      notifyListeners();
    } catch (e) {
      _setError('Failed to create event: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateEvent(GroupEvent updatedEvent) async {
    try {
      _setLoading(true);
      _setError(null);

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      final index = _events.indexWhere((event) => event.id == updatedEvent.id);
      if (index != -1) {
        _events[index] = updatedEvent.copyWith(updatedAt: DateTime.now());
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update event: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      _setLoading(true);
      _setError(null);

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      _events.removeWhere((event) => event.id == eventId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete event: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> assignStationToEvent(String eventId, String stationId) async {
    try {
      _setLoading(true);
      _setError(null);

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Update station
      final stationIndex = _gcsStations.indexWhere((s) => s.id == stationId);
      if (stationIndex != -1) {
        final station = _gcsStations[stationIndex];
        final updatedStation = station.copyWith(
          assignedEventIds: [...station.assignedEventIds, eventId],
          updatedAt: DateTime.now(),
        );
        _gcsStations[stationIndex] = updatedStation;
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to assign station: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> unassignStationFromEvent(
    String eventId,
    String stationId,
  ) async {
    try {
      _setLoading(true);
      _setError(null);

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Update station
      final stationIndex = _gcsStations.indexWhere((s) => s.id == stationId);
      if (stationIndex != -1) {
        final station = _gcsStations[stationIndex];
        final updatedStation = station.copyWith(
          assignedEventIds: station.assignedEventIds
              .where((id) => id != eventId)
              .toList(),
          updatedAt: DateTime.now(),
        );
        _gcsStations[stationIndex] = updatedStation;
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to unassign station: $e');
    } finally {
      _setLoading(false);
    }
  }

  // GCS Station Management Methods
  Future<void> updateStationStatus(
    String stationId,
    StationStatus status,
  ) async {
    try {
      _setLoading(true);
      _setError(null);

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      final index = _gcsStations.indexWhere(
        (station) => station.id == stationId,
      );
      if (index != -1) {
        final updatedStation = _gcsStations[index].copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );
        _gcsStations[index] = updatedStation;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update station status: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Search and Filter Methods
  List<GroupEvent> searchEvents(String query) {
    if (query.isEmpty) return _events;

    final lowercaseQuery = query.toLowerCase();
    return _events.where((event) {
      return event.title.toLowerCase().contains(lowercaseQuery) ||
          event.description.toLowerCase().contains(lowercaseQuery) ||
          event.location.address?.toLowerCase().contains(lowercaseQuery) ==
              true ||
          event.typeDisplay.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  List<GCSStation> searchStations(String query) {
    if (query.isEmpty) return _gcsStations;

    final lowercaseQuery = query.toLowerCase();
    return _gcsStations.where((station) {
      return station.name.toLowerCase().contains(lowercaseQuery) ||
          station.code.toLowerCase().contains(lowercaseQuery) ||
          station.location.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  List<GroupEvent> filterEventsByStatus(EventStatus status) {
    return _events.where((event) => event.status == status).toList();
  }

  List<GroupEvent> filterEventsByType(EventType type) {
    return _events.where((event) => event.type == type).toList();
  }

  List<GroupEvent> filterEventsBySeverity(EventSeverity severity) {
    return _events.where((event) => event.severity == severity).toList();
  }

  List<GCSStation> filterStationsByStatus(StationStatus status) {
    return _gcsStations.where((station) => station.status == status).toList();
  }

  GroupEvent? getEventById(String eventId) {
    try {
      return _events.firstWhere((event) => event.id == eventId);
    } catch (e) {
      return null;
    }
  }

  GCSStation? getStationById(String stationId) {
    try {
      return _gcsStations.firstWhere((station) => station.id == stationId);
    } catch (e) {
      return null;
    }
  }

  List<GCSStation> getStationsForEvent(String eventId) {
    return _gcsStations
        .where((station) => station.assignedEventIds.contains(eventId))
        .toList();
  }

  // Statistics Methods
  Map<String, int> getEventStatsByType() {
    final stats = <String, int>{};
    for (final event in _events) {
      final type = event.typeDisplay;
      stats[type] = (stats[type] ?? 0) + 1;
    }
    return stats;
  }

  Map<String, int> getEventStatsByStatus() {
    final stats = <String, int>{};
    for (final event in _events) {
      final status = event.statusDisplay;
      stats[status] = (stats[status] ?? 0) + 1;
    }
    return stats;
  }

  Map<String, int> getStationStatsByStatus() {
    final stats = <String, int>{};
    for (final station in _gcsStations) {
      final status = station.statusDisplay;
      stats[status] = (stats[status] ?? 0) + 1;
    }
    return stats;
  }

  int get totalActiveEvents => activeEvents.length;
  int get totalCriticalEvents => criticalEvents.length;
  int get totalOperationalStations => operationalStations.length;
  int get totalAvailableStations => availableStations.length;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void refreshData() {
    initializeMockData();
  }
}
