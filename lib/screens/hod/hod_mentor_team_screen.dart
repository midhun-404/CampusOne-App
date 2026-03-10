import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class HodMentorTeamScreen extends StatelessWidget {
  final String department;
  const HodMentorTeamScreen({super.key, required this.department});

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context);

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Mentor Team'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.primaryBlue,
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: fs.getDepartmentUsersStream(department, AppConstants.roleMentor),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final mentors = snapshot.data ?? [];

          if (mentors.isEmpty) return const Center(child: Text('No mentors found.'));

          return ListView.builder(
            itemCount: mentors.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final mentor = mentors[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: mentor.profileImageUrl != null ? NetworkImage(mentor.profileImageUrl!) : null,
                    child: mentor.profileImageUrl == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(mentor.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Class: ${mentor.semester ?? "N/A"} - ${mentor.division ?? "N/A"}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.message_outlined, color: AppTheme.primaryBlue, size: 20),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Contacting ${mentor.name}...')));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.email_outlined, color: AppTheme.primaryBlue, size: 20),
                        onPressed: () {
                          // Could launch mail client
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    // Show full contact card
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
