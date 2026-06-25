# Gate Pass Request & Approval Logic

This guide provides the core logic for requesting and approving gate passes using Firebase Firestore.

## 1. Gate Pass Model
Save this in `lib/models/gate_pass_model.dart`. It handles the data structure and Firestore conversion.

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class GatePassModel {
  final String id;
  final String studentId;
  final String studentName;
  final String department;
  final String reason;
  final String status; // 'Pending Mentor', 'Pending HOD', 'Approved', 'Rejected'
  final DateTime appliedAt;

  GatePassModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.department,
    required this.reason,
    required this.status,
    required this.appliedAt,
  });

  factory GatePassModel.fromMap(Map<String, dynamic> data, String docId) {
    return GatePassModel(
      id: docId,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      department: data['department'] ?? '',
      reason: data['reason'] ?? '',
      status: data['status'] ?? 'Pending Mentor',
      appliedAt: (data['appliedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'department': department,
      'reason': reason,
      'status': status,
      'appliedAt': Timestamp.fromDate(appliedAt),
    };
  }
}
```

## 2. Firestore Service
Add these methods to your `FirestoreService` to handle database operations.

```dart
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // REQUEST: Student creates a new pass
  Future<void> createGatePass(GatePassModel pass) async {
    await _db.collection('gate_pass_requests').add(pass.toMap());
  }

  // APPROVAL: HOD/Mentor updates the status
  Future<void> updateGatePassStatus(String passId, String newStatus) async {
    await _db.collection('gate_pass_requests').doc(passId).update({
      'status': newStatus,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  // FETCH: Get pending passes for a department (for HOD/Mentor)
  Stream<List<GatePassModel>> getPendingPasses(String dept, String status) {
    return _db.collection('gate_pass_requests')
        .where('department', isEqualTo: dept)
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snaps) => snaps.docs.map((doc) => GatePassModel.fromMap(doc.data(), doc.id)).toList());
  }
}
```

## 3. Usage Example

### Requesting a Pass (Student side)
```dart
final newPass = GatePassModel(
  id: '', 
  studentId: user.id,
  studentName: user.name,
  department: user.department,
  reason: 'Going home for festival',
  status: 'Pending Mentor', // Initial status
  appliedAt: DateTime.now(),
);

await firestoreService.createGatePass(newPass);
```

### Approval Logic (Multi-stage)

**Step 1: Mentor Review**
```dart
// Mentor recommends to HOD
await firestoreService.updateGatePassStatus(pass.id, 'Pending HOD');

// Or Mentor Rejects
await firestoreService.updateGatePassStatus(pass.id, 'Rejected');
```

**Step 2: HOD Final Approval**
```dart
// HOD Approves
await firestoreService.updateGatePassStatus(pass.id, 'Approved');

// Optional: Send SMS to Parent on approval
await SmsService.sendSms(
  phoneNumber: pass.parentPhone,
  message: 'Gate pass for ${pass.studentName} has been approved.',
);
```
