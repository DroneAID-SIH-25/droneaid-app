import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';

import '../../providers/group_management_provider.dart';
import '../../models/group_event.dart';
import '../../models/mission.dart';
import '../../models/user.dart';

class OngoingMissionsScreen extends StatefulWidget {
  const OngoingMissionsScreen({super.key});

  @override
  State<OngoingMissionsScreen> createState() => _OngoingMissionsScreenState();
}

class _OngoingMissionsScreenState extends State<OngoingMissionsScreen>
    with AutomaticKeepAliveClientMixin {
  String _searchQuery = '';
  MissionStatus? _statusFilter;
  EventType? _eventTypeFilter;
  bool _showOnlyActive = true;

  @override
  bool get wantKeepAlive => true;

  // Mock mission data - in real app would come from mission provider
  List<Mission> get _mockMissions => [
    Mission(
      title: 'Medical Supply Delivery',
      description: 'Urgent medical supplies delivery to flood-affected area',
      type: MissionType.medical,
      status: MissionStatus.inProgress,
      priority: MissionPriority.critical,
      assignedDroneId: 'DRN-MED-001',
      assignedOperatorId: 'OP-001',
      eventId: 'event-001',
      startLocation: LocationData(
        latitude: 19.0760,
        longitude: 72.8777,
        address: 'Mumbai Central, Maharashtra',
      ),
      targetLocation: LocationData(
        latitude: 19.1136,
        longitude: 72.8697,
        address: 'Dharavi, Mumbai, Maharashtra',
      ),
      estimatedDuration: const Duration(minutes: 45),
      actualStartTime: DateTime.now().subtract(const Duration(minutes: 15)),
      progress: 0.6,
      weatherConditions: 'Clear skies, light winds',
      fuelLevel: 75.0,
      batteryLevel: 80.0,
      altitude: 150.0,
      speed: 45.0,
      distance: 12.5,
      payload: 'Medical supplies - 5kg',
    ),
    Mission(
      title: 'Fire Incident Surveillance',
      description: 'Real-time monitoring and assessment of fire situation',
      type: MissionType.surveillance,
      status: MissionStatus.inProgress,
      priority: MissionPriority.high,
      assignedDroneId: 'DRN-SURV-003',
      assignedOperatorId: 'OP-002',
      eventId: 'event-002',
      startLocation: LocationData(
        latitude: 28.7041,
        longitude: 77.1025,
        address: 'Delhi GCS Base',
      ),
      targetLocation: LocationData(
        latitude: 28.6139,
        longitude: 77.2090,
        address: 'Industrial Area, Delhi',
      ),
      estimatedDuration: const Duration(hours: 2),
      actualStartTime: DateTime.now().subtract(const Duration(minutes: 30)),
      progress: 0.25,
      weatherConditions: 'Moderate visibility, smoke present',
      fuelLevel: 85.0,
      batteryLevel: 88.0,
      altitude: 200.0,
      speed: 35.0,
      distance: 8.2,
      payload: 'Thermal imaging camera',
    ),
    Mission(
      title: 'Search and Rescue Operation',
      description: 'Search for missing persons in earthquake-affected zone',
      type: MissionType.searchAndRescue,
      status: MissionStatus.assigned,
      priority: MissionPriority.critical,
      assignedDroneId: 'DRN-SAR-002',
      assignedOperatorId: 'OP-003',
      eventId: 'event-003',
      startLocation: LocationData(
        latitude: 23.0225,
        longitude: 72.5714,
        address: 'Ahmedabad GCS',
      ),
      targetLocation: LocationData(
        latitude: 23.0359,
        longitude: 72.6667,
        address: 'Affected Area, Ahmedabad',
      ),
      estimatedDuration: const Duration(hours: 3),
      scheduledStartTime: DateTime.now().add(const Duration(minutes: 10)),
      progress: 0.0,
      weatherConditions: 'Good visibility, calm winds',
      fuelLevel: 100.0,
      batteryLevel: 100.0,
      altitude: 0.0,
      speed: 0.0,
      distance: 15.3,
      payload: 'SAR equipment, medical kit',
    ),
    Mission(
      title: 'Damage Assessment',
      description: 'Post-cyclone damage assessment and mapping',
      type: MissionType.surveillance,
      status: MissionStatus.completed,
      priority: MissionPriority.medium,
      assignedDroneId: 'DRN-SURV-001',
      assignedOperatorId: 'OP-004',
      eventId: 'event-004',
      startLocation: LocationData(
        latitude: 20.9517,
        longitude: 85.0985,
        address: 'Bhubaneswar GCS',
      ),
      targetLocation: LocationData(
        latitude: 20.2961,
        longitude: 85.8245,
        address: 'Coastal Areas, Puri',
      ),
      estimatedDuration: const Duration(hours: 4),
      actualStartTime: DateTime.now().subtract(const Duration(hours: 6)),
      actualEndTime: DateTime.now().subtract(const Duration(hours: 2)),
      progress: 1.0,
      weatherConditions: 'Post-cyclone, clearing weather',
      fuelLevel: 25.0,
      batteryLevel: 15.0,
      altitude: 0.0,
      speed: 0.0,
      distance: 45.8,
      payload: 'High-res camera, mapping sensors',
    ),
    Mission(
      title: 'Medical Emergency Response',
      description: 'Emergency medical response and patient monitoring',
      type: MissionType.medical,
      status: MissionStatus.paused,
      priority: MissionPriority.high,
      assignedDroneId: 'DRN-MED-005',
      assignedOperatorId: 'OP-005',
      eventId: 'event-005',
      startLocation: LocationData(
        latitude: 10.8505,
        longitude: 76.2711,
        address: 'Kochi Medical GCS',
      ),
      targetLocation: LocationData(
        latitude: 10.7905,
        longitude: 76.6337,
        address: 'Rural Area, Ernakulam',
      ),
      estimatedDuration: const Duration(hours: 1, minutes: 30),
      actualStartTime: DateTime.now().subtract(const Duration(minutes: 45)),
      progress: 0.4,
      weatherConditions: 'Heavy rain, low visibility',
      fuelLevel: 65.0,
      batteryLevel: 70.0,
      altitude: 100.0,
      speed: 0.0,
      distance: 18.7,
      payload: 'Defibrillator, medical supplies',
    ),
  ];

  List<Mission> get _filteredMissions {
    var missions = _mockMissions;

    if (_showOnlyActive) {
      missions = missions
          .where(
            (mission) =>
                mission.status == MissionStatus.inProgress ||
                mission.status == MissionStatus.assigned,
          )
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      missions = missions
          .where(
            (mission) =>
                mission.title.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                mission.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                mission.assignedDroneId.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    if (_statusFilter != null) {
      missions = missions
          .where((mission) => mission.status == _statusFilter)
          .toList();
    }

    if (_eventTypeFilter != null) {
      // In real implementation, would filter by associated event type
      missions = missions
          .where(
            (mission) => mission.type.name.toLowerCase().contains(
              _eventTypeFilter!.name.toLowerCase(),
            ),
          )
          .toList();
    }

    return missions;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Consumer<GroupManagementProvider>(
        builder: (context, provider, child) {
          final missions = _filteredMissions;

          return Column(
            children: [
              _buildSearchAndFilters(),
              _buildStatsBar(missions),
              Expanded(
                child: missions.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _refreshMissions,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: missions.length,
                          itemBuilder: (context, index) {
                            final mission = missions[index];
                            return _buildMissionCard(mission);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search missions...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Active Only',
                  isSelected: _showOnlyActive,
                  onTap: () {
                    setState(() {
                      _showOnlyActive = !_showOnlyActive;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'In Progress',
                  isSelected: _statusFilter == MissionStatus.inProgress,
                  onTap: () {
                    setState(() {
                      _statusFilter = _statusFilter == MissionStatus.inProgress
                          ? null
                          : MissionStatus.inProgress;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Assigned',
                  isSelected: _statusFilter == MissionStatus.assigned,
                  onTap: () {
                    setState(() {
                      _statusFilter = _statusFilter == MissionStatus.assigned
                          ? null
                          : MissionStatus.assigned;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Critical',
                  isSelected: false, // Could add priority filter
                  onTap: () {
                    // Filter by critical priority
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar(List<Mission> missions) {
    final inProgressCount = missions
        .where((m) => m.status == MissionStatus.inProgress)
        .length;
    final assignedCount = missions
        .where((m) => m.status == MissionStatus.assigned)
        .length;
    final criticalCount = missions
        .where((m) => m.priority == MissionPriority.critical)
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'In Progress',
              inProgressCount,
              AppColors.warning,
            ),
          ),
          Expanded(
            child: _buildStatItem('Assigned', assignedCount, AppColors.info),
          ),
          Expanded(
            child: _buildStatItem('Critical', criticalCount, AppColors.error),
          ),
          Expanded(
            child: _buildStatItem('Total', missions.length, AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _showOnlyActive ? 'No Active Missions' : 'No Missions Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _showOnlyActive
                ? 'All missions are completed or not yet started'
                : 'Try adjusting your search or filters',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _statusFilter = null;
                _eventTypeFilter = null;
                _showOnlyActive = false;
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(Mission mission) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showMissionDetails(mission),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mission.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(mission.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                mission.description,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Mission details
              Row(
                children: [
                  Icon(Icons.flight, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    mission.assignedDroneId,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.person, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    mission.assignedOperatorId,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  _buildPriorityChip(mission.priority),
                ],
              ),

              if (mission.status == MissionStatus.inProgress) ...[
                const SizedBox(height: 12),
                _buildProgressSection(mission),
              ],

              const SizedBox(height: 12),
              _buildMissionStats(mission),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(MissionStatus status) {
    Color color;
    String text;

    switch (status) {
      case MissionStatus.assigned:
        color = AppColors.info;
        text = 'Assigned';
        break;
      case MissionStatus.inProgress:
        color = AppColors.warning;
        text = 'In Progress';
        break;
      case MissionStatus.completed:
        color = AppColors.success;
        text = 'Completed';
        break;
      case MissionStatus.paused:
        color = Colors.orange;
        text = 'Paused';
        break;
      case MissionStatus.cancelled:
        color = AppColors.error;
        text = 'Cancelled';
        break;
      case MissionStatus.failed:
        color = AppColors.error;
        text = 'Failed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(MissionPriority priority) {
    Color color;
    String text;

    switch (priority) {
      case MissionPriority.low:
        color = AppColors.success;
        text = 'Low';
        break;
      case MissionPriority.medium:
        color = AppColors.warning;
        text = 'Medium';
        break;
      case MissionPriority.high:
        color = Colors.orange;
        text = 'High';
        break;
      case MissionPriority.critical:
        color = AppColors.error;
        text = 'Critical';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildProgressSection(Mission mission) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progress',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
            Text(
              '${(mission.progress * 100).toInt()}%',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: mission.progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            mission.progress < 0.3
                ? AppColors.error
                : mission.progress < 0.7
                ? AppColors.warning
                : AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildMissionStats(Mission mission) {
    return Row(
      children: [
        if (mission.altitude > 0) ...[
          _buildStatChip(Icons.height, '${mission.altitude.toInt()}m'),
          const SizedBox(width: 8),
        ],
        if (mission.speed > 0) ...[
          _buildStatChip(Icons.speed, '${mission.speed.toInt()} km/h'),
          const SizedBox(width: 8),
        ],
        _buildStatChip(Icons.battery_std, '${mission.batteryLevel.toInt()}%'),
        const SizedBox(width: 8),
        _buildStatChip(
          Icons.local_gas_station,
          '${mission.fuelLevel.toInt()}%',
        ),
        const Spacer(),
        Text(
          _getTimeString(mission),
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 2),
          Text(text, style: TextStyle(fontSize: 10, color: Colors.grey[700])),
        ],
      ),
    );
  }

  String _getTimeString(Mission mission) {
    if (mission.status == MissionStatus.completed &&
        mission.actualEndTime != null) {
      return 'Completed ${_formatTime(mission.actualEndTime!)}';
    } else if (mission.actualStartTime != null) {
      final elapsed = DateTime.now().difference(mission.actualStartTime!);
      return 'Started ${_formatDuration(elapsed)} ago';
    } else if (mission.scheduledStartTime != null) {
      final remaining = mission.scheduledStartTime!.difference(DateTime.now());
      if (remaining.isNegative) {
        return 'Overdue';
      } else {
        return 'Starts in ${_formatDuration(remaining)}';
      }
    }
    return '';
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inDays}d';
    }
  }

  void _showMissionDetails(Mission mission) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
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
                      mission.title,
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
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatusChip(mission.status),
                  const SizedBox(width: 8),
                  _buildPriorityChip(mission.priority),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildDetailSection('Mission Details', [
                      _buildDetailItem('Description', mission.description),
                      _buildDetailItem(
                        'Type',
                        mission.type.toString().split('.').last,
                      ),
                      _buildDetailItem(
                        'Assigned Drone',
                        mission.assignedDroneId,
                      ),
                      _buildDetailItem(
                        'Assigned Operator',
                        mission.assignedOperatorId,
                      ),
                      _buildDetailItem('Distance', '${mission.distance} km'),
                      if (mission.payload.isNotEmpty)
                        _buildDetailItem('Payload', mission.payload),
                    ]),
                    const SizedBox(height: 16),
                    _buildDetailSection('Location', [
                      _buildDetailItem(
                        'Start Location',
                        mission.startLocation.address ?? 'Unknown',
                      ),
                      _buildDetailItem(
                        'Target Location',
                        mission.targetLocation.address ?? 'Unknown',
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildDetailSection('Status & Progress', [
                      if (mission.status == MissionStatus.inProgress) ...[
                        _buildDetailItem(
                          'Progress',
                          '${(mission.progress * 100).toInt()}%',
                        ),
                        _buildDetailItem(
                          'Current Altitude',
                          '${mission.altitude} m',
                        ),
                        _buildDetailItem(
                          'Current Speed',
                          '${mission.speed} km/h',
                        ),
                      ],
                      _buildDetailItem(
                        'Battery Level',
                        '${mission.batteryLevel}%',
                      ),
                      _buildDetailItem('Fuel Level', '${mission.fuelLevel}%'),
                      if (mission.weatherConditions.isNotEmpty)
                        _buildDetailItem('Weather', mission.weatherConditions),
                    ]),
                    const SizedBox(height: 16),
                    _buildDetailSection('Timeline', [
                      if (mission.scheduledStartTime != null)
                        _buildDetailItem(
                          'Scheduled Start',
                          _formatDateTime(mission.scheduledStartTime!),
                        ),
                      if (mission.actualStartTime != null)
                        _buildDetailItem(
                          'Actual Start',
                          _formatDateTime(mission.actualStartTime!),
                        ),
                      if (mission.actualEndTime != null)
                        _buildDetailItem(
                          'Completed',
                          _formatDateTime(mission.actualEndTime!),
                        ),
                      if (mission.estimatedDuration != null)
                        _buildDetailItem(
                          'Estimated Duration',
                          _formatDuration(mission.estimatedDuration!),
                        ),
                    ]),
                    const SizedBox(height: 24),
                    if (mission.status == MissionStatus.inProgress) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _pauseMission(mission),
                              icon: const Icon(Icons.pause),
                              label: const Text('Pause'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _abortMission(mission),
                              icon: const Icon(Icons.stop),
                              label: const Text('Abort'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (mission.status == MissionStatus.paused) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _resumeMission(mission),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Resume'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _abortMission(mission),
                              icon: const Icon(Icons.stop),
                              label: const Text('Abort'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (mission.status == MissionStatus.assigned) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _startMission(mission),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Mission'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
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

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
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

  Future<void> _refreshMissions() async {
    // Simulate refresh delay
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // In real app, would refresh data from provider
    });
  }

  void _pauseMission(Mission mission) {
    Navigator.pop(context);
    _showConfirmationDialog(
      title: 'Pause Mission',
      content: 'Are you sure you want to pause "${mission.title}"?',
      confirmText: 'Pause',
      onConfirm: () {
        // In real app, would call mission provider to pause mission
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mission "${mission.title}" paused'),
            backgroundColor: Colors.orange,
          ),
        );
      },
    );
  }

  void _resumeMission(Mission mission) {
    Navigator.pop(context);
    _showConfirmationDialog(
      title: 'Resume Mission',
      content: 'Are you sure you want to resume "${mission.title}"?',
      confirmText: 'Resume',
      onConfirm: () {
        // In real app, would call mission provider to resume mission
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mission "${mission.title}" resumed'),
            backgroundColor: AppColors.success,
          ),
        );
      },
    );
  }

  void _startMission(Mission mission) {
    Navigator.pop(context);
    _showConfirmationDialog(
      title: 'Start Mission',
      content: 'Are you sure you want to start "${mission.title}"?',
      confirmText: 'Start',
      onConfirm: () {
        // In real app, would call mission provider to start mission
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mission "${mission.title}" started'),
            backgroundColor: AppColors.success,
          ),
        );
      },
    );
  }

  void _abortMission(Mission mission) {
    Navigator.pop(context);
    _showConfirmationDialog(
      title: 'Abort Mission',
      content:
          'Are you sure you want to abort "${mission.title}"? This action cannot be undone.',
      confirmText: 'Abort',
      isDestructive: true,
      onConfirm: () {
        // In real app, would call mission provider to abort mission
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mission "${mission.title}" aborted'),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
  }

  void _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    required VoidCallback onConfirm,
    bool isDestructive = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive
                  ? AppColors.error
                  : AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}
