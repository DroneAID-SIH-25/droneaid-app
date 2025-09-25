import 'dart:math';
import '../models/drone.dart';
import '../models/emergency_request.dart';
import '../models/user.dart';
import '../providers/notification_provider.dart';

class MockDataService {
  static const List<String> _droneNames = [
    'Rescue Hawk',
    'Sky Guardian',
    'Emergency Eagle',
    'Medical Wing',
    'Storm Tracker',
    'Fire Fighter',
    'Search Scout',
    'Thunder Bird',
    'Life Saver',
    'Crisis Responder',
  ];

  static const List<String> _droneModels = [
    'DJI Matrice 300',
    'DJI Inspire 2',
    'Autel EVO MAX',
    'Skydio 2+',
    'Parrot ANAFI USA',
    'Yuneec H520',
    'Freefly Alta X',
    'DJI Air 2S',
    'Boeing ScanEagle',
    'General Atomics MQ-9',
  ];

  static final List<LocationData> _indiaBaseLocations = [
    LocationData(latitude: 28.6139, longitude: 77.2090, address: 'New Delhi'),
    LocationData(latitude: 19.0760, longitude: 72.8777, address: 'Mumbai'),
    LocationData(latitude: 12.9716, longitude: 77.5946, address: 'Bangalore'),
    LocationData(latitude: 13.0827, longitude: 80.2707, address: 'Chennai'),
    LocationData(latitude: 22.5726, longitude: 88.3639, address: 'Kolkata'),
    LocationData(latitude: 26.9124, longitude: 75.7873, address: 'Jaipur'),
    LocationData(latitude: 21.1458, longitude: 79.0882, address: 'Nagpur'),
    LocationData(latitude: 23.0225, longitude: 72.5714, address: 'Ahmedabad'),
    LocationData(latitude: 17.3850, longitude: 78.4867, address: 'Hyderabad'),
    LocationData(latitude: 15.2993, longitude: 74.1240, address: 'Goa'),
  ];

  Future<List<Drone>> getMockDrones() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    final random = Random();
    final List<Drone> drones = [];

    for (int i = 0; i < 15; i++) {
      final baseLocation =
          _indiaBaseLocations[random.nextInt(_indiaBaseLocations.length)];

      // Generate random location around base (within 5km radius)
      final double offsetLat = (random.nextDouble() - 0.5) * 0.09; // ~5km
      final double offsetLng = (random.nextDouble() - 0.5) * 0.09;

      final droneLocation = LocationData(
        latitude: baseLocation.latitude + offsetLat,
        longitude: baseLocation.longitude + offsetLng,
        address: '${baseLocation.address} Sector',
        timestamp: DateTime.now(),
        accuracy: 5.0 + random.nextDouble() * 10.0,
      );

      final drone = Drone(
        name: _droneNames[i % _droneNames.length],
        model: _droneModels[random.nextInt(_droneModels.length)],
        status: DroneStatus.values[random.nextInt(DroneStatus.values.length)],
        batteryLevel: 20 + random.nextInt(80), // 20-100%
        location: droneLocation,
        capabilities: _generateRandomCapabilities(random),
        maxFlightTime: 20 + random.nextInt(40), // 20-60 minutes
        maxRange: 5.0 + random.nextDouble() * 15.0, // 5-20 km
        payloadCapacity: 1.0 + random.nextDouble() * 4.0, // 1-5 kg
        currentMissionId: random.nextBool()
            ? 'mission_${random.nextInt(100)}'
            : null,
        operatingHours: random.nextDouble() * 1000, // 0-1000 hours
        serialNumber: 'DR-${(i + 1).toString().padLeft(3, '0')}',
        lastMaintenance: DateTime.now().subtract(
          Duration(days: random.nextInt(60)),
        ),
        nextMaintenance: DateTime.now().add(
          Duration(days: random.nextInt(30) + 7),
        ),
      );

      drones.add(drone);
    }

