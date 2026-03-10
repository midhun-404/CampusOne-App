import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/gate_pass_model.dart';
import '../../core/theme/app_theme.dart';

class StudentHistoryScreen extends StatelessWidget {
  const StudentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not found')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pass History')),
      backgroundColor: AppTheme.lightBg,
      body: StreamBuilder<List<GatePassModel>>(
        stream: fs.getStudentPasses(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allPasses = snapshot.data ?? [];
          if (allPasses.isEmpty) {
            return const Center(child: Text('No passes found.'));
          }

          // Sort by date (newest first)
          allPasses.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allPasses.length,
            itemBuilder: (context, index) {
              final pass = allPasses[index];
              return _HistoryCard(pass: pass);
            },
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final GatePassModel pass;
  const _HistoryCard({required this.pass});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (pass.status) {
      case 'Approved':
      case 'Verified':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'Expired':
        statusColor = Colors.grey;
        statusIcon = Icons.timer_off;
        break;
      case 'Used':
        statusColor = Colors.deepPurple;
        statusIcon = Icons.history;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat.yMMMd().format(pass.appliedAt),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        pass.status.toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                )
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.location_on, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(pass.destination ?? 'No Destination Provided', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.subject, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(pass.reason, style: const TextStyle(color: Colors.black87))),
              ],
            ),
            if (pass.mentorNotes != null && pass.mentorNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.comment, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Mentor Notes: ${pass.mentorNotes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                    )
                  ],
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
