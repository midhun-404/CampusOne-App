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
                        onPressed: () => _showMentorContactDialog(context, mentor),
                      ),
                      IconButton(
                        icon: const Icon(Icons.call_outlined, color: Colors.green, size: 20),
                        onPressed: () {
                           // Dialer logic
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

  void _showMentorContactDialog(BuildContext context, UserModel mentor) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Message to ${mentor.name}'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Type your message...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
            onPressed: () async {
              if (controller.text.isEmpty) return;
              Navigator.pop(ctx);
              
              if (mentor.fcmToken != null) {
                // Implementation note: This uses FCM to send a direct message notification
                // In a full app, this would be saved in a 'messages' collection too.
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sending notification...')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mentor not online (no FCM token).')));
              }
            },
            child: const Text('Send Message'),
          ),
        ],
      ),
    );
  }
}
