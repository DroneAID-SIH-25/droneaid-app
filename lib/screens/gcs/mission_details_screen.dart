import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_theme.dart';

class MissionDetailsScreen extends StatefulWidget {
  final String missionId;

  const MissionDetailsScreen({super.key, required this.missionId});

  @override
  State<MissionDetailsScreen> createState() => _MissionDetailsScreenState();
}

class _MissionDetailsScreenState extends State<MissionDetailsScreen> {
  late Map<String, dynamic> _missionData;

  @override
  void initState() {
    super.initState();
    _loadMissionData();
  }

  void _loadMissionData() {
    // Mock mission data - in real app, this would come from API
    _missionData = {
      'id': widget.missionId,
      'title': 'Medical Emergency Response',
      'type': 'Medical Emergency',
      'status': 'in_progress',
      'priority': 'critical',
      'description':
          'Heart attack patient needs immediate medical attention in residential area',
      'location': {
        'address': 'Sector 15, Dwarka, New Delhi, India',
        'latitude': 28.5921,
        'longitude': 77.0460,
      },
      'requester': {
        'name': 'John Doe',
        'phone': '+91 98765 43210',
        'email': 'john.doe@example.com',
      },
      'assignedDrone': {
        'id': 'EMR-001',
        'name': 'Emergency Response Drone 1',
        'batteryLevel': 78,
        'currentLocation': 'En route to destination',
      },
      'operator': {
        'name': 'Dr. Smith',
        'id': 'OP-001',
        'specialization': 'Emergency Medical Response',
      },
      'timeline': [
        {
          'time': '10:30 AM',
          'event': 'Emergency request received',
          'status': 'completed',
        },
        {
          'time': '10:32 AM',
          'event': 'Mission assigned to operator',
          'status': 'completed',
        },
        {
          'time': '10:35 AM',
          'event': 'Drone EMR-001 deployed',
          'status': 'completed',
        },
        {
          'time': '10:40 AM',
          'event': 'Drone en route to destination',
          'status': 'in_progress',
        },
        {
          'time': 'ETA 10:45 AM',
          'event': 'Arrive at emergency location',
          'status': 'pending',
        },
      ],
      'createdAt': DateTime.now().subtract(const Duration(minutes: 15)),
      'estimatedCompletion': DateTime.now().add(const Duration(minutes: 10)),
      'progress': 65,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mission ${widget.missionId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadMissionData();
              });
            },
          ),
          IconButton(icon: const Icon(Icons.map), onPressed: _openMap),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMissionHeader(),
            const SizedBox(height: 20),
            _buildProgressCard(),
            const SizedBox(height: 20),
            _buildLocationCard(),
            const SizedBox(height: 20),
            _buildAssignmentCard(),
            const SizedBox(height: 20),
            _buildTimelineCard(),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionHeader() {
    final statusColor = AppTheme.getStatusColor(_missionData['status']);
    final priorityColor = AppTheme.getPriorityColor(_missionData['priority']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _missionData['title'],
                  style: const TextStyle(
                    fontSize: 22,
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
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _missionData['status'].toString().toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: priorityColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_missionData['priority']} Priority • ${_missionData['type']}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: priorityColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _missionData['description'],
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mission Progress',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progress'),
              Text(
                '${_missionData['progress']}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _missionData['progress'] / 100,
            backgroundColor: AppColors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildProgressInfo('Started', '10:30 AM'),
              const SizedBox(width: 24),
              _buildProgressInfo('ETA', '10:45 AM'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    final location = _missionData['location'];
    final requester = _missionData['requester'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location & Contact',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Emergency Location'),
                    Text(
                      location['address'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.person, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(requester['name']),
                    Text(
                      requester['phone'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _callRequester(requester['phone']),
                icon: const Icon(Icons.call, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard() {
    final drone = _missionData['assignedDrone'];
    final operator = _missionData['operator'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assignment Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.flight, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${drone['name']} (${drone['id']})'),
                    Row(
                      children: [
                        Icon(
                          Icons.battery_std,
                          size: 16,
                          color: _getBatteryColor(drone['batteryLevel']),
                        ),
                        Text(
                          ' ${drone['batteryLevel']}% • ${drone['currentLocation']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.person_outline, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${operator['name']} (${operator['id']})'),
                    Text(
                      operator['specialization'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mission Timeline',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _missionData['timeline'].length,
            itemBuilder: (context, index) {
              final event = _missionData['timeline'][index];
              final isLast = index == _missionData['timeline'].length - 1;
              return _buildTimelineItem(event, isLast);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> event, bool isLast) {
    Color statusColor;
    IconData statusIcon;

    switch (event['status']) {
      case 'completed':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case 'in_progress':
        statusColor = AppColors.warning;
        statusIcon = Icons.access_time;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.radio_button_unchecked;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: statusColor.withOpacity(0.3),
                margin: const EdgeInsets.only(top: 4),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event['event'],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      event['time'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _updateMissionStatus,
            icon: const Icon(Icons.update),
            label: const Text('Update Status'),
            style: AppTheme.primaryButtonStyle,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _sendMessage,
                icon: const Icon(Icons.message),
                label: const Text('Message'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openMap,
                icon: const Icon(Icons.map),
                label: const Text('View Map'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getBatteryColor(int battery) {
    if (battery > 60) return AppColors.success;
    if (battery > 30) return AppColors.warning;
    return AppColors.error;
  }

  void _updateMissionStatus() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Update Mission Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Mark as In Progress'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mission marked as in progress'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Mark as Completed'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mission marked as completed')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel Mission'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mission cancelled')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _callRequester(String phone) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Calling $phone...')));
  }

  void _sendMessage() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening message center...')));
  }

  void _openMap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening mission map view...')),
    );
  }
}
