import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_colors.dart';
import '../../services/location_service.dart';
import '../../models/user.dart';

/// Emergency Response Map Widget using Flutter Map
class MapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double zoom;
  final List<MapMarker>? markers;
  final List<MapPolyline>? polylines;
  final List<MapCircle>? circles;
  final bool showCurrentLocation;
  final bool showZoomControls;
  final bool showLocationButton;
  final Function()? onMapCreated;
  final Function(LatLng)? onTap;
  final Function(LatLng)? onLongPress;
  final MapType mapType;

  const MapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.zoom = 14.0,
    this.markers,
    this.polylines,
    this.circles,
    this.showCurrentLocation = true,
    this.showZoomControls = true,
    this.showLocationButton = true,
    this.onMapCreated,
    this.onTap,
    this.onLongPress,
    this.mapType = MapType.street,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late MapController _mapController;
  MapType _currentMapType = MapType.street;
  final LocationService _locationService = LocationService();
  LocationData? _currentLocation;
  bool _locationLoading = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentMapType = widget.mapType;
    if (widget.showCurrentLocation) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_locationLoading) return;

    setState(() {
      _locationLoading = true;
    });

    try {
      final location = await _locationService.getCurrentLocation();
      if (location != null && mounted) {
        setState(() {
          _currentLocation = location;
        });
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _locationLoading = false;
        });
      }
    }
  }

  void _moveToCurrentLocation() async {
    await _getCurrentLocation();
    if (_currentLocation != null) {
      _mapController.move(
        LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
        15.0,
      );
    }
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildFlutterMap(),
        if (widget.showZoomControls || widget.showLocationButton)
          _buildMapControls(),
      ],
    );
  }

  Widget _buildFlutterMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(widget.latitude, widget.longitude),
        initialZoom: widget.zoom,
        minZoom: 3.0,
        maxZoom: 18.0,
        onMapReady: widget.onMapCreated,
        onTap: widget.onTap != null
            ? (tapPosition, point) => widget.onTap!(point)
            : null,
        onLongPress: widget.onLongPress != null
            ? (tapPosition, point) => widget.onLongPress!(point)
            : null,
      ),
      children: [
        // Tile Layer
        TileLayer(
          urlTemplate: _getTileUrlTemplate(),
          userAgentPackageName: 'com.droneaid.emergency',
          maxNativeZoom: 19,
          errorTileCallback: (tile, error, stackTrace) {
            debugPrint('Tile loading error: $error');
          },
        ),

        // Circles Layer
        if (widget.circles != null && widget.circles!.isNotEmpty)
          CircleLayer(
            circles: widget.circles!
                .where((circle) => _isValidCircle(circle))
                .map(
                  (circle) => CircleMarker(
                    point: circle.center,
                    radius: _clampRadius(circle.radius),
                    color: circle.color,
                    borderColor: circle.borderColor,
                    borderStrokeWidth: circle.borderWidth,
                  ),
                )
                .toList(),
          ),

        // Polylines Layer
        if (widget.polylines != null && widget.polylines!.isNotEmpty)
          PolylineLayer(
            polylines: widget.polylines!
                .map(
                  (polyline) => Polyline(
                    points: polyline.points,
                    color: polyline.color,
                    strokeWidth: polyline.width,
                  ),
                )
                .toList(),
          ),

        // Markers Layer
        if (widget.markers != null && widget.markers!.isNotEmpty)
          MarkerLayer(
            markers: widget.markers!
                .map(
                  (marker) => Marker(
                    point: marker.position,
                    width: marker.width,
                    height: marker.height,
                    child: marker.child,
                    alignment: marker.alignment,
                  ),
                )
                .toList(),
          ),

        // Current Location Layer
        if (widget.showCurrentLocation && _currentLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                  _currentLocation!.latitude,
                  _currentLocation!.longitude,
                ),
                width: 20.0,
                height: 20.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          // Map Type Toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _toggleMapType,
              icon: Icon(_getMapTypeIcon(), color: AppColors.primary),
              tooltip: 'Switch Map Type',
            ),
          ),

          if (widget.showLocationButton) ...[
            const SizedBox(height: 8),
            // Current Location Button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _locationLoading ? null : _moveToCurrentLocation,
                icon: _locationLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : Icon(
                        Icons.my_location,
                        color: _currentLocation != null
                            ? AppColors.primary
                            : Colors.grey,
                      ),
                tooltip: 'Current Location',
              ),
            ),
          ],

          if (widget.showZoomControls) ...[
            const SizedBox(height: 8),
            // Zoom Controls
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _zoomIn,
                    icon: const Icon(Icons.add),
                    tooltip: 'Zoom In',
                  ),
                  const Divider(height: 1),
                  IconButton(
                    onPressed: _zoomOut,
                    icon: const Icon(Icons.remove),
                    tooltip: 'Zoom Out',
                  ),
                ],
              ),
            ),
          ],

          if (widget.showLocationButton) ...[
            const SizedBox(height: 8),
            // Current Location Button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _goToCurrentLocation,
                icon: const Icon(Icons.my_location),
                color: AppColors.primary,
                tooltip: 'My Location',
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getTileUrlTemplate() {
    switch (_currentMapType) {
      case MapType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapType.terrain:
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      case MapType.street:
        return 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  IconData _getMapTypeIcon() {
    switch (_currentMapType) {
      case MapType.satellite:
        return Icons.satellite_alt;
      case MapType.terrain:
        return Icons.terrain;
      case MapType.street:
        return Icons.map;
    }
  }

  void _toggleMapType() {
    setState(() {
      switch (_currentMapType) {
        case MapType.street:
          _currentMapType = MapType.satellite;
          break;
        case MapType.satellite:
          _currentMapType = MapType.terrain;
          break;
        case MapType.terrain:
          _currentMapType = MapType.street;
          break;
      }
    });
  }

  void _zoomIn() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom + 1,
    );
  }

  void _zoomOut() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom - 1,
    );
  }

  void _goToCurrentLocation() {
    _mapController.move(
      LatLng(widget.latitude, widget.longitude),
      _mapController.camera.zoom,
    );
  }

  bool _isValidCircle(MapCircle circle) {
    // Validate latitude and longitude
    if (circle.center.latitude < -90 || circle.center.latitude > 90) {
      return false;
    }
    if (circle.center.longitude < -180 || circle.center.longitude > 180) {
      return false;
    }

    // Validate radius (must be positive and reasonable)
    if (circle.radius <= 0 || circle.radius > 50000) {
      return false;
    }

    return true;
  }

  double _clampRadius(double radius) {
    // Clamp radius to reasonable bounds (1 meter to 50km)
    return radius.clamp(1.0, 50000.0);
  }
}

