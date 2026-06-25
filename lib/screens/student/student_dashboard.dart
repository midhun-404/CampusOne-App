import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/gate_pass_model.dart';
import '../../models/notice_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import 'student_profile_screen.dart';
import 'student_settings_screen.dart';
import 'ai_chat_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _HomeView(),
    const StudentProfileScreen(),
    const StudentSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _screens[_selectedIndex],
      floatingActionButton: _AiFab(),
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

/// Floating AI assistant button
class _AiFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AiChatScreen()),
        );
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAB360), Color(0xFFD4943A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x55EAB360),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

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
                      'Welcome Back,',
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
              GestureDetector(
                onTap: () {}, // Removed logout directly from avatar, now handled by Settings.
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.accentYellow,
                  backgroundImage: user.profileImageUrl != null 
                      ? NetworkImage(user.profileImageUrl!) 
                      : null,
                  child: user.profileImageUrl == null 
                      ? const Icon(Icons.person, color: Colors.white) 
                      : null,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // HOD Notice Banner
        StreamBuilder<List<NoticeModel>>(
          stream: firestoreService.getNoticesStream(),
          builder: (context, snapshot) {
            final notices = snapshot.data ?? [];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildNoticeBanner(context, notices),
            );
          }
        ),

        const SizedBox(height: 16),
        
        // Stream for active pass banner
        StreamBuilder<List<GatePassModel>>(
          stream: firestoreService.getStudentPasses(user.id),
          builder: (context, snapshot) {
            final passes = snapshot.data ?? [];
            // Sort by appliedAt descending (client-side to avoid Firestore index issues)
            passes.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
            
            final activePassList = passes.where((p) => 
              (p.status == AppConstants.statusPendingMentor ||
              p.status == AppConstants.statusPendingHod ||
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
                            onPressed: () => context.push('/student/epass', extra: activePass),
                            child: const Text('View QR', style: TextStyle(fontWeight: FontWeight.bold)),
                          )
                        : const Icon(Icons.timer_outlined, color: AppTheme.primaryBlue),
                  ),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                color: Theme.of(context).colorScheme.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.grey.shade300, width: 1),
                ),
                child: const ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.grey),
                  title: Text('No pass is active', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            );
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
                onTap: () => context.push('/student/apply'),
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
              _buildGridItem(
                context, 
                icon: Icons.badge_rounded, 
                title: 'Digital ID', 
                color: Colors.indigo,
                onTap: () => context.push('/student/id_card'),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildNoticeBanner(BuildContext context, List<NoticeModel> notices) {
    if (notices.isEmpty) {
      final surface = Theme.of(context).colorScheme.surface;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.notifications_none, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 20,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                     Text('No new notices', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final latestNotice = notices.first;

    return GestureDetector(
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
