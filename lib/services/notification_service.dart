import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import '../config/firebase_config.dart';
// Notification channels
const _kChannelDefault = 'canteen_default_channel';
const _kChannelReady   = 'canteen_ready_channel';
const _kChannelGate    = 'gate_pass_channel';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  // -----------------------------------------------------------------------
  // INIT
  // -----------------------------------------------------------------------
  static Future<void> init() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Create Android notification channels via the platform-specific plugin
    final androidPlugin =
        _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      _kChannelDefault,
      'Canteen Notifications',
      description: 'Order status updates from the canteen',
      importance: Importance.high,
    ));
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      _kChannelReady,
      'Food Ready Alerts',
      description: 'High-priority alert when your food is ready to collect',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    ));
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      _kChannelGate,
      'Gate Pass Notifications',
      description: 'Gate pass status updates',
      importance: Importance.high,
    ));

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'),
    );
    await _local.initialize(settings: initSettings);

    // Show local notification while app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android      = message.notification?.android;
      if (notification != null && android != null) {
        final isReady = (notification.title ?? '').contains('Ready') ||
                        (notification.title ?? '').contains('🔔');
        _local.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              isReady ? _kChannelReady : _kChannelDefault,
              isReady ? 'Food Ready Alerts' : 'Canteen Notifications',
              importance:      isReady ? Importance.max : Importance.high,
              priority:        isReady ? Priority.max  : Priority.high,
              playSound:       true,
              enableVibration: true,
              icon:            '@drawable/ic_notification',
            ),
          ),
        );
      }
    });
  }

  static Future<String?> getToken() async => await _messaging.getToken();

  // -----------------------------------------------------------------------
  // INTERNAL: GET FCM v1 ACCESS TOKEN
  // -----------------------------------------------------------------------
  static Future<String> _getAccessToken() async {
    final accountCredentials =
        auth.ServiceAccountCredentials.fromJson(DefaultFirebaseOptions.serviceAccountJson);
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final client = await auth.clientViaServiceAccount(accountCredentials, scopes);
    final accessToken = client.credentials.accessToken.data;
    client.close();
    return accessToken;
  }

  // -----------------------------------------------------------------------
  // SEND NOTIFICATION  (generic, FCM v1)
  // -----------------------------------------------------------------------
  static Future<void> sendNotification({
    required String fcmToken,
    required String title,
    required String body,
    String channelId      = _kChannelDefault,
    bool   highPriority   = false,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      final projectId   = DefaultFirebaseOptions.serviceAccountJson['project_id'] as String;
      final url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': fcmToken,
            'notification': {'title': title, 'body': body},
            'android': {
              'priority': highPriority ? 'high' : 'normal',
              'notification': {
                'channel_id':            channelId,
                'notification_priority': highPriority ? 'PRIORITY_MAX' : 'PRIORITY_DEFAULT',
                'default_sound':         true,
                'default_vibrate_timings': true,
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              },
            },
          },
        }),
      );

      if (response.statusCode != 200) {
        // ignore: avoid_print
        print('[NotificationService] Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[NotificationService] Exception: $e');
    }
  }

  // -----------------------------------------------------------------------
  // CANTEEN SHORTCUT – picks right channel & priority per order status
  // -----------------------------------------------------------------------
  static Future<void> sendCanteenStatusNotification({
    required String fcmToken,
    required String newStatus,
    String canteenName = 'Canteen',
  }) async {
    // (title, body, channelId, highPriority)
    final Map<String, (String, String, String, bool)> config = {
      'Preparing': (
        '🍳 Order Being Prepared',
        'Your food is being prepared at $canteenName. Ready soon!',
        _kChannelDefault,
        false,
      ),
      'Ready': (
        '🔔 Your Food is Ready!',
        'Please collect your order from the $canteenName counter now.',
        _kChannelReady,
        true,
      ),
      'Delivered': (
        '✅ Order Delivered – Enjoy!',
        'Your order from $canteenName has been collected. Bon appétit!',
        _kChannelDefault,
        false,
      ),
    };

    final entry = config[newStatus];
    if (entry == null) return;

    await sendNotification(
      fcmToken:      fcmToken,
      title:         entry.$1,
      body:          entry.$2,
      channelId:     entry.$3,
      highPriority:  entry.$4,
    );
  }
}
