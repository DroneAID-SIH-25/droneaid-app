import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_theme.dart';
import '../../routes/app_router.dart';

class TrackMissionScreen extends StatefulWidget {
  final String missionId;

  const TrackMissionScreen({super.key, required this.missionId});

  @override
  State<TrackMissionScreen> createState() => _TrackMissionScreenState();
}

class _TrackMissionScreenState extends State<TrackMissionScreen> {
  String _missionStatus = 'in_progress';
  double _progress = 0.65;
  String _droneLocation = 'En route to destination';
  String _estimatedArrival = '5 minutes';

  final List<Map<String, dynamic>> _missionUpdates = [
    {
      'time': '10:30 AM',
      'status': 'Mission Started',
      'description': 'Drone deployed from base station',
      'isCompleted': true,
    },
    {
      'time': '10:35 AM',
      'status': 'En Route',
      'description': 'Drone is traveling to emergency location',
      'isCompleted': true,
    },
    {
      'time': '10:40 AM',
      'status': 'Approaching Destination',
      'description': 'Drone is 2km away from target location',
      'isCompleted': true,
    },
    {
      'time': '10:45 AM',
      'status': 'On Site',
      'description': 'Drone has arrived at emergency location',
      'isCompleted': false,
    },
    {
      'time': 'Pending',
      'status': 'Mission Complete',
      'description': 'Emergency response completed',
      'isCompleted': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Mission #${widget.missionId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMissionStatus,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mission Status Card
            _buildMissionStatusCard(),
            const SizedBox(height: 20),

            // Progress Indicator
            _buildProgressIndicator(),
            const SizedBox(height: 20),

            // Drone Information
            _buildDroneInfoCard(),
            const SizedBox(height: 20),

            // Mission Timeline
            _buildMissionTimeline(),
            const SizedBox(height: 20),

            // Emergency Contacts
            _buildEmergencyContacts(),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mission Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _missionStatus.toUpperCase(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                'ETA: $_estimatedArrival',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mission Progress',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: _progress,
          backgroundColor: AppColors.surface,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          '${(_progress * 100).toInt()}% Complete',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDroneInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Drone Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.flight, 'Drone ID', 'EMR-001'),
            _buildInfoRow(
              Icons.location_on,
              'Current Location',
              _droneLocation,
            ),
            _buildInfoRow(Icons.battery_std, 'Battery Level', '85%'),
            _buildInfoRow(Icons.speed, 'Speed', '45 km/h'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildMissionTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mission Timeline',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _missionUpdates.length,
          itemBuilder: (context, index) {
            final update = _missionUpdates[index];
            return _buildTimelineItem(
              update,
              index == _missionUpdates.length - 1,
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> update, bool isLast) {
    final isCompleted = update['isCompleted'] as bool;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.success : AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? AppColors.success : AppColors.border,
                  width: 2,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? AppColors.success : AppColors.border,
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
                    Text(
                      update['status'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isCompleted
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      update['time'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  update['description'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyContacts() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emergency, color: AppColors.error),
              const SizedBox(width: 8),
              const Text(
                'Emergency Contacts',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'If you need immediate assistance:\n'
            '• Emergency Services: 112\n'
            '• Mission Control: +91 98765 43210\n'
            '• Local Authorities: 100',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _refreshMissionStatus() {
    setState(() {
      _progress += 0.1;
      if (_progress > 1.0) _progress = 1.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mission status updated'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
