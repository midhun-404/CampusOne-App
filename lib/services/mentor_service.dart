import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/gate_pass_model.dart';
import '../../core/constants/app_constants.dart';

class MentorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches pending requests specifically for a mentor's assigned class and department.
  Stream<List<GatePassModel>> getPendingPassesForClass(String department, String semester, String division) {
    return _db.collection(AppConstants.collectionGatePasses)
        .where('department', isEqualTo: department)
        .where('semester', isEqualTo: semester)
        .where('division', isEqualTo: division)
        .where('status', isEqualTo: AppConstants.statusPendingMentor)
        .snapshots()
        .map((snapshot) {
           final docs = snapshot.docs
              .map((doc) => GatePassModel.fromMap(doc.data(), doc.id))
              .toList();
           docs.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
           return docs;
        });
  }

  /// Get Pass History Statistics for a Specific Student
  Future<Map<String, int>> getStudentPassHistoryStats(String studentId) async {
    final snapshot = await _db.collection(AppConstants.collectionGatePasses)
        .where('studentId', isEqualTo: studentId)
        .get();

    int approved = 0;
    int rejected = 0;
    int total = snapshot.docs.length;

    for (var doc in snapshot.docs) {
      final status = doc.data()['status'] as String? ?? '';
      if (status == AppConstants.statusApproved) approved++;
      if (status == AppConstants.statusRejected) rejected++;
    }

    return {
      'approved': approved,
      'rejected': rejected,
      'total': total,
    };
  }

  /// Get Pass History for the Entire Class
  Stream<List<GatePassModel>> getClassPassHistory(String department, String semester, String division) {
    return _db.collection(AppConstants.collectionGatePasses)
        .where('department', isEqualTo: department)
        .where('semester', isEqualTo: semester)
        .where('division', isEqualTo: division)
        .where('status', whereIn: [
          AppConstants.statusApproved, 
          AppConstants.statusRejected, 
          AppConstants.statusPendingHod,
          AppConstants.statusVerified,
          AppConstants.statusUsed,
          AppConstants.statusExpired
        ])
        .snapshots()
        .map((snapshot) {
           final docs = snapshot.docs
              .map((doc) => GatePassModel.fromMap(doc.data(), doc.id))
              .toList();
           docs.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
           return docs;
        });
  }
}
