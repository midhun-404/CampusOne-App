import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/gate_pass_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class HodPassDetailScreen extends StatelessWidget {
  final GatePassModel pass;
  const HodPassDetailScreen({super.key, required this.pass});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Pass Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.primaryBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundImage: pass.profileImageUrl != null ? NetworkImage(pass.profileImageUrl!) : null,
                        child: pass.profileImageUrl == null ? const Icon(Icons.person, size: 35) : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pass.studentName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('Reg: ${pass.regNo ?? "N/A"}', style: TextStyle(color: Colors.grey.shade600)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(pass.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                pass.status.toUpperCase(),
                                style: TextStyle(color: _getStatusColor(pass.status), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildDetailRow('Pass Type', pass.passType == AppConstants.passTypeFullDay ? 'Full Day' : 'Short Pass'),
                  _buildDetailRow('Destination', pass.destination ?? 'N/A'),
                  _buildDetailRow('Reason', pass.reason),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Timeline Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  _buildTimelineItem('Applied', pass.appliedAt, Icons.add_circle_outline, Colors.blue),
                  if (pass.mentorReviewedAt != null)
                    _buildTimelineItem('Mentor Reviewed (${pass.mentorRecommendation})', pass.mentorReviewedAt!, Icons.assignment_turned_in_outlined, Colors.orange),
                  if (pass.hodReviewedAt != null)
                    _buildTimelineItem('HOD Final Approval', pass.hodReviewedAt!, Icons.verified_user_outlined, Colors.green),
                  if (pass.usedAt != null)
                    _buildTimelineItem('Security Exit Scanned', pass.usedAt!, Icons.door_front_door_outlined, Colors.indigo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, DateTime time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(DateFormat.yMd().add_jm().format(time), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'verified': return Colors.blue;
      default: return Colors.orange;
    }
  }
}
