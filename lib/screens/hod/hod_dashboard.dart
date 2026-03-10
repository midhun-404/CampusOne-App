import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/gate_pass_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import 'hod_review_queue_screen.dart';
import 'hod_student_directory_screen.dart';
import 'hod_mentor_team_screen.dart';
import 'hod_pass_history_screen.dart';
import 'hod_security_feed_screen.dart';
import 'hod_profile_screen.dart';

class HodDashboard extends StatefulWidget {
  const HodDashboard({super.key});

  @override
  State<HodDashboard> createState() => _HodDashboardState();
}

class _HodDashboardState extends State<HodDashboard> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Refresh every 30 seconds so remaining times stay current
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final fs = Provider.of<FirestoreService>(context);

    if (user == null || user.department == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      body: CustomScrollView(
        slivers: [
          // Premium Header
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryBlue,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.only(top: 100, left: 24, right: 24, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HOD Dashboard - ${user.department}',
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Live Students Out Feed
                    StreamBuilder<List<GatePassModel>>(
                      stream: fs.getDepartmentStudentsOutStream(user.department!),
                      builder: (context, snapshot) {
                        final passes = snapshot.data ?? [];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.directions_run_rounded, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${passes.length} Student${passes.length == 1 ? '' : 's'} Outside',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: 8, height: 8,
                                    decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text('LIVE', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                ],
                              ),
                              if (passes.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Divider(color: Colors.white24, height: 1),
                                const SizedBox(height: 8),
                                ...passes.take(3).map((p) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person_outline, color: Colors.white70, size: 14),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          p.studentName,
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        _formatRemaining(p.expiryTimestamp),
                                        style: TextStyle(
                                          color: _isAlmostDue(p.expiryTimestamp) ? Colors.orangeAccent : Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                                if (passes.length > 3)
                                  Text('+${passes.length - 3} more', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                              ] else
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Text('All students are on campus', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    // Pending passes stat
                    StreamBuilder<List<GatePassModel>>(
                      stream: fs.getPendingPassesForDepartment(user.department!, isMentor: false),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;
                        return Row(
                          children: [
                            const Icon(Icons.hourglass_empty_rounded, color: Colors.white70, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '$count Pending Approval${count == 1 ? '' : 's'}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            if (count > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.orangeAccent, borderRadius: BorderRadius.circular(10)),
                                child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  await Provider.of<AuthService>(context, listen: false).logout();
                  if (mounted) context.go('/role_selection');
                },
              ),
            ],
          ),

          // Command Center Grid
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 1.1,
              children: [
                _buildGridItem(
                  context,
                  title: 'Review Queue',
                  icon: Icons.checklist_rtl_rounded,
                  color: Colors.orange,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => HodReviewQueueScreen(department: user.department!))),
                ),
                _buildGridItem(
                  context,
                  title: 'Students',
                  icon: Icons.people_alt_rounded,
                  color: Colors.blue,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => HodStudentDirectoryScreen(department: user.department!))),
                ),
                _buildGridItem(
                  context,
                  title: 'Mentor Team',
                  icon: Icons.assignment_ind_rounded,
                  color: Colors.teal,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => HodMentorTeamScreen(department: user.department!))),
                ),
                _buildGridItem(
                  context,
                  title: 'History Log',
                  icon: Icons.history_edu_rounded,
                  color: Colors.purple,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => HodPassHistoryScreen(department: user.department!))),
                ),
                _buildGridItem(
                  context,
                  title: 'Security Feed',
                  icon: Icons.security_rounded,
                  color: Colors.indigo,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => HodSecurityFeedScreen(department: user.department!))),
                ),
                _buildGridItem(
                  context,
                  title: 'Broadcast',
                  icon: Icons.campaign_rounded,
                  color: Colors.redAccent,
                  onTap: () => _showBroadcastDialog(context, user.department!),
                ),
                _buildGridItem(
                  context,
                  title: 'Profile',
                  icon: Icons.person_rounded,
                  color: Colors.orange,
                  onTap: () => context.push('/hod/profile'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  String _formatRemaining(DateTime? expiry) {
    if (expiry == null) return 'Full Day';
    final remaining = expiry.difference(DateTime.now());
    if (remaining.isNegative) return 'Overdue';
    if (remaining.inDays >= 1) return 'returns in ${remaining.inDays}d';
    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m left';
    return '${m}m left';
  }

  bool _isAlmostDue(DateTime? expiry) {
    if (expiry == null) return false;
    return expiry.difference(DateTime.now()).inMinutes <= 30;
  }

  Widget _buildStatCard(String label, Stream<int> stream, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreamBuilder<int>(
                    stream: stream,
                    builder: (context, snapshot) {
                      return Text(
                        '${snapshot.data ?? 0}',
                        style: const TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 22,
                          letterSpacing: -0.5,
                        ),
                      );
                    }
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8), 
                      fontSize: 11, 
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  void _showBroadcastDialog(BuildContext context, String department) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Broadcast Alert'),
        content: TextField(
          controller: textController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter department-wide notice...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              final msg = textController.text;
              if (msg.isEmpty) return;
              
              Navigator.pop(ctx);
              
              // Implementation note: This would typically trigger a cloud function or 
              // loop through department tokens. For now, we simulate the logic.
              final fs = Provider.of<FirestoreService>(context, listen: false);
              final students = await fs.getDepartmentUsers(department, AppConstants.roleStudent);
              
              int count = 0;
              for (var s in students) {
                if (s.fcmToken != null) {
                  await NotificationService.sendNotification(
                    fcmToken: s.fcmToken!,
                    title: "HOD BROADCAST - $department",
                    body: msg,
                  );
                  count++;
                }
              }
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Broadcast sent to $count users.')));
              }
            },
            child: const Text('Send Now'),
          ),
        ],
      ),
    );
  }
}
