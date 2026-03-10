import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class StudentSettingsScreen extends StatefulWidget {
  const StudentSettingsScreen({super.key});

  @override
  State<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text('Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
          const SizedBox(height: 32),
          const Text('Preferences', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _buildSettingsTile(
            Icons.notifications_active,
            'Push Notifications',
            trailing: Switch(
              value: _notificationsEnabled,
              activeColor: AppTheme.accentYellow,
              onChanged: (val) => setState(() => _notificationsEnabled = val),
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            Icons.dark_mode,
            'Dark Mode',
            trailing: const Text('Coming Soon', style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 32),
          const Text('Account', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _buildSettingsTile(
            Icons.help_outline,
            'Help & Support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact Admin for support')));
            },
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            Icons.logout,
            'Logout',
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: () async {
              await Provider.of<AuthService>(context, listen: false).logout();
              if (context.mounted) context.go('/role_selection');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, {Widget? trailing, VoidCallback? onTap, Color? iconColor, Color? textColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ]
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? AppTheme.primaryBlue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor ?? AppTheme.primaryBlue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor ?? AppTheme.primaryBlue)),
            ),
            if (trailing != null) trailing
            else if (onTap != null) const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
          ],
        ),
      ),
    );
  }
}
