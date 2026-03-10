import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/mentor_service.dart';
import '../../models/gate_pass_model.dart';
import '../../core/constants/app_constants.dart';

class MentorHistoryScreen extends StatelessWidget {
  const MentorHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final mentorService = MentorService();

    if (user == null || user.department == null || user.semester == null || user.division == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pass History')),
        body: const Center(child: Text('Mentor Class Details not configured properly.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Class Pass History (${user.semester} - ${user.division})'),
      ),
      body: StreamBuilder<List<GatePassModel>>(
        stream: mentorService.getClassPassHistory(user.department!, user.semester!, user.division!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final passes = snapshot.data ?? [];

          if (passes.isEmpty) {
            return const Center(
              child: Text(
                'No pass history found for your class.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            itemCount: passes.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final pass = passes[index];
              return _buildHistoryRow(pass);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryRow(GatePassModel pass) {
    Color statusColor = Colors.grey;
    if (pass.status == AppConstants.statusApproved) statusColor = Colors.green;
    if (pass.status == AppConstants.statusRejected) statusColor = Colors.red;
    if (pass.status == AppConstants.statusPendingHod) statusColor = Colors.blue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(pass.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                DateFormat.yMd().format(pass.appliedAt),
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pass.reason, 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pass.passType == AppConstants.passTypeFullDay ? 'Full Day Pass' : 'Short Pass',
                      style: TextStyle(
                        fontSize: 11, 
                        color: pass.passType == AppConstants.passTypeFullDay ? Colors.red.shade700 : Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pass.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
