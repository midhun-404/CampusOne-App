CANTEEN ORDER SYSTEM FULL CODE

DEPENDENCIES:
Add these to pubspec.yaml:
cloud_firestore: ^4.14.0
intl: ^0.19.0

1. CANTEEN MODELS
Save this in lib/models/canteen_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class CanteenItemModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final bool isAvailable;

  CanteenItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.isAvailable = true,
  });

  factory CanteenItemModel.fromMap(Map<String, dynamic> data, String docId) {
    return CanteenItemModel(
      id: docId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      isAvailable: data['isAvailable'] ?? true,
    );
  }
}

class CanteenOrderModel {
  final String id;
  final String studentId;
  final String studentName;
  final List<Map<String, dynamic>> items; // {name, quantity, price}
  final double totalAmount;
  final String status; // Pending, Preparing, Ready, Delivered
  final DateTime orderTime;

  CanteenOrderModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'items': items,
      'totalAmount': totalAmount,
      'status': status,
      'orderTime': Timestamp.fromDate(orderTime),
    };
  }

  factory CanteenOrderModel.fromMap(Map<String, dynamic> data, String docId) {
    return CanteenOrderModel(
      id: docId,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'Pending',
      orderTime: (data['orderTime'] as Timestamp).toDate(),
    );
  }
}


2. ORDER SERVICE METHODS
Add these to your FirestoreService

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // PLACE ORDER
  Future<void> createCanteenOrder(CanteenOrderModel order) async {
    await _db.collection('canteen_orders').add(order.toMap());
  }

  // UPDATE ORDER STATUS (Canteen Side)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _db.collection('canteen_orders').doc(orderId).update({
      'status': newStatus,
    });
  }

  // FETCH STUDENT ORDERS
  Stream<List<CanteenOrderModel>> getStudentOrders(String studentId) {
    return _db.collection('canteen_orders')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snaps) => snaps.docs
            .map((doc) => CanteenOrderModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}


3. USAGE EXAMPLE: PLACING AN ORDER
void placeOrder() async {
  final order = CanteenOrderModel(
    id: '', 
    studentId: 'user_u1', 
    studentName: 'Midhun',
    items: [
      {'name': 'Masala Dosa', 'quantity': 2, 'price': 50.0},
      {'name': 'Coffee', 'quantity': 1, 'price': 15.0},
    ],
    totalAmount: 115.0,
    status: 'Pending',
    orderTime: DateTime.now(),
  );

  await firestoreService.createCanteenOrder(order);
}


4. USAGE EXAMPLE: UPDATING STATUS (READY FOR PICKUP)
void markAsReady(String orderId) async {
  await firestoreService.updateOrderStatus(orderId, 'Ready');
  
  // Optional: Trigger FCM Notification
  // await notificationService.sendNotification(title: 'Food Ready!', body: 'Pick up now!');
}
