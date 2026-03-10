import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/mentor_service.dart';
import '../../services/firestore_service.dart';
import '../../models/gate_pass_model.dart';
import '../../core/constants/app_constants.dart';

class MentorPendingScreen extends StatelessWidget {
  const MentorPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final mentorService = MentorService();

    if (user == null || user.department == null || user.semester == null || user.division == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pending Requests')),
        body: const Center(child: Text('Mentor Class Details not configured properly.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Pending Requests (${user.semester} - ${user.division})'),
      ),
      body: StreamBuilder<List<GatePassModel>>(
        stream: mentorService.getPendingPassesForClass(user.department!, user.semester!, user.division!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final passes = snapshot.data ?? [];

          if (passes.isEmpty) {
            return const Center(
              child: Text(
                'No pending gate pass requests.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: passes.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final pass = passes[index];
              return _buildRequestCard(context, pass, mentorService);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, GatePassModel pass, MentorService mentorService) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (pass.profileImageUrl != null)
                  CircleAvatar(backgroundImage: NetworkImage(pass.profileImageUrl!))
                else
                  const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${pass.studentName} (${pass.department} - ${pass.semester})', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                      Text(
                        'Applied: ${DateFormat.yMd().add_jm().format(pass.appliedAt)}', 
                        style: const TextStyle(color: Colors.grey, fontSize: 12)
                      ),
                    ],
                  ),
                ),
                // Pass Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: pass.passType == AppConstants.passTypeFullDay ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: pass.passType == AppConstants.passTypeFullDay ? Colors.red : Colors.blue),
                  ),
                  child: Text(
                    pass.passType == AppConstants.passTypeFullDay ? 'FULL DAY' : 'SHORT PASS',
                    style: TextStyle(
                      color: pass.passType == AppConstants.passTypeFullDay ? Colors.red : Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('To: ${pass.destination ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  pass.passType == AppConstants.passTypeFullDay 
                      ? 'Leave: ${pass.leavingTime != null ? DateFormat.jm().format(pass.leavingTime!) : "N/A"}'
                      : 'Return: ${pass.expectedReturnTime != null ? DateFormat.jm().format(pass.expectedReturnTime!) : "N/A"}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Reason:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            Text(pass.reason, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            const Divider(),
            const Text('History:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            
            // Dynamic History Fetcher
            FutureBuilder<Map<String, int>>(
              future: mentorService.getStudentPassHistoryStats(pass.studentId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                   return const Padding(
                     padding: EdgeInsets.symmetric(vertical: 4.0),
                     child: SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                   );
                }
                final stats = snapshot.data ?? {'approved': 0, 'rejected': 0, 'total': 0};
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                  child: Row(
                    children: [
                      Text('Approved: ${stats['approved']}', style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      Text('Rejected: ${stats['rejected']}', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('Total: ${stats['total']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _updateStatus(context, pass, AppConstants.statusRejected),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _updateStatus(context, pass, AppConstants.statusPendingHod),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Forward to HOD'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _updateStatus(BuildContext context, GatePassModel pass, String newStatus) async {
    final authUser = Provider.of<AuthService>(context, listen: false).currentUser;
    final fs = Provider.of<FirestoreService>(context, listen: false);

    if (authUser == null) return;

    String? notes;
    String? recommendation;

    if (newStatus == AppConstants.statusRejected) {
      notes = await _showRejectionDialog(context);
      if (notes == null) return; // Cancelled
    } else if (newStatus == AppConstants.statusPendingHod) {
      final result = await _showForwardDialog(context, pass);
      if (result == null) return; // Cancelled
      recommendation = result['recommendation'];
      notes = result['notes'];
    }

    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      
      await fs.updateGatePassStatus(
        pass.id,
        newStatus,
        mentorNotes: notes,
        mentorRecommendation: recommendation,
        mentorReviewedAt: DateTime.now(),
      );
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(newStatus == AppConstants.statusRejected 
              ? 'Pass Rejected successfully.' 
              : 'Pass Forwarded to HOD successfully.'),
          backgroundColor: newStatus == AppConstants.statusRejected ? Colors.red : Colors.green,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<Map<String, String>?> _showForwardDialog(BuildContext context, GatePassModel pass) async {
    final notesCtrl = TextEditingController();
    String recommendation = 'Recommended'; // Default

    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Forward to HOD'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Student Request Details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                Text('Name: ${pass.studentName}', style: const TextStyle(fontSize: 14)),
                Text('Reg No: ${pass.regNo ?? "N/A"}', style: const TextStyle(fontSize: 14)),
                Text('Class: ${pass.semester} - ${pass.division}', style: const TextStyle(fontSize: 14)),
                Text('Destination: ${pass.destination ?? "N/A"}', style: const TextStyle(fontSize: 14)),
                Text('Reason: ${pass.reason}', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
                const Divider(),
                const Text('Your Recommendation:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                Row(
                  children: [
                    Radio<String>(
                      value: 'Recommended',
                      groupValue: recommendation,
                      onChanged: (v) => setState(() => recommendation = v!),
                    ),
                    const Text('Recommended'),
                  ],
                ),
                Row(
                  children: [
                    Radio<String>(
                      value: 'Not Recommended',
                      groupValue: recommendation,
                      onChanged: (v) => setState(() => recommendation = v!),
                    ),
                    const Text('Not Recommended'),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Mentor Notes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Enter any additional notes for HOD...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx, {
                  'recommendation': recommendation,
                  'notes': notesCtrl.text.trim(),
                });
              },
              child: const Text('Forward'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showRejectionDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Gate Pass'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reason for rejection:'),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              maxLines: 2,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              if (ctrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a reason')));
                return;
              }
              Navigator.pop(ctx, ctrl.text.trim());
            }, 
            child: const Text('Confirm Reject')
          ),
        ],
      )
    );
  }
}
