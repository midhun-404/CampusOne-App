import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notice_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class FacultyNoticeScreen extends StatefulWidget {
  const FacultyNoticeScreen({super.key});

  @override
  State<FacultyNoticeScreen> createState() => _FacultyNoticeScreenState();
}

class _FacultyNoticeScreenState extends State<FacultyNoticeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitNotice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      final user = authService.currentUser;

      if (user == null) return;

      final notice = NoticeModel(
        id: '', // Firestore will generate
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        authorName: user.name,
        timestamp: DateTime.now(),
        expiryAt: DateTime.now().add(const Duration(days: 7)),
        targetDepartment: user.department ?? 'General',
      );

      await firestore.addNotice(notice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notice broadcasted successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Broadcast Notice'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create a New Announcement',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'This will be visible to all students in your department.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Notice Title',
                  hintText: 'e.g., Internal Exam Schedule',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _contentController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  hintText: 'Type your message here...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 120),
                    child: Icon(Icons.description_outlined),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Please enter content' : null,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitNotice,
                  icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded),
                  label: Text(_isLoading ? 'BROADCASTING...' : 'BROADCAST NOW'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
