import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationServicesEnabled = true;
  bool _emergencyAlertsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _selectedTheme = 'System';
  String _selectedLanguage = 'English';

  final List<String> _themes = ['Light', 'Dark', 'System'];
  final List<String> _languages = ['English', 'Hindi', 'Bengali'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('General', [
              _buildDropdownTile(
                Icons.palette,
                'Theme',
                _selectedTheme,
                _themes,
                (value) => setState(() => _selectedTheme = value!),
              ),
              _buildDropdownTile(
                Icons.language,
                'Language',
                _selectedLanguage,
                _languages,
                (value) => setState(() => _selectedLanguage = value!),
              ),
            ]),

            const SizedBox(height: 24),

            _buildSection('Notifications', [
              _buildSwitchTile(
                Icons.notifications,
                'Push Notifications',
                'Receive emergency alerts and updates',
                _notificationsEnabled,
                (value) => setState(() => _notificationsEnabled = value),
              ),
              _buildSwitchTile(
                Icons.emergency,
                'Emergency Alerts',
                'Critical emergency notifications',
                _emergencyAlertsEnabled,
                (value) => setState(() => _emergencyAlertsEnabled = value),
              ),
              _buildSwitchTile(
                Icons.volume_up,
                'Sound',
                'Play notification sounds',
                _soundEnabled,
                (value) => setState(() => _soundEnabled = value),
              ),
              _buildSwitchTile(
                Icons.vibration,
                'Vibration',
                'Vibrate for notifications',
                _vibrationEnabled,
                (value) => setState(() => _vibrationEnabled = value),
              ),
            ]),

            const SizedBox(height: 24),

            _buildSection('Location & Privacy', [
              _buildSwitchTile(
                Icons.location_on,
                'Location Services',
                'Allow location access for emergency services',
                _locationServicesEnabled,
                (value) => setState(() => _locationServicesEnabled = value),
              ),
              _buildActionTile(
                Icons.privacy_tip,
                'Privacy Policy',
                'View our privacy policy',
                _openPrivacyPolicy,
              ),
              _buildActionTile(
                Icons.security,
                'Data & Security',
                'Manage your data and security settings',
                _openDataSecurity,
              ),
            ]),

            const SizedBox(height: 24),

            _buildSection('Support', [
              _buildActionTile(
                Icons.help,
                'Help Center',
                'Get help and support',
                _openHelpCenter,
              ),
              _buildActionTile(
                Icons.feedback,
                'Send Feedback',
                'Share your feedback with us',
                _sendFeedback,
              ),
              _buildActionTile(
                Icons.bug_report,
                'Report Bug',
                'Report a bug or issue',
                _reportBug,
              ),
              _buildActionTile(
                Icons.star_rate,
                'Rate App',
                'Rate Drone AID on app store',
                _rateApp,
              ),
            ]),

            const SizedBox(height: 24),

            _buildSection('About', [
              _buildInfoTile('Version', '1.0.0'),
              _buildInfoTile('Build', '100'),
              _buildActionTile(
                Icons.description,
                'Terms of Service',
                'View terms and conditions',
                _openTerms,
              ),
              _buildActionTile(
                Icons.info,
                'About Drone AID',
                'Learn more about our mission',
                _aboutApp,
              ),
            ]),

            const SizedBox(height: 32),

            // Reset Settings Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _resetSettings,
                icon: const Icon(Icons.restore),
                label: const Text('Reset to Defaults'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: AppTheme.cardDecoration,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildDropdownTile(
    IconData icon,
    String title,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        items: options.map((option) {
          return DropdownMenuItem(value: option, child: Text(option));
        }).toList(),
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return ListTile(
      leading: const Icon(Icons.info_outline, color: AppColors.primary),
      title: Text(title),
      trailing: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  void _openPrivacyPolicy() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening privacy policy...')));
  }

  void _openDataSecurity() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening data & security settings...')),
    );
  }

  void _openHelpCenter() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening help center...')));
  }

  void _sendFeedback() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening feedback form...')));
  }

  void _reportBug() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening bug report form...')));
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening app store for rating...')),
    );
  }

  void _openTerms() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening terms of service...')),
    );
  }

  void _aboutApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Drone AID'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Drone AID is a comprehensive emergency response system that uses drone technology to provide rapid assistance during disasters and emergencies.',
            ),
            SizedBox(height: 12),
            Text(
              'Our mission is to save lives by reducing emergency response times and providing real-time situational awareness to first responders.',
            ),
            SizedBox(height: 12),
            Text('Version: 1.0.0'),
            Text('© 2024 Drone AID Team'),
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

  void _resetSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _notificationsEnabled = true;
                _locationServicesEnabled = true;
                _emergencyAlertsEnabled = true;
                _soundEnabled = true;
                _vibrationEnabled = true;
                _selectedTheme = 'System';
                _selectedLanguage = 'English';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
