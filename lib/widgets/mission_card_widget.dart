import 'package:flutter/material.dart';
import '../models/ongoing_mission.dart';
import '../models/mission.dart';
import '../core/constants/app_colors.dart';

class MissionCardWidget extends StatelessWidget {
  final OngoingMission mission;
  final VoidCallback? onTap;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onAbort;

  const MissionCardWidget({
    super.key,
    required this.mission,
    this.onTap,
    this.onPause,
    this.onResume,
    this.onAbort,
  });

  @override
  Widget build(BuildContext context) {
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [_buildHeader(context), _buildContent(context)],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                    _buildPriorityChip(context, mission.priority),
                    const SizedBox(width: 8),
                    _buildStatusChip(context, mission.status),
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
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mission.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: AppColors.error),
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
              const Icon(Icons.gps_fixed, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'GPS: ${mission.currentGPS.latitude.toStringAsFixed(4)}, ${mission.currentGPS.longitude.toStringAsFixed(4)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSensorDataRow(context),
          const SizedBox(height: 12),
          _buildProgressSection(context),
          const SizedBox(height: 12),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildSensorDataRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSensorItem(
            context,
            'Temp',
            '${mission.sensorReadings.temperature.toStringAsFixed(1)}°C',
            Icons.thermostat,
            _getTemperatureColor(mission.sensorReadings.temperature),
          ),
        ),
        Expanded(
          child: _buildSensorItem(
            context,
            'Humidity',
            '${mission.sensorReadings.humidity.toStringAsFixed(0)}%',
            Icons.water_drop,
            AppColors.primary,
          ),
        ),
        Expanded(
          child: _buildSensorItem(
            context,
            'PM2.5',
            mission.sensorReadings.airQuality.pm25.toStringAsFixed(0),
            Icons.air,
            mission.sensorReadings.airQuality.level.color,
          ),
        ),
        Expanded(
          child: _buildSensorItem(
            context,
            'CO',
            mission.sensorReadings.airQuality.co.toStringAsFixed(0),
            Icons.cloud,
            _getAirQualityColor(mission.sensorReadings.airQuality.co, 15),
          ),
        ),
      ],
    );
  }

  Widget _buildSensorItem(
    BuildContext context,
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

  Widget _buildProgressSection(BuildContext context) {
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
            backgroundColor: AppColors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(mission.missionProgress.completionPercentage),
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTap,
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
              onPressed: onPause,
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
              onPressed: onResume,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Resume'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
            ),
          ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onAbort,
          icon: const Icon(Icons.stop, color: AppColors.error),
          tooltip: 'Abort Mission',
        ),
      ],
    );
  }

  Widget _buildPriorityChip(BuildContext context, MissionPriority priority) {
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

  Widget _buildStatusChip(BuildContext context, MissionStatus status) {
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
}
