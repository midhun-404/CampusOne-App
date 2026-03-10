import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsService {
  static const MethodChannel _channel = MethodChannel('com.app.sgms/sms');

  static Future<bool> sendSms({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // Check for SMS Permission
      var status = await Permission.sms.status;
      if (!status.isGranted) {
        status = await Permission.sms.request();
      }

      if (status.isGranted) {
        final bool result = await _channel.invokeMethod('sendSMS', {
          'phoneNumber': phoneNumber,
          'message': message,
        });
        print("Native SMS Channel Result: $result");
        return result; 
      } else {
        print("SMS Permission denied");
        return false;
      }
    } catch (e) {
      print("Error sending SMS: $e");
      return false;
    }
  }
}
