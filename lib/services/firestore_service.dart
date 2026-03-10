import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/gate_pass_model.dart';
import '../models/canteen_model.dart';
import '../core/constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // USER METHODS
  Future<void> createUser(UserModel user) async {
    await _db.collection(AppConstants.collectionUsers).doc(user.id).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    var doc = await _db.collection(AppConstants.collectionUsers).doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection(AppConstants.collectionUsers).doc(uid).update(data);
  }

  Future<void> deleteUser(String userId) async {
    await _db.collection(AppConstants.collectionUsers).doc(userId).delete();
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _db
        .collection(AppConstants.collectionUsers)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!, doc.id) : null);
  }

  Future<void> clearUserDeviceId(String userId) async {
    await _db.collection(AppConstants.collectionUsers).doc(userId).update({'deviceId': null});
  }

  Future<void> addStudentToMentor(String studentId, String mentorId) async {
    await _db.collection(AppConstants.collectionUsers).doc(studentId).update({'mentorId': mentorId});
  }

  Stream<List<UserModel>> getMentorStudents(String mentorId) {
    return _db.collection(AppConstants.collectionUsers)
        .where('mentorId', isEqualTo: mentorId)
        .snapshots()
        .map((snaps) => snaps.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<List<UserModel>> getDepartmentUsers(String department, String role) async {
    final snapshot = await _db.collection(AppConstants.collectionUsers)
        .where('department', isEqualTo: department)
        .get();
    
    return snapshot.docs
        .where((doc) => doc.data()['role'] == role)
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<UserModel>> getDepartmentUsersStream(String department, String role) {
    return _db.collection(AppConstants.collectionUsers)
        .where('department', isEqualTo: department)
        .snapshots()
        .map((snaps) => snaps.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .where((u) => u.role == role)
            .toList());
  }

  Future<List<String>> getMentorTokens(String department) async {
    final snapshot = await _db.collection(AppConstants.collectionUsers)
        .where('department', isEqualTo: department)
        .get();
    
    return snapshot.docs
        .where((doc) => doc.data()['role'] == 'Mentor')
        .map((doc) => doc.data()['fcmToken'] as String?)
        .where((token) => token != null)
        .cast<String>()
        .toList();
  }

  Future<List<String>> getHodTokens(String department) async {
    final snapshot = await _db.collection(AppConstants.collectionUsers)
        .where('department', isEqualTo: department)
        .get();
    
    return snapshot.docs
        .where((doc) => doc.data()['role'] == 'HOD')
        .map((doc) => doc.data()['fcmToken'] as String?)
        .where((token) => token != null)
        .cast<String>()
        .toList();
  }

  // GATE PASS METHODS
  Future<void> createGatePass(GatePassModel pass) async {
    await _db.collection(AppConstants.collectionGatePasses).add(pass.toMap());
  }

  Future<void> updateGatePassStatus(
    String id, 
    String status, {
      String? mentorNotes, 
      String? mentorRecommendation,
      DateTime? expiryTimestamp, 
      DateTime? mentorReviewedAt, 
      DateTime? hodReviewedAt,
      DateTime? usedAt,
  }) async {
    Map<String, dynamic> data = {'status': status};
    if (mentorNotes != null) data['mentorNotes'] = mentorNotes;
    if (mentorRecommendation != null) data['mentorRecommendation'] = mentorRecommendation;
    if (expiryTimestamp != null) data['expiryTimestamp'] = Timestamp.fromDate(expiryTimestamp);
    if (mentorReviewedAt != null) data['mentorReviewedAt'] = Timestamp.fromDate(mentorReviewedAt);
    if (hodReviewedAt != null) data['hodReviewedAt'] = Timestamp.fromDate(hodReviewedAt);
    if (usedAt != null) data['usedAt'] = Timestamp.fromDate(usedAt);

    await _db.collection(AppConstants.collectionGatePasses).doc(id).update(data);
  }

  Stream<List<GatePassModel>> getStudentPasses(String studentId) {
    return _db
        .collection(AppConstants.collectionGatePasses)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => GatePassModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<List<GatePassModel>> getStudentActivePasses(String studentId) async {
    final snapshot = await _db
        .collection(AppConstants.collectionGatePasses)
        .where('studentId', isEqualTo: studentId)
        .get();
    
    return snapshot.docs
        .map((doc) => GatePassModel.fromMap(doc.data(), doc.id))
        .where((p) => 
            p.status == AppConstants.statusPendingMentor || 
            p.status == AppConstants.statusPendingHod || 
            p.status == AppConstants.statusApproved ||
            p.status == AppConstants.statusVerified
        )
        .toList();
  }

  Future<bool> hasFullDayPassToday(String studentId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    final snapshot = await _db
        .collection(AppConstants.collectionGatePasses)
        .where('studentId', isEqualTo: studentId)
        .get();
    
    return snapshot.docs.any((doc) {
      final data = doc.data();
      final appliedAt = (data['appliedAt'] as Timestamp?)?.toDate();
      final type = data['passType'];
      return type == AppConstants.passTypeFullDay && 
             appliedAt != null && 
             appliedAt.isAfter(startOfDay);
    });
  }

  Stream<List<GatePassModel>> getPendingPassesForDepartment(String department, {bool isMentor = false}) {
    String requiredStatus = isMentor ? AppConstants.statusPendingMentor : AppConstants.statusPendingHod;
    return _db
        .collection(AppConstants.collectionGatePasses)
        .where('department', isEqualTo: department)
        .snapshots()
        .map((snapshot) {
          final passes = snapshot.docs
              .map((doc) => GatePassModel.fromMap(doc.data(), doc.id))
              .where((p) => p.status == requiredStatus)
              .toList();
          // Sort by appliedAt descending
          passes.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
          return passes;
        });
  }

  Stream<List<GatePassModel>> getDepartmentPassesStream(String department) {
    return _db.collection(AppConstants.collectionGatePasses)
        .where('department', isEqualTo: department)
        .snapshots()
        .map((snaps) {
          final passes = snaps.docs.map((doc) => GatePassModel.fromMap(doc.data(), doc.id)).toList();
          passes.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
          return passes;
        });
  }

  Stream<int> getDepartmentActiveStudentCount(String department) {
    return _db.collection(AppConstants.collectionGatePasses)
        .where('department', isEqualTo: department)
        .snapshots()
        .map((snaps) {
          return snaps.docs
              .map((doc) => GatePassModel.fromMap(doc.data(), doc.id))
              .where((p) => p.status == AppConstants.statusVerified)
              .length;
        });
  }

  /// Returns a live list of students currently outside (Verified, not yet expired).
  Stream<List<GatePassModel>> getDepartmentStudentsOutStream(String department) {
    return _db.collection(AppConstants.collectionGatePasses)
        .where('department', isEqualTo: department)
        .snapshots()
        .map((snaps) {
          final now = DateTime.now();
          return snaps.docs
              .map((doc) => GatePassModel.fromMap(doc.data(), doc.id))
              .where((p) =>
                  p.status == AppConstants.statusVerified &&
                  (p.expiryTimestamp == null || p.expiryTimestamp!.isAfter(now)))
              .toList();
        });
  }

  Future<GatePassModel?> getGatePassById(String id) async {
    var doc = await _db.collection(AppConstants.collectionGatePasses).doc(id).get();
    if (doc.exists) {
      return GatePassModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Stream<GatePassModel?> getGatePassStream(String id) {
    return _db
        .collection(AppConstants.collectionGatePasses)
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? GatePassModel.fromMap(doc.data()!, doc.id) : null);
  }

  Future<void> logGatePassScan(String passId, String scannedBy, String result, String department) async {
    await _db.collection(AppConstants.collectionGatePassLogs).add({
      'passId': passId,
      'scannedBy': scannedBy,
      'scannedAt': FieldValue.serverTimestamp(),
      'result': result,
      'department': department,
    });
  }

  Stream<List<Map<String, dynamic>>> getDepartmentSecurityLogsStream(String department) {
    return _db.collection(AppConstants.collectionGatePassLogs)
        .where('department', isEqualTo: department)
        .snapshots()
        .map((snaps) {
          final logs = snaps.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
          logs.sort((a, b) {
            final aTime = (a['scannedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            final bTime = (b['scannedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });
          return logs;
        });
  }

  // CANTEEN PROFILE
  Stream<CanteenProfileModel?> getCanteenProfile() {
    return _db.collection(AppConstants.collectionCanteenProfile).doc('config').snapshots()
        .map((doc) => doc.exists ? CanteenProfileModel.fromMap(doc.data()!, doc.id) : null);
  }

  Future<void> setCanteenProfile(CanteenProfileModel profile) async {
    await _db.collection(AppConstants.collectionCanteenProfile).doc('config').set(profile.toMap());
  }

  // CANTEEN MENU
  Stream<List<CanteenItemModel>> getCanteenMenu() {
    return _db.collection(AppConstants.collectionCanteenMenu).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => CanteenItemModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> addCanteenItem(CanteenItemModel item) async {
    await _db.collection(AppConstants.collectionCanteenMenu).add(item.toMap());
  }

  Future<void> updateCanteenItem(String id, Map<String, dynamic> data) async {
    await _db.collection(AppConstants.collectionCanteenMenu).doc(id).update(data);
  }

  Future<void> deleteCanteenItem(String id) async {
    await _db.collection(AppConstants.collectionCanteenMenu).doc(id).delete();
  }

  // CANTEEN ORDERS
  Future<void> createCanteenOrder(CanteenOrderModel order) async {
    await _db.collection(AppConstants.collectionCanteenOrders).doc(order.id).set(order.toMap());
  }

  Stream<List<CanteenOrderModel>> getCanteenOrders() {
    return _db.collection(AppConstants.collectionCanteenOrders)
        .snapshots()
        .map((snaps) {
          final orders = snaps.docs.map((doc) => CanteenOrderModel.fromMap(doc.data(), doc.id)).toList();
          orders.sort((a, b) => b.orderTime.compareTo(a.orderTime));
          return orders;
        });
  }

  Stream<List<CanteenOrderModel>> getStudentOrders(String studentId) {
    return _db.collection(AppConstants.collectionCanteenOrders)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snaps) {
          final orders = snaps.docs.map((doc) => CanteenOrderModel.fromMap(doc.data(), doc.id)).toList();
          orders.sort((a, b) => b.orderTime.compareTo(a.orderTime));
          return orders;
        });
  }

  Future<void> updateOrderStatus(String id, String status, {String? studentFcmToken, DateTime? estimatedReadyTime}) async {
    final Map<String, dynamic> updates = {'status': status};
    if (estimatedReadyTime != null) {
      updates['estimatedReadyTime'] = Timestamp.fromDate(estimatedReadyTime);
    }
    await _db.collection(AppConstants.collectionCanteenOrders).doc(id).update(updates);
  }

  Future<void> updateOrderRating(String id, double rating, String feedback) async {
    await _db.collection(AppConstants.collectionCanteenOrders).doc(id).update({
      'rating': rating,
      'feedback': feedback,
    });
  }

  Future<void> cancelOrder(String id) async {
    // Only allow if pending (security check should also be on frontend/rules)
    await _db.collection(AppConstants.collectionCanteenOrders).doc(id).delete();
  }

  Future<Map<String, dynamic>> getCanteenAnalytics() async {
    final snapshot = await _db.collection(AppConstants.collectionCanteenOrders).get();
    double totalRevenue = 0;
    int totalOrders = snapshot.docs.length;
    double totalRating = 0;
    int ratedOrders = 0;
    Map<String, int> itemCounts = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      totalRevenue += (data['totalAmount'] ?? 0.0);
      if (data['rating'] != null) {
        totalRating += (data['rating'] as num).toDouble();
        ratedOrders++;
      }
      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
      for (var item in items) {
        final name = item['name'] as String;
        itemCounts[name] = (itemCounts[name] ?? 0) + (item['quantity'] as int);
      }
    }

    return {
      'revenue': totalRevenue,
      'orders': totalOrders,
      'avgRating': ratedOrders > 0 ? totalRating / ratedOrders : 0.0,
      'itemSales': itemCounts,
    };
  }
}
