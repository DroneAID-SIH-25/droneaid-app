import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';

import '../../providers/ongoing_missions_provider.dart';
import '../../models/ongoing_mission.dart';
import '../../models/mission.dart';

class EnhancedOngoingMissionsScreen extends StatefulWidget {
  const EnhancedOngoingMissionsScreen({super.key});

  @override
  State<EnhancedOngoingMissionsScreen> createState() =>
      _EnhancedOngoingMissionsScreenState();
}

class _EnhancedOngoingMissionsScreenState
    extends State<EnhancedOngoingMissionsScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OngoingMissionsProvider>().initialize();
    });

    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) => _refreshMissions(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _refreshMissions() {
    if (mounted) {
      context.read<OngoingMissionsProvider>().refreshMissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchAndFilters(),
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildHeader() {
    return Consumer<OngoingMissionsProvider>(
      builder: (context, provider, child) {
        final stats = provider.missionStats;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ongoing Missions',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      if (provider.isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        IconButton(
                          onPressed: _refreshMissions,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh',
                        ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatsRow(stats),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(Map<String, int> stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total',
            stats['total'] ?? 0,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Active',
            stats['active'] ?? 0,
            AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Critical',
            stats['critical'] ?? 0,
            AppColors.error,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Alerts',
            stats['withAlerts'] ?? 0,
            AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search missions, drones, locations...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        context
                            .read<OngoingMissionsProvider>()
                            .updateSearchQuery('');
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              context.read<OngoingMissionsProvider>().updateSearchQuery(value);
            },
          ),
          const SizedBox(height: 12),
          // Filter chips
          _buildFilterChips(),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Consumer<OngoingMissionsProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('Active Only'),
                selected: provider.showOnlyActive,
                onSelected: (_) => provider.toggleActiveFilter(),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Critical'),
                selected: provider.showOnlyCritical,
                onSelected: (_) => provider.toggleCriticalFilter(),
              ),
              const SizedBox(width: 8),
              // Status filter
              PopupMenuButton<MissionStatus>(
                child: Chip(
                  label: Text(
                    provider.statusFilter?.displayName ?? 'All Status',
                  ),
                  deleteIcon: provider.statusFilter != null
                      ? const Icon(Icons.close, size: 18)
                      : null,
                  onDeleted: provider.statusFilter != null
                      ? () => provider.updateStatusFilter(null)
                      : null,
                ),
                onSelected: (status) => provider.updateStatusFilter(status),
                itemBuilder: (context) => MissionStatus.values
                    .map(
                      (status) => PopupMenuItem(
                        value: status,
                        child: Text(status.displayName),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(width: 8),
              // Priority filter
              PopupMenuButton<MissionPriority>(
                child: Chip(
                  label: Text(
                    provider.priorityFilter?.displayName ?? 'All Priority',
                  ),
                  deleteIcon: provider.priorityFilter != null
                      ? const Icon(Icons.close, size: 18)
                      : null,
                  onDeleted: provider.priorityFilter != null
                      ? () => provider.updatePriorityFilter(null)
                      : null,
                ),
                onSelected: (priority) =>
                    provider.updatePriorityFilter(priority),
                itemBuilder: (context) => MissionPriority.values
                    .map(
                      (priority) => PopupMenuItem(
                        value: priority,
                        child: Text(priority.displayName),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'All Missions'),
          Tab(text: 'Map View'),
          Tab(text: 'Analytics'),
          Tab(text: 'Alerts'),
        ],
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildMissionsList(),
        _buildMapView(),
        _buildAnalyticsView(),
        _buildAlertsView(),
      ],
    );
  }

  Widget _buildMissionsList() {
    return Consumer<OngoingMissionsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.ongoingMissions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Error: ${provider.error}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.initialize(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final missions = provider.filteredMissions;

        if (missions.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => provider.refreshMissions(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: missions.length,
            itemBuilder: (context, index) {
              final mission = missions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildEnhancedMissionCard(mission),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEnhancedMissionCard(OngoingMission mission) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: mission.hasCriticalReadings
              ? AppColors.error
              : mission.priority == MissionPriority.critical
              ? AppColors.warning
              : Colors.transparent,
          width: mission.hasCriticalReadings ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getPriorityColor(mission.priority).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            mission.assignedDroneId,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'ETA: ${mission.eta}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildPriorityChip(mission.priority),
                          const SizedBox(width: 8),
                          _buildStatusChip(mission.status),
                          const Spacer(),
                          Text(
                            'Parcel: ${mission.payload}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Mission Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Target: ${mission.targetLocation.address}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.gps_fixed,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'GPS: ${mission.currentGPS.latitude.toStringAsFixed(4)}, ${mission.currentGPS.longitude.toStringAsFixed(4)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Sensor Data Row
                _buildSensorDataRow(mission.sensorReadings),

                const SizedBox(height: 12),

                // Progress Bar
                _buildProgressSection(mission),

                const SizedBox(height: 12),

                // Action Buttons
                _buildActionButtons(mission),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorDataRow(SensorData sensorData) {
    return Row(
      children: [
        Expanded(
          child: _buildSensorItem(
            'Temp',
            '${sensorData.temperature.toStringAsFixed(1)}°C',
            Icons.thermostat,
            _getTemperatureColor(sensorData.temperature),
          ),
        ),
        Expanded(
          child: _buildSensorItem(
            'Humidity',
            '${sensorData.humidity.toStringAsFixed(0)}%',
            Icons.water_drop,
            AppColors.primary,
          ),
        ),
        Expanded(
          child: _buildSensorItem(
            'PM2.5',
            sensorData.airQuality.pm25.toStringAsFixed(0),
            Icons.air,
            sensorData.airQuality.level.color,
          ),
        ),
        Expanded(
          child: _buildSensorItem(
            'CO',
            sensorData.airQuality.co.toStringAsFixed(0),
            Icons.cloud,
            _getAirQualityColor(sensorData.airQuality.co, 15),
          ),
        ),
      ],
    );
  }

  Widget _buildSensorItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(OngoingMission mission) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress: ${mission.missionProgress.currentPhase}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '${mission.missionProgress.completionPercentage.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: mission.missionProgress.completionPercentage / 100,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(mission.missionProgress.completionPercentage),
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(OngoingMission mission) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showMissionDetails(mission),
            icon: const Icon(Icons.info_outline),
            label: const Text('Details'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (mission.status == MissionStatus.inProgress)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _pauseMission(mission),
              icon: const Icon(Icons.pause),
              label: const Text('Pause'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
              ),
            ),
          )
        else if (mission.status == MissionStatus.assigned)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _resumeMission(mission),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Resume'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
            ),
          ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _showAbortDialog(mission),
          icon: const Icon(Icons.stop, color: AppColors.error),
          tooltip: 'Abort Mission',
        ),
      ],
    );
  }

  Widget _buildMapView() {
    return const Center(child: Text('Map View - Coming Soon'));
  }

  Widget _buildAnalyticsView() {
    return Consumer<OngoingMissionsProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mission Analytics',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Add analytics widgets here
              const Center(child: Text('Analytics Dashboard - Coming Soon')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertsView() {
    return Consumer<OngoingMissionsProvider>(
      builder: (context, provider, child) {
        final missionsWithAlerts = provider.missionsWithAlerts;

        if (missionsWithAlerts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: AppColors.success,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Critical Alerts',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: AppColors.success),
                ),
                const SizedBox(height: 8),
                Text(
                  'All missions are operating normally',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: missionsWithAlerts.length,
          itemBuilder: (context, index) {
            final mission = missionsWithAlerts[index];
            return Card(
              color: AppColors.error.withOpacity(0.1),
              child: ListTile(
                leading: Icon(Icons.warning, color: AppColors.error),
                title: Text(mission.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: mission.criticalAlerts
                      .map((alert) => Text('• $alert'))
                      .toList(),
                ),
                trailing: TextButton(
                  onPressed: () => _showMissionDetails(mission),
                  child: const Text('VIEW'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flight_takeoff, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No Ongoing Missions',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'All missions completed or no active missions',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      heroTag: "refresh_missions_fab",
      onPressed: _refreshMissions,
      tooltip: 'Refresh Missions',
      child: const Icon(Icons.refresh),
    );
  }

  // Helper methods
  Widget _buildPriorityChip(MissionPriority priority) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getPriorityColor(priority),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority.displayName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusChip(MissionStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getPriorityColor(MissionPriority priority) {
    switch (priority) {
      case MissionPriority.low:
        return AppColors.success;
      case MissionPriority.medium:
        return AppColors.warning;
      case MissionPriority.high:
        return Colors.deepOrange;
      case MissionPriority.critical:
        return AppColors.error;
    }
  }

  Color _getStatusColor(MissionStatus status) {
    switch (status) {
      case MissionStatus.assigned:
        return Colors.blue;
      case MissionStatus.inProgress:
        return AppColors.success;
      case MissionStatus.completed:
        return Colors.green.shade700;
      case MissionStatus.cancelled:
        return AppColors.error;
      case MissionStatus.failed:
        return Colors.red.shade700;
      case MissionStatus.paused:
        return AppColors.warning;
    }
  }

  Color _getTemperatureColor(double temperature) {
    if (temperature > 35) return AppColors.error;
    if (temperature < 0) return Colors.blue;
    return AppColors.success;
  }

  Color _getAirQualityColor(double value, double threshold) {
    if (value > threshold) return AppColors.error;
    if (value > threshold * 0.7) return AppColors.warning;
    return AppColors.success;
  }

  Color _getProgressColor(double percentage) {
    if (percentage < 30) return AppColors.error;
    if (percentage < 70) return AppColors.warning;
    return AppColors.success;
  }

  // Action methods
  void _pauseMission(OngoingMission mission) {
    context.read<OngoingMissionsProvider>().pauseMission(mission.id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Mission ${mission.title} paused')));
  }

  void _resumeMission(OngoingMission mission) {
    context.read<OngoingMissionsProvider>().resumeMission(mission.id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Mission ${mission.title} resumed')));
  }

  void _showAbortDialog(OngoingMission mission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abort Mission'),
        content: Text('Are you sure you want to abort "${mission.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<OngoingMissionsProvider>().abortMission(
                mission.id,
                'User initiated abort',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Mission ${mission.title} aborted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Abort'),
          ),
        ],
      ),
    );
  }

  void _showMissionDetails(OngoingMission mission) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Mission Details',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Title', mission.title),
                      _buildDetailRow('Drone ID', mission.assignedDroneId),
                      _buildDetailRow('Status', mission.status.displayName),
                      _buildDetailRow('Priority', mission.priority.displayName),
                      _buildDetailRow('ETA', mission.eta),
                      _buildDetailRow(
                        'Progress',
                        '${mission.missionProgress.completionPercentage.toStringAsFixed(1)}%',
                      ),
                      _buildDetailRow(
                        'Current Phase',
                        mission.missionProgress.currentPhase,
                      ),
                      _buildDetailRow(
                        'Target',
                        mission.targetLocation.address ?? 'Unknown',
                      ),
                      _buildDetailRow(
                        'GPS',
                        '${mission.currentGPS.latitude.toStringAsFixed(6)}, ${mission.currentGPS.longitude.toStringAsFixed(6)}',
                      ),
                      _buildDetailRow(
                        'Altitude',
                        '${mission.currentGPS.altitude.toStringAsFixed(1)}m',
                      ),
                      _buildDetailRow(
                        'Speed',
                        '${mission.currentGPS.speed.toStringAsFixed(1)} m/s',
                      ),
                      _buildDetailRow(
                        'Battery',
                        '${mission.batteryLevel.toStringAsFixed(1)}%',
                      ),
                      _buildDetailRow(
                        'Fuel',
                        '${mission.fuelLevel.toStringAsFixed(1)}%',
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sensor Readings',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Temperature',
                        '${mission.sensorReadings.temperature.toStringAsFixed(1)}°C',
                      ),
                      _buildDetailRow(
                        'Humidity',
                        '${mission.sensorReadings.humidity.toStringAsFixed(1)}%',
                      ),
                      _buildDetailRow(
                        'Pressure',
                        '${mission.sensorReadings.pressure.toStringAsFixed(1)} hPa',
                      ),
                      _buildDetailRow(
                        'PM2.5',
                        '${mission.sensorReadings.airQuality.pm25.toStringAsFixed(0)} µg/m³',
                      ),
                      _buildDetailRow(
                        'CO',
                        '${mission.sensorReadings.airQuality.co.toStringAsFixed(0)} mg/m³',
                      ),
                      _buildDetailRow(
                        'NO2',
                        '${mission.sensorReadings.airQuality.no2.toStringAsFixed(0)} µg/m³',
                      ),
                      _buildDetailRow(
                        'Air Quality',
                        mission.sensorReadings.airQuality.level.displayName,
                      ),
                      if (mission.criticalAlerts.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Critical Alerts',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                        ),
                        const SizedBox(height: 8),
                        ...mission.criticalAlerts.map(
                          (alert) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning,
                                  size: 16,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(alert)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