    return drones;
  }

  List<String> _generateRandomCapabilities(Random random) {
    final capabilities = [
      'Search',
      'Rescue',
      'Medical Delivery',
      'Surveillance',
      'Thermal Imaging',
      'Night Vision',
      'Live Streaming',
      'Cargo Transport',
      'Weather Monitoring',
      'Firefighting',
    ];

    final count = 2 + random.nextInt(4); // 2-5 capabilities
    final selected = <String>[];

    while (selected.length < count) {
      final capability = capabilities[random.nextInt(capabilities.length)];
      if (!selected.contains(capability)) {
        selected.add(capability);
      }
    }

    return selected;
  }

  Future<List<EmergencyRequest>> getUserEmergencyRequests(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final random = Random();
    final List<EmergencyRequest> requests = [];

    // Generate 5-10 mock requests
    final requestCount = 5 + random.nextInt(6);

    for (int i = 0; i < requestCount; i++) {
      final emergencyType =
          EmergencyType.values[random.nextInt(EmergencyType.values.length)];
      final status = i == 0 && random.nextBool()
          ? EmergencyStatus
                .inProgress // Make first one potentially active
          : EmergencyStatus.values[random.nextInt(
              EmergencyStatus.values.length,
            )];

      final createdAt = DateTime.now().subtract(
        Duration(
          days: random.nextInt(30),
          hours: random.nextInt(24),
          minutes: random.nextInt(60),
        ),
      );

      final location =
          _indiaBaseLocations[random.nextInt(_indiaBaseLocations.length)];
      final randomLocation = LocationData(
        latitude: location.latitude + (random.nextDouble() - 0.5) * 0.02,
        longitude: location.longitude + (random.nextDouble() - 0.5) * 0.02,
        address: '${location.address} ${random.nextInt(100)} Area',
        timestamp: createdAt,
      );

      final request = EmergencyRequest(
        userId: userId,
        emergencyType: emergencyType,
        description: _generateEmergencyDescription(emergencyType),
        location: randomLocation,
        status: status,
        priority: emergencyType.defaultPriority,
        createdAt: createdAt,
        contactNumber: '+91${random.nextInt(9000000000) + 1000000000}',
        assignedMissionId: status != EmergencyStatus.pending
            ? 'mission_${random.nextInt(1000)}'
            : null,
        resolvedAt: status == EmergencyStatus.resolved
            ? createdAt.add(Duration(minutes: 30 + random.nextInt(120)))
            : null,
        updates: _generateEmergencyUpdates(status, createdAt),
        images: _generateMockImageUrls(random.nextInt(4)),
      );

      requests.add(request);
    }

    // Sort by creation date (newest first)
    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return requests;
  }

  String _generateEmergencyDescription(EmergencyType type) {
    final descriptions = {
      EmergencyType.medicalEmergency: [
        'Person unconscious, needs immediate medical attention',
        'Heart attack victim, requires emergency response',
        'Severe injury from accident, bleeding heavily',
        'Elderly person fell and cannot get up',
        'Child having severe allergic reaction',
      ],
      EmergencyType.fireEmergency: [
        'Building on fire, people trapped inside',
        'Forest fire spreading rapidly',
        'Gas leak explosion, fire spreading',
        'Vehicle caught fire on highway',
        'Electrical fire in residential area',
      ],
      EmergencyType.naturalDisaster: [
        'Earthquake victims trapped in rubble',
        'Flood waters rising, people stranded',
        'Cyclone damage, power lines down',
        'Landslide blocking road, casualties reported',
        'Tsunami warning, coastal evacuation needed',
      ],
      EmergencyType.accident: [
        'Multi-vehicle collision on highway',
        'Construction site accident, worker injured',
        'Boat capsized in river',
        'Aircraft emergency landing required',
        'Train derailment with casualties',
      ],
      EmergencyType.security: [
        'Robbery in progress, suspects armed',
        'Terrorist threat reported in area',
        'Kidnapping reported, victim location unknown',
        'Bomb threat at public building',
        'Armed conflict, civilians in danger',
      ],
      EmergencyType.searchAndRescue: [
        'Hiker missing in mountains for 2 days',
        'Child lost in dense forest area',
        'Climber stranded on cliff face',
        'Swimmer missing in lake',
        'Pilot missing after small plane crash',
      ],
    };

    final typeDescriptions =
        descriptions[type] ?? ['Emergency situation requiring assistance'];
    final random = Random();
    return typeDescriptions[random.nextInt(typeDescriptions.length)];
  }

  List<EmergencyUpdate> _generateEmergencyUpdates(
    EmergencyStatus status,
    DateTime createdAt,
  ) {
    final updates = <EmergencyUpdate>[];

    // Initial update
    updates.add(
      EmergencyUpdate(
        requestId: 'temp_id',
        updatedBy: 'System',
        message: 'Emergency request received and being processed',
        timestamp: createdAt,
      ),
    );

    if (status == EmergencyStatus.pending) return updates;

    // Assignment update
    updates.add(
      EmergencyUpdate(
        requestId: 'temp_id',
        updatedBy: 'GCS Operator',
        message:
            'Emergency request assigned to drone unit. Preparing for deployment.',
        timestamp: createdAt.add(const Duration(minutes: 2)),
      ),
    );

    if (status == EmergencyStatus.assigned) return updates;

    // In progress updates
    updates.add(
      EmergencyUpdate(
        requestId: 'temp_id',
        updatedBy: 'Drone System',
        message: 'Drone has taken off and is en route to your location.',
        timestamp: createdAt.add(const Duration(minutes: 5)),
      ),
    );

    updates.add(
      EmergencyUpdate(
        requestId: 'temp_id',
        updatedBy: 'Drone System',
        message: 'Drone is approaching your location. ETA: 2 minutes.',
        timestamp: createdAt.add(const Duration(minutes: 15)),
      ),
    );

    if (status == EmergencyStatus.inProgress) return updates;

    // Resolution update
    if (status == EmergencyStatus.resolved) {
      updates.add(
        EmergencyUpdate(
          requestId: 'temp_id',
          updatedBy: 'Emergency Services',
          message:
              'Emergency response completed successfully. Ground units have arrived.',
          timestamp: createdAt.add(const Duration(minutes: 30)),
        ),
      );
    } else if (status == EmergencyStatus.cancelled) {
      updates.add(
        EmergencyUpdate(
          requestId: 'temp_id',
          updatedBy: 'User',
          message: 'Emergency request cancelled by user.',
          timestamp: createdAt.add(const Duration(minutes: 10)),
        ),
      );
    }

    return updates;
  }

  List<String> _generateMockImageUrls(int count) {
    final urls = <String>[];
    for (int i = 0; i < count; i++) {
      urls.add('https://picsum.photos/400/300?random=$i');
    }
    return urls;
  }

  Future<void> createEmergencyRequest(EmergencyRequest request) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));

    // In a real app, this would send the request to the server
    // For now, we just simulate success
  }

  Future<List<AppNotification>> getMockNotifications() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final random = Random();
    final notifications = <AppNotification>[];

    // Generate 10-15 notifications
    for (int i = 0; i < 12; i++) {
      final type = NotificationType
          .values[random.nextInt(NotificationType.values.length)];
      final priority = NotificationPriority
          .values[random.nextInt(NotificationPriority.values.length)];

      final notification = AppNotification(
        id: 'notification_$i',
        title: _getNotificationTitle(type),
        body: _getNotificationBody(type),
        type: type,
        priority: priority,
        timestamp: DateTime.now().subtract(
          Duration(hours: random.nextInt(72), minutes: random.nextInt(60)),
        ),
        isRead: random.nextBool(),
      );

      notifications.add(notification);
    }

    return notifications;
  }

  Future<List<AppNotification>> getMockDisasterAlerts() async {
    await Future.delayed(const Duration(milliseconds: 150));

    return [
      AppNotification(
        id: 'disaster_1',
        title: 'Cyclone Warning',
        body:
            'Severe cyclone Biparjoy approaching Gujarat coast. Take immediate shelter.',
        type: NotificationType.disasterAlert,
        priority: NotificationPriority.urgent,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        location: LocationData(
          latitude: 23.0225,
          longitude: 72.5714,
          address: 'Gujarat',
        ),
      ),
      AppNotification(
        id: 'disaster_2',
        title: 'Flood Warning',
        body:
            'Heavy rainfall causing flood-like situation in Kerala. Stay alert.',
        type: NotificationType.disasterAlert,
        priority: NotificationPriority.high,
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        location: LocationData(
          latitude: 10.8505,
          longitude: 76.2711,
          address: 'Kerala',
        ),
      ),
      AppNotification(
        id: 'disaster_3',
        title: 'Earthquake Alert',
        body: 'Mild earthquake of magnitude 4.2 recorded in Himachal Pradesh.',
        type: NotificationType.disasterAlert,
        priority: NotificationPriority.normal,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        location: LocationData(
          latitude: 31.1048,
          longitude: 77.1734,
          address: 'Himachal Pradesh',
        ),
      ),
    ];
  }

  String _getNotificationTitle(NotificationType type) {
    final titles = {
      NotificationType.emergencyAlert: [
        'Emergency Alert',
        'Urgent Response Required',
        'Critical Situation',
        'Emergency Services Active',
      ],
      NotificationType.droneApproach: [
        'Drone Approaching',
        'Rescue Drone En Route',
        'Emergency Drone Deployed',
        'Drone ETA Update',
      ],
      NotificationType.systemUpdate: [
        'System Update',
        'Service Notification',
        'App Update Available',
        'Maintenance Notice',
      ],
      NotificationType.weatherAlert: [
        'Weather Alert',
        'Severe Weather Warning',
        'Climate Advisory',
        'Weather Update',
      ],
      NotificationType.disasterAlert: [
        'Disaster Alert',
        'Emergency Warning',
        'Natural Disaster',
        'Evacuation Notice',
      ],
      NotificationType.missionUpdate: [
        'Mission Update',
        'Response Update',
        'Operation Status',
        'Mission Progress',
      ],
      NotificationType.maintenanceAlert: [
        'Maintenance Alert',
        'Service Schedule',
        'System Maintenance',
        'Scheduled Downtime',
      ],
    };

    final typeTitles = titles[type] ?? ['Notification'];
    final random = Random();
    return typeTitles[random.nextInt(typeTitles.length)];
  }

  String _getNotificationBody(NotificationType type) {
    final bodies = {
      NotificationType.emergencyAlert: [
        'Emergency services are responding to incidents in your area.',
        'Multiple emergency units deployed nearby.',
        'Stay indoors and follow safety protocols.',
        'Emergency response in progress, avoid the area.',
      ],
      NotificationType.droneApproach: [
        'Emergency drone is 500m away from your location.',
        'Rescue drone will arrive in 3 minutes.',
        'Medical supply drone approaching your area.',
        'Search and rescue drone deployed to your location.',
      ],
      NotificationType.systemUpdate: [
        'New features and improvements are available.',
        'Scheduled maintenance will occur tonight.',
        'System performance enhancements deployed.',
        'Security updates have been applied.',
      ],
      NotificationType.weatherAlert: [
        'Heavy rainfall expected in your area.',
        'Strong winds and thunderstorms approaching.',
        'Temperature will drop significantly tonight.',
        'Visibility reduced due to fog conditions.',
      ],
      NotificationType.disasterAlert: [
        'Natural disaster warning issued for your region.',
        'Evacuation advisory for coastal areas.',
        'Emergency shelters have been set up.',
        'Follow official evacuation routes.',
      ],
      NotificationType.missionUpdate: [
        'Your emergency request has been updated.',
        'Rescue mission is proceeding as planned.',
        'Ground teams are coordinating response.',
        'Mission status has been changed to active.',
      ],
      NotificationType.maintenanceAlert: [
        'System maintenance scheduled for tonight.',
        'Service may be temporarily unavailable.',
        'Drone fleet undergoing routine maintenance.',
        'Emergency services remain fully operational.',
      ],
    };

    final typeBodies = bodies[type] ?? ['System notification'];
    final random = Random();
    return typeBodies[random.nextInt(typeBodies.length)];
  }
}
