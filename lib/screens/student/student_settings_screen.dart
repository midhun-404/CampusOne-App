import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';

class StudentSettingsScreen extends StatefulWidget {
  const StudentSettingsScreen({super.key});

  @override
  State<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final surface = isDark ? AppTheme.darkSurface : Colors.white;
    final bg = isDark ? AppTheme.darkBg : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : AppTheme.primaryBlue;
    final subTextColor = isDark ? Colors.white54 : Colors.grey;

    return Container(
      color: bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text('Settings',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 32),
            Text('Preferences',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: subTextColor,
                    letterSpacing: 1.2)),
            const SizedBox(height: 16),
            _buildSettingsTile(
              Icons.notifications_active,
              'Push Notifications',
              surface: surface,
              textColor: textColor,
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
              surface: surface,
              textColor: textColor,
              trailing: Switch(
                value: isDark,
                activeColor: AppTheme.accentYellow,
                onChanged: (val) => themeProvider.toggleTheme(val),
              ),
            ),
            const SizedBox(height: 32),
            Text('Account',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: subTextColor,
                    letterSpacing: 1.2)),
            const SizedBox(height: 16),
            _buildSettingsTile(
              Icons.help_outline,
              'Help & Support',
              surface: surface,
              textColor: textColor,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact Admin for support')));
              },
            ),
            _buildSettingsTile(
              Icons.info_outline,
              'About App',
              surface: surface,
              textColor: textColor,
              onTap: () => context.push('/about'),
            ),
            const SizedBox(height: 16),
            _buildSettingsTile(
              Icons.logout,
              'Logout',
              iconColor: Colors.red,
              textColor: Colors.red,
              surface: surface,
              onTap: () async {
                await Provider.of<AuthService>(context, listen: false).logout();
                if (context.mounted) context.go('/role_selection');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title, {
    required Color surface,
    required Color textColor,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
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
              child: Text(title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
            ),
            if (trailing != null)
              trailing
            else if (onTap != null)
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
          ],
        ),
      ),
    );
  }
}
