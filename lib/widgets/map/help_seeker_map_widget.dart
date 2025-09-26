import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/drone.dart' as DroneModel;
import '../../models/user.dart';
import '../../providers/drone_tracking_provider.dart' as DroneTracking;
import '../../providers/map_provider.dart';
import '../../services/map_service.dart';
import '../common/loading_indicator.dart';

/// Map widget specifically designed for help seekers
class HelpSeekerMapWidget extends StatefulWidget {
  final double height;
  final bool showControls;
  final bool showGeofenceToggle;
  final bool showDroneDetails;
  final Function(DroneModel.Drone)? onDroneSelected;
  final VoidCallback? onEmergencyPressed;

  const HelpSeekerMapWidget({
    Key? key,
    this.height = 400,
    this.showControls = true,
    this.showGeofenceToggle = true,
    this.showDroneDetails = true,
    this.onDroneSelected,
    this.onEmergencyPressed,
  }) : super(key: key);

  @override
  State<HelpSeekerMapWidget> createState() => _HelpSeekerMapWidgetState();
}

class _HelpSeekerMapWidgetState extends State<HelpSeekerMapWidget>
    with TickerProviderStateMixin {
  late MapController _mapController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
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
            child: const LoadingIndicator(message: 'Loading map...'),
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
              if (mapProvider.userLocation != null)
                _buildStatsOverlay(mapProvider),
              if (widget.showDroneDetails && mapProvider.selectedDrone != null)
                _buildDroneDetailsPanel(mapProvider),
              if (widget.onEmergencyPressed != null) _buildEmergencyFAB(),
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
        onMapEvent: (event) {
          if (event is MapEventMoveEnd) {
            mapProvider.updateMapCenter(event.camera.center);
            mapProvider.updateZoomLevel(event.camera.zoom);
          }
        },
        onTap: (_, __) => mapProvider.clearSelections(),
      ),
      children: [
        // Base map layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.droneaid.app',
        ),

        // Geofence layer
        if (mapProvider.showGeofence && mapProvider.userLocation != null)
          _buildGeofenceLayer(mapProvider),

        // Drone coverage areas
        if (mapProvider.showCoverage) _buildCoverageLayer(mapProvider),

        // Route layer
        if (mapProvider.showRoutes && mapProvider.routePoints.isNotEmpty)
          _buildRouteLayer(mapProvider),

        // User location marker
        if (mapProvider.userLocation != null)
          _buildUserLocationLayer(mapProvider),

        // Drone markers
        if (mapProvider.showDrones) _buildDroneMarkersLayer(mapProvider),

        // Emergency request markers
        _buildEmergencyMarkersLayer(mapProvider),
      ],
    );
  }

  Widget _buildGeofenceLayer(MapProvider mapProvider) {
    final geofencePoints = mapProvider.getGeofencePolygon();
    if (geofencePoints.isEmpty) return const SizedBox.shrink();

    return PolygonLayer(
      polygons: [
        Polygon(
          points: geofencePoints,
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderColor: Theme.of(context).primaryColor.withOpacity(0.5),
          borderStrokeWidth: 2.0,
        ),
      ],
    );
  }

  Widget _buildCoverageLayer(MapProvider mapProvider) {
    final coverageAreas = mapProvider.getDroneCoverageAreas();

    return PolygonLayer(
      polygons: coverageAreas.map((area) {
        final points = MapService().calculateGeofencePolygon(
          area.center,
          area.radius,
        );

        return Polygon(
          points: points,
          color: Colors.green.withOpacity(0.1),
          borderColor: Colors.green.withOpacity(0.3),
          borderStrokeWidth: 1.0,
        );
      }).toList(),
    );
  }

  Widget _buildRouteLayer(MapProvider mapProvider) {
    return PolylineLayer(
      polylines: [
        Polyline(
          points: mapProvider.routePoints,
          color: Theme.of(context).primaryColor,
          strokeWidth: 3.0,
        ),
      ],
    );
  }

  Widget _buildUserLocationLayer(MapProvider mapProvider) {
    final userLocation = mapProvider.userLocation!;
    final userLatLng = LatLng(userLocation.latitude, userLocation.longitude);

    return MarkerLayer(
      markers: [
        Marker(
          point: userLatLng,
          width: 60,
          height: 60,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_pin_circle,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDroneMarkersLayer(MapProvider mapProvider) {
    final dronesInGeofence = mapProvider.dronesInGeofence;

    return MarkerLayer(
      markers: dronesInGeofence.map((drone) {
        final droneLatLng = LatLng(
          drone.position.latitude,
          drone.position.longitude,
        );
        final isSelected = mapProvider.selectedDrone == drone.id;

        return Marker(
          point: droneLatLng,
          width: isSelected ? 80 : 60,
          height: isSelected ? 80 : 60,
          child: GestureDetector(
            onTap: () {
              mapProvider.selectDroneById(drone.id);
              // Convert DroneInfo to Drone for callback
              final droneObj = DroneModel.Drone(
                id: drone.id,
                name: drone.name,
                model: 'Model',
                location: LocationData(
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
                color: _getDroneStatusColor(_convertDroneStatus(drone.status)),
                border: Border.all(
                  color: isSelected ? Colors.orange : Colors.white,
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getDroneStatusColor(
                      _convertDroneStatus(drone.status),
                    ).withOpacity(0.3),
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
                    size: isSelected ? 32 : 24,
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
                  ).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.emergency, color: Colors.white, size: 24),
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

          // Location control
          Card(
            child: IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: () {
                mapProvider.centerOnUserLocation();
                if (mapProvider.userLocation != null) {
                  _mapController.move(
                    LatLng(
                      mapProvider.userLocation!.latitude,
                      mapProvider.userLocation!.longitude,
                    ),
                    15.0,
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 8),

          // Geofence toggle
          if (widget.showGeofenceToggle)
            Card(
              child: IconButton(
                icon: Icon(
                  mapProvider.showGeofence
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: mapProvider.showGeofence
                      ? Theme.of(context).primaryColor
                      : null,
                ),
                onPressed: mapProvider.toggleGeofence,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsOverlay(MapProvider mapProvider) {
    final dronesInRange = mapProvider.dronesInGeofence;
    final availableDrones = dronesInRange
        .where((d) => d.status == DroneTracking.DroneStatus.active)
        .length;

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
                'Drones in Range',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.flight,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text('$availableDrones available'),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.radar, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${dronesInRange.length} total'),
                ],
              ),
              if (mapProvider.geofenceRadius != 1000)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.radio_button_checked,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(mapProvider.geofenceRadius / 1000).toStringAsFixed(1)}km radius',
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

    final drone = mapProvider.dronesInGeofence.firstWhere(
      (d) => d.id == selectedDroneId,
      orElse: () => mapProvider.dronesInGeofence.first,
    );
    final distance = mapProvider.getDistanceToUser(drone.position);
    final eta = mapProvider.getETAToUser(drone.position, drone.speed);

    return Positioned(
      bottom: 10,
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
                          'Type: ${drone.type.toString().split('.').last}',
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
                    child: _buildDetailItem(
                      'Status',
                      drone.status.toString().split('.').last,
                      Icons.info_outline,
                      _getDroneStatusColor(_convertDroneStatus(drone.status)),
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Battery',
                      '${drone.batteryLevel.toInt()}%',
                      Icons.battery_full,
                      _getBatteryColor(drone.batteryLevel.toInt()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Distance',
                      '${distance.toStringAsFixed(1)}km',
                      Icons.straighten,
                      Colors.grey[700]!,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'ETA',
                      eta,
                      Icons.access_time,
                      Colors.grey[700]!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Capabilities:',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children:
                    [
                      'Search & Rescue',
                      'Medical Supply',
                      'Emergency Response',
                    ].map((capability) {
                      return Chip(
                        label: Text(
                          capability,
                          style: const TextStyle(fontSize: 10),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(
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

  Widget _buildEmergencyFAB() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: FloatingActionButton(
        onPressed: widget.onEmergencyPressed,
        backgroundColor: Colors.red,
        heroTag: "emergency_map_fab",
        child: const Icon(Icons.emergency, color: Colors.white),
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
          Text('Map Error', style: Theme.of(context).textTheme.titleMedium),
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

  Color _getDroneStatusColor(DroneModel.DroneStatus status) {
    switch (status) {
      case DroneModel.DroneStatus.active:
        return Colors.green;
      case DroneModel.DroneStatus.deployed:
        return Colors.blue;
      case DroneModel.DroneStatus.maintenance:
        return Colors.orange;
      case DroneModel.DroneStatus.offline:
        return Colors.grey;
      case DroneModel.DroneStatus.charging:
        return Colors.yellow;
      case DroneModel.DroneStatus.emergency:
        return Colors.red;
    }
  }

  // Convert DroneStatus from tracking provider to models enum
  DroneModel.DroneStatus _convertDroneStatus(dynamic status) {
    if (status.toString().contains('active'))
      return DroneModel.DroneStatus.active;
    if (status.toString().contains('standby'))
      return DroneModel.DroneStatus.active;
    if (status.toString().contains('maintenance'))
      return DroneModel.DroneStatus.maintenance;
    if (status.toString().contains('charging'))
      return DroneModel.DroneStatus.charging;
    if (status.toString().contains('offline'))
      return DroneModel.DroneStatus.offline;
    return DroneModel.DroneStatus.active; // default
  }

  Color _getBatteryColor(int batteryLevel) {
    if (batteryLevel > 60) return Colors.green;
    if (batteryLevel > 20) return Colors.orange;
    return Colors.red;
  }

  Color _getEmergencyColor(String? urgency) {
    switch (urgency?.toLowerCase()) {
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
}
