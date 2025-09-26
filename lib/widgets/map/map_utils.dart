import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../models/drone.dart';
import '../../models/mission.dart';
import '../../services/map_service.dart';

/// Utility widgets and components for map functionality
class MapUtils {
  static final MapService _mapService = MapService();

  /// Creates a custom marker for drones
  static Widget createDroneMarker({
    required Drone drone,
    required bool isSelected,
    required VoidCallback onTap,
    required BuildContext context,
    double size = 50,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isSelected ? size + 10 : size,
        height: isSelected ? size + 10 : size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: getDroneStatusColor(drone.status),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.white,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: getDroneStatusColor(drone.status).withOpacity(0.4),
              blurRadius: isSelected ? 15 : 8,
              spreadRadius: isSelected ? 3 : 1,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.flight, color: Colors.white, size: isSelected ? 28 : 20),
            // Battery warning indicator
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
            // Mission indicator
            if (drone.currentMissionId != null)
              Positioned(
                bottom: 2,
                child: Container(
                  width: 16,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 6,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Creates a custom marker for missions
  static Widget createMissionMarker({
    required Mission mission,
    required bool isSelected,
    required VoidCallback onTap,
    required BuildContext context,
    double size = 45,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isSelected ? size + 10 : size,
        height: isSelected ? size + 10 : size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: getMissionPriorityColor(mission.priority),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.white,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: getMissionPriorityColor(mission.priority).withOpacity(0.4),
              blurRadius: isSelected ? 15 : 8,
              spreadRadius: isSelected ? 3 : 1,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              getMissionTypeIcon(mission.type),
              color: Colors.white,
              size: isSelected ? 24 : 18,
            ),
            // Priority indicator for critical missions
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
  }

  /// Creates a pulsing user location marker
  static Widget createUserLocationMarker({
    required Animation<double> pulseAnimation,
    double size = 60,
  }) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: pulseAnimation.value,
          child: Container(
            width: size,
            height: size,
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
    );
  }

  /// Creates an emergency request marker
  static Widget createEmergencyMarker({
    required String urgency,
    required Animation<double>? pulseAnimation,
    double size = 50,
  }) {
    final color = getEmergencyColor(urgency);

    Widget marker = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.emergency, color: Colors.white, size: 24),
    );

    if (pulseAnimation != null) {
      return AnimatedBuilder(
        animation: pulseAnimation,
        builder: (context, child) {
          return Transform.scale(scale: pulseAnimation.value, child: marker);
        },
      );
    }

    return marker;
  }

  /// Creates a GCS station marker
  static Widget createGCSStationMarker({
    required String status,
    required int activeDrones,
    required bool isSelected,
    required VoidCallback onTap,
    required Animation<double>? rotationAnimation,
    double size = 60,
  }) {
    final color = getStationStatusColor(status);

    Widget marker = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isSelected ? size + 20 : size,
        height: isSelected ? size + 20 : size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.white,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
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
            if (activeDrones > 0)
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
                    activeDrones.toString(),
                    style: TextStyle(
                      color: color,
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

    if (rotationAnimation != null && status == 'active') {
      return AnimatedBuilder(
        animation: rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: rotationAnimation.value * 2 * 3.14159,
            child: marker,
          );
        },
      );
    }

