import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/drone.dart';
import '../../models/mission.dart';
import '../../models/gcs_station.dart';
import '../../models/user.dart';
import '../../providers/map_provider.dart';

import '../../services/map_service.dart';
import '../common/loading_indicator.dart';

/// Map widget specifically designed for GCS operators
class GCSMapWidget extends StatefulWidget {
  final double height;
  final bool showControls;
  final bool showLegend;
  final bool showStats;
  final Function(Mission)? onMissionSelected;
  final Function(Drone)? onDroneSelected;
  final Function(GCSStation)? onStationSelected;
  final VoidCallback? onCreateMissionPressed;

  const GCSMapWidget({
    Key? key,
    this.height = 600,
    this.showControls = true,
    this.showLegend = true,
    this.showStats = true,
    this.onMissionSelected,
    this.onDroneSelected,
    this.onStationSelected,
    this.onCreateMissionPressed,
  }) : super(key: key);

  @override
  State<GCSMapWidget> createState() => _GCSMapWidgetState();
}

class _GCSMapWidgetState extends State<GCSMapWidget>
    with TickerProviderStateMixin {
  late MapController _mapController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, mapProvider, child) {
        if (mapProvider.isLoading) {
          return SizedBox(
            height: widget.height,
            child: const LoadingIndicator(message: 'Loading GCS map...'),
          );
        }

        if (mapProvider.errorMessage != null) {
          return SizedBox(
            height: widget.height,
            child: _buildErrorWidget(mapProvider.errorMessage!),
          );
        }

        return SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              _buildMap(mapProvider),
              if (widget.showControls) _buildMapControls(mapProvider),
              if (widget.showLegend) _buildLegend(mapProvider),
              if (widget.showStats) _buildStatsOverlay(mapProvider),
              _buildFilterBar(mapProvider),
              if (mapProvider.selectedMission != null)
                _buildMissionDetailsPanel(mapProvider),
              if (mapProvider.selectedDrone != null)
                _buildDroneDetailsPanel(mapProvider),
              if (widget.onCreateMissionPressed != null)
                _buildCreateMissionFAB(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMap(MapProvider mapProvider) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: mapProvider.currentCenter,
        initialZoom: mapProvider.currentZoom,
        onTap: (_, __) => mapProvider.clearSelections(),
      ),
      children: [
        // Base map layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.droneaid.app',
        ),

        // Coverage areas layer
        if (mapProvider.showCoverage && mapProvider.coverageAreas.isNotEmpty)
          _buildCoverageLayer(mapProvider),

        // Route optimization layer
        if (mapProvider.showRoutes && mapProvider.routePoints.isNotEmpty)
          _buildRouteLayer(mapProvider),

        // GCS Station markers
        if (mapProvider.showGCSStations) _buildGCSStationsLayer(mapProvider),

        // Mission markers
        if (mapProvider.showMissions) _buildMissionMarkersLayer(mapProvider),

        // Drone markers
        if (mapProvider.showDrones) _buildDroneMarkersLayer(mapProvider),

        // Emergency request markers
        _buildEmergencyMarkersLayer(mapProvider),
      ],
    );
  }

  Widget _buildCoverageLayer(MapProvider mapProvider) {
    return PolygonLayer(
      polygons: mapProvider.gcsStations.map((station) {
        final points = MapService().calculateGeofencePolygon(
          LatLng(station.coordinates.latitude, station.coordinates.longitude),
          5000, // Default coverage radius in meters
        );

        return Polygon(
          points: points,
          color: _getStationStatusColor(station.status.name).withOpacity(0.1),
          borderColor: _getStationStatusColor(
            station.status.name,
          ).withOpacity(0.3),
          borderStrokeWidth: 1.0,
        );
      }).toList(),
    );
  }

  Widget _buildRouteLayer(MapProvider mapProvider) {
    return PolylineLayer(
      polylines: [
        // Route points
        if (mapProvider.routePoints.isNotEmpty)
          Polyline(
            points: mapProvider.routePoints,
            color: Theme.of(context).primaryColor,
            strokeWidth: 4.0,
          ),
      ],
    );
  }

  Widget _buildGCSStationsLayer(MapProvider mapProvider) {
    return MarkerLayer(
      markers: mapProvider.gcsStations.map((station) {
        final stationLatLng = LatLng(
          station.coordinates.latitude,
          station.coordinates.longitude,
        );
        final isSelected = mapProvider.selectedGCSStation == station.id;

        return Marker(
          point: stationLatLng,
          width: isSelected ? 80 : 60,
          height: isSelected ? 80 : 60,
          child: GestureDetector(
            onTap: () {
              mapProvider.selectGCSStation(station);
              widget.onStationSelected?.call(station);
            },
            child: AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: station.status == 'active'
                      ? _rotationAnimation.value * 2 * 3.14159
                      : 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getStationStatusColor(station.status.name),
                      border: Border.all(
                        color: isSelected ? Colors.orange : Colors.white,
                        width: isSelected ? 3 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getStationStatusColor(
                            station.status.name,
                          ).withOpacity(0.4),
                          blurRadius: isSelected ? 20 : 10,
                          spreadRadius: isSelected ? 5 : 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.radio_button_checked,
                          color: Colors.white,
                          size: isSelected ? 32 : 24,
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              station.currentOperators.toString(),
                              style: TextStyle(
                                color: _getStationStatusColor(
                                  station.status.name,
                                ),
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMissionMarkersLayer(MapProvider mapProvider) {
    return MarkerLayer(
      markers: mapProvider.filteredMissions.map((mission) {
        final missionLatLng = LatLng(
          mission.targetLocation.latitude,
          mission.targetLocation.longitude,
        );
        final isSelected = mapProvider.selectedMission?.id == mission.id;

        return Marker(
          point: missionLatLng,
          width: isSelected ? 70 : 50,
          height: isSelected ? 70 : 50,
          child: GestureDetector(
            onTap: () {
              mapProvider.selectMission(mission);
              widget.onMissionSelected?.call(mission);
            },
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: mission.priority == MissionPriority.critical
                      ? _pulseAnimation.value
                      : 1.0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getMissionPriorityColor(mission.priority),
                      border: Border.all(
                        color: isSelected ? Colors.orange : Colors.white,
                        width: isSelected ? 3 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getMissionPriorityColor(
                            mission.priority,
                          ).withOpacity(0.4),
                          blurRadius: isSelected ? 15 : 8,
                          spreadRadius: isSelected ? 3 : 1,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          _getMissionTypeIcon(mission.type),
                          color: Colors.white,
                          size: isSelected ? 28 : 20,
                        ),
                        if (mission.priority == MissionPriority.critical)
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDroneMarkersLayer(MapProvider mapProvider) {
    return MarkerLayer(
      markers: mapProvider.filteredDrones.map((drone) {
        final droneLatLng = LatLng(
          drone.position.latitude,
          drone.position.longitude,
        );
        final isSelected = mapProvider.selectedDrone == drone.id;

        return Marker(
          point: droneLatLng,
          width: isSelected ? 70 : 50,
          height: isSelected ? 70 : 50,
          child: GestureDetector(
            onTap: () {
              mapProvider.selectDroneById(drone.id);
              // Create a Drone object for the callback
              final droneObj = Drone(
                id: drone.id,
                name: drone.name,
                model: '',
                location: Location(
                  latitude: drone.position.latitude,
                  longitude: drone.position.longitude,
                ),
                maxFlightTime: 30,
                maxRange: 10.0,
                payloadCapacity: 5.0,
              );
              widget.onDroneSelected?.call(droneObj);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getDroneStatusColor(drone.status),
                border: Border.all(
                  color: isSelected ? Colors.orange : Colors.white,
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getDroneStatusColor(drone.status).withOpacity(0.3),
                    blurRadius: isSelected ? 15 : 8,
                    spreadRadius: isSelected ? 3 : 1,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.flight,
                    color: Colors.white,
                    size: isSelected ? 28 : 20,
                  ),
                  if (drone.batteryLevel < 20)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                        ),
                        child: const Icon(
                          Icons.battery_alert,
                          color: Colors.white,
                          size: 8,
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${drone.batteryLevel}%',
                        style: TextStyle(
                          color: _getDroneStatusColor(drone.status),
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmergencyMarkersLayer(MapProvider mapProvider) {
    return MarkerLayer(
      markers: mapProvider.emergencyRequests.map((request) {
        final requestLatLng = LatLng(
          request.position.latitude,
          request.position.longitude,
        );

        return Marker(
          point: requestLatLng,
          width: 50,
          height: 50,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getEmergencyColor(
                      request.priority.displayName.toLowerCase(),
                    ),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _getEmergencyColor(
                          request.priority.displayName.toLowerCase(),
                        ).withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emergency,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMapControls(MapProvider mapProvider) {
    return Positioned(
      top: 10,
      right: 10,
      child: Column(
        children: [
          // Zoom controls
          Card(
            child: Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    _mapController.move(
                      mapProvider.currentCenter,
                      mapProvider.currentZoom + 1,
                    );
                  },
                ),
                const Divider(height: 1),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    _mapController.move(
                      mapProvider.currentCenter,
                      mapProvider.currentZoom - 1,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Center on India
          Card(
            child: IconButton(
              icon: const Icon(Icons.public),
              onPressed: () {
                mapProvider.centerOnIndia();
                _mapController.move(const LatLng(20.5937, 78.9629), 5.0);
              },
            ),
          ),
          const SizedBox(height: 8),

          // Layer toggles
          Card(
            child: Column(
              children: [
                IconButton(
                  icon: Icon(
                    mapProvider.showDrones
                        ? Icons.flight
                        : Icons.flight_takeoff,
                    color: mapProvider.showDrones
                        ? Theme.of(context).primaryColor
                        : null,
                  ),
                  onPressed: mapProvider.toggleDrones,
                  tooltip: 'Toggle Drones',
                ),
                IconButton(
                  icon: Icon(
                    mapProvider.showMissions
                        ? Icons.location_on
                        : Icons.location_off,
                    color: mapProvider.showMissions
                        ? Theme.of(context).primaryColor
                        : null,
                  ),
                  onPressed: mapProvider.toggleMissions,
                  tooltip: 'Toggle Missions',
                ),
                IconButton(
                  icon: Icon(
                    mapProvider.showGCSStations
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: mapProvider.showGCSStations
                        ? Theme.of(context).primaryColor
                        : null,
                  ),
                  onPressed: mapProvider.toggleGCSStations,
                  tooltip: 'Toggle GCS Stations',
                ),
                IconButton(
                  icon: Icon(
                    mapProvider.showCoverage
                        ? Icons.radar
                        : Icons.radio_button_off,
                    color: mapProvider.showCoverage
                        ? Theme.of(context).primaryColor
                        : null,
                  ),
                  onPressed: mapProvider.toggleCoverage,
                  tooltip: 'Toggle Coverage Areas',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(MapProvider mapProvider) {
    return Positioned(
      bottom: 10,
      left: 10,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Legend',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildLegendItem(Icons.flight, 'Drones', Colors.green),
              _buildLegendItem(Icons.location_on, 'Missions', Colors.blue),
              _buildLegendItem(
                Icons.radio_button_checked,
                'GCS Stations',
                Colors.orange,
              ),
              _buildLegendItem(Icons.emergency, 'Emergencies', Colors.red),
              if (mapProvider.showCoverage)
                _buildLegendItem(Icons.radar, 'Coverage Area', Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildStatsOverlay(MapProvider mapProvider) {
    final droneStats = mapProvider.getDroneStatistics();
    final missionStats = mapProvider.getMissionStatistics();

    return Positioned(
      top: 10,
      left: 10,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Fleet Overview',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatItem(
                    'Active',
                    droneStats['Active'] ?? 0,
                    Colors.green,
                  ),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    'Deployed',
                    droneStats['Deployed'] ?? 0,
                    Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatItem(
                    'Missions',
                    missionStats['Active'] ?? 0,
                    Colors.orange,
                  ),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    'Stations',
                    mapProvider.gcsStations.length,
                    Colors.purple,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildFilterBar(MapProvider mapProvider) {
    return Positioned(
      top: 60,
      left: 10,
      right: 100,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.filter_list, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search missions, drones...',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: mapProvider.setSearchQuery,
                ),
              ),
              if (mapProvider.searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => mapProvider.setSearchQuery(''),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissionDetailsPanel(MapProvider mapProvider) {
    final mission = mapProvider.selectedMission!;
    final distance = mapProvider.getDistanceToUser(
      LatLng(mission.targetLocation.latitude, mission.targetLocation.longitude),
    );

    return Positioned(
      bottom: 80,
      left: 10,
      right: 10,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          mission.description,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => mapProvider.clearSelections(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMissionDetailItem(
                      'Status',
                      mission.statusDisplay,
                      Icons.info_outline,
                      _getMissionStatusColor(mission.status),
                    ),
                  ),
                  Expanded(
                    child: _buildMissionDetailItem(
                      'Priority',
                      mission.priorityDisplay,
                      Icons.priority_high,
                      _getMissionPriorityColor(mission.priority),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMissionDetailItem(
                      'Type',
                      mission.type.displayName,
                      _getMissionTypeIcon(mission.type),
                      Colors.grey[700]!,
                    ),
                  ),
                  Expanded(
                    child: _buildMissionDetailItem(
                      'Distance',
                      '${distance.toStringAsFixed(1)}km',
                      Icons.location_on,
                      Colors.grey[700]!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDroneDetailsPanel(MapProvider mapProvider) {
    final selectedDroneId = mapProvider.selectedDrone;
    if (selectedDroneId == null) return const SizedBox.shrink();

    final drone = mapProvider.filteredDrones.firstWhere(
      (d) => d.id == selectedDroneId,
    );
    final distance = 0.0;

    return Positioned(
      bottom: 80,
      left: 10,
      right: 10,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          drone.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'ID: ${drone.id.substring(0, 8)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => mapProvider.clearSelections(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDroneDetailItem(
                      'Status',
                      drone.status.toString().split('.').last,
                      Icons.info_outline,
                      _getDroneStatusColor(drone.status),
                    ),
                  ),
                  Expanded(
                    child: _buildDroneDetailItem(
                      'Battery',
                      '${drone.batteryLevel.toInt()}%',
                      Icons.battery_std,
                      _getBatteryColor(drone.batteryLevel.toInt()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDroneDetailItem(
                      'Range',
                      '10.0km',
                      Icons.radar,
                      Colors.grey[700]!,
                    ),
                  ),
                  Expanded(
                    child: _buildDroneDetailItem(
                      'Distance',
                      '${distance.toStringAsFixed(1)}km',
                      Icons.location_on,
                      Colors.grey[700]!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissionDetailItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDroneDetailItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCreateMissionFAB() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: FloatingActionButton(
        onPressed: widget.onCreateMissionPressed,
        backgroundColor: Theme.of(context).primaryColor,
        heroTag: "create_mission_gcs_fab",
        child: const Icon(Icons.add_location, color: Colors.white),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('GCS Map Error', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<MapProvider>().clearError();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Color helper methods
  Color _getDroneStatusColor(dynamic status) {
    final statusString = status.toString().split('.').last;
    switch (statusString) {
      case 'active':
        return Colors.green;
      case 'deployed':
        return Colors.blue;
      case 'standby':
        return Colors.blue;
      case 'maintenance':
        return Colors.orange;
      case 'offline':
        return Colors.grey;
      case 'charging':
        return Colors.yellow;
      case 'emergency':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getBatteryColor(int batteryLevel) {
    if (batteryLevel > 60) return Colors.green;
    if (batteryLevel > 20) return Colors.orange;
    return Colors.red;
  }

  Color _getMissionPriorityColor(MissionPriority priority) {
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

  Color _getMissionStatusColor(MissionStatus status) {
    switch (status) {
      case MissionStatus.assigned:
        return Colors.orange;
      case MissionStatus.inProgress:
        return Colors.blue;
      case MissionStatus.completed:
        return Colors.green;
      case MissionStatus.cancelled:
        return Colors.grey;
      case MissionStatus.failed:
        return Colors.red;
      case MissionStatus.paused:
        return Colors.yellow;
    }
  }

  Color _getStationStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'maintenance':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Color _getEmergencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Icon helper methods
  IconData _getMissionTypeIcon(MissionType type) {
    switch (type) {
      case MissionType.search:
        return Icons.search;
      case MissionType.rescue:
        return Icons.medical_services;
      case MissionType.delivery:
        return Icons.local_shipping;
      case MissionType.surveillance:
        return Icons.videocam;
      case MissionType.reconnaissance:
        return Icons.explore;
      case MissionType.medical:
        return Icons.medical_services;
      case MissionType.firefighting:
        return Icons.local_fire_department;
      case MissionType.emergencyResponse:
        return Icons.emergency;
      case MissionType.evacuation:
        return Icons.exit_to_app;
      case MissionType.assessment:
        return Icons.assessment;
      case MissionType.monitoring:
        return Icons.monitor;
      case MissionType.other:
        return Icons.help_outline;
      case MissionType.searchAndRescue:
        return Icons.search_off;
      case MissionType.mapping:
        return Icons.map;
      case MissionType.inspection:
        return Icons.visibility;
      case MissionType.patrol:
        return Icons.security;
    }
  }
}
