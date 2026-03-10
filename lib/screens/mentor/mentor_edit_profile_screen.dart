import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class MentorEditProfileScreen extends StatefulWidget {
  const MentorEditProfileScreen({super.key});

  @override
  State<MentorEditProfileScreen> createState() => _MentorEditProfileScreenState();
}

class _MentorEditProfileScreenState extends State<MentorEditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _divisionCtrl = TextEditingController();
  
  String _selectedDept = AppConstants.departments.first;
  String _selectedSem = 'S1';
  
  File? _newProfileImage;
  String? _existingProfileImageUrl;
  
  final _formKey = GlobalKey<FormState>();
  final List<String> _semesters = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user != null) {
        _nameCtrl.text = user.name;
        _divisionCtrl.text = user.division ?? '';
        if (user.department != null && AppConstants.departments.contains(user.department)) {
          _selectedDept = user.department!;
        }
        if (user.semester != null && _semesters.contains(user.semester)) {
          _selectedSem = user.semester!;
        }
        _existingProfileImageUrl = user.profileImageUrl;
        setState(() {});
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _newProfileImage = File(picked.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = auth.currentUser;
      if (user == null) throw Exception("User not found");

      String? updatedImageUrl = _existingProfileImageUrl;

      if (_newProfileImage != null) {
        String? uploadedUrl = await StorageService().uploadProfileImage(user.id, _newProfileImage!);
        if (uploadedUrl != null) {
          updatedImageUrl = uploadedUrl;
        }
      }

      final updateData = {
        'name': _nameCtrl.text.trim(),
        'division': _divisionCtrl.text.trim(),
        'department': _selectedDept,
        'semester': _selectedSem,
        'profileImageUrl': updatedImageUrl,
      };

      await Provider.of<FirestoreService>(context, listen: false).updateUser(user.id, updateData);
      await auth.refreshUser(); // Updates local Provider instance

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff Profile updated successfully!')));
      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Staff Profile')),
      backgroundColor: AppTheme.lightBg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primaryBlue, width: 3),
                            image: _newProfileImage != null
                                ? DecorationImage(image: FileImage(_newProfileImage!), fit: BoxFit.cover)
                                : (_existingProfileImageUrl != null && _existingProfileImageUrl!.isNotEmpty
                                    ? DecorationImage(image: NetworkImage(_existingProfileImageUrl!), fit: BoxFit.cover)
                                    : null),
                          ),
                          child: _newProfileImage == null && (_existingProfileImageUrl == null || _existingProfileImageUrl!.isEmpty)
                              ? const Icon(Icons.person, size: 50, color: Colors.grey)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Tap to change photo', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 32),
                      
                      _buildTextField(
                        controller: _nameCtrl,
                        label: 'Full Name',
                        icon: Icons.person,
                        validator: (val) => val == null || val.isEmpty ? 'Please enter name' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      _buildDropdown(
                        label: 'Department',
                        icon: Icons.school,
                        value: _selectedDept,
                        items: AppConstants.departments,
                        onChanged: (val) => setState(() => _selectedDept = val!),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildDropdown(
                        label: 'Mentoring Semester',
                        icon: Icons.timeline,
                        value: _selectedSem,
                        items: _semesters,
                        onChanged: (val) => setState(() => _selectedSem = val!),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildTextField(
                        controller: _divisionCtrl,
                        label: 'Mentoring Division (e.g. A, B)',
                        icon: Icons.people,
                      ),
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 5,
                          ),
                          child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        floatingLabelStyle: const TextStyle(color: AppTheme.accentYellow, fontWeight: FontWeight.bold),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: AppTheme.primaryBlue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white12),
        ),
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
      value: value.isNotEmpty ? value : items.first,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        floatingLabelStyle: const TextStyle(color: AppTheme.accentYellow, fontWeight: FontWeight.bold),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: AppTheme.primaryBlue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white12),
        ),
      ),
      dropdownColor: AppTheme.primaryBlue,
      style: const TextStyle(color: Colors.white),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }
}
