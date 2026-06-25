import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/kerala_colleges.dart';

class HodProfileScreen extends StatefulWidget {
  const HodProfileScreen({super.key});

  @override
  State<HodProfileScreen> createState() => _HodProfileScreenState();
}

class _HodProfileScreenState extends State<HodProfileScreen> {
  String? _selectedCollege;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    _selectedCollege = user?.college;
  }

  Future<void> _updateCollege(String? newVal) async {
    if (newVal == null) return;
    setState(() => _isLoading = true);
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final fs = Provider.of<FirestoreService>(context, listen: false);
    
    try {
      await fs.updateUser(authService.currentUser!.id, {'college': newVal});
      await authService.refreshUser();
      if (mounted) {
        setState(() {
          _selectedCollege = newVal;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('College updated successfully!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.primaryBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, size: 28),
            onPressed: () => context.push('/hod/edit_profile'),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: AppTheme.primaryBlue,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    user.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Head of Department - ${user.department}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  _buildProfileItem(Icons.email_outlined, 'Email Address', user.email),
                  _buildProfileItem(Icons.business_rounded, 'Department', user.department ?? 'N/A'),
                  
                  // College Selection
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.account_balance_rounded, color: AppTheme.primaryBlue, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('College', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              _isLoading 
                                ? const LinearProgressIndicator()
                                : DropdownButton<String>(
                                    isExpanded: true,
                                    value: _selectedCollege,
                                    hint: const Text('Select College'),
                                    underline: const SizedBox(),
                                    items: KeralaColleges.list.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
                                    onChanged: _updateCollege,
                                  ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  _buildProfileItem(Icons.security_rounded, 'Role Privilege', 'Departmental Administrator (HOD)'),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.info_outline, color: AppTheme.primaryBlue),
                    label: const Text('About App'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: const BorderSide(color: AppTheme.primaryBlue),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () => context.push('/about'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout Session'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () async {
                      await Provider.of<AuthService>(context, listen: false).logout();
                      if (context.mounted) context.go('/role_selection');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
