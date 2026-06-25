class AppConstants {
  // Roles
  static const String roleStudent = 'Student';
  static const String roleMentor = 'Mentor';
  static const String roleHod = 'HOD';
  static const String roleSecurity = 'Security';
  static const String roleCanteen = 'Canteen';
  static const String roleFaculty = 'Faculty';
  static const String roleAdmin = 'Admin';

  static const List<String> roles = [
    roleStudent,
    roleMentor,
    roleHod,
    roleSecurity,
    roleCanteen,
    roleFaculty,
    roleAdmin,
  ];

  // Departments
  static const List<String> departments = [
    'CSE',
    'ECE',
    'EEE',
    'MECH',
    'CIVIL',
  ];

  // Gate Pass Statuses
  static const String statusPendingMentor = 'Pending Mentor';
  static const String statusPendingHod = 'Pending HOD';
  static const String statusApproved = 'Approved';
  static const String statusRejected = 'Rejected';
  static const String statusUsed = 'Used';
  static const String statusExpired = 'Expired';
  static const String statusVerified = 'Verified';

  // Pass Types
  static const String passTypeShort = 'short';
  static const String passTypeFullDay = 'full_day';

  // Razorpay
  static const String razorpayTestKey = 'YOUR_RAZORPAY_TEST_KEY_HERE';

  // Firebase Collections
  static const String collectionUsers = 'users';
  static const String collectionGatePasses = 'gate_pass_requests';
  static const String collectionGatePassLogs = 'gate_pass_logs';
  static const String collectionCanteenMenu = 'canteen_menu';
  static const String collectionCanteenOrders = 'canteen_orders';
  static const String collectionCanteenProfile = 'canteen_profile';
  static const String collectionNotices = 'notices';
}
