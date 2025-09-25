import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';

import '../../core/widgets/map_widget.dart' as map_widget;
import '../../providers/group_management_provider.dart';
import '../../models/group_event.dart';
import '../../models/gcs_station.dart';
import '../../services/location_service.dart';
import '../../models/user.dart';

class GCSMapScreen extends StatefulWidget {
  const GCSMapScreen({super.key});

  @override
  State<GCSMapScreen> createState() => _GCSMapScreenState();
}

class _GCSMapScreenState extends State<GCSMapScreen>
    with AutomaticKeepAliveClientMixin {
  List<map_widget.MapMarker> _markers = [];
  List<map_widget.MapCircle> _circles = [];
  bool _showEvents = true;
  bool _showStations = true;
  EventType? _eventTypeFilter;
  StationStatus? _stationStatusFilter;

  // Default center on India
  static const double _defaultLatitude = 20.5937; // Center of India
  static const double _defaultLongitude = 78.9629;
  static const double _defaultZoom = 5.0;

  // Location service
  final LocationService _locationService = LocationService();
  LocationData? _currentLocation;
  bool _locationLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMapMarkers();
    });
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

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Consumer<GroupManagementProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildFilterBar(provider),
              Expanded(
                child: Stack(
                  children: [
                    map_widget.MapWidget(
                      latitude: _currentLocation?.latitude ?? _defaultLatitude,
                      longitude:
                          _currentLocation?.longitude ?? _defaultLongitude,
                      zoom: _currentLocation != null ? 12.0 : _defaultZoom,
                      markers: _markers,
                      circles: _circles,
                      showCurrentLocation: _currentLocation != null,
                      showZoomControls: true,
                      showLocationButton: true,
                      onMapCreated: () {
                        _updateMapMarkers();
                      },
                      onTap: (LatLng position) {
                        _showLocationInfo(position);
                      },
                    ),
                    _buildMapControls(),
                    _buildLegend(),
                    _buildStatsOverlay(provider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(GroupManagementProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildToggleChip(
                    label: 'Events',
                    isSelected: _showEvents,
                    onTap: () {
                      setState(() {
                        _showEvents = !_showEvents;
                      });
                      _updateMapMarkers();
                    },
                    icon: Icons.event,
                  ),
                  const SizedBox(width: 8),
                  _buildToggleChip(
                    label: 'Stations',
                    isSelected: _showStations,
                    onTap: () {
                      setState(() {
                        _showStations = !_showStations;
                      });
                      _updateMapMarkers();
                    },
                    icon: Icons.location_city,
                  ),
                  const SizedBox(width: 16),
                  _buildFilterDropdown<EventType>(
                    label: 'Event Type',
                    value: _eventTypeFilter,
                    items: EventType.values,
                    itemBuilder: (type) => type.displayName,
                    onChanged: (type) {
                      setState(() {
                        _eventTypeFilter = type;
                      });
                      _updateMapMarkers();
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterDropdown<StationStatus>(
                    label: 'Station Status',
                    value: _stationStatusFilter,
                    items: StationStatus.values,
                    itemBuilder: (status) => status.displayName,
                    onChanged: (status) {
                      setState(() {
                        _stationStatusFilter = status;
                      });
                      _updateMapMarkers();
                    },
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _eventTypeFilter = null;
                _stationStatusFilter = null;
                _showEvents = true;
                _showStations = true;
              });
              _updateMapMarkers();
            },
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Filters',
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[700]
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyMedium?.color ??
                          AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemBuilder,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<T>(
        value: value,
        hint: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        underline: const SizedBox(),
        dropdownColor: Theme.of(context).cardColor,
        items: [
          DropdownMenuItem<T>(
            value: null,
            child: Text(
              'All ${label}s',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          ...items.map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemBuilder(item),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ),
        ],
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        icon: Icon(
          Icons.arrow_drop_down,
          color: Theme.of(context).iconTheme.color,
        ),
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
            heroTag: "gcs_map_location_fab",
            onPressed: _locationLoading ? null : _centerOnIndia,
            backgroundColor: Theme.of(context).cardColor,
            foregroundColor: _currentLocation != null
                ? AppColors.primary
                : Colors.grey,
            child: _locationLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Positioned(
      left: 16,
      bottom: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border.withOpacity(0.3)),
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
            const Text(
              'Legend',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            _buildLegendItem(Icons.event, 'Critical Event', AppColors.error),
            _buildLegendItem(Icons.warning, 'Major Event', AppColors.warning),
            _buildLegendItem(Icons.info, 'Minor Event', AppColors.info),
            _buildLegendItem(
              Icons.location_city,
              'GCS Station',
              AppColors.primary,
            ),
            _buildLegendItem(
              Icons.radio_button_unchecked,
              'Affected Area',
              AppColors.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildStatsOverlay(GroupManagementProvider provider) {
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
            const Text(
              'Live Stats',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            _buildStatItem(
              'Active Events',
              provider.totalActiveEvents,
              AppColors.warning,
            ),
            _buildStatItem(
              'Critical Events',
              provider.totalCriticalEvents,
              AppColors.error,
            ),
            _buildStatItem(
              'Operational Stations',
              provider.totalOperationalStations,
              AppColors.success,
            ),
            _buildStatItem(
              'Available Stations',
              provider.totalAvailableStations,
              AppColors.info,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 11)),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _updateMapMarkers() {
    final provider = context.read<GroupManagementProvider>();
    final List<map_widget.MapMarker> markers = [];
    final List<map_widget.MapCircle> circles = [];

    // Add event markers
    if (_showEvents) {
      var events = provider.events;
      if (_eventTypeFilter != null) {
        events = events
            .where((event) => event.type == _eventTypeFilter)
            .toList();
      }

      for (final event in events) {
        final color = _getEventColor(event);
        markers.add(
          map_widget.MapMarker(
            position: LatLng(event.location.latitude, event.location.longitude),
            child: GestureDetector(
              onTap: () => _showEventDetails(event),
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
                child: Icon(
                  _getEventIcon(event),
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        );

        // Add affected area circle
        // Validate and clamp radius before creating circle
        double radiusInMeters = (event.affectedRadius * 1000).clamp(
          1.0,
          50000.0,
        );

        circles.add(
          map_widget.MapCircle(
            center: LatLng(event.location.latitude, event.location.longitude),
            radius: radiusInMeters, // Convert km to meters with validation
            color: color.withValues(alpha: 0.1),
            borderColor: color.withValues(alpha: 0.5),
            borderWidth: 2,
          ),
        );
      }
    }

    // Add station markers
    if (_showStations) {
      var stations = provider.gcsStations;
      if (_stationStatusFilter != null) {
        stations = stations
            .where((station) => station.status == _stationStatusFilter)
            .toList();
      }

      for (final station in stations) {
        markers.add(
          map_widget.MapMarker(
            position: LatLng(
              station.coordinates.latitude,
              station.coordinates.longitude,
            ),
            child: GestureDetector(
              onTap: () => _showStationDetails(station),
              child: map_widget.EmergencyMarkers.gcsStation(
                position: LatLng(
                  station.coordinates.latitude,
                  station.coordinates.longitude,
                ),
                onTap: () => _showStationDetails(station),
              ).child,
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
      _circles = circles;
    });
  }

  IconData _getEventIcon(GroupEvent event) {
    switch (event.type) {
      case EventType.flood:
        return Icons.water;
      case EventType.fireIncident:
        return Icons.local_fire_department;
      case EventType.earthquake:
        return Icons.warning;
      case EventType.tornado:
        return Icons.tornado;
      case EventType.landslide:
        return Icons.terrain;
      case EventType.industrialAccident:
        return Icons.car_crash;
      case EventType.naturalDisaster:
        return Icons.emergency;
      case EventType.hurricane:
        return Icons.cyclone;
      case EventType.tsunami:
        return Icons.waves;
      case EventType.volcanicEruption:
        return Icons.volcano;
      case EventType.chemicalSpill:
        return Icons.science;
      case EventType.buildingCollapse:
        return Icons.business;
      case EventType.other:
        return Icons.emergency;
      default:
        return Icons.emergency;
    }
  }

  Color _getEventColor(GroupEvent event) {
    switch (event.severity) {
      case EventSeverity.critical:
        return AppColors.error;
      case EventSeverity.major:
        return Colors.deepOrange;
      case EventSeverity.moderate:
        return Colors.orange;
      case EventSeverity.minor:
        return AppColors.info;
    }
  }

  Color _getStationColor(GCSStation station) {
    switch (station.status) {
      case StationStatus.operational:
        return AppColors.success;
      case StationStatus.maintenance:
        return AppColors.warning;
      case StationStatus.offline:
        return AppColors.error;
      case StationStatus.emergency:
        return Colors.purple;
      case StationStatus.standby:
        return AppColors.info;
    }
  }

  void _centerOnIndia() async {
    if (_currentLocation != null) {
      // If we have current location, center on it
      setState(() {
        // This would trigger a map center update to current location
      });
    } else {
      // Try to get current location first
      await _getCurrentLocation();
      if (_currentLocation == null) {
        // Fallback to centering on India
        setState(() {
          // Center map on India using default coordinates
        });
      }
    }
  }

  void _showLocationInfo(LatLng position) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Location Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Coordinates'),
              subtitle: Text(
                '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to create event with this location
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Event'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDetails(GroupEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildEventDetailItem('Type', event.typeDisplay),
                    _buildEventDetailItem('Status', event.statusDisplay),
                    _buildEventDetailItem('Severity', event.severityDisplay),
                    _buildEventDetailItem('Priority', event.priorityDisplay),
                    _buildEventDetailItem(
                      'Location',
                      event.location.address ?? 'Unknown',
                    ),
                    _buildEventDetailItem(
                      'Affected Radius',
                      '${event.affectedRadius} km',
                    ),
                    _buildEventDetailItem(
                      'Estimated Affected People',
                      event.estimatedAffectedPeople.toString(),
                    ),
                    _buildEventDetailItem(
                      'Assigned Operators',
                      event.assignedOperators.length.toString(),
                    ),
                    _buildEventDetailItem(
                      'Created',
                      _formatDateTime(event.createdAt),
                    ),
                    if (event.coordinatingAgency != null)
                      _buildEventDetailItem(
                        'Coordinating Agency',
                        event.coordinatingAgency!,
                      ),
                    if (event.contactPerson != null)
                      _buildEventDetailItem(
                        'Contact Person',
                        event.contactPerson!,
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(event.description),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStationDetails(GCSStation station) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      station.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildEventDetailItem('Code', station.code),
                    _buildEventDetailItem('Status', station.statusDisplay),
                    _buildEventDetailItem('Type', station.typeDisplay),
                    _buildEventDetailItem('Location', station.location),
                    _buildEventDetailItem(
                      'Capacity',
                      '${station.currentOperators}/${station.maxCapacity}',
                    ),
                    _buildEventDetailItem(
                      'Assigned Events',
                      station.assignedEvents.toString(),
                    ),
                    _buildEventDetailItem(
                      'Contact Email',
                      station.contactEmail,
                    ),
                    _buildEventDetailItem(
                      'Contact Phone',
                      station.contactPhone,
                    ),
                    if (station.description != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(station.description!),
                    ],
                    if (station.certifications.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Certifications',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: station.certifications
                            .map(
                              (cert) => Chip(
                                label: Text(
                                  cert,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: AppColors.primary.withOpacity(
                                  0.1,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
