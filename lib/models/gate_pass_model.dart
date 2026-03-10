import 'package:cloud_firestore/cloud_firestore.dart';

class GatePassModel {
  final String id;
  final String studentId;
  final String studentName;
  final String department;
  final String? regNo;
  final String? semester;
  final String? division;
  final String? profileImageUrl;
  final String reason;
  final String? destination;
  final String? parentPhone;
  final String status;
  final String passType; // 'short' or 'full_day'
  final DateTime? expectedReturnTime;
  final DateTime? leavingTime;
  final DateTime appliedAt;
  final DateTime? mentorReviewedAt;
  final String? mentorRecommendation;
  final String? mentorNotes;
  final DateTime? hodReviewedAt;
  final DateTime? expiryTimestamp;
  final DateTime? usedAt;

  GatePassModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.department,
    this.regNo,
    this.semester,
    this.division,
    this.profileImageUrl,
    required this.reason,
    this.destination,
    this.parentPhone,
    required this.status,
    required this.passType,
    this.expectedReturnTime,
    this.leavingTime,
    required this.appliedAt,
    this.mentorReviewedAt,
    this.mentorRecommendation,
    this.mentorNotes,
    this.hodReviewedAt,
    this.expiryTimestamp,
    this.usedAt,
  });

  factory GatePassModel.fromMap(Map<String, dynamic> data, String documentId) {
    return GatePassModel(
      id: documentId,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      department: data['department'] ?? '',
      regNo: data['regNo'],
      semester: data['semester'],
      division: data['division'],
      profileImageUrl: (data['profileImageUrl']?.toString().isEmpty ?? true) ? null : data['profileImageUrl'],
      reason: data['reason'] ?? '',
      destination: data['destination'],
      parentPhone: data['parentPhone'],
      status: data['status'] ?? 'Pending',
      passType: data['passType'] ?? 'short',
      expectedReturnTime: (data['expectedReturnTime'] as Timestamp?)?.toDate(),
      leavingTime: (data['leavingTime'] as Timestamp?)?.toDate(),
      appliedAt: (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mentorReviewedAt: (data['mentorReviewedAt'] as Timestamp?)?.toDate(),
      mentorRecommendation: data['mentorRecommendation'],
      mentorNotes: data['mentorNotes'],
      hodReviewedAt: (data['hodReviewedAt'] as Timestamp?)?.toDate(),
      expiryTimestamp: (data['expiryTimestamp'] as Timestamp?)?.toDate(),
      usedAt: (data['usedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'department': department,
      'regNo': regNo,
      'semester': semester,
      'division': division,
      'profileImageUrl': profileImageUrl,
      'reason': reason,
      'destination': destination,
      'parentPhone': parentPhone,
      'status': status,
      'passType': passType,
      'expectedReturnTime': expectedReturnTime != null ? Timestamp.fromDate(expectedReturnTime!) : null,
      'leavingTime': leavingTime != null ? Timestamp.fromDate(leavingTime!) : null,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'mentorReviewedAt': mentorReviewedAt != null ? Timestamp.fromDate(mentorReviewedAt!) : null,
      'mentorRecommendation': mentorRecommendation,
      'mentorNotes': mentorNotes,
      'hodReviewedAt': hodReviewedAt != null ? Timestamp.fromDate(hodReviewedAt!) : null,
      'expiryTimestamp': expiryTimestamp != null ? Timestamp.fromDate(expiryTimestamp!) : null,
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
    };
  }

  bool get isExpired {
    if (expiryTimestamp == null) return false;
    return DateTime.now().isAfter(expiryTimestamp!);
  }
}
