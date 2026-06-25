import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../core/constants/kerala_colleges.dart';
import '../../core/theme/app_theme.dart';

class HodEditProfileScreen extends StatefulWidget {
  const HodEditProfileScreen({super.key});

  @override
  State<HodEditProfileScreen> createState() => _HodEditProfileScreenState();
}

class _HodEditProfileScreenState extends State<HodEditProfileScreen> {
  final _nameCtrl = TextEditingController();
  String? _selectedCollege;
  
  File? _newProfileImage;
  String? _existingProfileImageUrl;
  
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user != null) {
        _nameCtrl.text = user.name;
        _selectedCollege = user.college;
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
        'college': _selectedCollege,
        'profileImageUrl': updatedImageUrl,
      };

      await Provider.of<FirestoreService>(context, listen: false).updateUser(user.id, updateData);
      await auth.refreshUser();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
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
      appBar: AppBar(
        title: const Text('Edit HOD Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.primaryBlue,
      ),
      backgroundColor: AppTheme.lightBg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
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
                              : (_existingProfileImageUrl != null
                                  ? DecorationImage(image: NetworkImage(_existingProfileImageUrl!), fit: BoxFit.cover)
                                  : null),
                        ),
                        child: _newProfileImage == null && _existingProfileImageUrl == null
                            ? const Icon(Icons.person, size: 50, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text("Tap to change photo", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 32),
                    
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                            validator: (v) => v!.isEmpty ? 'Enter your name' : null,
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: _selectedCollege,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'College', prefixIcon: Icon(Icons.account_balance)),
                            items: KeralaColleges.list.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (val) => setState(() => _selectedCollege = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Save Changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }
}
