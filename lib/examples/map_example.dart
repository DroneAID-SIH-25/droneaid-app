import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../providers/map_provider.dart';
import '../services/map_service.dart';
import '../models/drone.dart';
import '../models/mission.dart';
import '../models/gcs_station.dart';
import '../models/user.dart';

import '../widgets/help_seeker_map.dart';
import '../widgets/gcs_map.dart';

/// Comprehensive example demonstrating map integration features
/// for both Help Seekers and GCS operators
class MapIntegrationExample extends StatefulWidget {
  const MapIntegrationExample({Key? key}) : super(key: key);

  @override
  State<MapIntegrationExample> createState() => _MapIntegrationExampleState();
}

class _MapIntegrationExampleState extends State<MapIntegrationExample>
    with TickerProviderStateMixin {
  final MapService _mapService = MapService();

  int _selectedTab = 0;

  // Example data
  late LocationData _userLocation;
  late List<Drone> _droneFleet;
  late List<Mission> _activeMissions;
  late List<GCSStation> _gcsStations;

  @override
  void initState() {
    super.initState();
    _initializeExampleData();
    _initializeMapProvider();
  }

  void _initializeExampleData() {
    // Example user location (New York City)
    _userLocation = LocationData(
      latitude: 40.7128,
      longitude: -74.0060,
      timestamp: DateTime.now(),
      accuracy: 25.0,
    );

    // Example drone fleet
    _droneFleet = [
      Drone(
        id: 'drone_001',
        name: 'Rescue Hawk 1',
        model: 'RH-450',
        status: DroneStatus.active,
        batteryLevel: 85,
        location: LocationData(
          latitude: 40.7580,
          longitude: -73.9855,
          timestamp: DateTime.now(),
        ),
        capabilities: ['search', 'rescue', 'medicalDelivery'],
        maxFlightTime: 45,
        maxRange: 15.0,
        payloadCapacity: 5.0,
      ),
      Drone(
        id: 'drone_002',
        name: 'Med Supply 2',
        model: 'MS-350',
        status: DroneStatus.deployed,
        batteryLevel: 62,
        location: LocationData(
          latitude: 40.6892,
          longitude: -74.0445,
          timestamp: DateTime.now(),
        ),
        capabilities: ['medicalDelivery', 'cargoTransport'],
        maxFlightTime: 35,
        maxRange: 12.0,
        payloadCapacity: 8.0,
        currentMissionId: 'mission_001',
      ),
      Drone(
        id: 'drone_003',
        name: 'Search Eagle 3',
        model: 'SE-600',
        status: DroneStatus.active,
        batteryLevel: 91,
        location: LocationData(
          latitude: 40.7282,
          longitude: -74.0776,
          timestamp: DateTime.now(),
        ),
        capabilities: ['search', 'surveillance', 'thermalImaging'],
        maxFlightTime: 60,
        maxRange: 20.0,
        payloadCapacity: 3.0,
      ),
    ];

    // Example GCS stations
    _gcsStations = [
      GCSStation(
        id: 'gcs_001',
        name: 'Manhattan Control',
        code: 'MAN001',
        location: 'Manhattan, NY',
        coordinates: LocationData(
          latitude: 40.7614,
          longitude: -73.9776,
          timestamp: DateTime.now(),
        ),
        operatorIds: ['op_001'],
        status: StationStatus.operational,
        organizationId: 'org_001',
        contactEmail: 'manhattan@droneaid.com',
        contactPhone: '+1-555-0001',
      ),
      GCSStation(
        id: 'gcs_002',
        name: 'Brooklyn Base',
        code: 'BRK001',
        location: 'Brooklyn, NY',
        coordinates: LocationData(
          latitude: 40.6782,
          longitude: -73.9442,
          timestamp: DateTime.now(),
        ),
        operatorIds: ['op_002'],
        status: StationStatus.operational,
        organizationId: 'org_001',
        contactEmail: 'brooklyn@droneaid.com',
        contactPhone: '+1-555-0002',
      ),
    ];

    // Example active missions
    _activeMissions = [
      Mission(
        id: 'mission_001',
        assignedDroneId: 'drone_002',
        assignedOperatorId: 'op_001',
        title: 'Medical Supply Delivery',
        description: 'Emergency insulin delivery to diabetes patient',
        type: MissionType.delivery,
        status: MissionStatus.inProgress,
        priority: MissionPriority.critical,
        startLocation: _gcsStations[0].coordinates,
        targetLocation: LocationData(
          latitude: 40.7089,
          longitude: -74.0184,
          timestamp: DateTime.now(),
        ),
        progress: 0.45,
      ),
      Mission(
        id: 'mission_002',
        assignedDroneId: 'drone_003',
        assignedOperatorId: 'op_002',
        title: 'Search and Rescue',
        description: 'Missing person in Central Park',
        type: MissionType.search,
        status: MissionStatus.assigned,
        priority: MissionPriority.high,
        startLocation: _gcsStations[1].coordinates,
        targetLocation: LocationData(
          latitude: 40.7829,
          longitude: -73.9654,
          timestamp: DateTime.now(),
        ),
        progress: 0.0,
      ),
    ];
  }

  void _initializeMapProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mapProvider = context.read<MapProvider>();
      mapProvider.initialize();

      // Add missions to map
      for (int i = 0; i < _activeMissions.length; i++) {
        final mission = _activeMissions[i];
        final drone = _droneFleet.firstWhere(
          (d) => d.id == mission.assignedDroneId,
        );
        mapProvider.addMission(mission, drone);
      }
    });
  }

  void _onMissionSelected(String missionId) {
    final mission = _activeMissions.firstWhere((m) => m.id == missionId);
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildMissionDetails(mission),
    );
  }

  void _onDroneSelected(String droneId) {
    final drone = _droneFleet.firstWhere((d) => d.id == droneId);
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildDroneDetails(drone),
    );
  }

  Widget _buildMissionDetails(Mission mission) {
    final assignedDrone = _droneFleet.firstWhere(
      (d) => d.id == mission.assignedDroneId,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getMissionIcon(mission.type),
                color: _getPriorityColor(mission.priority),
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mission.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            mission.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Status', mission.statusDisplay),
          _buildInfoRow('Priority', mission.priorityDisplay),
          _buildInfoRow('Assigned Drone', assignedDrone.name),
          _buildInfoRow('Progress', '${(mission.progress * 100).toInt()}%'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _trackMission(mission.id),
                icon: const Icon(Icons.my_location),
                label: const Text('Track'),
              ),
              ElevatedButton.icon(
                onPressed: () => _showRouteDetails(mission.id),
                icon: const Icon(Icons.route),
                label: const Text('Route'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDroneDetails(Drone drone) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flight,
                color: _getDroneStatusColor(drone.status),
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  drone.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Model', drone.model),
          _buildInfoRow('Status', drone.statusDisplay),
          _buildInfoRow('Battery', drone.batteryDisplay),
          _buildInfoRow('Range', drone.rangeDisplay),
          _buildInfoRow('Flight Time', drone.flightTimeDisplay),
          const SizedBox(height: 8),
          Text('Capabilities:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: drone.capabilities
                .map(
                  (cap) => Chip(
                    label: Text(cap),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          if (drone.currentMissionId != null)
            ElevatedButton.icon(
              onPressed: () => _trackDrone(drone.id),
              icon: const Icon(Icons.track_changes),
              label: const Text('Track Mission'),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  IconData _getMissionIcon(MissionType type) {
    switch (type) {
      case MissionType.search:
        return Icons.search;
      case MissionType.delivery:
        return Icons.local_shipping;
      case MissionType.surveillance:
        return Icons.visibility;
      case MissionType.patrol:
        return Icons.security;
      case MissionType.mapping:
        return Icons.map;
      default:
        return Icons.assignment;
    }
  }

  Color _getPriorityColor(MissionPriority priority) {
    switch (priority) {
      case MissionPriority.critical:
        return Colors.red;
      case MissionPriority.high:
        return Colors.orange;
      case MissionPriority.medium:
        return Colors.blue;
      case MissionPriority.low:
        return Colors.green;
    }
  }

  Color _getDroneStatusColor(DroneStatus status) {
    switch (status) {
      case DroneStatus.active:
        return Colors.green;
      case DroneStatus.deployed:
        return Colors.blue;
      case DroneStatus.maintenance:
        return Colors.orange;
      case DroneStatus.charging:
        return Colors.yellow.shade700;
      case DroneStatus.emergency:
        return Colors.red;
      case DroneStatus.offline:
        return Colors.grey;
    }
  }

  void _trackMission(String missionId) {
    final mapProvider = context.read<MapProvider>();
    mapProvider.centerOnMission(missionId);
    Navigator.pop(context);
  }

  void _trackDrone(String droneId) {
    // Implementation for tracking specific drone
    Navigator.pop(context);
  }

  void _showRouteDetails(String missionId) {
    final mission = _activeMissions.firstWhere((m) => m.id == missionId);

    final startLocation = LatLng(
      mission.startLocation.latitude,
      mission.startLocation.longitude,
    );
    final targetLocation = LatLng(
      mission.targetLocation.latitude,
      mission.targetLocation.longitude,
    );

    final distance = _mapService.calculateDistance(
      startLocation,
      targetLocation,
    );
    final eta = _mapService.calculateETA(distance);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Route Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              'Distance',
              '${(distance / 1000).toStringAsFixed(1)} km',
            ),
            _buildInfoRow('ETA', eta),
            _buildInfoRow('Drone Speed', '15 m/s (avg)'),
            _buildInfoRow('Route Type', 'Optimized Direct'),
            const SizedBox(height: 8),
            Text(
              'Waypoints: ${_mapService.getRoutePoints(startLocation, targetLocation).length}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );

    Navigator.pop(context);
  }

  Widget _buildRouteOptimizationDemo() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Optimization Demo',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const Text(
            'This demo shows K-Nearest Neighbor (KNN) route optimization:',
          ),
          const SizedBox(height: 8),
          const Text('1. Critical missions get priority routing'),
          const Text('2. Regular missions use nearest-neighbor optimization'),
          const Text(
            '3. Straight-line distances are calculated using Haversine formula',
          ),
          const Text(
            '4. Real-time ETA updates based on drone speed and position',
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _demonstrateRouteOptimization,
            child: const Text('Run Optimization Demo'),
          ),
        ],
      ),
    );
  }

  void _demonstrateRouteOptimization() {
    final gcsLocation = LatLng(
      _gcsStations[0].coordinates.latitude,
      _gcsStations[0].coordinates.longitude,
    );

    final targets = _activeMissions
        .map(
          (m) => RouteTarget(
            location: LatLng(
              m.targetLocation.latitude,
              m.targetLocation.longitude,
            ),
            priority: m.priority,
            id: m.id,
          ),
        )
        .toList();

    final optimizedRoute = _mapService.optimizeRouteWithPriority(
      gcsLocation,
      targets,
    );
    final totalDistance = _mapService.calculateRouteDistance(optimizedRoute);
    final totalETA = _mapService.calculateETA(totalDistance);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Route Optimization Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Optimized ${targets.length} missions'),
            _buildInfoRow(
              'Total Distance',
              '${(totalDistance / 1000).toStringAsFixed(1)} km',
            ),
            _buildInfoRow('Total ETA', totalETA),
            _buildInfoRow('Waypoints', '${optimizedRoute.length}'),
            const SizedBox(height: 8),
            const Text('Route Order:'),
            ...optimizedRoute.skip(1).map((point) {
              final mission = _activeMissions.firstWhere(
                (m) =>
                    m.targetLocation.latitude == point.latitude &&
                    m.targetLocation.longitude == point.longitude,
              );
              return Text(
                '• ${mission.title} (${mission.priority.displayName})',
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Integration Example'),
        bottom: TabBar(
          controller: TabController(length: 3, vsync: this),
          onTap: (index) => setState(() => _selectedTab = index),
          tabs: const [
            Tab(text: 'Help Seeker', icon: Icon(Icons.person)),
            Tab(text: 'GCS View', icon: Icon(Icons.dashboard)),
            Tab(text: 'Demo', icon: Icon(Icons.play_arrow)),
          ],
        ),
      ),
      body: Consumer<MapProvider>(
        builder: (context, mapProvider, _) {
          return IndexedStack(
            index: _selectedTab,
            children: [
              // Help Seeker Map
              HelpSeekerMap(
                userLocation: _userLocation,
                nearbyDrones: _droneFleet
                    .where(
                      (d) =>
                          mapProvider.currentUserLocation != null &&
                          _mapService.isWithinGeofence(
                            mapProvider.currentUserLocation!,
                            LatLng(d.location.latitude, d.location.longitude),
                            1000.0,
                          ),
                    )
                    .toList(),
                assignedDrone: _droneFleet.firstWhere(
                  (d) => d.currentMissionId != null,
                  orElse: () => _droneFleet.first,
                ),
                onLocationUpdate: () {
                  mapProvider.updateDronesInGeofence(_droneFleet);
                },
              ),

              // GCS Map
              GCSMap(
                activeMissions: _activeMissions,
                droneFleet: _droneFleet,
                gcsStations: _gcsStations,
                onMissionSelected: _onMissionSelected,
                onDroneSelected: _onDroneSelected,
              ),

              // Demo Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRouteOptimizationDemo(),
                    const SizedBox(height: 24),
                    Text(
                      'Geofencing Demo',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text('Geofence Features:'),
                    const Text('• 1km radius monitoring zone'),
                    const Text('• Real-time drone detection'),
                    const Text('• Visual boundary indicators'),
                    const Text('• Automatic alerts for entering/leaving'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        final mapProvider = context.read<MapProvider>();
                        mapProvider.updateGeofenceSettings(
                          radius: 1500.0,
                          enabled: true,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Geofence updated to 1.5km'),
                          ),
                        );
                      },
                      child: const Text('Update Geofence to 1.5km'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _selectedTab < 2
          ? FloatingActionButton(
              onPressed: () {
                final mapProvider = context.read<MapProvider>();
                mapProvider.centerOnUser();
              },
              child: const Icon(Icons.my_location),
            )
          : null,
    );
  }
}

/// Extension methods for easier integration
extension MapIntegrationHelpers on MapProvider {
  /// Add multiple missions at once
  void addMissions(List<Mission> missions, List<Drone> drones) {
    for (final mission in missions) {
      final assignedDrone = drones.firstWhere(
        (d) => d.id == mission.assignedDroneId,
        orElse: () => drones.first,
      );
      addMission(mission, assignedDrone);
    }
  }

  /// Get all missions within a geofence
  List<String> getMissionsInGeofence(LatLng center, double radius) {
    final missionsInRange = <String>[];
    for (final entry in missionData.entries) {
      final distance = MapService().calculateDistance(
        center,
        entry.value.targetMarker.position,
      );
      if (distance <= radius) {
        missionsInRange.add(entry.key);
      }
    }
    return missionsInRange;
  }
}
