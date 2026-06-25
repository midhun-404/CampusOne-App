import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/gate_pass_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class GatePassDetailScreen extends StatelessWidget {
  final String passId;
  const GatePassDetailScreen({super.key, required this.passId});

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Pass Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.primaryBlue,
      ),
      body: FutureBuilder<GatePassModel?>(
        future: fs.getGatePass(passId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Pass not found'));
          }

          final pass = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildStatusSection(pass),
                const SizedBox(height: 24),
                _buildStudentCard(pass),
                const SizedBox(height: 24),
                _buildDetailsCard(pass),
                if (pass.mentorNotes != null && pass.mentorNotes!.isNotEmpty) ...[
                   const SizedBox(height: 24),
                   _buildNotesCard(pass),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusSection(GatePassModel pass) {
    Color statusColor;
    switch (pass.status) {
      case AppConstants.statusApproved:
      case AppConstants.statusVerified:
        statusColor = Colors.green;
        break;
      case AppConstants.statusRejected:
        statusColor = Colors.red;
        break;
      case AppConstants.statusPendingMentor:
      case AppConstants.statusPendingHod:
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            pass.status.toUpperCase(),
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2),
          ),
          const SizedBox(height: 4),
          Text(
            'Applied on ${DateFormat('MMM dd, yyyy • hh:mm a').format(pass.appliedAt)}',
            style: TextStyle(color: statusColor.withOpacity(0.8), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(GatePassModel pass) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: pass.profileImageUrl != null ? NetworkImage(pass.profileImageUrl!) : null,
            child: pass.profileImageUrl == null ? const Icon(Icons.person, size: 30) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pass.studentName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Dept: ${pass.department}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(GatePassModel pass) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pass Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(height: 32),
          _buildInfoRow(Icons.location_on_outlined, 'Destination', pass.destination ?? 'N/A'),
          _buildInfoRow(Icons.subject_outlined, 'Reason', pass.reason),
          _buildInfoRow(Icons.timer_outlined, 'Pass Type', pass.passType == AppConstants.passTypeFullDay ? 'Full Day' : 'Short Pass'),
          _buildInfoRow(Icons.schedule, 'Status', pass.status),
          if (pass.usedAt != null)
             _buildInfoRow(Icons.exit_to_app, 'Scanned At', DateFormat('hh:mm a').format(pass.usedAt!)),
        ],
      ),
    );
  }

  Widget _buildNotesCard(GatePassModel pass) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.accentYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentYellow.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.comment_outlined, size: 18, color: Colors.orange),
              SizedBox(width: 8),
              Text('Mentor Notes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 12),
          Text(pass.mentorNotes!, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
