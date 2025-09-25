import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/drone.dart';
import '../core/constants/app_colors.dart';

class DroneSelectionWidget extends StatelessWidget {
  final List<Drone> availableDrones;
  final String? selectedDroneId;
  final Function(String?) onDroneSelected;
  final bool showDetailedInfo;

  const DroneSelectionWidget({
    super.key,
    required this.availableDrones,
    required this.selectedDroneId,
    required this.onDroneSelected,
    this.showDetailedInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    if (availableDrones.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.warning, size: 48, color: Colors.orange[600]),
              const SizedBox(height: 16),
              const Text(
                'No Available Drones',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'All drones are currently assigned, in maintenance, or have low battery.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Drones',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...availableDrones.map((drone) => _buildDroneCard(context, drone)),
      ],
    );
  }

  Widget _buildDroneCard(BuildContext context, Drone drone) {
    final isSelected = selectedDroneId == drone.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 2,
      color: isSelected ? AppColors.primary.withOpacity(0.05) : null,
      child: InkWell(
        onTap: () => onDroneSelected(drone.id),
        child: Container(
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildStatusIndicator(drone),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            drone.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppColors.primary : null,
                            ),
                          ),
                          Text(
                            drone.model,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppColors.primary,
                        size: 24,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildQuickInfo(drone),
                if (showDetailedInfo || isSelected) ...[
                  const SizedBox(height: 16),
                  _buildDetailedInfo(drone),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(Drone drone) {
    Color statusColor;
    IconData statusIcon;

    if (drone.hasLowBattery) {
      statusColor = Colors.red;
      statusIcon = Icons.battery_alert;
    } else if (drone.needsMaintenance) {
      statusColor = Colors.orange;
      statusIcon = Icons.build;
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(statusIcon, color: statusColor, size: 20),
    );
  }

  Widget _buildQuickInfo(Drone drone) {
    return Row(
      children: [
        _buildInfoChip(
          Icons.battery_full,
          '${drone.batteryLevel}%',
          drone.hasLowBattery ? Colors.red : Colors.green,
        ),
        const SizedBox(width: 8),
        _buildInfoChip(Icons.speed, drone.rangeDisplay, Colors.blue),
        const SizedBox(width: 8),
        _buildInfoChip(
          Icons.fitness_center,
          drone.payloadDisplay,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInfo(Drone drone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        const Text(
          'Specifications',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildSpecificationGrid(drone),
        const SizedBox(height: 16),
        _buildLocationInfo(drone),
        const SizedBox(height: 16),
        _buildMaintenanceInfo(drone),
        const SizedBox(height: 16),
        _buildCapabilities(drone),
      ],
    );
  }

  Widget _buildSpecificationGrid(Drone drone) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSpecItem('Flight Time', drone.flightTimeDisplay),
              ),
              Expanded(child: _buildSpecItem('Max Range', drone.rangeDisplay)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSpecItem('Payload Cap.', drone.payloadDisplay),
              ),
              Expanded(
                child: _buildSpecItem(
                  'Operating Hrs',
                  '${drone.operatingHours.toStringAsFixed(1)}h',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLocationInfo(Drone drone) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.blue[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Location',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${drone.location.latitude.toStringAsFixed(4)}, ${drone.location.longitude.toStringAsFixed(4)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceInfo(Drone drone) {
    Color maintenanceColor = drone.isMaintenanceDue
        ? Colors.red
        : drone.needsMaintenance
        ? Colors.orange
        : Colors.green;

    String maintenanceText;
    if (drone.lastMaintenance != null) {
      final daysSince = DateTime.now()
          .difference(drone.lastMaintenance!)
          .inDays;
      maintenanceText =
          'Last: ${DateFormat('MMM dd').format(drone.lastMaintenance!)} ($daysSince days ago)';
    } else {
      maintenanceText = 'No maintenance records';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: maintenanceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.build, color: maintenanceColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maintenance Status',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: maintenanceColor,
                  ),
                ),
                Text(
                  maintenanceText,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: maintenanceColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              drone.maintenanceStatus,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: maintenanceColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilities(Drone drone) {
    if (drone.capabilities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Capabilities',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: drone.capabilities.map((capability) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Text(
                capability,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class CompactDroneSelector extends StatelessWidget {
  final List<Drone> availableDrones;
  final String? selectedDroneId;
  final Function(String?) onDroneSelected;

  const CompactDroneSelector({
    super.key,
    required this.availableDrones,
    required this.selectedDroneId,
    required this.onDroneSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedDroneId,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Select Drone',
        hintText: 'Choose available drone',
      ),
      validator: (value) {
        if (value == null) {
          return 'Please select a drone';
        }
        return null;
      },
      items: availableDrones.map((drone) {
        return DropdownMenuItem(
          value: drone.id,
          child: _buildDropdownItem(drone),
        );
      }).toList(),
      onChanged: onDroneSelected,
    );
  }

  Widget _buildDropdownItem(Drone drone) {
    return Row(
      children: [
        _buildStatusDot(drone),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${drone.name} - ${drone.model}',
                style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Battery: ${drone.batteryLevel}% | Range: ${drone.rangeDisplay}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDot(Drone drone) {
    Color color;
    if (drone.hasLowBattery) {
      color = Colors.red;
    } else if (drone.needsMaintenance) {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
