import 'package:cloud_firestore/cloud_firestore.dart';

class AccountRequestModel {
  final String id;
  final String name;
  final String email;
  final String department;
  final String role;
  final String password; // stored temporarily until HOD approves
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime requestedAt;
  final String? rejectionReason;

  AccountRequestModel({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.role,
    required this.password,
    required this.status,
    required this.requestedAt,
    this.rejectionReason,
  });

  factory AccountRequestModel.fromMap(Map<String, dynamic> data, String id) {
    return AccountRequestModel(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      department: data['department'] ?? '',
      role: data['role'] ?? 'Faculty',
      password: data['password'] ?? '',
      status: data['status'] ?? 'pending',
      requestedAt: (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rejectionReason: data['rejectionReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'department': department,
      'role': role,
      'password': password,
      'status': status,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'rejectionReason': rejectionReason,
    };
  }
}
