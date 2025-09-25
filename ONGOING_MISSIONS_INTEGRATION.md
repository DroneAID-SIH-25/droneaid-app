# Ongoing Missions System Integration Guide

This guide explains how to integrate the new ongoing missions real-time monitoring system into your Drone Aid application.

## Quick Start

### 1. Add Provider to Your App

First, register the `OngoingMissionsProvider` in your main app:

```dart
// main.dart
import 'package:provider/provider.dart';
import 'providers/ongoing_missions_provider.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ... other providers
        ChangeNotifierProvider(create: (_) => OngoingMissionsProvider()),
      ],
      child: MaterialApp(
        // ... app configuration
      ),
    );
  }
}
```

### 2. Navigate to Enhanced Ongoing Missions Screen

Replace your existing ongoing missions screen with the enhanced version:

```dart
// In your navigation/routing
import 'screens/gcs/enhanced_ongoing_missions_screen.dart';

// Navigate to the screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const EnhancedOngoingMissionsScreen(),
  ),
);
```

### 3. Initialize the Provider

The provider will automatically initialize when the screen is first accessed. You can also manually initialize:

```dart
// Initialize manually if needed
final provider = Provider.of<OngoingMissionsProvider>(context, listen: false);
await provider.initialize();
```

## Components Overview

### Core Components

1. **Models**
   - `OngoingMission` - Extended mission with real-time data
   - `GPSReading` - Live GPS coordinates and movement data
   - `SensorData` - Environmental sensor readings
   - `AirQualityReading` - Air quality measurements with automatic level calculation

2. **Services**
   - `RealTimeMissionService` - Handles real-time data simulation and streaming
   - Manages mission monitoring streams and data updates

3. **Provider**
   - `OngoingMissionsProvider` - State management for ongoing missions
   - Handles filtering, searching, and real-time updates

4. **Widgets**
   - `EnhancedOngoingMissionsScreen` - Main dashboard
   - `MissionCardWidget` - Individual mission cards
   - `SensorDataWidget` - Environmental data display
   - `GPSTrackingWidget` - GPS tracking display

## Features

### Real-time Monitoring

- **Live GPS Updates**: Drone positions update every 5 seconds
- **Sensor Data Streaming**: Temperature, humidity, air quality readings
- **Progress Tracking**: Real-time mission completion percentage
- **ETA Calculations**: Dynamic arrival time estimates

### Mission Management

- **Pause/Resume**: Control mission execution
- **Abort Mission**: Emergency stop with confirmation dialog
- **Mission Details**: Comprehensive information modal
- **Filter & Search**: Find missions by status, priority, type, or keywords

### Visual Indicators

- **Status Badges**: Color-coded mission status
- **Priority Chips**: Visual priority indicators
- **Progress Bars**: Mission completion visualization
- **Alert Notifications**: Critical sensor reading warnings

## Customization

### Adding Real Data Sources

To replace mock data with real data sources, modify the `RealTimeMissionService`:

```dart
// Example: Connect to real WebSocket
class RealTimeMissionService {
  WebSocketChannel? _websocket;
  
  Stream<OngoingMission> startMissionMonitoring(String missionId) {
    // Replace mock timer with WebSocket stream
    _websocket = WebSocketChannel.connect(
      Uri.parse('ws://your-api/missions/$missionId/stream'),
    );
    
    return _websocket!.stream.map((data) {
      final json = jsonDecode(data);
      return OngoingMission.fromJson(json);
    });
  }
}
```

### Custom Alert Thresholds

Configure custom alert thresholds for sensor readings:

```dart
// In your configuration
class AlertConfig {
  static const double maxTemperature = 45.0;
  static const double minTemperature = -10.0;
  static const double maxHumidity = 90.0;
  static const double maxPM25 = 150.0;
}
```

### Custom Mission Card Layout

Extend the `MissionCardWidget` for custom layouts:

```dart
class CustomMissionCard extends MissionCardWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Your custom header
          _buildCustomHeader(),
          // Original content
          super.build(context),
          // Your custom footer
          _buildCustomFooter(),
        ],
      ),
    );
  }
}
```

## Error Handling

### Network Connectivity

The system handles network issues gracefully:

```dart
// Provider automatically handles connection errors
class OngoingMissionsProvider extends ChangeNotifier {
  void _handleError(String error) {
    _setError(error);
    // Automatic retry after delay
    Timer(Duration(seconds: 5), () => refreshMissions());
  }
}
```

