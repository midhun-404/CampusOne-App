import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Widget _buildRoleCard(BuildContext context, String title, IconData icon, String role) {
    bool isStudent = role == AppConstants.roleStudent;
    
    return GestureDetector(
      onTap: () {
        context.push('/login', extra: role);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: isStudent 
              ? [AppTheme.primaryBlue.withOpacity(0.8), AppTheme.primaryBlue.withOpacity(0.4)]
              : [AppTheme.darkSurface.withOpacity(0.8), AppTheme.darkSurface.withOpacity(0.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isStudent ? AppTheme.primaryBlue.withOpacity(0.5) : Colors.white12,
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isStudent ? Colors.white.withOpacity(0.2) : AppTheme.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: isStudent ? Colors.white : AppTheme.primaryBlue, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isStudent ? Colors.white : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isStudent ? "Create an account or login" : "Admin credentials required",
                          style: TextStyle(
                            fontSize: 12,
                            color: isStudent ? Colors.white70 : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: isStudent ? Colors.white : AppTheme.primaryBlue, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                "Welcome to",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                "CampusOne",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Please select your role to continue.",
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildRoleCard(context, "Student", Icons.school, AppConstants.roleStudent),
                    _buildRoleCard(context, "Mentor", Icons.co_present, AppConstants.roleMentor),
                    _buildRoleCard(context, "Head of Department", Icons.admin_panel_settings, AppConstants.roleHod),
                    _buildRoleCard(context, "Security", Icons.security, AppConstants.roleSecurity),
                    _buildRoleCard(context, "Canteen", Icons.fastfood, AppConstants.roleCanteen),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
