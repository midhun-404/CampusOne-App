import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../core/theme/app_theme.dart';

class MentorProfileScreen extends StatelessWidget {
  const MentorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) return const Center(child: CircularProgressIndicator());

    String mentorClass = "Not Assigned";
    if (user.semester != null && user.division != null) {
      mentorClass = "S${user.semester} - Div ${user.division}";
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Premium Header with Gradient & Avatar
            _buildHeader(context, user, isDark),
            
            const SizedBox(height: 60),

            // User Name and Professional Badge
            _buildNameSection(user, isDark),
            
            const SizedBox(height: 32),

            // Statistics Row - Professional Look
            _buildStatsSection(context, user, isDark),

            const SizedBox(height: 32),
            
            // Info Sections
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildGlassCard(
                    title: 'Academic Profile',
                    isDark: isDark,
                    children: [
                      _buildProfileItem(Icons.apartment_rounded, 'Department', user.department ?? 'Faculty', isDark),
                      _buildProfileItem(Icons.school_rounded, 'Assigned Class', mentorClass, isDark),
                      _buildProfileItem(Icons.business_rounded, 'College', user.college ?? 'CampusOne', isDark),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildGlassCard(
                    title: 'Contact Information',
                    isDark: isDark,
                    children: [
                      _buildProfileItem(Icons.alternate_email_rounded, 'Email Address', user.email, isDark),
                      _buildProfileItem(Icons.phone_iphone_rounded, 'Phone Number', user.phone ?? 'Not Provided', isDark),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Action Buttons
            _buildActions(context, isDark),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user, bool isDark) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark 
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [AppTheme.primaryBlue, const Color(0xFF1E3A8A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    onPressed: () => context.pop(),
                  ),
                  const Text(
                    'FACULTY PROFILE',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 14),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
                    onPressed: () => context.push('/student/settings'),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBg : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 65,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: user.profileImageUrl != null
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null
                  ? Icon(Icons.person, size: 65, color: Colors.grey.shade400)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameSection(UserModel user, bool isDark) {
    return Column(
      children: [
        Text(
          user.name,
          style: TextStyle(
            fontSize: 28, 
            fontWeight: FontWeight.bold, 
            color: isDark ? Colors.white : AppTheme.primaryBlue,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.accentYellow.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.accentYellow.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_user_rounded, color: AppTheme.accentYellow, size: 16),
              const SizedBox(width: 6),
              const Text(
                'OFFICIAL FACULTY',
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.bold, 
                  color: AppTheme.accentYellow,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, UserModel user, bool isDark) {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final isMentor = user.role == 'Mentor';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          StreamBuilder<int>(
            stream: fs.getPendingCountStream(user.department ?? '', isMentor: isMentor),
            builder: (context, snapshot) => _buildStatItem(
              'PENDING', 
              snapshot.hasData ? snapshot.data!.toString().padLeft(2, '0') : '--', 
              Icons.timer_outlined, 
              Colors.orange, 
              isDark
            ),
          ),
          _buildStatSeparator(isDark),
          StreamBuilder<int>(
            stream: fs.getApprovedCountStream(user.id),
            builder: (context, snapshot) => _buildStatItem(
              'APPROVED', 
              snapshot.hasData ? snapshot.data!.toString() : '--', 
              Icons.check_circle_outline, 
              Colors.green, 
              isDark
            ),
          ),
          _buildStatSeparator(isDark),
          StreamBuilder<int>(
            stream: fs.getMenteeCountStream(user.id),
            builder: (context, snapshot) => _buildStatItem(
              'MENTEES', 
              snapshot.hasData ? snapshot.data!.toString() : '--', 
              Icons.people_outline, 
              Colors.blue, 
              isDark
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20, 
            fontWeight: FontWeight.bold, 
            color: isDark ? Colors.white : AppTheme.primaryBlue,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10, 
            fontWeight: FontWeight.bold, 
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatSeparator(bool isDark) {
    return Container(
      height: 40,
      width: 1,
      color: isDark ? Colors.white10 : Colors.grey.shade200,
    );
  }

  Widget _buildGlassCard({required String title, required List<Widget> children, required bool isDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold, 
              color: Colors.grey.shade500,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              int idx = entry.key;
              Widget child = entry.value;
              return Column(
                children: [
                  child,
                  if (idx != children.length - 1)
                    Divider(height: 30, color: isDark ? Colors.white10 : Colors.grey.shade50),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.white : AppTheme.darkSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  'Edit Profile',
                  Icons.edit_note_rounded,
                  AppTheme.primaryBlue,
                  () => context.push('/mentor/edit_profile'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  context,
                  'Privacy Settings',
                  Icons.lock_outline_rounded,
                  isDark ? Colors.white24 : Colors.grey.shade300,
                  () {},
                  textColor: isDark ? Colors.white : AppTheme.darkSurface,
                  iconColor: isDark ? Colors.white : AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                await Provider.of<AuthService>(context, listen: false).logout();
                if (context.mounted) context.go('/role_selection');
              },
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              label: const Text('Logout Permanent Session', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap, {Color? textColor, Color? iconColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (color == AppTheme.primaryBlue)
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor ?? Colors.white),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: textColor ?? Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

