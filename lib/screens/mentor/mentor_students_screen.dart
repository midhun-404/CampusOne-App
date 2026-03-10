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
  void _openScanner(BuildContext context, String mentorId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Scan Student ID QR',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    MobileScanner(
                      onDetect: (capture) async {
                        final List<Barcode> barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty) {
                          final String? studentId = barcodes.first.rawValue;
                          if (studentId != null) {
                            Navigator.pop(context); // Close scanner
                            _addStudent(studentId, mentorId);
                          }
                        }
                      },
                    ),
                    // Scan box overlay
                    CustomPaint(
                      painter: ScannerOverlayPainter(),
                      child: Container(),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Point the camera at the QR code on the student\'s Digital ID card',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addStudent(String studentId, String mentorId) async {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final student = await firestore.getUser(studentId);
      if (student == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student not found!')),
          );
        }
        return;
      }

      await firestore.addStudentToMentor(studentId, mentorId);
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${student.name} added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

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
                    'Use the scanner to add students to your list',
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openScanner(context, mentorId),
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: const Text('Add Student', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.5);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    final scanSize = size.width * 0.65;
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanSize,
      height: scanSize,
    );

    // Draw overlay with hole
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(12))),
      ),
      paint,
    );

    // Draw corner guides
    final borderPaint = Paint()
      ..color = AppTheme.accentYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    final rrect = RRect.fromRectAndRadius(scanRect, const Radius.circular(12));
    canvas.drawRRect(rrect, borderPaint);
    
    // Optional: add a scanning line animation (static for now as it's a painter)
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
