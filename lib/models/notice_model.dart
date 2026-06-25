import 'package:cloud_firestore/cloud_firestore.dart';

class NoticeModel {
  final String id;
  final String title;
  final String content;
  final String authorName;
  final DateTime timestamp;
  final DateTime? expiryAt;
  final String? targetDepartment;

  NoticeModel({
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    required this.timestamp,
    this.expiryAt,
    this.targetDepartment,
  });

  bool get isExpired {
    if (expiryAt == null) return false;
    return DateTime.now().isAfter(expiryAt!);
  }

  factory NoticeModel.fromMap(Map<String, dynamic> data, String documentId) {
    return NoticeModel(
      id: documentId,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorName: data['authorName'] ?? 'HOD',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryAt: (data['expiryAt'] as Timestamp?)?.toDate(),
      targetDepartment: data['targetDepartment'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'authorName': authorName,
      'timestamp': Timestamp.fromDate(timestamp),
      'expiryAt': expiryAt != null ? Timestamp.fromDate(expiryAt!) : null,
      'targetDepartment': targetDepartment,
    };
  }
}
