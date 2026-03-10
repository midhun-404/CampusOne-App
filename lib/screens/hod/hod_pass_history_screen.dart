import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/gate_pass_model.dart';
import '../../services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import 'hod_pass_detail_screen.dart';

class HodPassHistoryScreen extends StatefulWidget {
  final String department;
  const HodPassHistoryScreen({super.key, required this.department});

  @override
  State<HodPassHistoryScreen> createState() => _HodPassHistoryScreenState();
}

class _HodPassHistoryScreenState extends State<HodPassHistoryScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context);

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Department Pass History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.primaryBlue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by Student Reg No',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<GatePassModel>>(
              stream: fs.getDepartmentPassesStream(widget.department),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                final allPasses = snapshot.data ?? [];
                final passes = allPasses.where((p) {
                  return p.regNo?.toLowerCase().contains(_searchQuery) ?? false;
                }).toList();

                if (passes.isEmpty) return const Center(child: Text('No history found matching search.'));

                return ListView.builder(
                  itemCount: passes.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final pass = passes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: pass.profileImageUrl != null ? NetworkImage(pass.profileImageUrl!) : null,
                          child: pass.profileImageUrl == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text('${pass.studentName} (${pass.status.toUpperCase()})', 
                          style: TextStyle(fontWeight: FontWeight.bold, color: _getStatusColor(pass.status))),
                        subtitle: Text('Applied: ${DateFormat.yMd().add_jm().format(pass.appliedAt)}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => HodPassDetailScreen(pass: pass))),
                      ),
                    );
                  },
                );
              },
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
