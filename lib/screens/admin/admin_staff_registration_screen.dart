import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/kerala_colleges.dart';

class AdminStaffRegistrationScreen extends StatefulWidget {
  const AdminStaffRegistrationScreen({super.key});

  @override
  State<AdminStaffRegistrationScreen> createState() => _AdminStaffRegistrationScreenState();
}

class _AdminStaffRegistrationScreenState extends State<AdminStaffRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _password = '';
  String _role = AppConstants.roleMentor;
  String? _department;
  String? _semester;
  String? _division;
  String? _selectedCollege;

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Register Staff'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.primaryBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add New Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              const SizedBox(height: 8),
              Text('Create HOD or Mentor accounts for the institution.', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 32),
              
              _buildTextField('Full Name', Icons.person_outline, (val) => _name = val!),
              const SizedBox(height: 20),
              _buildTextField('Email Address', Icons.email_outlined, (val) => _email = val!, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 20),
              _buildTextField('Login Password', Icons.lock_outline, (val) => _password = val!, obscureText: true),
              const SizedBox(height: 20),
              
              const Text('Account Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              
              // Role Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _role,
                    items: [AppConstants.roleMentor, AppConstants.roleHod, AppConstants.roleSecurity, AppConstants.roleCanteen]
                        .map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) => setState(() => _role = val!),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Department (Required for HOD/Mentor)
              if (_role == AppConstants.roleMentor || _role == AppConstants.roleHod) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _department,
                      hint: const Text('Select Department'),
                      items: AppConstants.departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (val) => setState(() => _department = val),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Mentor Specific Fields
              if (_role == AppConstants.roleMentor) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField('Semester (e.g. S6)', Icons.class_outlined, (val) => _semester = val),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField('Division (e.g. A)', Icons.grid_view, (val) => _division = val),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              
              // College Selection
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCollege,
                    hint: const Text('Select College'),
                    items: KeralaColleges.list.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (val) => setState(() => _selectedCollege = val),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('CREATE STAFF ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, Function(String?) onSaved, {bool obscureText = false, TextInputType? keyboardType}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      onSaved: onSaved,
    );
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCollege == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a college.')));
      return;
    }
    _formKey.currentState!.save();
    
    setState(() => _isLoading = true);
    
    final auth = Provider.of<AuthService>(context, listen: false);
    final result = await auth.registerStaff(
      name: _name,
      email: _email,
      password: _password,
      role: _role,
      department: _department,
      semester: _semester,
      division: _division,
      college: _selectedCollege,
    );
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (result == null) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Account Created'),
            content: Text('Staff account for $_name has been successfully registered.'),
            actions: [
              TextButton(onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              }, child: const Text('Back to Dashboard'))
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
      }
    }
  }
}
