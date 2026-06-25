import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth(context);
    });
  }

  void _checkAuth(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    // If already initialized, route immediately
    if (authService.isInitialized) {
      _handleRouting(authService);
    } else {
      // Otherwise, listen for when it becomes initialized
      authService.addListener(() {
        if (mounted && authService.isInitialized) {
          _handleRouting(authService);
          authService.removeListener(() {}); // Simple cleanup logic isn't strictly necessary since SplashScreen pops, but good practice
        }
      });
    }
  }

  void _handleRouting(AuthService authService) {
    if (authService.currentUser == null) {
      context.go('/role_selection');
    } else {
      _routeUser(authService.currentUser!.role);
    }
  }

  void _routeUser(String role) {
    switch (role) {
      case AppConstants.roleStudent:
        context.go('/student');
        break;
      case AppConstants.roleMentor:
        context.go('/mentor');
        break;
      case AppConstants.roleHod:
        context.go('/hod');
        break;
      case AppConstants.roleSecurity:
        context.go('/security');
        break;
      case AppConstants.roleCanteen:
        context.go('/canteen');
        break;
      case AppConstants.roleAdmin:
        context.go('/admin');
        break;
      default:
        context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
