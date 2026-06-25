import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/account_request_model.dart';
import '../../services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class FacultyAccountRequestScreen extends StatefulWidget {
  const FacultyAccountRequestScreen({super.key});

  @override
  State<FacultyAccountRequestScreen> createState() => _FacultyAccountRequestScreenState();
}

class _FacultyAccountRequestScreenState extends State<FacultyAccountRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  String _selectedDept = AppConstants.departments.first;
  String _selectedRole = AppConstants.roleFaculty;
  bool _isLoading = false;
  bool _obscurePass = true;

  final List<String> _staffRoles = [
    AppConstants.roleFaculty,
    AppConstants.roleMentor,
  ];

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final request = AccountRequestModel(
        id: '',
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        department: _selectedDept,
        role: _selectedRole,
        password: _passCtrl.text,
        status: 'pending',
        requestedAt: DateTime.now(),
      );

      await Provider.of<FirestoreService>(context, listen: false)
          .createAccountRequest(request);

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
          title: const Text('Request Submitted!', textAlign: TextAlign.center),
          content: Text(
            'Your account request has been sent to the ${_selectedDept} HOD for approval. You will be able to login once it is approved.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.pop();
                },
                child: const Text('Back to Login'),
              ),
            ),
          ],
        ),
      );
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryBlue,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryBlue, Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 14),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Staff Account Request', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                Text('Pending HOD Approval', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppTheme.primaryBlue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your request will be reviewed by your department HOD. Once approved, you can log in using your credentials.',
                              style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    _buildSectionLabel('Personal Information'),
                    const SizedBox(height: 12),
                    _buildField(controller: _nameCtrl, label: 'Full Name', icon: Icons.person_outline,
                        validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    _buildField(controller: _emailCtrl, label: 'College Email Address', icon: Icons.alternate_email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v!.isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        }),
                    const SizedBox(height: 28),

                    _buildSectionLabel('Department & Role'),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Department',
                      icon: Icons.school_outlined,
                      value: _selectedDept,
                      items: AppConstants.departments,
                      onChanged: (v) => setState(() => _selectedDept = v!),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'Role',
                      icon: Icons.badge_outlined,
                      value: _selectedRole,
                      items: _staffRoles,
                      onChanged: (v) => setState(() => _selectedRole = v!),
                    ),
                    const SizedBox(height: 28),

                    _buildSectionLabel('Set Login Password'),
                    const SizedBox(height: 12),
                    _buildField(controller: _passCtrl, label: 'Password', icon: Icons.lock_outline,
                        obscureText: _obscurePass,
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePass = !_obscurePass),
                        ),
                        validator: (v) => v!.length < 6 ? 'Min 6 characters' : null),
                    const SizedBox(height: 16),
                    _buildField(controller: _confirmPassCtrl, label: 'Confirm Password', icon: Icons.lock_outline,
                        obscureText: _obscurePass,
                        validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 36),

                    SizedBox(
                      width: double.infinity,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton.icon(
                              onPressed: _submitRequest,
                              icon: const Icon(Icons.send_rounded),
                              label: const Text('Submit Request to HOD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: 4,
                              ),
                            ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1));
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2)),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
    );
  }
}
