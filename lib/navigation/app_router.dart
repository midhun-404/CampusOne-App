import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../core/constants/app_constants.dart';

import '../screens/student/student_dashboard.dart';
import '../screens/student/apply_pass_screen.dart';
import '../screens/student/active_pass_screen.dart';
import '../screens/student/student_canteen_screen.dart';
import '../screens/student/student_orders_screen.dart';
import '../screens/student/student_history_screen.dart';
import '../screens/student/student_edit_profile_screen.dart';
import '../screens/student/digital_id_screen.dart';

import '../screens/mentor/mentor_dashboard.dart';
import '../screens/mentor/mentor_edit_profile_screen.dart';
import '../screens/mentor/mentor_students_screen.dart';
import '../screens/hod/hod_dashboard.dart';
import '../screens/hod/hod_profile_screen.dart';
import '../screens/security/security_dashboard.dart';
import '../screens/security/qr_scanner_screen.dart';
import '../screens/canteen/canteen_dashboard.dart';
import '../screens/splash_screen.dart';
import '../models/gate_pass_model.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(), // Handles role-based redirection
      ),
      GoRoute(
        path: '/role_selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          // Default to student if no role was passed
          final role = state.extra as String? ?? AppConstants.roleStudent;
          return LoginScreen(role: role);
        },
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentDashboard(),
        routes: [
          GoRoute(
            path: 'apply',
            builder: (context, state) => const ApplyPassScreen(),
          ),
          GoRoute(
            path: 'epass',
            builder: (context, state) {
              final pass = state.extra as GatePassModel;
              return ActivePassScreen(pass: pass);
            },
          ),
          GoRoute(
            path: 'history',
            builder: (context, state) => const StudentHistoryScreen(),
          ),
          GoRoute(
            path: 'edit_profile',
            builder: (context, state) => const StudentEditProfileScreen(),
          ),
          GoRoute(
            path: 'id_card',
            builder: (context, state) => const DigitalIDScreen(),
          ),
          GoRoute(
            path: 'canteen',
            builder: (context, state) => StudentCanteenScreen(initialCart: state.extra as List<Map<String, dynamic>>?),
            routes: [
              GoRoute(
                path: 'orders',
                builder: (context, state) => const StudentOrdersScreen(),
              ),
            ]
          ),
        ]
      ),
      GoRoute(
        path: '/mentor',
        builder: (context, state) => const MentorDashboard(),
        routes: [
          GoRoute(
            path: 'edit_profile',
            builder: (context, state) => const MentorEditProfileScreen(),
          ),
          GoRoute(
            path: 'students',
            builder: (context, state) => const MentorStudentsScreen(),
          )
        ]
      ),
      GoRoute(
        path: '/hod',
        builder: (context, state) => const HodDashboard(),
        routes: [
           GoRoute(
            path: 'profile',
            builder: (context, state) => const HodProfileScreen(),
          ),
        ]
      ),
      GoRoute(
        path: '/security',
        builder: (context, state) => const SecurityDashboard(),
        routes: [
          GoRoute(
            path: 'scan',
            builder: (context, state) => const QrScannerScreen(),
          ),
        ]
      ),
      GoRoute(
        path: '/canteen',
        builder: (context, state) => const CanteenDashboard(),
      ),
    ],
  );
}
