import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/kerala_colleges.dart';
import '../../core/theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _regNoCtrl = TextEditingController();
  final _divisionCtrl = TextEditingController();
  final _parentPhoneCtrl = TextEditingController();
  
  String _selectedDept = AppConstants.departments.first;
  String _selectedSem = 'S1';
  String _selectedCollege = KeralaColleges.list.first;
  File? _profileImage;
  final _formKey = GlobalKey<FormState>();

  final List<String> _semesters = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8'];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  void _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a profile image')));
      return;
    }

    final auth = Provider.of<AuthService>(context, listen: false);
    String? error = await auth.registerStudent(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
      department: _selectedDept,
      regNo: _regNoCtrl.text.trim().toUpperCase(),
      semester: _selectedSem,
      division: _divisionCtrl.text.trim().toUpperCase(),
      college: _selectedCollege,
      parentPhone: _parentPhoneCtrl.text.trim(),
      profileImage: _profileImage,
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      context.go('/student');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Registration'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryBlue, width: 2),
                      image: _profileImage != null
                          ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _profileImage == null ? const Icon(Icons.camera_alt, size: 40, color: AppTheme.primaryBlue) : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Upload Photo",
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                ),
                const SizedBox(height: 32),
                
                // Form Fields wrapped in a glassmorphic/flat card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                        validator: (v) => v!.isEmpty ? 'Enter your name' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                        validator: (v) => v!.isEmpty ? 'Enter email' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.password)),
                        validator: (v) => (v?.length ?? 0) < 6 ? 'Password must be at least 6 characters' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _regNoCtrl,
                        decoration: const InputDecoration(labelText: 'Register Number', prefixIcon: Icon(Icons.badge)),
                        validator: (v) => v!.isEmpty ? 'Enter Register Number' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedSem,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Semester', prefixIcon: Icon(Icons.timeline)),
                        items: _semesters.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setState(() => _selectedSem = val!),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedDept,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Department', prefixIcon: Icon(Icons.business)),
                        items: AppConstants.departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (val) => setState(() => _selectedDept = val!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _divisionCtrl,
                        decoration: const InputDecoration(labelText: 'Division (e.g. A, B)', prefixIcon: Icon(Icons.class_)),
                        validator: (v) => v!.isEmpty ? 'Enter Division' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _parentPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Parent Phone Number', prefixIcon: Icon(Icons.phone_android)),
                        validator: (v) => v!.isEmpty ? 'Enter Parent Phone Number' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCollege,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'College', prefixIcon: Icon(Icons.account_balance)),
                        items: KeralaColleges.list.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) => setState(() => _selectedCollege = val!),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                auth.isLoading
                  ? const CircularProgressIndicator(color: AppTheme.primaryBlue)
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _signup,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('CREATE ACCOUNT', style: TextStyle(fontSize: 16, letterSpacing: 1.1)),
                      ),
                    ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.go('/login', extra: AppConstants.roleStudent),
                  child: Text(
                    "Already have an account? Login",
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

