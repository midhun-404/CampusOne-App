import 'package:cloud_firestore/cloud_firestore.dart';

class CanteenProfileModel {
  final String id;
  final String college;
  final String canteenName;
  final String adminName;
  final String openTime;
  final String closeTime;
  final String? phone;
  final int defaultPrepTime; // in minutes

  CanteenProfileModel({
    required this.id,
    required this.college,
    required this.canteenName,
    required this.adminName,
    required this.openTime,
    required this.closeTime,
    this.phone,
    this.defaultPrepTime = 15,
  });

  factory CanteenProfileModel.fromMap(Map<String, dynamic> data, String documentId) {
    return CanteenProfileModel(
      id: documentId,
      college: data['college'] ?? '',
      canteenName: data['canteenName'] ?? 'Campus Canteen',
      adminName: data['adminName'] ?? '',
      openTime: data['openTime'] ?? '8:00 AM',
      closeTime: data['closeTime'] ?? '5:00 PM',
      phone: data['phone'],
      defaultPrepTime: data['defaultPrepTime'] ?? 15,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'college': college,
      'canteenName': canteenName,
      'adminName': adminName,
      'openTime': openTime,
      'closeTime': closeTime,
      'phone': phone,
      'defaultPrepTime': defaultPrepTime,
    };
  }

  /// Derives a short, friendly canteen name from the full college name.
  /// e.g. "Ilahia College of Engineering and Technology, Moovattupuzha" -> "Ilahia College Canteen"
  /// e.g. "College of Engineering Trivandrum (CET)" -> "CET Canteen"
  static String deriveCanteenName(String collegeName) {
    // If there's a known abbreviation in parentheses, use it directly
    final abbrevMatch = RegExp(r'\(([A-Z]{2,6})\)').firstMatch(collegeName);
    if (abbrevMatch != null) {
      return '${abbrevMatch.group(1)} Canteen';
    }

    // Strip location (everything after first comma)
    String name = collegeName.replaceAll(RegExp(r',.*'), '').trim();

    // Strip common engineering/institute suffixes (longer first to avoid partial matches)
    const suffixes = [
      'College of Engineering and Technology',
      'College of Engineering',
      'Institute of Science and Technology',
      'Institute of Technology',
      'School of Engineering & Technology',
      'School of Engineering and Technology',
      'Engineering College',
    ];
    for (final suffix in suffixes) {
      if (name.contains(suffix)) {
        name = name.replaceAll(suffix, '').trim();
        break;
      }
    }

    // Clean trailing prepositions left behind
    name = name.replaceAll(RegExp(r'\s+(of|and|&)\s*$', caseSensitive: false), '').trim();
    // Collapse multiple spaces
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (name.isEmpty || name == 'Other/Not Listed') return 'Campus Canteen';
    return '$name Canteen';
  }

}

class CanteenItemModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;
  final String category; // 'Breakfast', 'Lunch', 'Snacks', 'Drinks', 'Other'

  CanteenItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    this.isAvailable = true,
    this.category = 'Other',
  });

  factory CanteenItemModel.fromMap(Map<String, dynamic> data, String documentId) {
    return CanteenItemModel(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'],
      isAvailable: data['isAvailable'] ?? true,
      category: data['category'] ?? 'Other',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'category': category,
    };
  }
}

class CanteenOrderModel {
  final String id;
  final String studentId;
  final String studentName;
  final String? studentPhone;
  final String? studentFcmToken;
  final List<Map<String, dynamic>> items; // {itemId, name, quantity, price}
  final double totalAmount;
  final String paymentId; // Razorpay transaction ID
  final String status; // Pending, Preparing, Ready, Delivered
  final DateTime orderTime;
  final String? canteenName;
  final double? rating;
  final String? feedback;
  final DateTime? estimatedReadyTime;

  CanteenOrderModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.studentPhone,
    this.studentFcmToken,
    required this.items,
    required this.totalAmount,
    required this.paymentId,
    required this.status,
    required this.orderTime,
    this.canteenName,
    this.rating,
    this.feedback,
    this.estimatedReadyTime,
  });

  factory CanteenOrderModel.fromMap(Map<String, dynamic> data, String documentId) {
    return CanteenOrderModel(
      id: documentId,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentPhone: data['studentPhone'],
      studentFcmToken: data['studentFcmToken'],
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      paymentId: data['paymentId'] ?? '',
      status: data['status'] ?? 'Pending',
      orderTime: (data['orderTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      canteenName: data['canteenName'],
      rating: (data['rating'] as num?)?.toDouble(),
      feedback: data['feedback'],
      estimatedReadyTime: (data['estimatedReadyTime'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentPhone': studentPhone,
      'studentFcmToken': studentFcmToken,
      'items': items,
      'totalAmount': totalAmount,
      'paymentId': paymentId,
      'status': status,
      'orderTime': Timestamp.fromDate(orderTime),
      'canteenName': canteenName,
      'rating': rating,
      'feedback': feedback,
      'estimatedReadyTime': estimatedReadyTime != null ? Timestamp.fromDate(estimatedReadyTime!) : null,
    };
  }
}
