import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/mentor_service.dart';
import '../../models/gate_pass_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class MentorHistoryScreen extends StatefulWidget {
  const MentorHistoryScreen({super.key});

  @override
  State<MentorHistoryScreen> createState() => _MentorHistoryScreenState();
}

class _MentorHistoryScreenState extends State<MentorHistoryScreen> {
  String _searchQuery = "";
  DateTimeRange? _dateRange;

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

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
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: Text('${user.semester}-${user.division} History'),
        actions: [
          if (_dateRange != null || _searchQuery.isNotEmpty)
            TextButton(
              onPressed: () => setState(() {
                _dateRange = null;
                _searchQuery = "";
              }),
              child: const Text('ALL', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search Name / Reg No',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _selectDateRange(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _dateRange != null ? AppTheme.primaryBlue : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.calendar_month, 
                      color: _dateRange != null ? Colors.white : AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_dateRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${DateFormat.yMMMd().format(_dateRange!.start)} - ${DateFormat.yMMMd().format(_dateRange!.end)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<GatePassModel>>(
              stream: mentorService.getClassPassHistory(user.department!, user.semester!, user.division!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final allPasses = snapshot.data ?? [];
                final passes = allPasses.where((p) {
                  // Search filter
                  final matchesSearch = p.studentName.toLowerCase().contains(_searchQuery) || 
                                      (p.regNo?.toLowerCase().contains(_searchQuery) ?? false);
                  
                  // Date range filter
                  bool matchesDate = true;
                  if (_dateRange != null) {
                    final appliedDate = DateTime(p.appliedAt.year, p.appliedAt.month, p.appliedAt.day);
                    matchesDate = appliedDate.isAtSameMomentAs(_dateRange!.start) ||
                                (appliedDate.isAfter(_dateRange!.start) && appliedDate.isBefore(_dateRange!.end)) ||
                                appliedDate.isAtSameMomentAs(_dateRange!.end);
                  }
                  
                  return matchesSearch && matchesDate;
                }).toList();

                if (passes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(_searchQuery.isEmpty && _dateRange == null ? 'No pass history found.' : 'No matching results.'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: passes.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final pass = passes[index];
                    return _buildHistoryRow(context, pass);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(BuildContext context, GatePassModel pass) {
    Color statusColor = Colors.grey;
    if (pass.status == AppConstants.statusApproved) statusColor = Colors.green;
    if (pass.status == AppConstants.statusRejected) statusColor = Colors.red;
    if (pass.status == AppConstants.statusPendingHod) statusColor = Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => context.push('/gate_pass_detail/${pass.id}'),
        leading: CircleAvatar(
          backgroundImage: pass.profileImageUrl != null ? NetworkImage(pass.profileImageUrl!) : null,
          child: pass.profileImageUrl == null ? const Icon(Icons.person) : null,
        ),
        title: Text(pass.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reg No: ${pass.regNo ?? 'N/A'}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy • hh:mm a').format(pass.appliedAt),
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        trailing: Container(
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
      ),
    );
  }
}
