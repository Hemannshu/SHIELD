import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TwilioService {
  static final String _accountSid = dotenv.get('TWILIO_ACCOUNT_SID');
  static final String _authToken = dotenv.get('TWILIO_AUTH_TOKEN');
  static final String _twilioNumber = dotenv.get('TWILIO_PHONE_NUMBER');

  static Future<bool> sendSMS({
    required String toNumber,
    required String message,
  }) async {
    final url = Uri.parse(
      'https://api.twilio.com/2010-04-01/Accounts/$_accountSid/Messages.json',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Basic ${base64Encode(utf8.encode('$_accountSid:$_authToken'))}',
      },
      body: {
        'From': _twilioNumber,
        'To': toNumber,
        'Body': message,
      },
    );

    return response.statusCode == 201;
  }
}