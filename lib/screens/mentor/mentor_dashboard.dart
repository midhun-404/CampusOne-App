import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import 'mentor_pending_screen.dart';
import 'mentor_history_screen.dart';
import '../student/student_settings_screen.dart';
import 'mentor_profile_screen.dart';
import '../faculty/faculty_notice_screen.dart';
import 'mentor_active_outs_screen.dart';

class MentorDashboard extends StatefulWidget {
  const MentorDashboard({super.key});

  @override
  State<MentorDashboard> createState() => _MentorDashboardState();
}

class _MentorDashboardState extends State<MentorDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final List<Widget> _screens = [
      const _MentorHomeView(),
      const StudentSettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))
          ]
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            selectedItemColor: AppTheme.primaryBlue,
            unselectedItemColor: Colors.grey,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}

class _MentorHomeView extends StatelessWidget {
  const _MentorHomeView();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    if (user == null) return const SizedBox.shrink();

    String mentorClass = "";
    if (user.semester != null && user.division != null) {
      mentorClass = "${user.semester} - ${user.division}";
    }

    return Column(
      children: [
        // Custom Curved Header
        Container(
          padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
          decoration: const BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mentor Dashboard - ${user.department}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mentorClass.isNotEmpty ? mentorClass : user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.accentYellow,
                backgroundImage: user.profileImageUrl != null 
                    ? NetworkImage(user.profileImageUrl!) 
                    : null,
                child: user.profileImageUrl == null 
                    ? const Icon(Icons.person, color: Colors.white) 
                    : null,
              ),
            ],
          ),
        ),
        
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.all(24),
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.1,
            children: [
              _buildGridItem(
                context, 
                icon: Icons.pending_actions_rounded, 
                title: 'Pending Requests', 
                color: AppTheme.primaryBlue,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MentorPendingScreen()));
                },
              ),
              _buildGridItem(
                context, 
                icon: Icons.history, 
                title: 'Pass History', 
                color: AppTheme.accentYellow,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MentorHistoryScreen()));
                },
              ),
              _buildGridItem(
                context, 
                icon: Icons.group_rounded, 
                title: 'Students List', 
                color: Colors.teal,
                onTap: () {
                  context.push('/mentor/students');
                },
              ),
              _buildGridItem(
                context, 
                icon: Icons.person_outline, 
                title: 'Profile', 
                color: Colors.orange,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MentorProfileScreen()));
                },
              ),
              _buildGridItem(
                context, 
                icon: Icons.campaign_rounded, 
                title: 'Broadcast', 
                color: Colors.purple,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const FacultyNoticeScreen()));
                },
              ),
              _buildGridItem(
                context, 
                icon: Icons.exit_to_app_rounded, 
                title: 'Students Out', 
                color: Colors.pink,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MentorActiveOutsScreen()));
                },
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildGridItem(BuildContext context, {required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
