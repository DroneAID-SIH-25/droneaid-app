import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/drone.dart';
import '../../models/emergency_request.dart';
import '../../models/user.dart';
import '../../services/map_service.dart';
import '../../services/location_service.dart';

class HelpSeekerMapWidget extends StatefulWidget {
  final LocationData userLocation;
  final EmergencyRequest? emergencyRequest;
  final List<Drone> nearbyDrones;
  final VoidCallback? onLocationUpdate;
  final Function(LatLng)? onMapTap;

  const HelpSeekerMapWidget({
    Key? key,
    required this.userLocation,
    this.emergencyRequest,
    this.nearbyDrones = const [],
    this.onLocationUpdate,
    this.onMapTap,
  }) : super(key: key);

  @override
  State<HelpSeekerMapWidget> createState() => _HelpSeekerMapWidgetState();
}

class _HelpSeekerMapWidgetState extends State<HelpSeekerMapWidget>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final MapService _mapService = MapService();
  final LocationService _locationService = LocationService();

  StreamSubscription<List<Drone>>? _dronesSubscription;
  StreamSubscription<RouteUpdate>? _routeSubscription;
  StreamSubscription<LocationData>? _locationSubscription;

  List<Drone> _dronesInGeofence = [];
  RouteUpdate? _currentRouteUpdate;
  LocationData? _currentLocation;
  bool _isLocationLoading = false;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _droneAnimationController;
  late Animation<double> _pulseAnimation;

  static const double _geofenceRadius = 1000.0; // 1km
  static const double _maxZoom = 18.0;
  static const double _minZoom = 8.0;
  static const double _defaultZoom = 15.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeMapData();
    _setupStreams();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _droneAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
    _droneAnimationController.repeat();
  }

  void _initializeMapData() {
    _currentLocation = widget.userLocation;
    _updateGeofenceMonitoring();
  }

  void _setupStreams() {
    // Monitor drones in geofence
    _dronesSubscription = _mapService.dronesInGeofenceStream.listen((drones) {
      if (mounted) {
        setState(() {
          _dronesInGeofence = drones;
        });
      }
    });

    // Monitor route updates
    _routeSubscription = _mapService.routeUpdatesStream.listen((routeUpdate) {
      if (mounted) {
        setState(() {
          _currentRouteUpdate = routeUpdate;
        });
      }
    });

    // Monitor location updates
    _locationSubscription = _locationService.locationStream.listen((
      locationData,
    ) {
      if (mounted) {
        setState(() {
          _currentLocation = locationData;
        });
        _updateGeofenceMonitoring();
        widget.onLocationUpdate?.call();
      }
    });
  }

  void _updateGeofenceMonitoring() {
    if (_currentLocation != null) {
      final userLatLng = LatLng(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );
      _mapService.updateGeofenceMonitoring(userLatLng, widget.nearbyDrones);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userLatLng = LatLng(
      _currentLocation?.latitude ?? widget.userLocation.latitude,
      _currentLocation?.longitude ?? widget.userLocation.longitude,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            _buildMap(userLatLng, theme),
            _buildMapOverlays(theme),
            _buildLocationButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(LatLng userLatLng, ThemeData theme) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: userLatLng,
        initialZoom: _defaultZoom,
        maxZoom: _maxZoom,
        minZoom: _minZoom,
        onTap: (tapPosition, point) => widget.onMapTap?.call(point),
      ),
      children: [
        // Base map layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.drone_aid',
          maxZoom: _maxZoom,
        ),

        // Geofence layer
        _buildGeofenceLayer(userLatLng, theme),

        // Route layer (if emergency request exists)
        if (widget.emergencyRequest != null) _buildRouteLayer(theme),

        // Drone markers layer
        _buildDroneMarkersLayer(),

        // User location marker layer
        _buildUserLocationLayer(userLatLng, theme),

        // Emergency marker layer
        if (widget.emergencyRequest != null) _buildEmergencyMarkerLayer(),
      ],
    );
  }

  Widget _buildGeofenceLayer(LatLng center, ThemeData theme) {
    final geofencePoints = _mapService.createGeofenceCircle(
      center,
      _geofenceRadius,
    );

    return PolygonLayer(
      polygons: [
        Polygon(
          points: geofencePoints,
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderColor: theme.colorScheme.primary.withOpacity(0.3),
          borderStrokeWidth: 2.0,
        ),
      ],
    );
  }

  Widget _buildRouteLayer(ThemeData theme) {
    if (widget.emergencyRequest == null || _dronesInGeofence.isEmpty) {
      return const SizedBox.shrink();
    }

    // Find nearest drone for route visualization
    final userLatLng = LatLng(
      _currentLocation?.latitude ?? widget.userLocation.latitude,
      _currentLocation?.longitude ?? widget.userLocation.longitude,
    );

    final nearestDrone = _mapService.findNearestDrone(
      userLatLng,
      _dronesInGeofence,
    );

    if (nearestDrone == null) return const SizedBox.shrink();

    final droneLatLng = LatLng(
      nearestDrone.location.latitude,
      nearestDrone.location.longitude,
    );

    final routePoints = _mapService.getRoutePoints(droneLatLng, userLatLng);

    return PolylineLayer(
      polylines: [
        Polyline(
          points: routePoints,
          strokeWidth: 3.0,
          color: theme.colorScheme.secondary,
        ),
      ],
    );
  }

  Widget _buildDroneMarkersLayer() {
    return MarkerLayer(
      markers: _dronesInGeofence.map((drone) {
        final droneLatLng = LatLng(
          drone.location.latitude,
          drone.location.longitude,
        );

        return Marker(
          point: droneLatLng,
          width: 50,
          height: 50,
          child: AnimatedBuilder(
            animation: _droneAnimationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _droneAnimationController.value * 2 * 3.14159,
                child: _buildDroneMarker(drone),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDroneMarker(Drone drone) {
    Color markerColor;
    IconData markerIcon;

    switch (drone.status) {
      case DroneStatus.active:
        markerColor = Colors.green;
        markerIcon = Icons.flight;
        break;
      case DroneStatus.deployed:
        markerColor = Colors.blue;
        markerIcon = Icons.flight_takeoff;
        break;
      case DroneStatus.charging:
        markerColor = Colors.orange;
        markerIcon = Icons.battery_charging_full;
        break;
      case DroneStatus.emergency:
        markerColor = Colors.red;
        markerIcon = Icons.warning;
        break;
      default:
        markerColor = Colors.grey;
        markerIcon = Icons.flight;
    }

    return Container(
      decoration: BoxDecoration(
        color: markerColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(markerIcon, color: Colors.white, size: 20),
    );
  }

  Widget _buildUserLocationLayer(LatLng userLatLng, ThemeData theme) {
    return MarkerLayer(
      markers: [
        Marker(
          point: userLatLng,
          width: 60,
          height: 60,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Pulse circle
                  Container(
                    width: 60 * (0.5 + 0.5 * _pulseAnimation.value),
                    height: 60 * (0.5 + 0.5 * _pulseAnimation.value),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withOpacity(
                        0.3 * (1 - _pulseAnimation.value),
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  // User marker
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.person, color: Colors.white, size: 16),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyMarkerLayer() {
    if (widget.emergencyRequest == null) {
      return const SizedBox.shrink();
    }

    final emergencyLatLng = LatLng(
      widget.emergencyRequest!.location.latitude,
      widget.emergencyRequest!.location.longitude,
    );

    return MarkerLayer(
      markers: [
        Marker(
          point: emergencyLatLng,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red,
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
            child: const Icon(Icons.emergency, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildMapOverlays(ThemeData theme) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Column(
        children: [
          _buildDroneCountCard(theme),
          const SizedBox(height: 8),
          if (_currentRouteUpdate != null) _buildETACard(theme),
        ],
      ),
    );
  }

  Widget _buildDroneCountCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flight, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            '${_dronesInGeofence.length} drones nearby',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildETACard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            'ETA: ${_currentRouteUpdate!.eta}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(_currentRouteUpdate!.remainingDistance / 1000).toStringAsFixed(1)} km',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationButton() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: FloatingActionButton.small(
        onPressed: _centerOnUserLocation,
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).colorScheme.primary,
        child: _isLocationLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : const Icon(Icons.my_location),
      ),
    );
  }

  Future<void> _centerOnUserLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      final location = await _mapService.getCurrentLocation();
      if (location != null) {
        _mapController.move(location, _defaultZoom);
        setState(() {
          _currentLocation = _mapService.latLngToLocationData(location);
        });
      }
    } catch (e) {
      print('Error centering on user location: $e');
    } finally {
      setState(() {
        _isLocationLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _droneAnimationController.dispose();
    _dronesSubscription?.cancel();
    _routeSubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }
}
