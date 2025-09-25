import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:drone_aid/screens/gcs/gcs_main_screen.dart';
import 'package:drone_aid/providers/group_management_provider.dart';
import 'package:drone_aid/models/group_event.dart';
import 'package:drone_aid/models/gcs_station.dart';

void main() {
  group('GCS Navigation System Tests', () {
    late GroupManagementProvider mockProvider;

    setUp(() {
      mockProvider = GroupManagementProvider();
    });

    testWidgets('GCS Main Screen initializes with correct tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<GroupManagementProvider>.value(
            value: mockProvider,
            child: const GCSMainScreen(),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify the bottom navigation bar exists
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Verify all 4 tabs are present
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Ongoing'), findsOneWidget);
      expect(find.text('Create Group'), findsOneWidget);
      expect(find.text('Create Mission'), findsOneWidget);
    });

    testWidgets('Tab navigation works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<GroupManagementProvider>.value(
            value: mockProvider,
            child: const GCSMainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially should be on Map tab (index 0)
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, equals(0));

      // Tap on Create Group tab
      await tester.tap(find.text('Create Group'));
      await tester.pumpAndSettle();

      // Verify navigation occurred
      expect(find.text('Create Event/Group'), findsOneWidget);
    });

    testWidgets('App bar updates title based on current tab', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<GroupManagementProvider>.value(
            value: mockProvider,
            child: const GCSMainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially should show Operations Center
      expect(find.text('Operations Center'), findsOneWidget);

      // Navigate to Create Group tab
      await tester.tap(find.text('Create Group'));
      await tester.pumpAndSettle();

      // App bar should update to Event Management
      expect(find.text('Event Management'), findsOneWidget);
    });

    test('GroupManagementProvider initializes correctly', () {
      final provider = GroupManagementProvider();

      expect(provider.events, isEmpty);
      expect(provider.gcsStations, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, null);
    });

    test('GroupManagementProvider mock data loads correctly', () {
      final provider = GroupManagementProvider();
      provider.initializeMockData();

      expect(provider.events, isNotEmpty);
      expect(provider.gcsStations, isNotEmpty);
      expect(provider.events.length, greaterThan(3));
      expect(provider.gcsStations.length, greaterThan(3));
    });

    test('Event filtering works correctly', () {
      final provider = GroupManagementProvider();
      provider.initializeMockData();

      final activeEvents = provider.activeEvents;
      final criticalEvents = provider.criticalEvents;

      expect(activeEvents.every((event) => event.isOngoing), true);
      expect(criticalEvents.every((event) => event.isCritical), true);
    });

    test('GCS Station filtering works correctly', () {
      final provider = GroupManagementProvider();
      provider.initializeMockData();

      final operationalStations = provider.operationalStations;
      final availableStations = provider.availableStations;

      expect(
        operationalStations.every((station) => station.isOperational),
        true,
      );
      expect(
        availableStations.every((station) => station.canAcceptNewEvents),
        true,
      );
    });

    test('Event creation works correctly', () async {
      final provider = GroupManagementProvider();

      final testEvent = GroupEvent(
        title: 'Test Event',
        description: 'This is a test event',
        type: EventType.flood,
        severity: EventSeverity.moderate,
        priority: EventPriority.medium,
        location: const LocationData(
          latitude: 19.0760,
          longitude: 72.8777,
          address: 'Test Location',
        ),
        createdBy: 'test-user',
      );

      await provider.createEvent(testEvent);

      expect(provider.events, contains(testEvent));
      expect(provider.events.first.title, equals('Test Event'));
    });

    test('Station assignment to event works', () async {
      final provider = GroupManagementProvider();
      provider.initializeMockData();

      final event = provider.events.first;
      final station = provider.gcsStations.first;

      await provider.assignStationToEvent(event.id, station.id);

      final updatedStation = provider.getStationById(station.id);
      expect(updatedStation?.assignedEventIds, contains(event.id));
    });

    test('Search functionality works correctly', () {
      final provider = GroupManagementProvider();
      provider.initializeMockData();

      final searchResults = provider.searchEvents('flood');
      expect(
        searchResults.every(
          (event) =>
              event.title.toLowerCase().contains('flood') ||
              event.description.toLowerCase().contains('flood') ||
              event.typeDisplay.toLowerCase().contains('flood'),
        ),
        true,
      );
    });

    test('Statistics calculation works correctly', () {
      final provider = GroupManagementProvider();
      provider.initializeMockData();

      expect(provider.totalActiveEvents, greaterThanOrEqualTo(0));
      expect(provider.totalCriticalEvents, greaterThanOrEqualTo(0));
      expect(provider.totalOperationalStations, greaterThanOrEqualTo(0));
      expect(provider.totalAvailableStations, greaterThanOrEqualTo(0));

      final eventStatsByType = provider.getEventStatsByType();
      final eventStatsByStatus = provider.getEventStatsByStatus();
      final stationStatsByStatus = provider.getStationStatsByStatus();

      expect(eventStatsByType, isA<Map<String, int>>());
      expect(eventStatsByStatus, isA<Map<String, int>>());
      expect(stationStatsByStatus, isA<Map<String, int>>());
    });
  });

  group('GCS Models Tests', () {
    test('GCSStation model works correctly', () {
      final station = GCSStation(
        name: 'Test Station',
        code: 'TEST-001',
        location: 'Test Location',
        coordinates: const LocationData(
          latitude: 19.0760,
          longitude: 72.8777,
          address: 'Test Address',
        ),
        organizationId: 'org-001',
        contactEmail: 'test@example.com',
        contactPhone: '+91-1234567890',
        maxCapacity: 10,
        currentOperators: 5,
      );

      expect(station.name, equals('Test Station'));
      expect(station.isOperational, true);
      expect(station.hasCapacity, true);
      expect(station.capacityPercentage, equals(50.0));
      expect(station.canAcceptNewEvents, true);
    });

    test('GroupEvent model works correctly', () {
      final event = GroupEvent(
        title: 'Test Event',
        description: 'Test Description',
        type: EventType.flood,
        severity: EventSeverity.moderate,
        priority: EventPriority.medium,
        location: const LocationData(
          latitude: 19.0760,
          longitude: 72.8777,
          address: 'Test Location',
        ),
        createdBy: 'test-user',
      );

      expect(event.title, equals('Test Event'));
      expect(event.typeDisplay, equals('Flood'));
      expect(event.severityDisplay, equals('Moderate'));
      expect(event.priorityDisplay, equals('Medium'));
      expect(event.isActive, true);
    });

    test('Event enums work correctly', () {
      expect(EventType.flood.displayName, equals('Flood'));
      expect(EventStatus.active.displayName, equals('Active'));
      expect(EventSeverity.critical.displayName, equals('Critical'));
      expect(EventPriority.high.displayName, equals('High'));
    });

    test('Station enums work correctly', () {
      expect(StationStatus.operational.displayName, equals('Operational'));
      expect(StationType.fixed.displayName, equals('Fixed Station'));
    });
  });

  group('Integration Tests', () {
    testWidgets('Full workflow: Create Group → View in List', (
      WidgetTester tester,
    ) async {
      final provider = GroupManagementProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<GroupManagementProvider>.value(
            value: provider,
            child: const GCSMainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to Create Group tab
      await tester.tap(find.text('Create Group'));
      await tester.pumpAndSettle();

      // Verify create group form is displayed
      expect(find.text('Create Event/Group'), findsOneWidget);
      expect(find.text('Event Name *'), findsOneWidget);
      expect(find.text('Description *'), findsOneWidget);
    });

    testWidgets('Navigation between all tabs works', (
      WidgetTester tester,
    ) async {
      final provider = GroupManagementProvider();
      provider.initializeMockData();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<GroupManagementProvider>.value(
            value: provider,
            child: const GCSMainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test all tab navigations
      final tabs = ['Map', 'Ongoing', 'Create Group', 'Create Mission'];
      final expectedTitles = [
        'Operations Center',
        'Active Missions',
        'Event Management',
        'Mission Control',
      ];

      for (int i = 0; i < tabs.length; i++) {
        await tester.tap(find.text(tabs[i]));
        await tester.pumpAndSettle();
        expect(find.text(expectedTitles[i]), findsOneWidget);
      }
    });
  });
}
