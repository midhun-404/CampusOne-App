import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../shared/student_detail_screen.dart';

class MentorStudentsScreen extends StatefulWidget {
  const MentorStudentsScreen({super.key});

  @override
  State<MentorStudentsScreen> createState() => _MentorStudentsScreenState();
}

class _MentorStudentsScreenState extends State<MentorStudentsScreen> {
  void _showStudentDetails(UserModel student) {
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => StudentDetailScreen(student: student)));
  }
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestore = Provider.of<FirestoreService>(context);
    final mentorId = authService.currentUser?.id;

    if (mentorId == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('My Students'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.primaryBlue,
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: firestore.getMentorStudents(mentorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No students added yet',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Students are automatically added here when they register for your class (Semester & Division).',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          final students = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundImage: student.profileImageUrl != null 
                        ? NetworkImage(student.profileImageUrl!) 
                        : null,
                    child: student.profileImageUrl == null 
                        ? const Icon(Icons.person) 
                        : null,
                  ),
                  title: Text(
                    student.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Reg No: ${student.regNo ?? "N/A"}'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => _showStudentDetails(student),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

