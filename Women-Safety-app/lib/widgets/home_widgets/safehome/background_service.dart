import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:another_telephony/telephony.dart';
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
  final telephony = Telephony.instance;
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
      final hasPermission = await telephony.requestSmsPermissions;
      if (hasPermission == true) {  // Explicit null check
        final unsentLocations = await dbHelper.getUnsentLocations();
        for (final location in unsentLocations) {
          try {
            final message = "Emergency! My location is: "
                "Lat: ${location['latitude']}, Long: ${location['longitude']}";
            await telephony.sendSms(
              to: "+918448018504", // Your emergency number
              message: message,
            );
            await dbHelper.markAsSent(location['id'] as int);
          } catch (e) {
            print('Failed to send queued message: $e');
          }
        }
      } else {
        print('SMS permission not granted');
      }
    }
  });
}