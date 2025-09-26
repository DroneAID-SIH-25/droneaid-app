import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../../models/drone.dart' as DroneModel;
import '../../providers/map_provider.dart';
import '../../providers/drone_tracking_provider.dart' as DroneTracking;
import '../../widgets/map/help_seeker_map_widget.dart';
import '../../widgets/map/map_utils.dart';
import '../../widgets/common/loading_indicator.dart';

/// Enhanced map tracking screen for help seekers with comprehensive drone tracking
class EnhancedMapTrackingScreen extends StatefulWidget {
  final String? emergencyRequestId;

  const EnhancedMapTrackingScreen({Key? key, this.emergencyRequestId})
    : super(key: key);

  @override
  State<EnhancedMapTrackingScreen> createState() =>
      _EnhancedMapTrackingScreenState();
}

class _EnhancedMapTrackingScreenState extends State<EnhancedMapTrackingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  bool _showDroneList = false;
  bool _isTrackingEnabled = true;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Available', 'Deployed', 'Nearby'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );

    _initializeMapProvider();
  }

  Future<void> _initializeMapProvider() async {
    if (_isTrackingEnabled) {
      // mapProvider.startLocationTracking();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Consumer<MapProvider>(
        builder: (context, mapProvider, child) {
          if (mapProvider.isLoading) {
            return const LoadingIndicator(
              message: 'Loading drone tracking system...',
            );
          }

          if (mapProvider.errorMessage != null) {
            return _buildErrorWidget(mapProvider);
          }

          return Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMapTab(mapProvider),
                    _buildDroneListTab(mapProvider),
                    _buildStatsTab(mapProvider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButtons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Drone Tracking'),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        Consumer<MapProvider>(
          builder: (context, mapProvider, child) {
            return IconButton(
              icon: Icon(
                mapProvider.isRealTimeEnabled
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
              ),
              onPressed: mapProvider.toggleRealTimeUpdates,
              tooltip: mapProvider.isRealTimeEnabled
                  ? 'Pause updates'
                  : 'Resume updates',
            );
          },
        ),
        IconButton(
          icon: Icon(_isTrackingEnabled ? Icons.gps_fixed : Icons.gps_off),
          onPressed: _toggleLocationTracking,
          tooltip: 'Toggle location tracking',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuSelection,
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'refresh', child: Text('Refresh')),
            const PopupMenuItem(value: 'settings', child: Text('Settings')),
            const PopupMenuItem(value: 'help', child: Text('Help')),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).primaryColor,
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(icon: Icon(Icons.map), text: 'Map'),
          Tab(icon: Icon(Icons.flight), text: 'Drones'),
          Tab(icon: Icon(Icons.analytics), text: 'Stats'),
        ],
      ),
    );
  }

  Widget _buildMapTab(MapProvider mapProvider) {
    return Stack(
      children: [
        HelpSeekerMapWidget(
          height: double.infinity,
          showControls: true,
          showGeofenceToggle: true,
          showDroneDetails: true,
          onDroneSelected: _onDroneSelectedWrapper,
          onEmergencyPressed: _showEmergencyDialog,
        ),
        _buildMapOverlays(mapProvider),
      ],
    );
  }

  Widget _buildMapOverlays(MapProvider mapProvider) {
    return Stack(
      children: [
        // Filter bar
        Positioned(
          top: 10,
          left: 10,
          right: 80,
          child: _buildFilterBar(mapProvider),
        ),
        // Quick stats
        if (mapProvider.userLocation != null)
          Positioned(top: 70, left: 10, child: _buildQuickStats(mapProvider)),
        // Emergency request info
        if (widget.emergencyRequestId != null)
          Positioned(
            bottom: 100,
            left: 10,
            right: 10,
            child: _buildEmergencyRequestCard(mapProvider),
          ),
      ],
    );
  }

  Widget _buildFilterBar(MapProvider mapProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.filter_list, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'Filter:',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFilter,
                  isDense: true,
                  items: _filters.map((filter) {
                    return DropdownMenuItem(
                      value: filter,
                      child: Text(filter, style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value ?? 'All';
                    });
                    _applyFilter(mapProvider, _selectedFilter);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(MapProvider mapProvider) {
    final dronesInRange = mapProvider.dronesInGeofence;
    final availableDrones = dronesInRange
        .where(
          (d) =>
              d.status == DroneTracking.DroneStatus.active ||
              d.status == DroneTracking.DroneStatus.standby,
        )
        .length;
    final deployedDrones = dronesInRange
        .where((d) => d.assignedMission != null)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nearby Drones',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              Icons.flight_takeoff,
              'Available',
              availableDrones.toString(),
              Colors.green,
            ),
            _buildStatRow(
              Icons.flight,
              'Deployed',
              deployedDrones.toString(),
              Colors.blue,
            ),
            _buildStatRow(
              Icons.radar,
              'In Range',
              dronesInRange.length.toString(),
              Colors.orange,
            ),
            const SizedBox(height: 8),
            Text(
              'Range: ${MapUtils.formatDistance(mapProvider.geofenceRadius)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyRequestCard(MapProvider mapProvider) {
    // Find emergency request by ID
    final request = mapProvider.emergencyRequests
        .where((r) => r.id == widget.emergencyRequestId)
        .firstOrNull;

    if (request == null) return const SizedBox.shrink();

    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.emergency, color: Colors.red, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency Request',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        request.description,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildRequestDetailChip(
                  'Urgency',
                  request.priority.displayName,
                  MapUtils.getEmergencyColor(
                    request.priority.displayName.toLowerCase(),
                  ),
                ),
                const SizedBox(width: 8),
                _buildRequestDetailChip(
                  'Status',
                  request.status.displayName,
                  _getRequestStatusColor(request.status.displayName),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestDetailChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 12, color: color)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDroneListTab(MapProvider mapProvider) {
    final filteredDrones = _getFilteredDrones(mapProvider);

    return Column(
      children: [
        _buildDroneListHeader(filteredDrones.length),
        Expanded(
          child: filteredDrones.isEmpty
              ? _buildEmptyDroneList()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDrones.length,
                  itemBuilder: (context, index) {
                    final drone = filteredDrones[index];
                    return _buildDroneCard(drone, mapProvider);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDroneListHeader(int droneCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.flight, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Text(
            '$droneCount Drone${droneCount == 1 ? '' : 's'} Found',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<MapProvider>().initialize(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDroneList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flight_takeoff, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Drones Found',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or location',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildDroneCard(
    DroneTracking.DroneInfo drone,
    MapProvider mapProvider,
  ) {
    final isSelected = mapProvider.selectedDrone == drone.id;
    final distance = mapProvider.getDistanceToUser(drone.position);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 8 : 2,
      child: InkWell(
        onTap: () {
          // Handle drone selection
          mapProvider.selectDroneById(drone.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getBatteryColor(drone.batteryLevel),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                          'Drone Model',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getDroneStatusColor(
                            drone.status,
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          drone.status.toString().split('.').last,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getDroneStatusColor(drone.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildDroneInfoChip(
                    Icons.battery_std,
                    '${drone.batteryLevel.toInt()}%',
                    _getBatteryColor(drone.batteryLevel),
                  ),
                  const SizedBox(width: 8),
                  _buildDroneInfoChip(
                    Icons.straighten,
                    '${distance.toStringAsFixed(1)}km',
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildDroneInfoChip(Icons.access_time, '5 min', Colors.green),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Capabilities: Search, Rescue',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDroneInfoChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab(MapProvider mapProvider) {
    final stats = mapProvider.getDroneStatistics();
    final missionStats = mapProvider.getMissionStatistics();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsSection('Drone Fleet Statistics', Icons.flight, stats),
          const SizedBox(height: 24),
          _buildStatsSection(
            'Mission Statistics',
            Icons.assignment,
            missionStats,
          ),
          const SizedBox(height: 24),
          _buildLocationStats(mapProvider),
          const SizedBox(height: 24),
          _buildSystemStatus(mapProvider),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
    String title,
    IconData icon,
    Map<String, dynamic> stats,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...stats.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        entry.value.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
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

  Widget _buildLocationStats(MapProvider mapProvider) {
    final userLocation = mapProvider.userLocation;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.my_location, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Location Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (userLocation != null) ...[
              _buildLocationRow(
                'Latitude',
                userLocation.latitude.toStringAsFixed(6),
              ),
              _buildLocationRow(
                'Longitude',
                userLocation.longitude.toStringAsFixed(6),
              ),
              _buildLocationRow('Accuracy', 'Unknown'),
              _buildLocationRow(
                'Geofence Radius',
                MapUtils.formatDistance(mapProvider.geofenceRadius),
              ),
              _buildLocationRow(
                'Tracking Status',
                mapProvider.isTrackingLocation ? 'Active' : 'Inactive',
              ),
            ] else
              const Text('Location not available'),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSystemStatus(MapProvider mapProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text(
                  'System Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusRow(
              'Real-time Updates',
              mapProvider.isRealTimeEnabled ? 'Enabled' : 'Disabled',
              mapProvider.isRealTimeEnabled ? Colors.green : Colors.red,
            ),
            _buildStatusRow(
              'Location Services',
              mapProvider.isLocationEnabled ? 'Enabled' : 'Disabled',
              mapProvider.isLocationEnabled ? Colors.green : Colors.red,
            ),
            _buildStatusRow(
              'Update Interval',
              '${mapProvider.updateIntervalSeconds}s',
              Colors.blue,
            ),
            _buildStatusRow('Connection Status', 'Connected', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_tabController.index == 0) ...[
          FloatingActionButton(
            heroTag: "emergency_fab",
            backgroundColor: Colors.red,
            onPressed: _showEmergencyDialog,
            child: const Icon(Icons.emergency, color: Colors.white),
          ),
          const SizedBox(height: 16),
        ],
        FloatingActionButton(
          heroTag: "toggle_list_fab",
          backgroundColor: Theme.of(context).primaryColor,
          onPressed: _toggleDroneList,
          child: Icon(
            _showDroneList ? Icons.map : Icons.list,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(MapProvider mapProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Map',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.red[700]),
            ),
            const SizedBox(height: 8),
            Text(
              mapProvider.errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => mapProvider.initialize(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // Event handlers
  void _onDroneSelectedWrapper(DroneModel.Drone drone) {
    final mapProvider = context.read<MapProvider>();
    mapProvider.selectDroneById(drone.id);

    if (_tabController.index != 0) {
      _tabController.animateTo(0);
    }
  }

  void _onDroneSelected(DroneTracking.DroneInfo drone) {
    final mapProvider = context.read<MapProvider>();
    mapProvider.selectDroneById(drone.id);

    if (_tabController.index != 0) {
      _tabController.animateTo(0);
    }
  }

  void _toggleLocationTracking() async {
    final mapProvider = context.read<MapProvider>();

    setState(() {
      _isTrackingEnabled = !_isTrackingEnabled;
    });

    if (_isTrackingEnabled) {
      // await mapProvider.startLocationTracking();
    } else {
      mapProvider.stopLocationTracking();
    }
  }

  void _toggleDroneList() {
    setState(() {
      _showDroneList = !_showDroneList;
    });

    if (_showDroneList) {
      _tabController.animateTo(1);
    } else {
      _tabController.animateTo(0);
    }
  }

  void _applyFilter(MapProvider mapProvider, String filter) {
    // Filter logic can be implemented based on requirements
    switch (filter) {
      case 'Available':
        // Show only available drones
        break;
      case 'Deployed':
        // Show only deployed drones
        break;
      case 'Nearby':
        // Show only nearby drones
        break;
      default:
        // Show all drones
        break;
    }
  }

  List<DroneTracking.DroneInfo> _getFilteredDrones(MapProvider mapProvider) {
    List<DroneTracking.DroneInfo> drones = mapProvider.filteredDrones;

    switch (_selectedFilter) {
      case 'Available':
        return drones
            .where((d) => d.status == DroneTracking.DroneStatus.active)
            .toList();
      case 'Deployed':
        return drones.where((d) => d.assignedMission != null).toList();
      case 'Nearby':
        return mapProvider.dronesInGeofence;
      default:
        return drones;
    }
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency Request'),
          ],
        ),
        content: const Text(
          'Do you want to send an emergency request to nearby drones?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _sendEmergencyRequest();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Send Request',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _sendEmergencyRequest() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency request sent to nearby drones'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'refresh':
        context.read<MapProvider>().initialize();
        break;
      case 'settings':
        _showSettingsDialog();
        break;
      case 'help':
        _showHelpDialog();
        break;
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Settings'),
        content: Consumer<MapProvider>(
          builder: (context, mapProvider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Real-time Updates'),
                  trailing: Switch(
                    value: mapProvider.isRealTimeEnabled,
                    onChanged: (_) => mapProvider.toggleRealTimeUpdates(),
                  ),
                ),
                ListTile(
                  title: const Text('Show Geofence'),
                  trailing: Switch(
                    value: mapProvider.showGeofence,
                    onChanged: (_) => mapProvider.toggleGeofence(),
                  ),
                ),
                ListTile(
                  title: const Text('Show Routes'),
                  trailing: Switch(
                    value: mapProvider.showRoutes,
                    onChanged: (_) => mapProvider.toggleRoutes(),
                  ),
                ),
                ListTile(
                  title: const Text('Geofence Radius'),
                  subtitle: Slider(
                    value: mapProvider.geofenceRadius / 1000,
                    min: 0.5,
                    max: 5.0,
                    divisions: 9,
                    label:
                        '${(mapProvider.geofenceRadius / 1000).toStringAsFixed(1)}km',
                    onChanged: (value) =>
                        mapProvider.updateGeofenceRadius(value * 1000),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Map Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Blue circle: Your location'),
              Text('• Colored circles: Nearby drones'),
              Text('• Dotted circle: Geofence area'),
              Text('• Red markers: Emergency requests'),
              SizedBox(height: 16),
              Text('Controls:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Tap drone markers for details'),
              Text('• Use + and - to zoom'),
              Text('• Tap location button to center on you'),
              Text('• Toggle geofence with the radar button'),
              SizedBox(height: 16),
              Text(
                'Drone Status Colors:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Green: Available'),
              Text('• Blue: Deployed on mission'),
              Text('• Orange: Under maintenance'),
              Text('• Yellow: Charging'),
              Text('• Red: Emergency'),
              Text('• Gray: Offline'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Color _getRequestStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getBatteryColor(double batteryLevel) {
    if (batteryLevel > 75) {
      return Colors.green;
    } else if (batteryLevel > 50) {
      return Colors.orange;
    } else if (batteryLevel > 25) {
      return Colors.deepOrange;
    } else {
      return Colors.red;
    }
  }

  Color _getDroneStatusColor(DroneTracking.DroneStatus status) {
    switch (status) {
      case DroneTracking.DroneStatus.active:
        return Colors.green;
      case DroneTracking.DroneStatus.standby:
        return Colors.blue;
      case DroneTracking.DroneStatus.maintenance:
        return Colors.orange;
      case DroneTracking.DroneStatus.charging:
        return Colors.yellow;
      case DroneTracking.DroneStatus.offline:
        return Colors.grey;
    }
  }
}
