import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_theme.dart';
import '../../routes/app_router.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _mockRequests = [
    {
      'id': '1',
      'title': 'Medical Emergency',
      'type': 'Medical Emergency',
      'status': 'completed',
      'priority': 'critical',
      'location': 'New Delhi, India',
      'time': '2 hours ago',
      'description': 'Heart attack patient needs immediate medical attention',
      'assignedDrone': 'MED-001',
      'operator': 'Dr. Smith',
    },
    {
      'id': '2',
      'title': 'Fire Emergency',
      'type': 'Fire',
      'status': 'in_progress',
      'priority': 'high',
      'location': 'Mumbai, India',
      'time': '1 day ago',
      'description': 'Building fire on 3rd floor, people trapped',
      'assignedDrone': 'FIRE-005',
      'operator': 'Fire Chief Johnson',
    },
    {
      'id': '3',
      'title': 'Flood Rescue',
      'type': 'Flood',
      'status': 'assigned',
      'priority': 'high',
      'location': 'Chennai, India',
      'time': '3 days ago',
      'description': 'Family stranded on rooftop due to flooding',
      'assignedDrone': 'RESCUE-003',
      'operator': 'Rescue Team Alpha',
    },
    {
      'id': '4',
      'title': 'Search and Rescue',
      'type': 'Search and Rescue',
      'status': 'pending',
      'priority': 'medium',
      'location': 'Bangalore, India',
      'time': '5 days ago',
      'description': 'Missing hiker in forest area',
      'assignedDrone': null,
      'operator': null,
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

  List<Map<String, dynamic>> _getFilteredRequests(String status) {
    if (status == 'all') return _mockRequests;
    return _mockRequests.where((req) => req['status'] == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myRequests),
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
            icon: const Icon(Icons.refresh),
            onPressed: _refreshRequests,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestsList(_getFilteredRequests('all')),
          _buildRequestsList(_getFilteredRequests('pending')),
          _buildRequestsList(_getFilteredRequests('in_progress')),
          _buildRequestsList(_getFilteredRequests('completed')),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AppRouter.goToRequestHelp(),
        icon: const Icon(Icons.emergency),
        label: const Text('New Request'),
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildRequestsList(List<Map<String, dynamic>> requests) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (requests.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return _buildRequestCard(request);
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final statusColor = AppTheme.getStatusColor(request['status']);
    final priorityColor = AppTheme.getPriorityColor(request['priority']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _viewRequestDetails(request),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request['title'],
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
                      request['status'].toString().toUpperCase(),
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

              // Priority and Type Row
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
                    '${request['priority']} Priority',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: priorityColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.category,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    request['type'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                request['description'],
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Location and Time Row
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
                      request['location'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    request['time'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // Assignment Info (if assigned)
              if (request['assignedDrone'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.flight,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Assigned to ${request['assignedDrone']}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.success,
                        ),
                      ),
                      if (request['status'] == 'in_progress') ...[
                        const Spacer(),
                        TextButton(
                          onPressed: () => _trackMission(request['id']),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 32),
                          ),
                          child: const Text('Track'),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'No requests found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your emergency requests will appear here',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => AppRouter.goToRequestHelp(),
            icon: const Icon(Icons.emergency),
            label: const Text('Request Help'),
            style: AppTheme.emergencyButtonStyle,
          ),
        ],
      ),
    );
  }

  Future<void> _refreshRequests() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Requests updated'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _viewRequestDetails(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildRequestDetailsModal(request),
    );
  }

  Widget _buildRequestDetailsModal(Map<String, dynamic> request) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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

              // Title and Status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request['title'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.getStatusColor(
                        request['status'],
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      request['status'].toString().toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getStatusColor(request['status']),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Details
                    _buildDetailRow('Type', request['type']),
                    _buildDetailRow('Priority', request['priority']),
                    _buildDetailRow('Location', request['location']),
                    _buildDetailRow('Submitted', request['time']),
                    if (request['assignedDrone'] != null)
                      _buildDetailRow(
                        'Assigned Drone',
                        request['assignedDrone'],
                      ),
                    if (request['operator'] != null)
                      _buildDetailRow('Operator', request['operator']),

                    const SizedBox(height: 16),

                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      request['description'],
                      style: const TextStyle(fontSize: 14),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    if (request['status'] == 'in_progress')
                      ElevatedButton.icon(
                        onPressed: () => _trackMission(request['id']),
                        icon: const Icon(Icons.track_changes),
                        label: const Text('Track Mission'),
                        style: AppTheme.primaryButtonStyle,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
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

  void _trackMission(String requestId) {
    Navigator.pop(context);
    AppRouter.goToTrackMission();
  }
}
