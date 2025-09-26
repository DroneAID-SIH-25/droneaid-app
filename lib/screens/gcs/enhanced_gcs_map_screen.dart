import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/drone.dart' as DroneModel;
import '../../models/mission.dart';
import '../../models/gcs_station.dart';
import '../../models/user.dart';
import '../../providers/map_provider.dart';
import '../../providers/drone_tracking_provider.dart';
import '../../widgets/map/gcs_map_widget.dart';
import '../../widgets/map/map_utils.dart';
import '../../widgets/common/loading_indicator.dart';

/// Enhanced GCS map screen with comprehensive mission overview and route optimization
class EnhancedGCSMapScreen extends StatefulWidget {
  const EnhancedGCSMapScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedGCSMapScreen> createState() => _EnhancedGCSMapScreenState();
}

class _EnhancedGCSMapScreenState extends State<EnhancedGCSMapScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabAnimationController;

  bool _showSidebar = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _initializeMapProvider();
  }

  Future<void> _initializeMapProvider() async {
    final mapProvider = context.read<MapProvider>();
    mapProvider.initialize();
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
              message: 'Loading GCS mission overview...',
            );
          }

          if (mapProvider.errorMessage != null) {
            return _buildErrorWidget(mapProvider);
          }

          return Row(
            children: [
              if (_showSidebar) _buildSidebar(mapProvider),
              Expanded(
                child: Column(
                  children: [
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(mapProvider),
                          _buildMissionsTab(mapProvider),
                          _buildFleetTab(mapProvider),
                          _buildCoverageTab(mapProvider),
                        ],
                      ),
                    ),
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
      title: const Text('GCS Command Center'),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        Consumer<MapProvider>(
          builder: (context, mapProvider, child) {
            return Row(
              children: [
                IconButton(
                  icon: Icon(
                    mapProvider.isRealTimeEnabled
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                  ),
                  onPressed: mapProvider.toggleRealTimeUpdates,
                  tooltip: mapProvider.isRealTimeEnabled
                      ? 'Pause real-time updates'
                      : 'Resume real-time updates',
                ),
                IconButton(
                  icon: Icon(
                    _showSidebar ? Icons.close_fullscreen : Icons.open_in_full,
                  ),
                  onPressed: () => setState(() => _showSidebar = !_showSidebar),
                  tooltip: 'Toggle sidebar',
                ),
                PopupMenuButton<String>(
                  onSelected: _handleMenuSelection,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'optimize',
                      child: Text('Optimize Routes'),
                    ),
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Text('Refresh Data'),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: Text('Export Report'),
                    ),
                    const PopupMenuItem(
                      value: 'settings',
                      child: Text('Settings'),
                    ),
                  ],
                ),
              ],
            );
          },
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
          Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
          Tab(icon: Icon(Icons.assignment), text: 'Missions'),
          Tab(icon: Icon(Icons.flight), text: 'Fleet'),
          Tab(icon: Icon(Icons.radar), text: 'Coverage'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(MapProvider mapProvider) {
    return Stack(
      children: [
        GCSMapWidget(
          height: double.infinity,
          showControls: true,
          showLegend: true,
          showStats: true,
          onMissionSelected: _onMissionSelected,
          onDroneSelected: _onDroneSelected,
          onStationSelected: _onStationSelected,
          onCreateMissionPressed: _showCreateMissionDialog,
        ),
        _buildOverviewOverlays(mapProvider),
      ],
    );
  }

  Widget _buildOverviewOverlays(MapProvider mapProvider) {
    return Stack(
      children: [
        // Mission queue
        Positioned(top: 10, right: 10, child: _buildMissionQueue(mapProvider)),
        // Active alerts
        if (_hasActiveAlerts(mapProvider))
          Positioned(
            bottom: 100,
            left: 10,
            right: 10,
            child: _buildActiveAlerts(mapProvider),
          ),
      ],
    );
  }

  Widget _buildMissionQueue(MapProvider mapProvider) {
    final pendingMissions = mapProvider.missions
        .where((m) => m.status == MissionStatus.assigned)
        .take(3)
        .toList();

    if (pendingMissions.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.queue, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Mission Queue',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...pendingMissions.map(
              (mission) => _buildMissionQueueItem(mission),
            ),
            if (mapProvider.missions
                    .where((m) => m.status == MissionStatus.assigned)
                    .length >
                3)
              TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: Text(
                  'View All (${mapProvider.missions.where((m) => m.status == MissionStatus.assigned).length})',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionQueueItem(Mission mission) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MapUtils.getMissionPriorityColor(mission.priority),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  mission.priorityDisplay,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MapUtils.getMissionPriorityColor(mission.priority),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAlerts(MapProvider mapProvider) {
    final alerts = _getActiveAlerts(mapProvider);

    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'Active Alerts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...alerts.map(
              (alert) => Text(
                '• $alert',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionsTab(MapProvider mapProvider) {
    return Column(
      children: [
        _buildMissionFilters(mapProvider),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: GCSMapWidget(
                  height: double.infinity,
                  showControls: true,
                  showLegend: false,
                  showStats: false,
                  onMissionSelected: _onMissionSelected,
                  onDroneSelected: _onDroneSelected,
                  onStationSelected: _onStationSelected,
                  onCreateMissionPressed: _showCreateMissionDialog,
                ),
              ),
              Expanded(flex: 1, child: _buildMissionsList(mapProvider)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMissionFilters(MapProvider mapProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        children: [
          Icon(Icons.filter_list, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('Filters:', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 16),
          _buildFilterChip(
            'All',
            mapProvider.missionStatusFilter.length ==
                MissionStatus.values.length,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Pending',
            mapProvider.missionStatusFilter.contains(MissionStatus.assigned),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Active',
            mapProvider.missionStatusFilter.contains(MissionStatus.inProgress),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Critical',
            mapProvider.priorityFilter == MissionPriority.critical,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => mapProvider.initialize(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isActive) {
    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (selected) => _applyMissionFilter(label, selected),
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildMissionsList(MapProvider mapProvider) {
    final missions = mapProvider.filteredMissions;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(left: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor,
            child: Row(
              children: [
                const Icon(Icons.assignment, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Missions (${missions.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: missions.length,
              itemBuilder: (context, index) {
                final mission = missions[index];
                final isSelected =
                    mapProvider.selectedMission?.id == mission.id;

                return Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : null,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      MapUtils.getMissionTypeIcon(mission.type),
                      color: MapUtils.getMissionPriorityColor(mission.priority),
                    ),
                    title: Text(
                      mission.title,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mission.statusDisplay),
                        Text(
                          mission.priorityDisplay,
                          style: TextStyle(
                            color: MapUtils.getMissionPriorityColor(
                              mission.priority,
                            ),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _onMissionSelected(mission),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFleetTab(MapProvider mapProvider) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: GCSMapWidget(
            height: double.infinity,
            showControls: true,
            showLegend: false,
            showStats: false,
            onMissionSelected: _onMissionSelected,
            onDroneSelected: _onDroneSelected,
            onStationSelected: _onStationSelected,
            onCreateMissionPressed: _showCreateMissionDialog,
          ),
        ),
        Expanded(flex: 1, child: _buildFleetPanel(mapProvider)),
      ],
    );
  }

  Widget _buildFleetPanel(MapProvider mapProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(left: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor,
            child: Row(
              children: [
                const Icon(Icons.flight, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Drone Fleet',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildFleetStats(mapProvider),
                ...mapProvider.filteredDrones.map(
                  (drone) => _buildDroneListItem(drone, mapProvider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFleetStats(MapProvider mapProvider) {
    final stats = mapProvider.getDroneStatistics();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fleet Status',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...stats.entries.map(
              (entry) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key, style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    entry.value.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDroneListItem(DroneInfo drone, MapProvider mapProvider) {
    final isSelected = mapProvider.selectedDrone == drone.id;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : null,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: ListTile(
        leading: Stack(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getDroneStatusColor(drone.status),
              ),
              child: const Icon(Icons.flight, color: Colors.white, size: 20),
            ),
            if (drone.batteryLevel < 20)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                  child: const Icon(
                    Icons.battery_alert,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          drone.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${drone.status.toString().split('.').last} • ${drone.batteryLevel.toInt()}%',
              style: const TextStyle(fontSize: 12),
            ),
            if (drone.assignedMission != null)
              Text(
                'Mission: ${drone.assignedMission?.substring(0, 8)}...',
                style: TextStyle(fontSize: 10, color: Colors.blue[600]),
              ),
          ],
        ),
        onTap: () => _onDroneSelected(
          DroneModel.Drone(
            id: drone.id,
            name: drone.name,
            model: 'DJI Model',
            location: LocationData(
              latitude: drone.position.latitude,
              longitude: drone.position.longitude,
            ),
            maxFlightTime: 30,
            maxRange: 10.0,
            payloadCapacity: 5.0,
            capabilities: ['search', 'rescue'],
            batteryLevel: drone.batteryLevel.toInt(),
            status: DroneModel.DroneStatus.active,
          ),
        ),
      ),
    );
  }

  Widget _buildCoverageTab(MapProvider mapProvider) {
    return Stack(
      children: [
        GCSMapWidget(
          height: double.infinity,
          showControls: true,
          showLegend: true,
          showStats: false,
          onMissionSelected: _onMissionSelected,
          onDroneSelected: _onDroneSelected,
          onStationSelected: _onStationSelected,
          onCreateMissionPressed: _showCreateMissionDialog,
        ),
        Positioned(top: 10, left: 10, child: _buildCoverageStats(mapProvider)),
      ],
    );
  }

  Widget _buildCoverageStats(MapProvider mapProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Coverage Analysis',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildCoverageItem(
              'Active Stations',
              '${mapProvider.gcsStations.length}',
              Icons.radio_button_checked,
            ),
            _buildCoverageItem(
              'Total Range',
              '${mapProvider.totalCoverageRadius}km',
              Icons.radar,
            ),
            _buildCoverageItem(
              'Coverage Gaps',
              '2 areas',
              Icons.warning,
              Colors.orange,
            ),
            _buildCoverageItem(
              'Response Time',
              '3.2 min avg',
              Icons.access_time,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverageItem(
    String label,
    String value,
    IconData icon, [
    Color? color,
  ]) {
    final itemColor = color ?? Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: itemColor),
          const SizedBox(width: 8),
          Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: itemColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(MapProvider mapProvider) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(right: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor,
            child: Row(
              children: [
                const Icon(Icons.dashboard, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'Control Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => _showSidebar = false),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildSidebarSection('Quick Actions', [
                  _buildSidebarAction(
                    'Create Mission',
                    Icons.add_location,
                    _showCreateMissionDialog,
                  ),
                  _buildSidebarAction(
                    'Deploy Drone',
                    Icons.flight_takeoff,
                    _showDeployDroneDialog,
                  ),
                  _buildSidebarAction(
                    'Emergency Response',
                    Icons.emergency,
                    _showEmergencyDialog,
                  ),
                ]),
                _buildSidebarSection('System Status', [
                  _buildStatusIndicator('Communication', true),
                  _buildStatusIndicator('GPS Signal', true),
                  _buildStatusIndicator('Weather Clear', true),
                  _buildStatusIndicator('All Systems', false),
                ]),
                _buildSidebarSection('Recent Activity', [
                  _buildActivityItem(
                    'Drone Alpha deployed to sector 7',
                    '2 min ago',
                  ),
                  _buildActivityItem(
                    'Mission Beta completed successfully',
                    '5 min ago',
                  ),
                  _buildActivityItem(
                    'Emergency request received',
                    '12 min ago',
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  Widget _buildSidebarAction(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
      dense: true,
    );
  }

  Widget _buildStatusIndicator(String label, bool isActive) {
    return ListTile(
      leading: Icon(
        isActive ? Icons.check_circle : Icons.warning,
        color: isActive ? Colors.green : Colors.orange,
      ),
      title: Text(label),
      dense: true,
    );
  }

  Widget _buildActivityItem(String activity, String time) {
    return ListTile(
      title: Text(activity, style: const TextStyle(fontSize: 13)),
      subtitle: Text(time, style: const TextStyle(fontSize: 11)),
      dense: true,
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: "create_mission_fab",
          backgroundColor: Theme.of(context).primaryColor,
          onPressed: _showCreateMissionDialog,
          child: const Icon(Icons.add_location, color: Colors.white),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: "emergency_fab",
          backgroundColor: Colors.red,
          onPressed: _showEmergencyDialog,
          child: const Icon(Icons.emergency, color: Colors.white),
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
              'Unable to Load GCS Map',
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
  void _onMissionSelected(Mission mission) {
    final mapProvider = context.read<MapProvider>();
    mapProvider.selectMission(mission);
  }

  void _onDroneSelected(DroneModel.Drone drone) {
    final mapProvider = context.read<MapProvider>();
    mapProvider.selectDroneById(drone.id);
  }

  void _onStationSelected(GCSStation station) {
    final mapProvider = context.read<MapProvider>();
    mapProvider.selectGCSStation(station);
  }

  void _applyMissionFilter(String filter, bool selected) {
    final mapProvider = context.read<MapProvider>();

    switch (filter) {
      case 'All':
        if (selected) {
          mapProvider.setMissionStatusFilter(MissionStatus.values.toSet());
          mapProvider.setPriorityFilter(null);
        }
        break;
      case 'Pending':
        var filters = Set<MissionStatus>.from(mapProvider.missionStatusFilter);
        if (selected) {
          filters.add(MissionStatus.assigned);
        } else {
          filters.remove(MissionStatus.assigned);
        }
        mapProvider.setMissionStatusFilter(filters);
        break;
      case 'Active':
        var filters = Set<MissionStatus>.from(mapProvider.missionStatusFilter);
        if (selected) {
          filters.add(MissionStatus.inProgress);
        } else {
          filters.remove(MissionStatus.inProgress);
        }
        mapProvider.setMissionStatusFilter(filters);
        break;
      case 'Critical':
        mapProvider.setPriorityFilter(
          selected ? MissionPriority.critical : null,
        );
        break;
    }
  }

  bool _hasActiveAlerts(MapProvider mapProvider) {
    return _getActiveAlerts(mapProvider).isNotEmpty;
  }

  List<String> _getActiveAlerts(MapProvider mapProvider) {
    List<String> alerts = [];

    // Check for low battery drones
    final lowBatteryDrones = mapProvider.drones
        .where((d) => d.batteryLevel < 20)
        .length;
    if (lowBatteryDrones > 0) {
      alerts.add('$lowBatteryDrones drone(s) with low battery');
    }

    // Check for offline drones
    final offlineDrones = mapProvider.drones
        .where((d) => d.status == DroneModel.DroneStatus.offline)
        .length;
    if (offlineDrones > 0) {
      alerts.add('$offlineDrones drone(s) offline');
    }

    // Check for critical missions
    final criticalMissions = mapProvider.missions
        .where((m) => m.priority == MissionPriority.critical && m.isActive)
        .length;
    if (criticalMissions > 0) {
      alerts.add('$criticalMissions critical mission(s) active');
    }

    return alerts;
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'optimize':
        _optimizeRoutes();
        break;
      case 'refresh':
        context.read<MapProvider>().initialize();
        break;
      case 'export':
        _exportReport();
        break;
      case 'settings':
        _showSettingsDialog();
        break;
    }
  }

  void _optimizeRoutes() {
    final mapProvider = context.read<MapProvider>();
    final activeMissions = mapProvider.activeMissions;

    if (activeMissions.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Optimizing routes for ${activeMissions.length} active missions...',
          ),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
    }
  }

  Color _getDroneStatusColor(dynamic status) {
    final statusString = status.toString().split('.').last;
    switch (statusString) {
      case 'active':
        return Colors.green;
      case 'standby':
        return Colors.blue;
      case 'maintenance':
        return Colors.orange;
      case 'charging':
        return Colors.yellow;
      case 'offline':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting mission report...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GCS Settings'),
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
                  title: const Text('Show Coverage Areas'),
                  trailing: Switch(
                    value: mapProvider.showCoverage,
                    onChanged: (_) => mapProvider.toggleCoverage(),
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
                  title: const Text('Update Interval'),
                  subtitle: Slider(
                    value: mapProvider.updateIntervalSeconds.toDouble(),
                    min: 1.0,
                    max: 30.0,
                    divisions: 29,
                    label: '${mapProvider.updateIntervalSeconds}s',
                    onChanged: (value) =>
                        mapProvider.setUpdateInterval(value.round()),
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

  void _showCreateMissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Mission'),
        content: const Text('Mission creation form will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mission creation started')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showDeployDroneDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deploy Drone'),
        content: const Text(
          'Drone deployment interface will be implemented here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Drone deployment initiated')),
              );
            },
            child: const Text('Deploy'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency Response'),
          ],
        ),
        content: const Text('Activate emergency response protocol?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency response protocol activated'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Activate',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
