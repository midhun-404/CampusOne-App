import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../core/theme/app_theme.dart';

class SecurityLogHistoryScreen extends StatefulWidget {
  const SecurityLogHistoryScreen({super.key});

  @override
  State<SecurityLogHistoryScreen> createState() => _SecurityLogHistoryScreenState();
}

class _SecurityLogHistoryScreenState extends State<SecurityLogHistoryScreen> {
  DateTime? _selectedDate; // null means show recent 200 logs
  String _searchQuery = '';

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Log History'),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _selectDate(context),
            )
          ],
          bottom: const TabBar(
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryBlue,
            tabs: [
              Tab(text: 'Students'),
              Tab(text: 'Staff & Faculty'),
            ],
          ),
        ),
        body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: AppTheme.primaryBlue.withOpacity(0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null 
                        ? 'Showing Recent Passes' 
                        : 'Date: ${DateFormat('MMM d, yyyy').format(_selectedDate!)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Row(
                  children: [
                    if (_selectedDate != null)
                      TextButton(
                        onPressed: () => setState(() => _selectedDate = null),
                        child: const Text('Clear', style: TextStyle(color: Colors.red)),
                      ),
                    TextButton(
                      onPressed: () => _selectDate(context),
                      child: const Text('Filter Date'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search name, department, or status...",
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: fs.getAllSecurityLogsStream(_selectedDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading passes: ${snapshot.error}'));
                }
                
                final allLogs = snapshot.data ?? [];
                final logs = allLogs.where((log) {
                  final name = (log['studentName'] ?? '').toString().toLowerCase();
                  final dept = (log['department'] ?? '').toString().toLowerCase();
                  final res = (log['result'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) || dept.contains(_searchQuery) || res.contains(_searchQuery);
                }).toList();

                final studentLogs = logs.where((l) => !(l['isStaff'] ?? false)).toList();
                final staffLogs = logs.where((l) => (l['isStaff'] == true)).toList();

                return TabBarView(
                  children: [
                    _buildLogList(studentLogs),
                    _buildLogList(staffLogs),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildLogList(List<Map<String, dynamic>> logList) {
    if (logList.isEmpty && _searchQuery.isNotEmpty) {
      return const Center(child: Text('No results match your search.'));
    } else if (logList.isEmpty) {
      return const Center(child: Text('No gate pass logs available in this category.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logList.length,
      itemBuilder: (context, index) {
        final log = logList[index];
        final time = (log['scannedAt'] as Timestamp?)?.toDate();
        final isExit = log['result'] == 'EXIT' || log['result'] == 'VERIFIED'; // Often first scan is exit
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              backgroundImage: log['profileImageUrl'] != null ? NetworkImage(log['profileImageUrl']) : null,
              child: log['profileImageUrl'] == null ? const Icon(Icons.person, color: AppTheme.primaryBlue) : null,
            ),
            title: Text(
              log['studentName'] ?? 'Unknown User',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log['department'] ?? 'Staff/Faculty'),
                if (time != null)
                  Text(DateFormat.jm().format(time), style: const TextStyle(color: Colors.grey)),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isExit ? Colors.orange.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isExit ? Colors.orange.shade200 : Colors.green.shade200),
              ),
              child: Text(
                log['result'] ?? '',
                style: TextStyle(
                  color: isExit ? Colors.orange.shade700 : Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
