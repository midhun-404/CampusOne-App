import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? department;
  final String? regNo;
  final String? semester;
  final String? division;
  final String? college;
  final String? profileImageUrl;
  final String? phone;
  final String? deviceId;
  final String? parentPhone;
  final String? fcmToken;
  final String? mentorId;
  final List<String> searchKeywords;
  final DateTime createdAt;
  final bool isTestAccount;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.department,
    this.regNo,
    this.semester,
    this.division,
    this.college,
    this.profileImageUrl,
    this.phone,
    this.deviceId,
    this.parentPhone,
    this.fcmToken,
    this.mentorId,
    this.searchKeywords = const [],
    required this.createdAt,
    this.isTestAccount = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      id: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'Student',
      department: data['department'],
      regNo: data['regNo'],
      semester: data['semester'],
      division: data['division'],
      college: data['college'],
      profileImageUrl: (data['profileImageUrl']?.toString().isEmpty ?? true) ? null : data['profileImageUrl'],
      phone: data['phone'],
      deviceId: data['deviceId'],
      parentPhone: data['parentPhone'],
      fcmToken: data['fcmToken'],
      mentorId: data['mentorId'],
      searchKeywords: List<String>.from(data['searchKeywords'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isTestAccount: data['isTestAccount'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'regNo': regNo,
      'semester': semester,
      'division': division,
      'college': college,
      'profileImageUrl': profileImageUrl,
      'phone': phone,
      'deviceId': deviceId,
      'parentPhone': parentPhone,
      'fcmToken': fcmToken,
      'mentorId': mentorId,
      'searchKeywords': searchKeywords,
      'createdAt': Timestamp.fromDate(createdAt),
      'isTestAccount': isTestAccount,
    };
  }
}
