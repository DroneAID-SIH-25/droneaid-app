import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/drone.dart';
import '../models/mission.dart';
import '../models/gcs_station.dart';

import '../services/map_service.dart';

/// GCS Map widget showing all active missions with route optimization
class GCSMap extends StatefulWidget {
  final List<Mission> activeMissions;
  final List<Drone> droneFleet;
  final List<GCSStation> gcsStations;
  final Function(String)? onMissionSelected;
  final Function(String)? onDroneSelected;

  const GCSMap({
    Key? key,
    required this.activeMissions,
    required this.droneFleet,
    required this.gcsStations,
    this.onMissionSelected,
    this.onDroneSelected,
  }) : super(key: key);

  @override
  State<GCSMap> createState() => _GCSMapState();
}

class _GCSMapState extends State<GCSMap> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final MapService _mapService = MapService();

  late AnimationController _missionPulseController;
  late AnimationController _droneRotationController;

  String? _selectedMissionId;
  String? _selectedDroneId;
  bool _showRouteOptimization = true;
  bool _showCoverageAreas = false;
  bool _showDroneStatus = true;

  List<MissionRoute> _optimizedRoutes = [];
  Map<String, List<LatLng>> _coverageAreas = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateOptimizedRoutes();
    _calculateCoverageAreas();
    _centerMapOnMissions();
  }

  @override
  void didUpdateWidget(GCSMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeMissions != widget.activeMissions ||
        oldWidget.gcsStations != widget.gcsStations) {
      _generateOptimizedRoutes();
    }
    if (oldWidget.droneFleet != widget.droneFleet ||
        oldWidget.gcsStations != widget.gcsStations) {
      _calculateCoverageAreas();
    }
  }

  @override
  void dispose() {
    _missionPulseController.dispose();
    _droneRotationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _missionPulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _droneRotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  void _generateOptimizedRoutes() {
    if (widget.gcsStations.isEmpty) return;

    final Map<String, LatLng> gcsLocations = {};
    for (final station in widget.gcsStations) {
      gcsLocations[station.operatorIds.isNotEmpty
          ? station.operatorIds.first
          : station.id] = LatLng(
        station.coordinates.latitude,
        station.coordinates.longitude,
      );
    }

    _optimizedRoutes = _mapService.generateMissionRoutes(
      widget.activeMissions,
      gcsLocations,
    );

    setState(() {});
  }

  void _calculateCoverageAreas() {
    _coverageAreas.clear();

    for (final station in widget.gcsStations) {
      final center = LatLng(
        station.coordinates.latitude,
        station.coordinates.longitude,
      );

      // Calculate service area (assuming 50km radius for GCS coverage)
      final coverageCircle = _mapService.createGeofenceCircle(
        center,
        50000.0, // 50km in meters
        points: 32,
      );

      _coverageAreas[station.id] = coverageCircle;
    }

    setState(() {});
  }

  void _centerMapOnMissions() {
    if (widget.activeMissions.isEmpty) return;

    // Calculate center of all missions
    double latSum = 0;
    double lngSum = 0;
    int count = 0;

    for (final mission in widget.activeMissions) {
      latSum += mission.targetLocation.latitude;
      lngSum += mission.targetLocation.longitude;
      latSum += mission.startLocation.latitude;
      lngSum += mission.startLocation.longitude;
      count += 2;
    }

    if (count > 0) {
      final center = LatLng(latSum / count, lngSum / count);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(center, 10.0);
      });
    }
  }

  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];

    // GCS Station markers
    for (final station in widget.gcsStations) {
      markers.add(
        Marker(
          point: LatLng(
            station.coordinates.latitude,
            station.coordinates.longitude,
          ),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showStationDetails(station),
            child: Container(
              decoration: BoxDecoration(
                color: station.status == StationStatus.operational
                    ? Colors.green
                    : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.home_work, color: Colors.white, size: 20),
            ),
          ),
        ),
      );
    }

    // Mission target markers
    for (final mission in widget.activeMissions) {
      final isSelected = _selectedMissionId == mission.id;
      final priority = mission.priority;

      markers.add(
        Marker(
          point: LatLng(
            mission.targetLocation.latitude,
            mission.targetLocation.longitude,
          ),
          width: isSelected ? 50 : 35,
          height: isSelected ? 50 : 35,
          child: GestureDetector(
            onTap: () => _selectMission(mission.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: _getMissionColor(priority),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.yellow : Colors.white,
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getMissionColor(priority).withOpacity(0.5),
                    blurRadius: isSelected ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _missionPulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: priority == MissionPriority.critical
                        ? 0.8 + 0.4 * _missionPulseController.value
                        : 1.0,
                    child: Icon(
                      _getMissionIcon(mission.type),
                      color: Colors.white,
                      size: isSelected ? 25 : 18,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    // Drone markers
    if (_showDroneStatus) {
      for (final drone in widget.droneFleet) {
        final isSelected = _selectedDroneId == drone.id;

        markers.add(
          Marker(
            point: LatLng(drone.location.latitude, drone.location.longitude),
            width: isSelected ? 45 : 30,
            height: isSelected ? 45 : 30,
            child: GestureDetector(
              onTap: () => _selectDrone(drone.id),
              child: AnimatedBuilder(
                animation: _droneRotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: drone.status == DroneStatus.deployed
                        ? _droneRotationController.value * 2 * 3.14159
                        : 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getDroneStatusColor(drone.status),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.yellow : Colors.white,
                          width: isSelected ? 3 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: isSelected ? 6 : 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.flight,
                        color: Colors.white,
                        size: isSelected ? 22 : 15,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  List<Polyline> _buildPolylines() {
    final List<Polyline> polylines = [];

    if (_showRouteOptimization) {
      for (final route in _optimizedRoutes) {
        polylines.add(
          Polyline(
            points: route.waypoints,
            strokeWidth: route.priority == MissionPriority.critical ? 4.0 : 2.0,
            color: _getRouteColor(route.status, route.priority),
          ),
        );
      }
    }

    return polylines;
  }

  List<Polygon> _buildPolygons() {
    final List<Polygon> polygons = [];

    if (_showCoverageAreas) {
      for (final entry in _coverageAreas.entries) {
        final station = widget.gcsStations.firstWhere(
          (s) => s.id == entry.key,
          orElse: () => widget.gcsStations.first,
        );

        polygons.add(
          Polygon(
            points: entry.value,
            color: station.status == StationStatus.operational
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderColor: station.status == StationStatus.operational
                ? Colors.green.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
            borderStrokeWidth: 1,
          ),
        );
      }
    }

    return polygons;
  }

  Color _getMissionColor(MissionPriority priority) {
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

  Color _getRouteColor(MissionStatus status, MissionPriority priority) {
    if (priority == MissionPriority.critical) {
      return Colors.red;
    }

    switch (status) {
      case MissionStatus.inProgress:
        return Colors.blue;
      case MissionStatus.assigned:
        return Colors.orange;
      case MissionStatus.completed:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _selectMission(String missionId) {
    setState(() {
      _selectedMissionId = _selectedMissionId == missionId ? null : missionId;
    });
    widget.onMissionSelected?.call(missionId);
  }

  void _selectDrone(String droneId) {
    setState(() {
      _selectedDroneId = _selectedDroneId == droneId ? null : droneId;
    });
    widget.onDroneSelected?.call(droneId);
  }

  void _showStationDetails(GCSStation station) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              station.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Status: ${station.status.displayName}'),
            Text('Operators: ${station.operatorIds.length}'),
            Text('Active Events: ${station.assignedEvents}'),
            Text(
              'Capacity: ${station.currentOperators}/${station.maxCapacity}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          FloatingActionButton.small(
            heroTag: "center_map",
            onPressed: _centerMapOnMissions,
            child: const Icon(Icons.center_focus_strong),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: "toggle_routes",
            onPressed: () {
              setState(() {
                _showRouteOptimization = !_showRouteOptimization;
              });
            },
            backgroundColor: _showRouteOptimization ? Colors.blue : Colors.grey,
            child: const Icon(Icons.route),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: "toggle_coverage",
            onPressed: () {
              setState(() {
                _showCoverageAreas = !_showCoverageAreas;
              });
            },
            backgroundColor: _showCoverageAreas ? Colors.green : Colors.grey,
            child: const Icon(Icons.radar),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: "toggle_drones",
            onPressed: () {
              setState(() {
                _showDroneStatus = !_showDroneStatus;
              });
            },
            backgroundColor: _showDroneStatus ? Colors.orange : Colors.grey,
            child: const Icon(Icons.flight),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionStats() {
    final totalMissions = widget.activeMissions.length;
    final inProgressMissions = widget.activeMissions
        .where((m) => m.status == MissionStatus.inProgress)
        .length;
    final criticalMissions = widget.activeMissions
        .where((m) => m.priority == MissionPriority.critical)
        .length;
    final activeDrones = widget.droneFleet
        .where((d) => d.status == DroneStatus.deployed)
        .length;

    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mission Overview',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildStatRow(Icons.assignment, 'Total', totalMissions.toString()),
            _buildStatRow(
              Icons.play_arrow,
              'Active',
              inProgressMissions.toString(),
            ),
            _buildStatRow(
              Icons.priority_high,
              'Critical',
              criticalMissions.toString(),
            ),
            _buildStatRow(Icons.flight, 'Deployed', activeDrones.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: '),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(0, 0),
            initialZoom: 8.0,
            minZoom: 3.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.drone_aid',
            ),
            PolygonLayer(polygons: _buildPolygons()),
            PolylineLayer(polylines: _buildPolylines()),
            MarkerLayer(markers: _buildMarkers()),
          ],
        ),
        _buildMissionStats(),
        _buildMapControls(),
      ],
    );
  }
}
