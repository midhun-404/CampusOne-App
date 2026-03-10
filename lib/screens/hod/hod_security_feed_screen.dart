import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../core/theme/app_theme.dart';

class HodSecurityFeedScreen extends StatelessWidget {
  final String department;
  const HodSecurityFeedScreen({super.key, required this.department});

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Live Security Feed'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.primaryBlue,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: fs.getDepartmentSecurityLogsStream(department),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return const Center(child: Text('No security scans recorded yet.'));
          }

          return ListView.builder(
            itemCount: logs.length,
            padding: const EdgeInsets.all(24),
            itemBuilder: (context, index) {
              final log = logs[index];
              final time = (log['scannedAt'] as DateTime?) ?? DateTime.now();
              final result = (log['result'] as String?) ?? 'Unknown';
              final scannedBy = (log['scannedBy'] as String?) ?? 'Security';
              
              bool isSuccess = result.toLowerCase().contains('valid');

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSuccess ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSuccess ? Icons.login_rounded : Icons.report_problem_rounded,
                        color: isSuccess ? Colors.green : Colors.red,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result,
                            style: TextStyle(fontWeight: FontWeight.bold, color: isSuccess ? Colors.green.shade700 : Colors.red.shade700),
                          ),
                          Text(
                            'Scanned by: $scannedBy',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat.jm().format(time),
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
