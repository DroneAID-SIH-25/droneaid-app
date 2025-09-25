import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_theme.dart';

class DroneFleetScreen extends StatefulWidget {
  const DroneFleetScreen({super.key});

  @override
  State<DroneFleetScreen> createState() => _DroneFleetScreenState();
}

class _DroneFleetScreenState extends State<DroneFleetScreen> {
  final List<Map<String, dynamic>> _mockDrones = [
    {
      'id': 'EMR-001',
      'name': 'Emergency Response Drone 1',
      'status': 'available',
      'battery': 95,
      'type': 'Medical',
      'location': 'Base Station Alpha',
      'lastMaintenance': '2024-01-15',
      'flightHours': 145,
    },
    {
      'id': 'FIRE-005',
      'name': 'Fire Response Drone 5',
      'status': 'busy',
      'battery': 67,
      'type': 'Fire',
      'location': 'Mumbai Central',
      'lastMaintenance': '2024-01-10',
      'flightHours': 203,
    },
    {
      'id': 'RESCUE-003',
      'name': 'Search & Rescue Drone 3',
      'status': 'maintenance',
      'battery': 0,
      'type': 'Search & Rescue',
      'location': 'Maintenance Hangar',
      'lastMaintenance': '2024-01-20',
      'flightHours': 312,
    },
    {
      'id': 'SURV-007',
      'name': 'Surveillance Drone 7',
      'status': 'available',
      'battery': 88,
      'type': 'Surveillance',
      'location': 'Base Station Beta',
      'lastMaintenance': '2024-01-18',
      'flightHours': 89,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drone Fleet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Add new drone feature coming soon'),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _mockDrones.length,
        itemBuilder: (context, index) {
          final drone = _mockDrones[index];
          return _buildDroneCard(drone);
        },
      ),
    );
  }

  Widget _buildDroneCard(Map<String, dynamic> drone) {
    final statusColor = AppTheme.getStatusColor(drone['status']);
    final batteryColor = _getBatteryColor(drone['battery']);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.flight, color: AppColors.primary, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drone['id'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        drone['name'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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
                    drone['status'].toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Battery and Type
            Row(
              children: [
                Icon(Icons.battery_std, color: batteryColor, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${drone['battery']}%',
                  style: TextStyle(color: batteryColor),
                ),
                const SizedBox(width: 16),
                Icon(Icons.category, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 4),
                Text(
                  drone['type'],
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Location and Flight Hours
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    drone['location'],
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                Text(
                  '${drone['flightHours']}h flight time',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: drone['status'] == 'available'
                        ? () => _deployDrone(drone['id'])
                        : null,
                    icon: const Icon(Icons.flight_takeoff, size: 16),
                    label: const Text('Deploy'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewDroneDetails(drone),
                    icon: const Icon(Icons.info, size: 16),
                    label: const Text('Details'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getBatteryColor(int battery) {
    if (battery > 60) return AppColors.success;
    if (battery > 30) return AppColors.warning;
    return AppColors.error;
  }

  void _deployDrone(String droneId) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Deploying drone $droneId...')));
  }

  void _viewDroneDetails(Map<String, dynamic> drone) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Drone Details: ${drone['id']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Name: ${drone['name']}'),
            Text('Status: ${drone['status']}'),
            Text('Battery: ${drone['battery']}%'),
            Text('Type: ${drone['type']}'),
            Text('Location: ${drone['location']}'),
            Text('Last Maintenance: ${drone['lastMaintenance']}'),
            Text('Flight Hours: ${drone['flightHours']}h'),
          ],
        ),
      ),
    );
  }
}
