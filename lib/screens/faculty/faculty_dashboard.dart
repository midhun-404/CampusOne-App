import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/gate_pass_model.dart';
import '../../models/notice_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../student/student_profile_screen.dart'; // Reusing profile screen
import '../student/student_settings_screen.dart'; // Reusing settings screen
import '../mentor/mentor_profile_screen.dart'; // Dedicated profile

class FacultyDashboard extends StatefulWidget {
  const FacultyDashboard({super.key});

  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _FacultyHomeView(),
    const MentorProfileScreen(), // Use dedicated Faculty/Mentor profile screen
    const StudentSettingsScreen(), // Faculty can reuse settings
  ];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}

class _FacultyHomeView extends StatelessWidget {
  const _FacultyHomeView();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    if (user == null) return const SizedBox.shrink();

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome Back, Faculty',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
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
        
        const SizedBox(height: 12),
        
        // Notice Banner
        StreamBuilder<List<NoticeModel>>(
          stream: firestoreService.getNoticesStream(),
          builder: (context, snapshot) {
            final notices = snapshot.data ?? [];
            if (notices.isEmpty) return const SizedBox.shrink();
            final latestNotice = notices.first;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: () => context.push('/notice_detail', extra: latestNotice),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.campaign, size: 22, color: AppTheme.primaryBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('LATEST NOTICE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, letterSpacing: 1)),
                            Text(
                              latestNotice.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18, color: AppTheme.primaryBlue),
                    ],
                  ),
                ),
              ),
            );
          }
        ),

        const SizedBox(height: 16),
        
        // Active pass banner...
        StreamBuilder<List<GatePassModel>>(
          stream: firestoreService.getStudentPasses(user.id),
          builder: (context, snapshot) {
            final passes = snapshot.data ?? [];
            passes.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
            
            final activePassList = passes.where((p) => 
              (p.status == AppConstants.statusPendingHod || // Faculties skip Mentor
              p.status == AppConstants.statusApproved) &&
              !p.isExpired
            ).toList();
            
            if (activePassList.isNotEmpty) {
              final activePass = activePassList.first;
              bool showQr = (activePass.status == AppConstants.statusApproved || 
                           activePass.status == AppConstants.statusVerified) && 
                           !activePass.isExpired;
              
              String statusText = activePass.status;
              if (activePass.isExpired) {
                statusText = 'Expired ❌';
              } else if (activePass.status == AppConstants.statusVerified) {
                statusText = 'Verified by Security ✅';
              } else if (activePass.status == AppConstants.statusApproved) {
                statusText = 'Approved (Ready to Use) 🎫';
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                  color: AppTheme.accentYellow.withOpacity(0.15),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: AppTheme.accentYellow.withOpacity(0.5), width: 1),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: const Text('Active E-Gate Pass', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                    subtitle: Text('Status: $statusText', style: TextStyle(color: AppTheme.primaryBlue.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                    trailing: showQr 
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentYellow,
                              foregroundColor: AppTheme.primaryBlue,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: () => context.push('/faculty/epass', extra: activePass),
                            child: const Text('View QR', style: TextStyle(fontWeight: FontWeight.bold)),
                          )
                        : const Icon(Icons.timer_outlined, color: AppTheme.primaryBlue),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
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
                icon: Icons.add_circle_outline, 
                title: 'Apply Pass', 
                color: AppTheme.primaryBlue,
                onTap: () => context.push('/faculty/apply'),
              ),
              _buildGridItem(
                context, 
                icon: Icons.history, 
                title: 'Pass History', 
                color: AppTheme.accentYellow,
                onTap: () => context.push('/student/history'),
              ),
              _buildGridItem(
                context, 
                icon: Icons.fastfood_rounded, 
                title: 'Canteen', 
                color: Colors.orange,
                onTap: () => context.push('/student/canteen'),
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
      child: Builder(
        builder: (context) {
          final surface = Theme.of(context).colorScheme.surface;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black26 : color.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 40, color: color),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : AppTheme.darkSurface,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
