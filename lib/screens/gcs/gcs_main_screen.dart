import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/app_theme.dart';
import '../../providers/group_management_provider.dart';
import 'gcs_map_screen.dart';
import 'enhanced_ongoing_missions_screen.dart';
import 'create_group_screen.dart';
import 'create_mission_screen.dart';

class GCSMainScreen extends StatefulWidget {
  const GCSMainScreen({super.key});

  @override
  State<GCSMainScreen> createState() => _GCSMainScreenState();
}

class _GCSMainScreenState extends State<GCSMainScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const GCSMapScreen(),
    const EnhancedOngoingMissionsScreen(),
    const CreateGroupScreen(),
    const CreateMissionScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.map),
      activeIcon: Icon(Icons.map),
      label: 'Map',
      tooltip: 'Operations Overview',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.assignment_outlined),
      activeIcon: Icon(Icons.assignment),
      label: 'Ongoing',
      tooltip: 'Active Missions',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.group_add_outlined),
      activeIcon: Icon(Icons.group_add),
      label: 'Create Group',
      tooltip: 'Event Management',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.add_task_outlined),
      activeIcon: Icon(Icons.add_task),
      label: 'Create Mission',
      tooltip: 'Mission Assignment',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _screens.length,
      vsync: this,
      initialIndex: _currentIndex,
    );

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });

    // Initialize data if not already done
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupProvider = context.read<GroupManagementProvider>();
      if (groupProvider.events.isEmpty) {
        groupProvider.initializeMockData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Consumer<GroupManagementProvider>(
        builder: (context, groupProvider, child) {
          if (groupProvider.isLoading && groupProvider.events.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(), // Disable swiping
            children: _screens,
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigation(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final titles = [
      'Operations Center',
      'Active Missions',
      'Event Management',
      'Mission Control',
    ];

    return AppBar(
      title: Text(
        titles[_currentIndex],
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      centerTitle: false,
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      actions: [
        Consumer<GroupManagementProvider>(
          builder: (context, provider, child) {
            final criticalCount = provider.totalCriticalEvents;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => _showNotifications(context),
                  tooltip: 'Notifications',
                ),
                if (criticalCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        criticalCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            context.read<GroupManagementProvider>().refreshData();
          },
          tooltip: 'Refresh Data',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('Export Data'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'help',
              child: ListTile(
                leading: Icon(Icons.help_outline),
                title: Text('Help'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout, color: AppColors.error),
                title: Text('Logout', style: TextStyle(color: AppColors.error)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        items: _navItems,
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_currentIndex) {
      case 0: // Map
        return FloatingActionButton(
          heroTag: "gcs_map_fab",
          onPressed: () => _showQuickActions(context),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
          tooltip: 'Quick Actions',
        );
      case 1: // Ongoing Missions
        return FloatingActionButton(
          heroTag: "gcs_missions_fab",
          onPressed: () => _onTabTapped(3), // Navigate to Create Mission
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add_task),
          tooltip: 'Create Mission',
        );
      case 2: // Create Group
        return null; // No FAB needed, create functionality is in the screen
      case 3: // Create Mission
        return null; // No FAB needed, create functionality is in the screen
      default:
        return null;
    }
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          return Consumer<GroupManagementProvider>(
            builder: (context, provider, child) {
              final criticalEvents = provider.criticalEvents;

              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Critical Alerts',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: criticalEvents.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 64,
                                    color: AppColors.success,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No Critical Alerts',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'All systems are operating normally',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: criticalEvents.length,
                              itemBuilder: (context, index) {
                                final event = criticalEvents[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.warning,
                                        color: AppColors.error,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      event.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${event.typeDisplay} • ${event.location.address}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Text(
                                      _formatTime(event.createdAt),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _onTabTapped(0); // Navigate to map
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildQuickActionCard(
                  icon: Icons.group_add,
                  title: 'Create Event',
                  onTap: () {
                    Navigator.pop(context);
                    _onTabTapped(2);
                  },
                ),
                _buildQuickActionCard(
                  icon: Icons.add_task,
                  title: 'New Mission',
                  onTap: () {
                    Navigator.pop(context);
                    _onTabTapped(3);
                  },
                ),
                _buildQuickActionCard(
                  icon: Icons.emergency,
                  title: 'Emergency',
                  onTap: () {
                    Navigator.pop(context);
                    _handleEmergencyAction();
                  },
                ),
                _buildQuickActionCard(
                  icon: Icons.refresh,
                  title: 'Refresh',
                  onTap: () {
                    Navigator.pop(context);
                    context.read<GroupManagementProvider>().refreshData();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'settings':
        // Navigate to settings
        break;
      case 'export':
        _handleExportData();
        break;
      case 'help':
        _showHelpDialog();
        break;
      case 'logout':
        _handleLogout();
        break;
    }
  }

  void _handleEmergencyAction() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: AppColors.error),
            SizedBox(width: 8),
            Text('Emergency Action'),
          ],
        ),
        content: const Text(
          'This will trigger an emergency response protocol. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _onTabTapped(2); // Navigate to create event with emergency preset
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _handleExportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting data...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GCS Navigation:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• Map: Overview of all operations and events'),
            Text('• Ongoing: Monitor active missions in real-time'),
            Text('• Create Group: Manage events and emergencies'),
            Text('• Create Mission: Assign new missions to operators'),
            SizedBox(height: 16),
            Text(
              'For technical support, contact:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('support@droneaid.com'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle logout logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
