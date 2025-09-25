import 'package:flutter/material.dart';
import '../models/ongoing_mission.dart';
import '../models/user.dart';
import '../core/constants/app_colors.dart';
import 'dart:math' as math;

class GPSTrackingWidget extends StatelessWidget {
  final GPSReading gpsReading;
  final LocationData? targetLocation;
  final bool showDetails;
  final VoidCallback? onTap;

  const GPSTrackingWidget({
    super.key,
    required this.gpsReading,
    this.targetLocation,
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
              _buildLocationGrid(context),
              if (showDetails && targetLocation != null) ...[
                const SizedBox(height: 16),
                _buildNavigationDetails(context),
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
          'GPS Tracking',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getAccuracyColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getAccuracyColor()),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getAccuracyColor(),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _getSignalStatus(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getAccuracyColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildLocationCard(
                context,
                'Latitude',
                '${gpsReading.latitude.toStringAsFixed(6)}°',
                Icons.place,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLocationCard(
                context,
                'Longitude',
                '${gpsReading.longitude.toStringAsFixed(6)}°',
                Icons.place,
                AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildLocationCard(
                context,
                'Altitude',
                '${gpsReading.altitude.toStringAsFixed(1)} m',
                Icons.height,
                _getAltitudeColor(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLocationCard(
                context,
                'Speed',
                '${gpsReading.speed.toStringAsFixed(1)} m/s',
                Icons.speed,
                _getSpeedColor(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildLocationCard(
                context,
                'Heading',
                '${gpsReading.heading.toStringAsFixed(0)}° ${_getCardinalDirection()}',
                Icons.navigation,
                AppColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLocationCard(
                context,
                'Accuracy',
                '±${gpsReading.accuracy.toStringAsFixed(1)} m',
                Icons.gps_fixed,
                _getAccuracyColor(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationDetails(BuildContext context) {
    if (targetLocation == null) return Container();

    final distance = _calculateDistance(
      gpsReading.latitude,
      gpsReading.longitude,
      targetLocation!.latitude,
      targetLocation!.longitude,
    );

    final bearing = _calculateBearing(
      gpsReading.latitude,
      gpsReading.longitude,
      targetLocation!.latitude,
      targetLocation!.longitude,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Navigation to Target',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildNavigationItem(
                      context,
                      'Distance to Target',
                      '${distance.toStringAsFixed(2)} km',
                      Icons.straighten,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNavigationItem(
                      context,
                      'Bearing',
                      '${bearing.toStringAsFixed(0)}°',
                      Icons.explore,
                      AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (gpsReading.speed > 0) ...[
                _buildNavigationItem(
                  context,
                  'ETA (at current speed)',
                  _calculateETA(distance, gpsReading.speed),
                  Icons.access_time,
                  AppColors.success,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildLastUpdated(context),
      ],
    );
  }

  Widget _buildNavigationItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
        ),
      ],
    );
  }

  Widget _buildLastUpdated(BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(gpsReading.timestamp);
    String timeAgo;

    if (difference.inSeconds < 30) {
      timeAgo = 'Just now';
    } else if (difference.inMinutes < 1) {
      timeAgo = '${difference.inSeconds}s ago';
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

  // Helper methods
  Color _getAccuracyColor() {
    if (gpsReading.accuracy <= 3) return AppColors.success;
    if (gpsReading.accuracy <= 10) return AppColors.warning;
    return AppColors.error;
  }

  String _getSignalStatus() {
    if (gpsReading.accuracy <= 3) return 'Excellent';
    if (gpsReading.accuracy <= 10) return 'Good';
    return 'Poor';
  }

  Color _getAltitudeColor() {
    if (gpsReading.altitude < 0) return AppColors.error;
    if (gpsReading.altitude > 500) return AppColors.warning;
    return AppColors.success;
  }

  Color _getSpeedColor() {
    if (gpsReading.speed > 30) return AppColors.warning;
    if (gpsReading.speed > 50) return AppColors.error;
    return AppColors.success;
  }

  String _getCardinalDirection() {
    final heading = gpsReading.heading;
    if (heading >= 337.5 || heading < 22.5) return 'N';
    if (heading >= 22.5 && heading < 67.5) return 'NE';
    if (heading >= 67.5 && heading < 112.5) return 'E';
    if (heading >= 112.5 && heading < 157.5) return 'SE';
    if (heading >= 157.5 && heading < 202.5) return 'S';
    if (heading >= 202.5 && heading < 247.5) return 'SW';
    if (heading >= 247.5 && heading < 292.5) return 'W';
    if (heading >= 292.5 && heading < 337.5) return 'NW';
    return 'N';
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = _degreesToRadians(lon2 - lon1);
    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);

    final y = math.sin(dLon) * math.cos(lat2Rad);
    final x =
        math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);

    final heading = math.atan2(y, x);
    return (heading * 180 / math.pi + 360) % 360;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  String _calculateETA(double distanceKm, double speedMs) {
    final speedKmH = speedMs * 3.6; // Convert m/s to km/h
    final timeHours = distanceKm / speedKmH;
    final timeMinutes = timeHours * 60;

    if (timeMinutes < 60) {
      return '${timeMinutes.toStringAsFixed(0)} min';
    } else {
      final hours = timeMinutes ~/ 60;
      final minutes = timeMinutes % 60;
      return '${hours}h ${minutes.toStringAsFixed(0)}m';
    }
  }
}

// Compact version for use in lists
class CompactGPSWidget extends StatelessWidget {
  final GPSReading gpsReading;
  final VoidCallback? onTap;

  const CompactGPSWidget({super.key, required this.gpsReading, this.onTap});

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
            Icon(Icons.gps_fixed, color: _getAccuracyColor(), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GPS Location',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${gpsReading.latitude.toStringAsFixed(4)}, ${gpsReading.longitude.toStringAsFixed(4)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${gpsReading.speed.toStringAsFixed(1)} m/s',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '±${gpsReading.accuracy.toStringAsFixed(1)}m',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: _getAccuracyColor()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getAccuracyColor() {
    if (gpsReading.accuracy <= 3) return AppColors.success;
    if (gpsReading.accuracy <= 10) return AppColors.warning;
    return AppColors.error;
  }
}