### Data Validation

All sensor data is validated before display:

```dart
// Example validation in SensorData
class SensorData {
  bool get isValid {
    return temperature >= -50 && temperature <= 60 &&
           humidity >= 0 && humidity <= 100 &&
           pressure > 0;
  }
}
```

## Performance Optimization

### Stream Management

Streams are properly managed to prevent memory leaks:

```dart
// Automatic cleanup on dispose
@override
void dispose() {
  for (final subscription in _missionSubscriptions.values) {
    subscription.cancel();
  }
  _realTimeService.dispose();
  super.dispose();
}
```

### Efficient Updates

Updates are throttled to maintain performance:

```dart
// 5-second update intervals
Timer.periodic(
  const Duration(seconds: 5),
  (timer) => _updateMissionData(missionId),
);
```

## Testing

### Unit Tests

Test individual components:

```dart
// test/ongoing_mission_test.dart
void main() {
  group('OngoingMission Tests', () {
    test('should calculate distance to target correctly', () {
      final mission = createTestMission();
      final distance = mission.distanceToTarget;
      expect(distance, greaterThan(0));
    });
  });
}
```

### Widget Tests

Test UI components:

```dart
// test/widget/mission_card_test.dart
void main() {
  testWidgets('MissionCard displays mission info', (tester) async {
    final mission = createTestMission();
    
    await tester.pumpWidget(
      MaterialApp(
        home: MissionCardWidget(mission: mission),
      ),
    );
    
    expect(find.text(mission.title), findsOneWidget);
    expect(find.text(mission.assignedDroneId), findsOneWidget);
  });
}
```

## Troubleshooting

### Common Issues

1. **Provider Not Found**
   ```
   Error: Could not find the correct Provider<OngoingMissionsProvider>
   Solution: Ensure provider is registered in main.dart
   ```

2. **Stream Not Updating**
   ```
   Issue: Real-time data not updating
   Solution: Check if mission is added to active monitoring
   ```

3. **Memory Leaks**
   ```
   Issue: App performance degrading over time
   Solution: Ensure proper disposal of streams and timers
   ```

### Debug Mode

Enable debug logging for troubleshooting:

```dart
// Enable debug mode
class RealTimeMissionService {
  static const bool debugMode = true;
  
  void _log(String message) {
    if (debugMode) {
      print('[RealTimeMissionService] $message');
    }
  }
}
```

## Migration from Existing System

### Step-by-Step Migration

1. **Backup Current Implementation**
   - Save your existing ongoing missions screen
   - Document any custom modifications

2. **Install New Components**
   - Add new model files
   - Add service and provider files
   - Add new widget files

3. **Update Navigation**
   - Replace routes to use new screen
   - Update any deep links or shortcuts

4. **Test Integration**
   - Verify all features work as expected
   - Test with various mission states
   - Validate real-time updates

5. **Deploy Gradually**
   - Consider feature flags for gradual rollout
   - Monitor performance and user feedback

### Data Migration

If you have existing mission data:

```dart
// Convert existing missions to OngoingMission format
OngoingMission convertToOngoingMission(Mission mission) {
  return OngoingMission.fromMission(
    mission,
    currentGPS: generateMockGPS(mission.targetLocation),
    sensorReadings: generateMockSensorData(),
    eta: calculateETA(mission),
    missionProgress: calculateProgress(mission),
  );
}
```

## Best Practices

### Code Organization

- Keep models, services, and UI components separate
- Use consistent naming conventions
- Document custom modifications
- Follow Flutter/Dart style guidelines

### Performance

- Monitor stream subscriptions and dispose properly
- Use const constructors where possible
- Optimize widget rebuilds with proper keys
- Cache frequently accessed data

### User Experience

- Provide loading indicators during data updates
- Show meaningful error messages
- Implement proper accessibility features
- Test on various screen sizes and orientations

## Support

For issues or questions regarding the ongoing missions system:

1. Check the implementation documentation
2. Review common troubleshooting steps
3. Test with mock data to isolate issues
4. Verify all dependencies are properly installed

## Version History

- **v1.0.0** - Initial implementation with real-time monitoring
- Features: Live GPS tracking, sensor data display, mission management
- Platform: Flutter 3.x+, Provider state management