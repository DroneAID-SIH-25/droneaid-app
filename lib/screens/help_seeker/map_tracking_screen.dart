import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../providers/location_provider.dart';
import '../../providers/drone_tracking_provider.dart';
import '../../providers/emergency_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/drone.dart';
import '../../core/constants/app_colors.dart';
import '../../routes/app_router.dart';

class MapTrackingScreen extends StatefulWidget {
  const MapTrackingScreen({super.key});

  @override
  State<MapTrackingScreen> createState() => _MapTrackingScreenState();
}

class _MapTrackingScreenState extends State<MapTrackingScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Set<Polyline> _polylines = {};
  bool _isMapReady = false;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _fabController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fabAnimation;

  // UI state
  bool _showDroneDetails = true;
  bool _showGeofence = true;
  String? _selectedDroneId;

  // Camera positions for different areas in India
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(28.6139, 77.2090), // New Delhi
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeProviders();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );

    _fabController.forward();
  }

  void _initializeProviders() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider = context.read<LocationProvider>();
      final droneProvider = context.read<DroneTrackingProvider>();

      // Initialize location service
      locationProvider.initializeLocationService().then((_) {
        // Start drone tracking after location is ready
        droneProvider.startTracking();
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fabController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          Consumer3<LocationProvider, DroneTrackingProvider, EmergencyProvider>(
            builder:
                (
                  context,
                  locationProvider,
                  droneProvider,
                  emergencyProvider,
                  child,
                ) {
                  return Stack(
                    children: [
                      // Google Map
                      _buildGoogleMap(locationProvider, droneProvider),

                      // Top overlay with status info
                      _buildTopOverlay(locationProvider, droneProvider),

                      // Drone details panel
                      if (_showDroneDetails)
                        _buildDroneDetailsPanel(droneProvider),

                      // Emergency floating action button
                      _buildEmergencyFAB(),

                      // Map controls
                      _buildMapControls(),

                      // Loading overlay
                      if (locationProvider.isLoading ||
                          droneProvider.isTracking == false)
                        _buildLoadingOverlay(),
                    ],
                  );
                },
          ),
    );
  }

  Widget _buildGoogleMap(
    LocationProvider locationProvider,
    DroneTrackingProvider droneProvider,
  ) {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: _initialPosition,
      markers: _markers,
      circles: _circles,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      onTap: (position) {
        setState(() {
          _selectedDroneId = null;
        });
      },
    );
  }

  Widget _buildTopOverlay(
    LocationProvider locationProvider,
    DroneTrackingProvider droneProvider,
  ) {
    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: droneProvider.isTracking
                            ? AppColors.success.withOpacity(
                                _pulseAnimation.value,
                              )
                            : AppColors.error,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  droneProvider.isTracking
                      ? 'Live Tracking Active'
                      : 'Tracking Offline',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showNotifications(),
                  icon: Consumer<NotificationProvider>(
                    builder: (context, notificationProvider, child) {
                      final unreadCount = notificationProvider.unreadCount;
                      return Badge(
                        label: Text('$unreadCount'),
                        isLabelVisible: unreadCount > 0,
                        child: const Icon(Icons.notifications),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'In Range',
                  '${droneProvider.dronesInGeofence.length}',
                  Icons.radio_button_checked,
                  AppColors.primary,
                ),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                _buildStatItem(
                  'Nearest',
                  droneProvider.nearbyDrones.isNotEmpty
                      ? '${droneProvider.getDistanceToUser(droneProvider.nearbyDrones.first).round()}m'
                      : 'N/A',
                  Icons.near_me,
                  AppColors.secondary,
                ),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                _buildStatItem(
                  'Location',
                  locationProvider.currentLocation?.address?.split(',').first ??
                      'India',
                  Icons.location_on,
                  AppColors.info,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDroneDetailsPanel(DroneTrackingProvider droneProvider) {
    final dronesInRange = droneProvider.dronesInGeofence;

    if (dronesInRange.isEmpty) {
      return Positioned(
        bottom: 100,
        left: 16,
        right: 16,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flight_takeoff_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              const Text(
                'No Drones in Range',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const Text(
                '1km geofence area is empty',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(MdiIcons.drone, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Drones in Range (${dronesInRange.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showDroneDetails = false;
                      });
                    },
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),

            // Drone list
            Expanded(
              child: ListView.builder(
                itemCount: dronesInRange.length,
                itemBuilder: (context, index) {
                  final drone = dronesInRange[index];
                  final trackingInfo = droneProvider.getDroneTrackingInfo(
                    drone,
                  );
                  return _buildDroneListItem(drone, trackingInfo);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDroneListItem(Drone drone, DroneTrackingInfo trackingInfo) {
    final isSelected = _selectedDroneId == drone.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selectDrone(drone),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Drone status indicator
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getDroneStatusColor(drone.status),
                  ),
                ),
                const SizedBox(width: 12),

                // Drone info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drone.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${drone.serialNumber} • ${drone.model}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // Distance and ETA
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      trackingInfo.formattedDistance,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'ETA: ${trackingInfo.formattedETA}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),

                // Battery indicator
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _getBatteryColor(drone.batteryLevel),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.bottomCenter,
                    heightFactor: drone.batteryLevel / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getBatteryColor(drone.batteryLevel),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyFAB() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _showEmergencyDialog,
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.emergency, size: 24),
          label: const Text(
            'EMERGENCY',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          elevation: 8,
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      bottom: 180,
      right: 16,
      child: Column(
        children: [
          // My location button
          FloatingActionButton(
            mini: true,
            onPressed: _goToMyLocation,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 8),

          // Toggle geofence
          FloatingActionButton(
            mini: true,
            onPressed: _toggleGeofence,
            backgroundColor: Colors.white,
            foregroundColor: _showGeofence ? AppColors.primary : Colors.grey,
            child: Icon(
              _showGeofence
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
          ),
          const SizedBox(height: 8),

          // Toggle drone details
          FloatingActionButton(
            mini: true,
            onPressed: () {
              setState(() {
                _showDroneDetails = !_showDroneDetails;
              });
            },
            backgroundColor: Colors.white,
            foregroundColor: _showDroneDetails
                ? AppColors.primary
                : Colors.grey,
            child: Icon(MdiIcons.drone),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Initializing tracking system...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _isMapReady = true;
    _updateMapElements();
  }

  void _updateMapElements() {
    if (!_isMapReady) return;

    final locationProvider = context.read<LocationProvider>();
    final droneProvider = context.read<DroneTrackingProvider>();

    final markers = <Marker>{};
    final circles = <Circle>{};
    final polylines = <Polyline>{};

    // User location marker
    final userLocation = locationProvider.currentLocation;
    if (userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(userLocation.latitude, userLocation.longitude),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );

      // Geofence circle
      if (_showGeofence) {
        circles.add(
          Circle(
            circleId: const CircleId('geofence'),
            center: LatLng(userLocation.latitude, userLocation.longitude),
            radius: droneProvider.geofenceRadius,
            strokeColor: AppColors.primary.withOpacity(0.5),
            strokeWidth: 2,
            fillColor: AppColors.primary.withOpacity(0.1),
          ),
        );
      }
    }

    // Drone markers
    for (final drone in droneProvider.allDrones) {
      final isInGeofence = droneProvider.dronesInGeofence.contains(drone);
      final isSelected = _selectedDroneId == drone.id;

      markers.add(
        Marker(
          markerId: MarkerId(drone.id),
          position: LatLng(drone.location.latitude, drone.location.longitude),
          infoWindow: InfoWindow(
            title: drone.name,
            snippet: '${drone.serialNumber} • ${_getStatusText(drone.status)}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isInGeofence
                ? (isSelected
                      ? BitmapDescriptor.hueOrange
                      : BitmapDescriptor.hueGreen)
                : BitmapDescriptor.hueRed,
          ),
          onTap: () => _selectDrone(drone),
        ),
      );

      // Route line to user location (for drones in geofence)
      if (isInGeofence && userLocation != null) {
        polylines.add(
          Polyline(
            polylineId: PolylineId('route_${drone.id}'),
            points: [
              LatLng(drone.location.latitude, drone.location.longitude),
              LatLng(userLocation.latitude, userLocation.longitude),
            ],
            color: isSelected
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.3),
            width: isSelected ? 3 : 2,
            patterns: [PatternItem.dash(10), PatternItem.gap(5)],
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
      _circles = circles;
      _polylines = polylines;
    });
  }

  void _selectDrone(Drone drone) {
    setState(() {
      _selectedDroneId = _selectedDroneId == drone.id ? null : drone.id;
    });
    _updateMapElements();

    // Center map on selected drone
    if (_selectedDroneId == drone.id) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(drone.location.latitude, drone.location.longitude),
        ),
      );
    }
  }

  void _goToMyLocation() {
    final locationProvider = context.read<LocationProvider>();
    final userLocation = locationProvider.currentLocation;

    if (userLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(userLocation.latitude, userLocation.longitude),
          15,
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Location not available')));
    }
  }

  void _toggleGeofence() {
    setState(() {
      _showGeofence = !_showGeofence;
    });
    _updateMapElements();
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: AppColors.error),
            SizedBox(width: 8),
            Text('Emergency Request'),
          ],
        ),
        content: const Text(
          'Do you need immediate emergency assistance? This will alert nearby drones and emergency services.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              AppRouter.goToRequestHelp();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(
              'REQUEST HELP',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
    // Navigate to notifications screen or show modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.notifications,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Notifications',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (provider.unreadCount > 0)
                            TextButton(
                              onPressed: provider.markAllAsRead,
                              child: const Text('Mark All Read'),
                            ),
                        ],
                      ),
                    ),

                    // Notifications list
                    Expanded(
                      child: provider.notifications.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.notifications_none,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No notifications',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: provider.notifications.length,
                              itemBuilder: (context, index) {
                                final notification =
                                    provider.notifications[index];
                                return ListTile(
                                  leading: Icon(
                                    _getNotificationIcon(notification.type),
                                    color: notification.isRead
                                        ? Colors.grey
                                        : AppColors.primary,
                                  ),
                                  title: Text(
                                    notification.title,
                                    style: TextStyle(
                                      fontWeight: notification.isRead
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(notification.body),
                                  trailing: Text(
                                    notification.timeAgo,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  onTap: () =>
                                      provider.markAsRead(notification.id),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _getDroneStatusColor(DroneStatus status) {
    switch (status) {
      case DroneStatus.active:
        return AppColors.success;
      case DroneStatus.deployed:
        return AppColors.primary;
      case DroneStatus.maintenance:
        return AppColors.warning;
      case DroneStatus.offline:
        return AppColors.error;
      case DroneStatus.charging:
        return AppColors.info;
      case DroneStatus.emergency:
        return AppColors.error;
    }
  }

  Color _getBatteryColor(int batteryLevel) {
    if (batteryLevel > 60) return AppColors.success;
    if (batteryLevel > 30) return AppColors.warning;
    return AppColors.error;
  }

  String _getStatusText(DroneStatus status) {
    switch (status) {
      case DroneStatus.active:
        return 'Active';
      case DroneStatus.deployed:
        return 'Deployed';
      case DroneStatus.maintenance:
        return 'Maintenance';
      case DroneStatus.offline:
        return 'Offline';
      case DroneStatus.charging:
        return 'Charging';
      case DroneStatus.emergency:
        return 'Emergency';
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.emergencyAlert:
        return Icons.emergency;
      case NotificationType.droneApproach:
        return MdiIcons.drone;
      case NotificationType.systemUpdate:
        return Icons.system_update;
      case NotificationType.weatherAlert:
        return Icons.cloud;
      case NotificationType.disasterAlert:
        return Icons.warning;
      case NotificationType.missionUpdate:
        return Icons.update;
      case NotificationType.maintenanceAlert:
        return Icons.build;
    }
  }
}
