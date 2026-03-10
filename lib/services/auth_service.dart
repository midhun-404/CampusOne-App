import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';
import 'storage_service.dart';
import 'notification_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      // Combines hardware elements to create a unique fingerprint for the phone
      return '${androidInfo.brand}_${androidInfo.model}_${androidInfo.id}';
    }
    return 'unknown_device';
  }

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  bool _isRegistering = false;

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (_isRegistering) return; // Prevent race conditions during signup

    if (firebaseUser == null) {
      _currentUser = null;
    } else {
      final userModel = await _firestoreService.getUser(firebaseUser.uid);
      if (userModel != null) {
        String? fcmToken = await NotificationService.getToken();
        if (fcmToken != null && userModel.fcmToken != fcmToken) {
          await _firestoreService.updateUser(userModel.id, {'fcmToken': fcmToken});
          _currentUser = await _firestoreService.getUser(userModel.id);
        } else {
          _currentUser = userModel;
        }
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final userModel = await _firestoreService.getUser(cred.user!.uid);
      
      if (userModel == null) {
        await _auth.signOut();
        _isLoading = false;
        notifyListeners();
        return 'Login failed: Profile not found in registration database.';
      }

      if (userModel.role == 'Student') {
        final currentDeviceId = await _getDeviceId();
        
        // Skip device lock if this is a marked test account
        if (userModel.isTestAccount) {
          debugPrint('Bypassing Device ID lock for test account: ${userModel.email}');
          _currentUser = userModel;
        } else if (userModel.deviceId == null) {
          // If deviceId is null, bind it now
          await _firestoreService.updateUser(userModel.id, {'deviceId': currentDeviceId});
          _currentUser = await _firestoreService.getUser(userModel.id);
        } else if (userModel.deviceId != currentDeviceId) {
          // Device mismatch! Block login.
          await _auth.signOut();
          _isLoading = false;
          notifyListeners();
          return 'Access Denied: This account is bound to another device. Current ID: $currentDeviceId. Please contact staff to reset.';
        }

        // Update FCM Token on login
        String? fcmToken = await NotificationService.getToken();
        if (fcmToken != null && userModel.fcmToken != fcmToken) {
          await _firestoreService.updateUser(userModel.id, {'fcmToken': fcmToken});
          _currentUser = await _firestoreService.getUser(userModel.id);
        } else {
          _currentUser = userModel;
        }
      } else {
        _currentUser = userModel;
      }
      
      _isLoading = false;
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message ?? 'Login failed';
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> registerStudent({
    required String name,
    required String email,
    required String password,
    required String department,
    required String regNo,
    required String semester,
    required String division,
    required String college,
    required String parentPhone,
    File? profileImage,
  }) async {
    _isLoading = true;
    _isRegistering = true;
    notifyListeners();
    try {
      // 1. Create Auth User
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = cred.user!.uid;

      // 2. Upload Profile Image if provided
      String? profileImageUrl;
      if (profileImage != null) {
        profileImageUrl =
            await _storageService.uploadProfileImage(uid, profileImage);
      }

      // 3. Get FCM Token
      String? fcmToken = await NotificationService.getToken();

      // Generate search keywords for Firestore
      List<String> keywords = [];
      String temp = "";
      for (var char in name.toLowerCase().split('')) {
        temp += char;
        keywords.add(temp);
      }
      temp = "";
      for (var char in regNo.toLowerCase().split('')) {
        temp += char;
        keywords.add(temp);
      }
      keywords.add(email.toLowerCase());

      // Capture Device ID
      String deviceId = await _getDeviceId();
      
      // Auto-set as Test Account if email contains specific test domains
      bool isTest = email.endsWith('@test.com') || email.endsWith('@test.campusone.edu');

      // 5. Create Firestore User Document
      UserModel newUser = UserModel(
        id: uid,
        name: name,
        email: email,
        role: 'Student', // Hardcoded for signup
        department: department,
        regNo: regNo,
        semester: semester,
        division: division,
        college: college,
        profileImageUrl: profileImageUrl,
        deviceId: deviceId,
        parentPhone: parentPhone,
        fcmToken: fcmToken,
        searchKeywords: keywords,
        createdAt: DateTime.now(),
        isTestAccount: isTest,
      );

      await _firestoreService.createUser(newUser);
      _currentUser = newUser;
      _isInitialized = true; // Mark as Initialized so Splash routes properly

      _isLoading = false;
      _isRegistering = false;
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _isRegistering = false;
      notifyListeners();
      return e.message ?? 'Registration failed';
    } catch (e) {
      _isLoading = false;
      _isRegistering = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> refreshUser() async {
    if (_currentUser == null) return;
    _currentUser = await _firestoreService.getUser(_currentUser!.id);
    notifyListeners();
  }

  Future<void> setupStaffAccounts() async {
    _isLoading = true;
    notifyListeners();

    final List<Map<String, String>> staff = [
      // Computer Science (CSE)
      {'email': 'hod_cse@campusone.edu', 'pass': 'hod123', 'role': 'HOD', 'name': 'CSE HOD', 'dept': 'CSE', 'sem': '', 'div': ''},
      {'email': 'mentor_cse@campusone.edu', 'pass': 'mentor123', 'role': 'Mentor', 'name': 'CSE Mentor', 'dept': 'CSE', 'sem': 'S6', 'div': 'A'},
      
      // Electronics (ECE)
      {'email': 'hod_ece@campusone.edu', 'pass': 'hod123', 'role': 'HOD', 'name': 'ECE HOD', 'dept': 'ECE', 'sem': '', 'div': ''},
      {'email': 'mentor_ece@campusone.edu', 'pass': 'mentor123', 'role': 'Mentor', 'name': 'ECE Mentor', 'dept': 'ECE', 'sem': 'S6', 'div': 'A'},
      
      // Electrical (EEE)
      {'email': 'hod_eee@campusone.edu', 'pass': 'hod123', 'role': 'HOD', 'name': 'EEE HOD', 'dept': 'EEE', 'sem': '', 'div': ''},
      {'email': 'mentor_eee@campusone.edu', 'pass': 'mentor123', 'role': 'Mentor', 'name': 'EEE Mentor', 'dept': 'EEE', 'sem': 'S6', 'div': 'A'},
      
      // Mechanical (MECH)
      {'email': 'hod_mech@campusone.edu', 'pass': 'hod123', 'role': 'HOD', 'name': 'MECH HOD', 'dept': 'MECH', 'sem': '', 'div': ''},
      {'email': 'mentor_mech@campusone.edu', 'pass': 'mentor123', 'role': 'Mentor', 'name': 'MECH Mentor', 'dept': 'MECH', 'sem': 'S6', 'div': 'A'},
      
      // Civil
      {'email': 'hod_civil@campusone.edu', 'pass': 'hod123', 'role': 'HOD', 'name': 'CIVIL HOD', 'dept': 'CIVIL', 'sem': '', 'div': ''},
      {'email': 'mentor_civil@campusone.edu', 'pass': 'mentor123', 'role': 'Mentor', 'name': 'CIVIL Mentor', 'dept': 'CIVIL', 'sem': 'S6', 'div': 'A'},
 
      // Global Staff
      {'email': 'security@campusone.edu', 'pass': 'security123', 'role': 'Security', 'name': 'Campus Security', 'dept': '', 'sem': '', 'div': ''},
      {'email': 'canteen@campusone.edu', 'pass': 'canteen123', 'role': 'Canteen', 'name': 'College Canteen', 'dept': '', 'sem': '', 'div': ''},
    ];

    for (var s in staff) {
      String uid = '';
      try {
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: s['email']!,
          password: s['pass']!,
        );
        uid = cred.user!.uid;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // If it already exists, just sign in to get the UID so we can still create the Firestore doc!
          UserCredential cred = await _auth.signInWithEmailAndPassword(
            email: s['email']!,
            password: s['pass']!,
          );
          uid = cred.user!.uid;
        } else {
          print('Error creating ${s['email']}: ${e.message}');
          continue; // skip on other errors
        }
      } catch (e) {
        print('Error: $e');
        continue;
      }

      // 2. Create the Document in the primary users collection!
      try {
        UserModel newUser = UserModel(
          id: uid,
          name: s['name']!,
          email: s['email']!,
          role: s['role']!,
          department: s['dept']!.isEmpty ? null : s['dept']!,
          semester: s['sem']!.isEmpty ? null : s['sem']!,
          division: s['div']!.isEmpty ? null : s['div']!,
          createdAt: DateTime.now(),
        );
        await _firestoreService.createUser(newUser);
      } catch (e) {
        print('Firestore write error: $e');
      }
    }

    // Sign out because creating users signs them in automatically
    await _auth.signOut();
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }
}
