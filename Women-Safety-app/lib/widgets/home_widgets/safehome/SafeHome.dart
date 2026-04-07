import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:another_telephony/telephony.dart';

class SafeHome extends StatefulWidget {
  @override
  State<SafeHome> createState() => _SafeHomeState();
}

class _SafeHomeState extends State<SafeHome> {
  Position? _currentPosition;
  LocationPermission? permission;
  final Telephony telephony = Telephony.instance;

  @override
  void initState() {
    super.initState();
    _getPermission();
  }

  _getPermission() async {
    await [Permission.sms, Permission.location].request();
  }

  Future<bool> _sendSms(String phoneNumber, String message) async {
    try {
      // Check permissions with proper null handling
      final hasPermission = await telephony.requestSmsPermissions;
      if (hasPermission != true) {  // Explicit null check
        throw Exception('SMS permission not granted');
      }

      // Send SMS
      await telephony.sendSms(
        to: phoneNumber,
        message: message,
      );

      Fluttertoast.showToast(msg: "Message sent!");
      return true;
    } catch (error) {
      Fluttertoast.showToast(msg: "Failed to send message: $error");
      return false;
    }
  }

  _getCurrentLocation() async {
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: "Location permission denied");
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        Fluttertoast.showToast(msg: "Location permission denied permanently");
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Error getting location: $e");
    }
  }

  void showModelSafeHome(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {  // Proper builder parameter
        return Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Send your current location immediately",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink[800],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  await _getCurrentLocation();
                  if (_currentPosition != null) {
                    Fluttertoast.showToast(msg: "Location fetched");
                  } else {
                    Fluttertoast.showToast(msg: "Failed to fetch location");
                  }
                },
                icon: Icon(Icons.location_on),
                label: Text(
                  "GET LOCATION",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  if (_currentPosition != null) {
                    String message =
                        "Emergency! My location is: Lat: ${_currentPosition?.latitude}, "
                        "Long: ${_currentPosition?.longitude}";
                    await _sendSms("+918448018504", message);
                  } else {
                    Fluttertoast.showToast(msg: "Location not available yet");
                  }
                },
                icon: Icon(Icons.warning),
                label: Text(
                  "SEND ALERT",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showModelSafeHome(context),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          height: 180,
          width: MediaQuery.of(context).size.width * 0.8,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Send Location",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink[800]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Share your real-time location in an emergency.",
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/Safehome.jpg',
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}