import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/gate_pass_model.dart';
import '../../services/firestore_service.dart';
import '../../services/sms_service.dart';
import '../../services/notification_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import 'hod_pass_detail_screen.dart';

class HodReviewQueueScreen extends StatelessWidget {
  final String department;
  const HodReviewQueueScreen({super.key, required this.department});

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Review Queue'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.primaryBlue,
      ),
      body: StreamBuilder<List<GatePassModel>>(
        stream: fs.getPendingPassesForDepartment(department, isMentor: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final passes = snapshot.data ?? [];

          if (passes.isEmpty) return const Center(child: Text('No pending passes to review.'));

          return ListView.builder(
            itemCount: passes.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final pass = passes[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => HodPassDetailScreen(pass: pass))),
                  borderRadius: BorderRadius.circular(20),
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
                                  Text('${pass.studentName} (${pass.department})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('Applied: ${DateFormat.yMd().add_jm().format(pass.appliedAt)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            _buildPassTypeBadge(pass.passType),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('To: ${pass.destination ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Reason:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
                        Text(pass.reason, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                        if (pass.mentorRecommendation != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: pass.mentorRecommendation == 'Recommended' ? Colors.green.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: pass.mentorRecommendation == 'Recommended' ? Colors.green.shade200 : Colors.orange.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  pass.mentorRecommendation == 'Recommended' ? Icons.check_circle : Icons.warning_amber_rounded,
                                  size: 14,
                                  color: pass.mentorRecommendation == 'Recommended' ? Colors.green.shade700 : Colors.orange.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Mentor Feed: ${pass.mentorRecommendation}',
                                  style: TextStyle(fontSize: 12, color: pass.mentorRecommendation == 'Recommended' ? Colors.green.shade900 : Colors.orange.shade900, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _updateStatus(context, pass, AppConstants.statusRejected),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _showApproveDialog(context, pass),
                              child: const Text('Approve'),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPassTypeBadge(String type) {
    bool isFull = type == AppConstants.passTypeFullDay;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isFull ? Colors.red.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isFull ? Colors.red.shade200 : Colors.blue.shade200),
      ),
      child: Text(
        isFull ? 'FULL DAY' : 'SHORT PASS',
        style: TextStyle(color: isFull ? Colors.red.shade700 : Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  void _showApproveDialog(BuildContext context, GatePassModel pass) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Approve Pass'),
          content: Text('Confirm approval for ${pass.studentName}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                _updateStatus(context, pass, AppConstants.statusApproved);
              }, 
              child: const Text('Approve')
            )
          ],
        );
      }
    );
  }

  void _updateStatus(BuildContext context, GatePassModel pass, String status) async {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    await fs.updateGatePassStatus(pass.id, status, hodReviewedAt: DateTime.now());
    
    if (status == AppConstants.statusApproved && pass.parentPhone != null) {
      await SmsService.sendSms(phoneNumber: pass.parentPhone!, message: "CampusOne: Gate pass for ${pass.studentName} Approved.");
    }

    if (context.mounted) Navigator.pop(context);
  }
}
