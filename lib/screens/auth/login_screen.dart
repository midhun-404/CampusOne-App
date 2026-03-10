import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthService>(context, listen: false);
    String? error =
        await auth.login(_emailCtrl.text.trim(), _passCtrl.text.trim());

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else {
      // route based on role
      final role = auth.currentUser?.role;
      if (role != null) {
        if (role == AppConstants.roleStudent) {
          context.go('/student');
        } else if (role == AppConstants.roleMentor)
          context.go('/mentor');
        else if (role == AppConstants.roleHod)
          context.go('/hod');
        else if (role == AppConstants.roleSecurity)
          context.go('/security');
        else if (role == AppConstants.roleCanteen)
          context.go('/canteen');
        else
          context.go('/');
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text('Login - ${widget.role}'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png', height: 120),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Email', prefixIcon: Icon(Icons.email)),
                  validator: (v) => v!.isEmpty ? 'Enter email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Password', prefixIcon: Icon(Icons.password)),
                  validator: (v) => v!.isEmpty ? 'Enter password' : null,
                ),
                const SizedBox(height: 32),
                auth.isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _login,
                          child: const Text('Login'),
                        ),
                      ),
                if (widget.role == AppConstants.roleStudent) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.push('/signup'),
                    child: const Text("Student? Create an account"),
                  )
                ],
                const SizedBox(height: 32),
                const Divider(),
                TextButton.icon(
                  onPressed: () => _showDemoCredentialsDialog(context),
                  icon: const Icon(Icons.info_outline, color: AppTheme.primaryBlue),
                  label: const Text("View Demo Staff Credentials", style: TextStyle(color: AppTheme.primaryBlue)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDemoCredentialsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Demo Credentials'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Security:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Email: security@campusone.edu\nPass: security123\n'),
              Text('Canteen:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Email: canteen@campusone.edu\nPass: canteen123\n'),
              Divider(),
              Text('HODs (pass: hod123):', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('hod_cse@campusone.edu\nhod_ece@campusone.edu\nhod_eee@campusone.edu\nhod_mech@campusone.edu\nhod_civil@campusone.edu\n'),
              Text('Mentors (pass: mentor123):', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('mentor_cse@campusone.edu\nmentor_ece@campusone.edu\nmentor_eee@campusone.edu\nmentor_mech@campusone.edu\nmentor_civil@campusone.edu'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final auth = Provider.of<AuthService>(context, listen: false);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registering staff into new collection...')));
              await auth.setupStaffAccounts();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff accounts safely registered!')));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Force Register All', style: TextStyle(color: Colors.red)),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
        ],
      ),
    );
  }
}
