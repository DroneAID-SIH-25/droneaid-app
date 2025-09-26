import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../models/drone.dart';
import '../models/user.dart';
import '../services/map_service.dart';
import '../services/location_service.dart';

/// Map widget for Help Seekers with geofencing and real-time tracking
class HelpSeekerMap extends StatefulWidget {
  final LocationData userLocation;
  final List<Drone> nearbyDrones;
  final Drone? assignedDrone;
  final String? emergencyRequestId;
  final VoidCallback? onLocationUpdate;

  const HelpSeekerMap({
    Key? key,
    required this.userLocation,
    this.nearbyDrones = const [],
    this.assignedDrone,
    this.emergencyRequestId,
    this.onLocationUpdate,
  }) : super(key: key);

  @override
  State<HelpSeekerMap> createState() => _HelpSeekerMapState();
}

class _HelpSeekerMapState extends State<HelpSeekerMap>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final MapService _mapService = MapService();
  final LocationService _locationService = LocationService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  StreamSubscription<LocationData>? _locationSubscription;
  StreamSubscription<List<Drone>>? _dronesSubscription;

  LatLng? _currentUserLocation;
  List<LatLng> _routeToDrone = [];
  List<LatLng> _geofenceCircle = [];
  double _droneDistance = 0.0;
  String _droneETA = '--';
  bool _isLocationAccurate = false;

  static const double _geofenceRadius = 1000.0; // 1km radius
  static const double _locationAccuracyThreshold = 50.0; // 50 meters

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeMap();
    _startLocationTracking();
    _setupDroneTracking();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _locationSubscription?.cancel();
    _dronesSubscription?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _initializeMap() {
    _currentUserLocation = LatLng(
      widget.userLocation.latitude,
      widget.userLocation.longitude,
    );

    _updateGeofenceCircle();
    _updateRouteToAssignedDrone();

    // Center map on user location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentUserLocation != null) {
        _mapController.move(_currentUserLocation!, 15.0);
      }
    });
  }

  void _startLocationTracking() {
    _locationSubscription = _locationService.locationStream.listen((
      locationData,
    ) {
      setState(() {
        _currentUserLocation = LatLng(
          locationData.latitude,
          locationData.longitude,
        );
        _isLocationAccurate =
            (locationData.accuracy ?? double.infinity) <=
            _locationAccuracyThreshold;
      });

      _updateGeofenceCircle();
      _updateRouteToAssignedDrone();
      widget.onLocationUpdate?.call();
    });
  }

  void _setupDroneTracking() {
    if (_currentUserLocation != null) {
      _dronesSubscription = _mapService.dronesInGeofenceStream.listen((
        dronesInRange,
      ) {
        if (mounted) {
          setState(() {
            // Update is handled by parent widget passing nearbyDrones
          });
        }
      });

      // Start monitoring geofence
      _mapService.updateGeofenceMonitoring(
        _currentUserLocation!,
        widget.nearbyDrones,
      );
    }
  }

  void _updateGeofenceCircle() {
    if (_currentUserLocation != null) {
      _geofenceCircle = _mapService.createGeofenceCircle(
        _currentUserLocation!,
        _geofenceRadius,
      );
    }
  }

  void _updateRouteToAssignedDrone() {
    if (_currentUserLocation != null && widget.assignedDrone != null) {
      final droneLocation = LatLng(
        widget.assignedDrone!.location.latitude,
        widget.assignedDrone!.location.longitude,
      );

      _routeToDrone = _mapService.getRoutePoints(
        droneLocation,
        _currentUserLocation!,
        waypoints: 15,
      );

      _droneDistance = _mapService.calculateDistance(
        droneLocation,
        _currentUserLocation!,
      );

      _droneETA = _mapService.calculateETA(_droneDistance);
    }
  }

  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];

    // User location marker with accuracy indicator
    if (_currentUserLocation != null) {
      markers.add(
        Marker(
          point: _currentUserLocation!,
          width: 40,
          height: 40,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(_pulseAnimation.value * 0.3),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_pin_circle,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Location accuracy indicator
      if (!_isLocationAccurate) {
        markers.add(
          Marker(
            point: _currentUserLocation!,
            width: 35,
            height: 35,
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange,
              ),
              child: const Icon(Icons.warning, color: Colors.white, size: 12),
            ),
          ),
        );
      }
    }

    // Assigned drone marker
    if (widget.assignedDrone != null) {
      final droneLocation = LatLng(
        widget.assignedDrone!.location.latitude,
        widget.assignedDrone!.location.longitude,
      );

      markers.add(
        Marker(
          point: droneLocation,
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getDroneStatusColor(
                widget.assignedDrone!.status,
              ).withOpacity(0.7),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.my_location, color: Colors.white, size: 16),
          ),
        ),
      );
    }

    // Nearby drones markers
    for (final drone in widget.nearbyDrones) {
      if (drone.id == widget.assignedDrone?.id) continue; // Skip assigned drone

      final droneLocation = LatLng(
        drone.location.latitude,
        drone.location.longitude,
      );

      markers.add(
        Marker(
          point: droneLocation,
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getDroneStatusColor(drone.status).withOpacity(0.7),
              border: Border.all(color: Colors.grey, width: 1),
            ),
            child: Icon(Icons.flight, color: Colors.white, size: 20),
          ),
        ),
      );
    }

    return markers;
  }

  List<Polyline> _buildPolylines() {
    final List<Polyline> polylines = [];

    // Route to assigned drone
    if (_routeToDrone.isNotEmpty && widget.assignedDrone != null) {
      polylines.add(
        Polyline(points: _routeToDrone, strokeWidth: 4.0, color: Colors.blue),
      );
    }

    return polylines;
  }

  List<Polygon> _buildPolygons() {
    List<Polygon> polygons = [];

    // Geofence circle
    if (_geofenceCircle.isNotEmpty) {
      polygons.add(
        Polygon(
          points: _geofenceCircle,
          color: Colors.blue.withOpacity(0.1),
          borderColor: Colors.blue,
          borderStrokeWidth: 2.0,
        ),
      );
    }

    return polygons;
  }

  List<CircleMarker> _buildCircleMarkers() {
    final List<CircleMarker> circles = [];

    // User location accuracy circle
    if (_currentUserLocation != null && !_isLocationAccurate) {
      final accuracy = widget.userLocation.accuracy ?? 100.0;
      circles.add(
        CircleMarker(
          point: _currentUserLocation!,
          radius: accuracy,
          color: Colors.red.withOpacity(0.1),
          borderColor: Colors.red.withOpacity(0.3),
          borderStrokeWidth: 1,
        ),
      );
    }

    return circles;
  }

  Color _getDroneStatusColor(DroneStatus status) {
    switch (status) {
      case DroneStatus.active:
        return Colors.green;
      case DroneStatus.deployed:
        return Colors.orange;
      case DroneStatus.emergency:
        return Colors.red;
      case DroneStatus.maintenance:
        return Colors.grey;
      case DroneStatus.charging:
        return Colors.yellow;
      case DroneStatus.offline:
        return Colors.black;
    }
  }

  Widget _buildInfoPanel() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.my_location,
                    color: _isLocationAccurate ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Emergency Location',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _isLocationAccurate ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _isLocationAccurate ? 'Accurate' : 'Improving',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (widget.assignedDrone != null) ...[
                Row(
                  children: [
                    const Icon(Icons.flight, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assigned Drone: ${widget.assignedDrone!.name}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            'Status: ${widget.assignedDrone!.statusDisplay}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _droneETA,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '${(_droneDistance / 1000).toStringAsFixed(1)} km away',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: widget.assignedDrone!.batteryLevel / 100,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.assignedDrone!.batteryLevel > 50
                        ? Colors.green
                        : widget.assignedDrone!.batteryLevel > 20
                        ? Colors.orange
                        : Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Battery: ${widget.assignedDrone!.batteryLevel}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ] else ...[
                Row(
                  children: [
                    const Icon(Icons.search, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Searching for available drones...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatChip(
                    'Nearby Drones',
                    widget.nearbyDrones.length.toString(),
                    Icons.flight,
                  ),
                  _buildStatChip(
                    'Geofence',
                    '${(_geofenceRadius / 1000).toStringAsFixed(1)} km',
                    Icons.radio_button_unchecked,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      right: 16,
      bottom: 100,
      child: Column(
        children: [
          FloatingActionButton.small(
            heroTag: "zoom_in",
            onPressed: () {
              final currentZoom = _mapController.camera.zoom;
              _mapController.move(
                _mapController.camera.center,
                currentZoom + 1,
              );
            },
            child: const Icon(Icons.zoom_in),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: "zoom_out",
            onPressed: () {
              final currentZoom = _mapController.camera.zoom;
              _mapController.move(
                _mapController.camera.center,
                currentZoom - 1,
              );
            },
            child: const Icon(Icons.zoom_out),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: "center_location",
            onPressed: () {
              if (_currentUserLocation != null) {
                _mapController.move(_currentUserLocation!, 16.0);
              }
            },
            child: const Icon(Icons.my_location),
          ),
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
          options: MapOptions(
            initialCenter: _currentUserLocation ?? const LatLng(0, 0),
            initialZoom: 15.0,
            minZoom: 10.0,
            maxZoom: 20.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.droneaid.app',
              maxZoom: 20,
            ),
            PolygonLayer(polygons: _buildPolygons()),
            CircleLayer(circles: _buildCircleMarkers()),
            PolylineLayer(polylines: _buildPolylines()),
            MarkerLayer(markers: _buildMarkers()),
          ],
        ),
        _buildInfoPanel(),
        _buildMapControls(),
      ],
    );
  }
}
