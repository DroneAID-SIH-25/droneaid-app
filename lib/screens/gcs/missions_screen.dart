import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_theme.dart';
import '../../routes/app_router.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _mockMissions = [
    {
      'id': 'M001',
      'title': 'Medical Emergency Response',
      'type': 'Medical Emergency',
      'status': 'in_progress',
      'priority': 'critical',
      'location': 'New Delhi, India',
      'drone': 'EMR-001',
      'operator': 'Dr. Smith',
      'startTime': '10:30 AM',
      'progress': 65,
    },
    {
      'id': 'M002',
      'title': 'Fire Incident Monitoring',
      'type': 'Fire',
      'status': 'assigned',
      'priority': 'high',
      'location': 'Mumbai, India',
      'drone': 'FIRE-005',
      'operator': 'Fire Chief Johnson',
      'startTime': '11:00 AM',
      'progress': 25,
    },
    {
      'id': 'M003',
      'title': 'Flood Rescue Operation',
      'type': 'Flood',
      'status': 'completed',
      'priority': 'high',
      'location': 'Chennai, India',
      'drone': 'RESCUE-003',
      'operator': 'Rescue Team Alpha',
      'startTime': '09:15 AM',
      'progress': 100,
    },
    {
      'id': 'M004',
      'title': 'Search and Rescue',
      'type': 'Search and Rescue',
      'status': 'pending',
      'priority': 'medium',
      'location': 'Bangalore, India',
      'drone': null,
      'operator': null,
      'startTime': null,
      'progress': 0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredMissions(String status) {
    if (status == 'all') return _mockMissions;
    return _mockMissions
        .where((mission) => mission['status'] == status)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missions'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Create new mission feature coming soon'),
                ),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMissionsList(_getFilteredMissions('all')),
          _buildMissionsList(_getFilteredMissions('pending')),
          _buildMissionsList(_getFilteredMissions('in_progress')),
          _buildMissionsList(_getFilteredMissions('completed')),
        ],
      ),
    );
  }

  Widget _buildMissionsList(List<Map<String, dynamic>> missions) {
    if (missions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              'No missions found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: missions.length,
      itemBuilder: (context, index) {
        final mission = missions[index];
        return _buildMissionCard(mission);
      },
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> mission) {
    final statusColor = AppTheme.getStatusColor(mission['status']);
    final priorityColor = AppTheme.getPriorityColor(mission['priority']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => AppRouter.goToMissionDetails(mission['id']),
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
                      mission['title'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      mission['status'].toString().toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Priority and Type
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${mission['priority']} Priority',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: priorityColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    mission['type'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Location and Drone Info
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      mission['location'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (mission['drone'] != null) ...[
                    const Icon(
                      Icons.flight,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      mission['drone'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),

              // Progress Bar (if mission is active)
              if (mission['status'] == 'in_progress') ...[
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${mission['progress']}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: mission['progress'] / 100,
                      backgroundColor: AppColors.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],

              // Operator Info (if assigned)
              if (mission['operator'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: AppColors.info),
                      const SizedBox(width: 8),
                      Text(
                        'Operator: ${mission['operator']}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.info,
                        ),
                      ),
                      if (mission['startTime'] != null) ...[
                        const Spacer(),
                        Text(
                          'Started: ${mission['startTime']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
