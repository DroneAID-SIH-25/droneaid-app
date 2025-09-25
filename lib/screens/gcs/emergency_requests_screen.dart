import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_theme.dart';

class EmergencyRequestsScreen extends StatefulWidget {
  const EmergencyRequestsScreen({super.key});

  @override
  State<EmergencyRequestsScreen> createState() =>
      _EmergencyRequestsScreenState();
}

class _EmergencyRequestsScreenState extends State<EmergencyRequestsScreen> {
  final List<Map<String, dynamic>> _mockRequests = [
    {
      'id': 'REQ001',
      'title': 'Medical Emergency',
      'type': 'Medical Emergency',
      'priority': 'critical',
      'status': 'pending',
      'location': 'New Delhi, India',
      'requester': 'John Doe',
      'phone': '+91 98765 43210',
      'description': 'Heart attack patient needs immediate medical attention',
      'time': '5 minutes ago',
    },
    {
      'id': 'REQ002',
      'title': 'Building Fire',
      'type': 'Fire',
      'priority': 'high',
      'status': 'assigned',
      'location': 'Mumbai, India',
      'requester': 'Fire Department',
      'phone': '+91 98765 43211',
      'description': 'Fire on 5th floor, people trapped inside',
      'time': '15 minutes ago',
    },
    {
      'id': 'REQ003',
      'title': 'Flood Rescue',
      'type': 'Flood',
      'priority': 'high',
      'status': 'in_progress',
      'location': 'Chennai, India',
      'requester': 'Local Authorities',
      'phone': '+91 98765 43212',
      'description': 'Family stranded on rooftop due to heavy flooding',
      'time': '1 hour ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshRequests,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _mockRequests.length,
        itemBuilder: (context, index) {
          final request = _mockRequests[index];
          return _buildRequestCard(request);
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final priorityColor = AppTheme.getPriorityColor(request['priority']);
    final statusColor = AppTheme.getStatusColor(request['status']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request['priority'].toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: priorityColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              request['description'],
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
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
                Text(
                  request['time'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _assignMission(request),
                    child: const Text('Assign'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _viewDetails(request),
                    child: const Text('Details'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _refreshRequests() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Requests refreshed')));
  }

  void _assignMission(Map<String, dynamic> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Assigning mission for ${request['id']}')),
    );
  }

  void _viewDetails(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(request['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${request['type']}'),
            Text('Priority: ${request['priority']}'),
            Text('Location: ${request['location']}'),
            Text('Requester: ${request['requester']}'),
            Text('Phone: ${request['phone']}'),
            const SizedBox(height: 8),
            Text('Description: ${request['description']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
