import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/gate_pass_model.dart';
import '../models/canteen_model.dart';
import '../models/notice_model.dart';
import '../models/account_request_model.dart';
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

  Future<void> deleteUser(String uid) async {
    final batch = _db.batch();
    
    // 1. Delete user doc
    batch.delete(_db.collection(AppConstants.collectionUsers).doc(uid));
    
    // 2. Delete gate passes and their logs
    final passes = await _db.collection(AppConstants.collectionGatePasses)
        .where('studentId', isEqualTo: uid)
        .get();
    
    for (var doc in passes.docs) {
      batch.delete(doc.reference);
      
      // Delete logs associated with this pass
      final logs = await _db.collection(AppConstants.collectionGatePassLogs)
          .where('passId', isEqualTo: doc.id)
          .get();
      for (var logDoc in logs.docs) {
        batch.delete(logDoc.reference);
      }
    }
    
    // 3. Delete canteen orders
    final orders = await _db.collection(AppConstants.collectionCanteenOrders)
        .where('studentId', isEqualTo: uid)
        .get();
    for (var doc in orders.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _db
        .collection(AppConstants.collectionUsers)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!, doc.id) : null);
  }

  Stream<List<UserModel>> getUsersStream() {
    return _db.collection(AppConstants.collectionUsers)
        .snapshots()
        .map((snaps) => snaps.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList());
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

  Future<UserModel?> findMentorForClass(String dept, String sem, String div) async {
    final snaps = await _db.collection(AppConstants.collectionUsers)
        .where('role', isEqualTo: AppConstants.roleMentor)
        .where('department', isEqualTo: dept)
        .where('semester', isEqualTo: sem)
        .where('division', isEqualTo: div)
        .limit(1)
        .get();
    
    if (snaps.docs.isNotEmpty) {
      return UserModel.fromMap(snaps.docs.first.data(), snaps.docs.first.id);
    }
    return null;
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

  Future<GatePassModel?> getGatePass(String id) async {
    final doc = await _db.collection(AppConstants.collectionGatePasses).doc(id).get();
    if (doc.exists) {
      return GatePassModel.fromMap(doc.data()!, doc.id);
    }
    return null;
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
            p.status == AppConstants.statusApproved
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

  Stream<int> getPendingCountStream(String department, {bool isMentor = false}) {
    String status = isMentor ? AppConstants.statusPendingMentor : AppConstants.statusPendingHod;
    return _db.collection(AppConstants.collectionGatePasses)
        .where('department', isEqualTo: department)
        .where('status', isEqualTo: status)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<int> getApprovedCountStream(String userId) {
    return _db.collection(AppConstants.collectionGatePasses)
        .where('mentorId', isEqualTo: userId) // Or check approvedBy if we had that field
        .where('status', isEqualTo: AppConstants.statusApproved)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<int> getMenteeCountStream(String mentorId) {
    return _db.collection(AppConstants.collectionUsers)
        .where('mentorId', isEqualTo: mentorId)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<int> getDepartmentActiveStudentCount(String department) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _db.collection(AppConstants.collectionGatePasses)
        .where('department', isEqualTo: department)
        .snapshots()
        .map((snaps) => snaps.docs
            .map((doc) => GatePassModel.fromMap(doc.data(), doc.id))
            .where((p) => 
                p.status == AppConstants.statusVerified && 
                p.appliedAt.isAfter(startOfDay))
            .length);
  }

  /// Returns a live list of students currently outside (Verified today, not yet expired).
  Stream<List<GatePassModel>> getDepartmentStudentsOutStream(String department) {
    return _db.collection(AppConstants.collectionGatePasses)
        .where('department', isEqualTo: department)
        .snapshots()
        .map((snaps) {
          final now = DateTime.now();
          final startOfDay = DateTime(now.year, now.month, now.day);
          return snaps.docs
              .map((doc) => GatePassModel.fromMap(doc.data(), doc.id))
              .where((p) =>
                  p.status == AppConstants.statusVerified &&
                  p.appliedAt.isAfter(startOfDay) &&
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

  Future<void> logGatePassScan({
    required String passId, 
    required String studentName,
    required String scannedBy, 
    required String result, 
    required String department,
    String? profileImageUrl,
    bool isStaff = false,
  }) async {
    await _db.collection(AppConstants.collectionGatePassLogs).add({
      'passId': passId,
      'studentName': studentName,
      'scannedBy': scannedBy,
      'scannedAt': FieldValue.serverTimestamp(),
      'result': result,
      'department': department,
      'profileImageUrl': profileImageUrl,
      'isStaff': isStaff,
    });
  }

  Stream<List<Map<String, dynamic>>> getDepartmentSecurityLogsStream(String department) {
    return _db.collection(AppConstants.collectionGatePassLogs)
        .where('department', isEqualTo: department)
        .snapshots()
        .map((snaps) {
          final now = DateTime.now();
          final startOfDay = DateTime(now.year, now.month, now.day);
          final logs = snaps.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .where((l) {
                final time = (l['scannedAt'] as Timestamp?)?.toDate();
                return time != null && time.isAfter(startOfDay);
              })
              .toList();
          logs.sort((a, b) {
            final aTime = (a['scannedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            final bTime = (b['scannedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });
          return logs;
        });
  }

  Stream<List<Map<String, dynamic>>> getAllSecurityLogsStream([DateTime? date]) {
    Query query = _db.collection(AppConstants.collectionGatePassLogs).orderBy('scannedAt', descending: true);
    
    if (date != null) {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      query = query
          .where('scannedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('scannedAt', isLessThan: Timestamp.fromDate(endOfDay));
    } else {
      query = query.limit(200); // 200 recent passes if no date is picked
    }
    
    return query.snapshots().map((snaps) => snaps.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList());
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

  Stream<Map<String, dynamic>> getCanteenAnalytics([DateTime? date]) {
    Query query = _db.collection(AppConstants.collectionCanteenOrders);
    
    return query.snapshots().map((snapshot) {
      double totalRevenue = 0;
      int totalOrders = 0;
      double totalRating = 0;
      int ratedOrders = 0;
      Map<String, int> itemCounts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Date filtering
        if (date != null) {
          final orderTimestamp = data['orderTime'] as Timestamp?;
          if (orderTimestamp != null) {
            final orderTime = orderTimestamp.toDate();
            final orderDate = DateTime(orderTime.year, orderTime.month, orderTime.day);
            final filterDate = DateTime(date.year, date.month, date.day);
            if (!orderDate.isAtSameMomentAs(filterDate)) {
              continue; // Skip if it doesn't match the selected date
            }
          } else {
            continue; // Skip if no valid timestamp
          }
        }

        totalOrders++;
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

      // Sort items by count descending
      final sortedItemCounts = Map.fromEntries(
        itemCounts.entries.toList()..sort((e1, e2) => e2.value.compareTo(e1.value))
      );

      return {
        'revenue': totalRevenue,
        'orders': totalOrders,
        'avgRating': ratedOrders > 0 ? totalRating / ratedOrders : 0.0,
        'itemSales': sortedItemCounts,
      };
    });
  }

  // NOTICES
  /// All notices for HOD view (includes expired ones so HOD can delete them)
  Stream<List<NoticeModel>> getNoticesStream({bool includeExpired = false}) {
    return _db.collection(AppConstants.collectionNotices)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          final notices = snapshot.docs.map((doc) => NoticeModel.fromMap(doc.data(), doc.id)).toList();
          if (includeExpired) return notices;
          // Filter out expired notices for student view
          return notices.where((n) => !n.isExpired).toList();
        });
  }

  Future<void> addNotice(NoticeModel notice) async {
    await _db.collection(AppConstants.collectionNotices).add(notice.toMap());
  }

  Future<void> deleteNotice(String id) async {
    await _db.collection(AppConstants.collectionNotices).doc(id).delete();
  }

  // ACCOUNT REQUESTS
  static const String _colAccountRequests = 'account_requests';

  Future<void> createAccountRequest(AccountRequestModel request) async {
    await _db.collection(_colAccountRequests).add(request.toMap());
  }

  Stream<List<AccountRequestModel>> getAccountRequestsStream({String? department}) {
    Query query = _db.collection(_colAccountRequests)
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true);
    if (department != null) {
      query = query.where('department', isEqualTo: department);
    }
    return query.snapshots().map(
      (s) => s.docs.map((d) => AccountRequestModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList()
    );
  }

  Future<void> updateAccountRequestStatus(String id, String status, {String? reason}) async {
    final data = <String, dynamic>{'status': status};
    if (reason != null) data['rejectionReason'] = reason;
    await _db.collection(_colAccountRequests).doc(id).update(data);
  }
}
