FIREBASE AUTHENTICATION (LOGIN SYSTEM) FULL CODE

DEPENDENCIES:
Add these to pubspec.yaml:
firebase_auth: ^4.16.0
cloud_firestore: ^4.14.0
provider: ^6.1.1
device_info_plus: ^10.1.0 (Optional: for device locking)

1. USER MODEL
Save this in lib/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // Student, Mentor, HOD, etc.
  final String? deviceId;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.deviceId,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String docId) {
    return UserModel(
      id: docId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'Student',
      deviceId: data['deviceId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'deviceId': deviceId,
    };
  }
}


2. AUTHENTICATION SERVICE
Save this in lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  // LOGIN LOGIC
  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Firebase Auth Sign In
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );

      // 2. Fetch User Profile from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        _isLoading = false;
        notifyListeners();
        return 'User profile not found in database.';
      }

      _currentUser = UserModel.fromMap(userDoc.data()!, userDoc.id);
      
      _isLoading = false;
      notifyListeners();
      return null; // Success
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  // LOGOUT LOGIC
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}


3. LOGIN SCREEN LOGIC
Example implementation in your Login Widget

void handleLogin() async {
  final authService = Provider.of<AuthService>(context, listen: false);
  
  String? result = await authService.login(
    emailController.text.trim(),
    passwordController.text.trim(),
  );

  if (result == null) {
    // Navigate based on role
    final user = authService.currentUser;
    if (user?.role == 'Student') {
      Navigator.pushReplacementNamed(context, '/student_home');
    } else if (user?.role == 'HOD') {
      Navigator.pushReplacementNamed(context, '/hod_home');
    }
  } else {
    // Show error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result))
    );
  }
}


4. FIRESTORE SECURITY RULES (CRITICAL)
Add these to your firestore.rules to protect user data

service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