/// Map marker model for emergency response
class MapMarker {
  final LatLng position;
  final Widget child;
  final double width;
  final double height;
  final Alignment alignment;

  const MapMarker({
    required this.position,
    required this.child,
    this.width = 40.0,
    this.height = 40.0,
    this.alignment = Alignment.center,
  });
}

/// Map polyline model for routes
class MapPolyline {
  final List<LatLng> points;
  final Color color;
  final double width;
  final bool isDashed;

  const MapPolyline({
    required this.points,
    this.color = Colors.blue,
    this.width = 3.0,
    this.isDashed = false,
  });
}

/// Map circle model for zones
class MapCircle {
  final LatLng center;
  final double radius;
  final Color color;
  final Color borderColor;
  final double borderWidth;

  const MapCircle({
    required this.center,
    required this.radius,
    this.color = Colors.blue,
    this.borderColor = Colors.blueAccent,
    this.borderWidth = 2.0,
  });
}

/// Map types for different tile sources
enum MapType { street, satellite, terrain }

/// Emergency-specific marker builders
class EmergencyMarkers {
  /// Create a drone marker
  static MapMarker drone({
    required LatLng position,
    required DroneStatus status,
    VoidCallback? onTap,
  }) {
    Color color;
    IconData icon;

    switch (status) {
      case DroneStatus.active:
        color = AppColors.success;
        icon = Icons.flight;
        break;
      case DroneStatus.deployed:
        color = AppColors.warning;
        icon = Icons.flight_takeoff;
        break;
      case DroneStatus.maintenance:
        color = AppColors.textSecondary;
        icon = Icons.build;
        break;
      case DroneStatus.offline:
        color = AppColors.error;
        icon = Icons.flight_land;
        break;
    }

    return MapMarker(
      position: position,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  /// Create an emergency location marker
  static MapMarker emergency({
    required LatLng position,
    required EmergencyType type,
    VoidCallback? onTap,
  }) {
    Color color;
    IconData icon;

    switch (type) {
      case EmergencyType.medicalEmergency:
        color = AppColors.error;
        icon = Icons.local_hospital;
        break;
      case EmergencyType.fire:
        color = Colors.orange;
        icon = Icons.local_fire_department;
        break;
      case EmergencyType.naturalDisaster:
        color = Colors.purple;
        icon = Icons.warning;
        break;
      case EmergencyType.accident:
        color = AppColors.warning;
        icon = Icons.car_crash;
        break;
      default:
        color = AppColors.error;
        icon = Icons.emergency;
    }

    return MapMarker(
      position: position,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  /// Create a GCS station marker
  static MapMarker gcsStation({required LatLng position, VoidCallback? onTap}) {
    return MapMarker(
      position: position,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.cell_tower, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

/// Drone status enum
enum DroneStatus { active, deployed, maintenance, offline }

/// Emergency type enum
enum EmergencyType { medicalEmergency, fire, naturalDisaster, accident, other }
