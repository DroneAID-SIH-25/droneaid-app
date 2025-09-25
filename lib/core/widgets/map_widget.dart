import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as latLng;
import '../constants/app_colors.dart';

/// Map widget that supports both Google Maps and OpenStreetMap
class MapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double zoom;
  final Set<gmaps.Marker>? markers;
  final Set<gmaps.Polyline>? polylines;
  final gmaps.MapType mapType;
  final VoidCallback? onMapCreated;
  final Function(gmaps.LatLng)? onTap;
  final bool showCurrentLocation;
  final bool enableInteraction;

  const MapWidget({
    Key? key,
    this.latitude = 28.6139, // Default to Delhi, India
    this.longitude = 77.2090,
    this.zoom = 12.0,
    this.markers,
    this.polylines,
    this.mapType = gmaps.MapType.normal,
    this.onMapCreated,
    this.onTap,
    this.showCurrentLocation = true,
    this.enableInteraction = true,
  }) : super(key: key);

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  gmaps.GoogleMapController? _googleMapController;
  fmap.MapController? _openMapController;
  bool _useGoogleMaps = true; // Toggle between map providers

  @override
  void initState() {
    super.initState();
    _openMapController = fmap.MapController();
  }

  @override
  void dispose() {
    _googleMapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            _useGoogleMaps ? _buildGoogleMap() : _buildOpenStreetMap(),
            _buildMapControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleMap() {
    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(widget.latitude, widget.longitude),
        zoom: widget.zoom,
      ),
      markers: widget.markers ?? <gmaps.Marker>{},
      polylines: widget.polylines ?? <gmaps.Polyline>{},
      mapType: widget.mapType,
      myLocationEnabled: widget.showCurrentLocation,
      myLocationButtonEnabled: false, // We'll use custom button
      onMapCreated: (gmaps.GoogleMapController controller) {
        _googleMapController = controller;
        widget.onMapCreated?.call();
      },
      onTap: widget.onTap,
      gestureRecognizers: widget.enableInteraction
          ? <Factory<OneSequenceGestureRecognizer>>{}
          : <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
    );
  }

  Widget _buildOpenStreetMap() {
    return fmap.FlutterMap(
      mapController: _openMapController,
      options: fmap.MapOptions(
        initialCenter: latLng.LatLng(widget.latitude, widget.longitude),
        initialZoom: widget.zoom,
        onTap: widget.onTap != null
            ? (tapPosition, point) =>
                  widget.onTap!(gmaps.LatLng(point.latitude, point.longitude))
            : null,
      ),
      children: [
        fmap.TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.droneaid.app',
        ),
        if (widget.markers != null && widget.markers!.isNotEmpty)
          fmap.MarkerLayer(markers: _convertGoogleMarkersToFlutterMarkers()),
        if (widget.polylines != null && widget.polylines!.isNotEmpty)
          fmap.PolylineLayer(
            polylines: _convertGooglePolylinesToFlutterPolylines(),
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
          // Map provider toggle button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _useGoogleMaps ? Icons.map : Icons.satellite,
                color: AppColors.primary,
              ),
              onPressed: () {
                setState(() {
                  _useGoogleMaps = !_useGoogleMaps;
                });
              },
              tooltip: _useGoogleMaps
                  ? 'Switch to OpenStreetMap'
                  : 'Switch to Google Maps',
            ),
          ),
          const SizedBox(height: 8),

          // Zoom controls
          if (widget.enableInteraction) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, color: AppColors.primary),
                    onPressed: _zoomIn,
                    tooltip: 'Zoom In',
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  IconButton(
                    icon: const Icon(Icons.remove, color: AppColors.primary),
                    onPressed: _zoomOut,
                    tooltip: 'Zoom Out',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Current location button
          if (widget.showCurrentLocation)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.my_location, color: AppColors.primary),
                onPressed: _goToCurrentLocation,
                tooltip: 'Go to Current Location',
              ),
            ),
        ],
      ),
    );
  }

  void _zoomIn() {
    if (_useGoogleMaps) {
      _googleMapController?.animateCamera(gmaps.CameraUpdate.zoomIn());
    } else {
      // For FlutterMap, we'll use a simple zoom approach
      // Note: FlutterMap v6+ has different API
    }
  }

  void _zoomOut() {
    if (_useGoogleMaps) {
      _googleMapController?.animateCamera(gmaps.CameraUpdate.zoomOut());
    } else {
      // For FlutterMap, we'll use a simple zoom approach
      // Note: FlutterMap v6+ has different API
    }
  }

  void _goToCurrentLocation() {
    // This would typically involve getting current location from location service
    // For now, we'll center on Delhi, India
    const target = gmaps.LatLng(28.6139, 77.2090);

    if (_useGoogleMaps) {
      _googleMapController?.animateCamera(gmaps.CameraUpdate.newLatLng(target));
    } else {
      // For FlutterMap, we'll use a simple move approach
      // Note: FlutterMap v6+ has different API
    }
  }

  List<fmap.Marker> _convertGoogleMarkersToFlutterMarkers() {
    if (widget.markers == null) return [];

    return widget.markers!.map((googleMarker) {
      return fmap.Marker(
        width: 40,
        height: 40,
        point: latLng.LatLng(
          googleMarker.position.latitude,
          googleMarker.position.longitude,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.location_pin, color: Colors.white, size: 24),
        ),
      );
    }).toList();
  }

  List<fmap.Polyline> _convertGooglePolylinesToFlutterPolylines() {
    if (widget.polylines == null) return [];

    return widget.polylines!.map((googlePolyline) {
      return fmap.Polyline(
        points: googlePolyline.points
            .map((point) => latLng.LatLng(point.latitude, point.longitude))
            .toList(),
        color: googlePolyline.color,
        strokeWidth: googlePolyline.width.toDouble(),
      );
    }).toList();
  }
}

/// Simplified map widget for basic use cases
class SimpleMapWidget extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? title;
  final String? description;

  const SimpleMapWidget({
    Key? key,
    required this.latitude,
    required this.longitude,
    this.title,
    this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      latitude: latitude,
      longitude: longitude,
      markers: {
        gmaps.Marker(
          markerId: const gmaps.MarkerId('location'),
          position: gmaps.LatLng(latitude, longitude),
          infoWindow: gmaps.InfoWindow(
            title: title ?? 'Location',
            snippet: description,
          ),
        ),
      },
      enableInteraction: false,
      showCurrentLocation: false,
    );
  }
}
