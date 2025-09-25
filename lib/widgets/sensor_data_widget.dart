import 'package:flutter/material.dart';
import '../models/ongoing_mission.dart';
import '../core/constants/app_colors.dart';

class SensorDataWidget extends StatelessWidget {
  final SensorData sensorData;
  final bool showDetails;
  final VoidCallback? onTap;

  const SensorDataWidget({
    super.key,
    required this.sensorData,
    this.showDetails = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildSensorGrid(context),
              if (showDetails) ...[
                const SizedBox(height: 16),
                _buildAirQualityDetails(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Environmental Sensors',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getOverallStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getOverallStatusColor()),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getOverallStatusColor(),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _getOverallStatus(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getOverallStatusColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSensorGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSensorCard(
                context,
                'Temperature',
                '${sensorData.temperature.toStringAsFixed(1)}°C',
                Icons.thermostat,
                _getTemperatureColor(),
                _getTemperatureStatus(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSensorCard(
                context,
                'Humidity',
                '${sensorData.humidity.toStringAsFixed(1)}%',
                Icons.water_drop,
                _getHumidityColor(),
                _getHumidityStatus(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSensorCard(
                context,
                'Pressure',
                '${sensorData.pressure.toStringAsFixed(1)} hPa',
                Icons.speed,
                _getPressureColor(),
                _getPressureStatus(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSensorCard(
                context,
                'Air Quality',
                sensorData.airQuality.level.displayName,
                Icons.air,
                sensorData.airQuality.level.color,
                sensorData.airQuality.level.displayName,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSensorCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String status,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              status,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirQualityDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Air Quality Details',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAirQualityItem(
                context,
                'PM2.5',
                '${sensorData.airQuality.pm25.toStringAsFixed(0)} µg/m³',
                _getPM25Color(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAirQualityItem(
                context,
                'CO',
                '${sensorData.airQuality.co.toStringAsFixed(0)} mg/m³',
                _getCOColor(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAirQualityItem(
                context,
                'NO₂',
                '${sensorData.airQuality.no2.toStringAsFixed(0)} µg/m³',
                _getNO2Color(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAirQualityItem(
                context,
                'O₃',
                '${sensorData.airQuality.o3.toStringAsFixed(0)} µg/m³',
                _getO3Color(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAirQualityItem(
                context,
                'SO₂',
                '${sensorData.airQuality.so2.toStringAsFixed(0)} µg/m³',
                _getSO2Color(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Container()), // Empty space for alignment
          ],
        ),
        const SizedBox(height: 12),
        _buildLastUpdated(context),
      ],
    );
  }

  Widget _buildAirQualityItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdated(BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(sensorData.timestamp);
    String timeAgo;

    if (difference.inMinutes < 1) {
      timeAgo = 'Just now';
    } else if (difference.inMinutes < 60) {
      timeAgo = '${difference.inMinutes}m ago';
    } else {
      timeAgo = '${difference.inHours}h ago';
    }

    return Row(
      children: [
        Icon(Icons.update, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          'Last updated: $timeAgo',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // Color and status calculation methods
  Color _getTemperatureColor() {
    if (sensorData.temperature > 40) return AppColors.error;
    if (sensorData.temperature > 35) return AppColors.warning;
    if (sensorData.temperature < 0) return Colors.blue;
    if (sensorData.temperature < 5) return Colors.lightBlue;
    return AppColors.success;
  }

  String _getTemperatureStatus() {
    if (sensorData.temperature > 40) return 'Very Hot';
    if (sensorData.temperature > 35) return 'Hot';
    if (sensorData.temperature < 0) return 'Freezing';
    if (sensorData.temperature < 5) return 'Very Cold';
    if (sensorData.temperature < 15) return 'Cold';
    if (sensorData.temperature < 25) return 'Cool';
    return 'Normal';
  }

  Color _getHumidityColor() {
    if (sensorData.humidity > 80) return AppColors.error;
    if (sensorData.humidity > 70) return AppColors.warning;
    if (sensorData.humidity < 20) return AppColors.warning;
    return AppColors.success;
  }

  String _getHumidityStatus() {
    if (sensorData.humidity > 80) return 'Very High';
    if (sensorData.humidity > 70) return 'High';
    if (sensorData.humidity < 20) return 'Very Low';
    if (sensorData.humidity < 30) return 'Low';
    return 'Normal';
  }

  Color _getPressureColor() {
    if (sensorData.pressure > 1025) return AppColors.warning;
    if (sensorData.pressure < 1000) return AppColors.warning;
    return AppColors.success;
  }

  String _getPressureStatus() {
    if (sensorData.pressure > 1025) return 'High';
    if (sensorData.pressure < 1000) return 'Low';
    return 'Normal';
  }

  Color _getPM25Color() {
    if (sensorData.airQuality.pm25 > 150) return AppColors.error;
    if (sensorData.airQuality.pm25 > 55) return AppColors.warning;
    if (sensorData.airQuality.pm25 > 35) return Colors.orange;
    return AppColors.success;
  }

  Color _getCOColor() {
    if (sensorData.airQuality.co > 30) return AppColors.error;
    if (sensorData.airQuality.co > 15) return AppColors.warning;
    return AppColors.success;
  }

  Color _getNO2Color() {
    if (sensorData.airQuality.no2 > 200) return AppColors.error;
    if (sensorData.airQuality.no2 > 100) return AppColors.warning;
    return AppColors.success;
  }

  Color _getO3Color() {
    if (sensorData.airQuality.o3 > 180) return AppColors.error;
    if (sensorData.airQuality.o3 > 120) return AppColors.warning;
    return AppColors.success;
  }

  Color _getSO2Color() {
    if (sensorData.airQuality.so2 > 500) return AppColors.error;
    if (sensorData.airQuality.so2 > 200) return AppColors.warning;
    return AppColors.success;
  }

  Color _getOverallStatusColor() {
    // Check for critical conditions
    if (sensorData.temperature > 40 || sensorData.temperature < 0) {
      return AppColors.error;
    }
    if (sensorData.humidity > 90) return AppColors.error;
    if (sensorData.airQuality.level.index >= 3) return AppColors.error;

    // Check for warning conditions
    if (sensorData.temperature > 35 || sensorData.temperature < 5) {
      return AppColors.warning;
    }
    if (sensorData.humidity > 80 || sensorData.humidity < 20) {
      return AppColors.warning;
    }
    if (sensorData.airQuality.level.index >= 1) return AppColors.warning;

    return AppColors.success;
  }

  String _getOverallStatus() {
    final color = _getOverallStatusColor();
    if (color == AppColors.error) return 'Critical';
    if (color == AppColors.warning) return 'Warning';
    return 'Normal';
  }
}

// Compact version for use in lists
class CompactSensorDataWidget extends StatelessWidget {
  final SensorData sensorData;
  final VoidCallback? onTap;

  const CompactSensorDataWidget({
    super.key,
    required this.sensorData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.sensors, color: _getOverallStatusColor(), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Environmental Data',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${sensorData.temperature.toStringAsFixed(1)}°C • ${sensorData.humidity.toStringAsFixed(0)}% • ${sensorData.airQuality.level.displayName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getOverallStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getOverallStatus(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getOverallStatusColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getOverallStatusColor() {
    if (sensorData.temperature > 40 || sensorData.temperature < 0) {
      return AppColors.error;
    }
    if (sensorData.humidity > 90) return AppColors.error;
    if (sensorData.airQuality.level.index >= 3) return AppColors.error;

    if (sensorData.temperature > 35 || sensorData.temperature < 5) {
      return AppColors.warning;
    }
    if (sensorData.humidity > 80 || sensorData.humidity < 20) {
      return AppColors.warning;
    }
    if (sensorData.airQuality.level.index >= 1) return AppColors.warning;

    return AppColors.success;
  }

  String _getOverallStatus() {
    final color = _getOverallStatusColor();
    if (color == AppColors.error) return 'Critical';
    if (color == AppColors.warning) return 'Warning';
    return 'Normal';
  }
}
