import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:title_proj/services/native_sms_service.dart';
import 'database_helper.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'emergency_channel',
      initialNotificationTitle: 'Emergency Service',
      initialNotificationContent: 'Monitoring for emergency alerts',
    ),
    iosConfiguration: IosConfiguration(),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  final dbHelper = DatabaseHelper();
  final connectivity = Connectivity();

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Check for unsent messages every 5 minutes
  Timer.periodic(Duration(minutes: 5), (timer) async {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Emergency Alert Service",
        content: "Checking for unsent alerts",
      );
    }

    final result = await connectivity.checkConnectivity();
    if (result != ConnectivityResult.none) {
      final unsentLocations = await dbHelper.getUnsentLocations();
      for (final location in unsentLocations) {
        try {
          final message = "Emergency! My location is: "
              "Lat: ${location['latitude']}, Long: ${location['longitude']}";
          await NativeSmsService.sendSms(
            phone: "+918448018504", // Your emergency number
            message: message,
          );
          await dbHelper.markAsSent(location['id'] as int);
        } catch (e) {
          print('Failed to send queued message: $e');
        }
      }
    }
  });
}