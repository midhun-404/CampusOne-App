FCM NOTIFICATION SERVICE FULL CODE

DEPENDENCIES:
Add these to pubspec.yaml:
firebase_messaging: ^14.7.10
flutter_local_notifications: ^16.3.2
http: ^1.2.0
googleapis_auth: ^1.4.1

1. NOTIFICATION SERVICE
Save this in lib/services/notification_service.dart
Note: This uses FCM v1 API which requires a Service Account JSON for server-side sending.

import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  // INITIALIZATION
  static Future<void> init() async {
    // 1. Request Permission
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // 2. Setup Android Channels
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel', 
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    final androidPlugin = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidChannel);

    // 3. Initialize Local Notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'),
    );
    await _local.initialize(settings: initSettings);

    // 4. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _local.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              androidChannel.id,
              androidChannel.name,
              channelDescription: androidChannel.description,
              icon: '@drawable/ic_notification',
            ),
          ),
        );
      }
    });
  }

  // GET DEVICE TOKEN
  static Future<String?> getToken() async => await _messaging.getToken();

  // SEND NOTIFICATION (FCM v1)
  // Requires serviceAccountJson from Firebase Console -> Project Settings -> Service Accounts
  static Future<void> sendNotification({
    required String fcmToken,
    required String title,
    required String body,
    required Map<String, dynamic> serviceAccountJson,
  }) async {
    try {
      // Get OAuth2 Access Token
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson), 
        scopes
      );
      final accessToken = client.credentials.accessToken.data;
      final projectId = serviceAccountJson['project_id'];

      // Send to FCM v1 API
      final url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
      await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': fcmToken,
            'notification': {'title': title, 'body': body},
            'android': {
              'notification': {
                'channel_id': 'high_importance_channel',
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              },
            },
          },
        }),
      );
      client.close();
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
}


2. USAGE IN MAIN.DART
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize notifications
  await NotificationService.init();
  
  runApp(const MyApp());
}


3. USAGE IN APP (EXAMPLE)
await NotificationService.sendNotification(
  fcmToken: 'RECIPIENT_TOKEN',
  title: 'Gate Pass Approved',
  body: 'Your gate pass has been approved by the HOD.',
  serviceAccountJson: myServiceAccountData,
);