    return marker;
  }

  /// Creates a route polyline
  static Widget createRoutePolyline({
    required List<LatLng> points,
    required Color color,
    double strokeWidth = 3.0,
    bool isDashed = false,
  }) {
    // This would be used within a PolylineLayer
    // Returning a placeholder widget here
    return const SizedBox.shrink();
  }

  /// Creates a geofence circle
  static List<LatLng> createGeofenceCircle({
    required LatLng center,
    required double radiusInMeters,
    int points = 32,
  }) {
    return _mapService.calculateGeofencePolygon(
      center,
      radiusInMeters,
      points: points,
    );
  }

  /// Creates a info popup for map markers
  static Widget createInfoPopup({
    required String title,
    required String subtitle,
    required List<MapInfoItem> items,
    VoidCallback? onClose,
    required BuildContext context,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
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
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  if (onClose != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClose,
                      iconSize: 18,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ...items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Icon(item.icon, size: 16, color: item.color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                                Text(
                                  item.value,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: item.color,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }

  /// Creates a map statistics overlay
  static Widget createStatsOverlay({
    required Map<String, dynamic> stats,
    required BuildContext context,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Statistics',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...stats.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      entry.value.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Creates a map legend
  static Widget createLegend({
    required List<LegendItem> items,
    required BuildContext context,
  }) {
    return Card(
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
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 16, color: item.color),
                    const SizedBox(width: 8),
                    Text(
                      item.label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // Color utility methods
  static Color getDroneStatusColor(DroneStatus status) {
    switch (status) {
      case DroneStatus.active:
        return Colors.green;
      case DroneStatus.deployed:
        return Colors.blue;
      case DroneStatus.maintenance:
        return Colors.orange;
      case DroneStatus.offline:
        return Colors.grey;
      case DroneStatus.charging:
        return Colors.yellow[700]!;
      case DroneStatus.emergency:
        return Colors.red;
    }
  }

  static Color getMissionPriorityColor(MissionPriority priority) {
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

  static Color getMissionStatusColor(MissionStatus status) {
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

  static Color getStationStatusColor(String status) {
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

  static Color getEmergencyColor(String urgency) {
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

  static Color getBatteryColor(int batteryLevel) {
    if (batteryLevel > 60) return Colors.green;
    if (batteryLevel > 20) return Colors.orange;
    return Colors.red;
  }

  // Icon utility methods
  static IconData getMissionTypeIcon(MissionType type) {
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
      case MissionType.emergencyResponse:
        return Icons.emergency;
      case MissionType.medical:
        return Icons.medical_services;
      case MissionType.firefighting:
        return Icons.local_fire_department;
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

  static IconData getDroneStatusIcon(DroneStatus status) {
    switch (status) {
      case DroneStatus.active:
        return Icons.flight_takeoff;
      case DroneStatus.deployed:
        return Icons.flight;
      case DroneStatus.maintenance:
        return Icons.build;
      case DroneStatus.offline:
        return Icons.flight_land;
      case DroneStatus.charging:
        return Icons.battery_charging_full;
      case DroneStatus.emergency:
        return Icons.warning;
    }
  }

  // Utility methods
  static String formatDistance(double distanceInMeters) {
    return _mapService.formatDistance(distanceInMeters);
  }

  static String formatCoordinates(LatLng position) {
    return _mapService.formatCoordinates(position);
  }

  static String calculateETA(double distanceInMeters, {double? speedMps}) {
    return _mapService.calculateETA(distanceInMeters, speedMps: speedMps);
  }

  static double calculateDistance(LatLng start, LatLng end) {
    return _mapService.calculateDistance(start, end);
  }

  static double calculateBearing(LatLng start, LatLng end) {
    return _mapService.calculateBearing(start, end);
  }
}

/// Data class for map info items
class MapInfoItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  MapInfoItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

/// Data class for legend items
class LegendItem {
  final String label;
  final IconData icon;
  final Color color;

  LegendItem({required this.label, required this.icon, required this.color});
}

/// Custom map controls widget
class MapControlsWidget extends StatelessWidget {
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onMyLocation;
  final VoidCallback? onCenterMap;
  final bool showMyLocation;
  final bool showCenterMap;

  const MapControlsWidget({
    Key? key,
    this.onZoomIn,
    this.onZoomOut,
    this.onMyLocation,
    this.onCenterMap,
    this.showMyLocation = true,
    this.showCenterMap = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Zoom controls
        Card(
          child: Column(
            children: [
              IconButton(icon: const Icon(Icons.add), onPressed: onZoomIn),
              const Divider(height: 1),
              IconButton(icon: const Icon(Icons.remove), onPressed: onZoomOut),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Location controls
        if (showMyLocation)
          Card(
            child: IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: onMyLocation,
            ),
          ),

        if (showCenterMap) ...[
          const SizedBox(height: 8),
          Card(
            child: IconButton(
              icon: const Icon(Icons.public),
              onPressed: onCenterMap,
            ),
          ),
        ],
      ],
    );
  }
}

/// Map layer toggle widget
class MapLayerToggle extends StatelessWidget {
  final Map<String, bool> layers;
  final Function(String, bool) onLayerToggle;

  const MapLayerToggle({
    Key? key,
    required this.layers,
    required this.onLayerToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Layers',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...layers.entries.map((entry) {
              return Row(
                children: [
                  Switch(
                    value: entry.value,
                    onChanged: (value) => onLayerToggle(entry.key, value),
                  ),
                  const SizedBox(width: 8),
                  Text(entry.key),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
