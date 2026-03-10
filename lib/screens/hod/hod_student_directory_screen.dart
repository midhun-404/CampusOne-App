import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../shared/student_detail_screen.dart';

class HodStudentDirectoryScreen extends StatefulWidget {
  final String department;
  const HodStudentDirectoryScreen({super.key, required this.department});

  @override
  State<HodStudentDirectoryScreen> createState() => _HodStudentDirectoryScreenState();
}

class _HodStudentDirectoryScreenState extends State<HodStudentDirectoryScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context);

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Student Directory'),
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
                hintText: 'Search by Name or Reg No',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: fs.getDepartmentUsersStream(widget.department, AppConstants.roleStudent),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                final students = snapshot.data?.where((u) {
                  return u.name.toLowerCase().contains(_searchQuery) || (u.regNo?.toLowerCase().contains(_searchQuery) ?? false);
                }).toList() ?? [];

                if (students.isEmpty) return const Center(child: Text('No students found.'));

                return ListView.builder(
                  itemCount: students.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: student.profileImageUrl != null ? NetworkImage(student.profileImageUrl!) : null,
                          child: student.profileImageUrl == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Reg: ${student.regNo ?? "N/A"}'),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => StudentDetailScreen(student: student))),
                        trailing: const Icon(Icons.chevron_right, color: AppTheme.primaryBlue),
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

}
