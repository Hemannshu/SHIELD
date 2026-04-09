import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Sends SMS using Android's native SmsManager via platform channel.
/// Works without being the default SMS app (unlike another_telephony).
class NativeSmsService {
  static const _channel = MethodChannel('com.sheild.sms/send');

  /// Request SMS permission and send a text message.
  /// Returns true if sent successfully.
  static Future<bool> sendSms({
    required String phone,
    required String message,
  }) async {
    // Ensure permission is granted
    var status = await Permission.sms.status;
    if (!status.isGranted) {
      status = await Permission.sms.request();
      if (!status.isGranted) {
        throw Exception('SMS permission not granted');
      }
    }

    try {
      final result = await _channel.invokeMethod('sendSms', {
        'phone': phone,
        'message': message,
      });
      return result == true;
    } on PlatformException catch (e) {
      throw Exception('SMS failed: ${e.message}');
    }
  }
}
