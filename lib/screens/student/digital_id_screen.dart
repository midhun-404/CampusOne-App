import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class DigitalIDScreen extends StatelessWidget {
  const DigitalIDScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      appBar: AppBar(
        title: const Text('Digital Student ID', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Premium ID Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // Header with College Name
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      child: Column(
                        children: [
                          Image.asset('assets/images/logo.png', height: 40),
                          const SizedBox(height: 8),
                          Text(
                            user.college ?? 'CAMPUSONE COLLEGE',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Profile Image
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.accentYellow,
                      backgroundImage: user.profileImageUrl != null 
                          ? NetworkImage(user.profileImageUrl!) 
                          : null,
                      child: user.profileImageUrl == null 
                          ? const Icon(Icons.person, size: 60, color: Colors.white) 
                          : null,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Student Info
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'REG NO: ${user.regNo ?? "N/A"}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      child: Divider(thickness: 1),
                    ),
                    
                    // Details Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDetailItem('Department', user.department ?? 'N/A'),
                          _buildDetailItem('Semester', user.semester ?? 'N/A'),
                          _buildDetailItem('Division', user.division ?? 'N/A'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // QR Code for easy scanning
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: QrImageView(
                        data: user.id,
                        version: QrVersions.auto,
                        size: 150.0,
                        foregroundColor: AppTheme.primaryBlue,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    const Text(
                      'Scan to Verify Identity',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              // Bottom Label
              const Opacity(
                opacity: 0.7,
                child: Text(
                  'CampusOne - Security Gate Management System',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
