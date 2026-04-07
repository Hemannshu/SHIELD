// Bluetooth SOS Demo Widget
// Shows how SOS works in low network areas via Bluetooth

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:title_proj/services/bluetooth_sos_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Bluetooth SOS Demo Widget
/// Perfect for showing how SOS works in low network areas
class BluetoothSOSDemoWidget extends StatefulWidget {
  const BluetoothSOSDemoWidget({Key? key}) : super(key: key);

  @override
  State<BluetoothSOSDemoWidget> createState() => _BluetoothSOSDemoWidgetState();
}

class _BluetoothSOSDemoWidgetState extends State<BluetoothSOSDemoWidget> {
  final BluetoothSOSService _bluetoothSOS = BluetoothSOSService();
  bool _isScanning = false;
  bool _isSending = false;
  List<BluetoothDevice> _nearbyDevices = [];
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Location error: $e');
    }
  }

  Future<void> _scanForDevices() async {
    setState(() {
      _isScanning = true;
      _nearbyDevices = [];
    });

    try {
      final devices = await _bluetoothSOS.scanForNearbyDevices(
        timeout: Duration(seconds: 5),
      );

      setState(() {
        _nearbyDevices = devices;
        _isScanning = false;
      });

      Fluttertoast.showToast(
        msg: 'Found ${devices.length} nearby device(s)',
        backgroundColor: Colors.blue,
      );
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      Fluttertoast.showToast(
        msg: 'Scan error: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _sendSOSDemo() async {
    if (_currentPosition == null) {
      Fluttertoast.showToast(
        msg: 'Location not available',
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userName = user?.displayName ?? 'Demo User';

      final success = await _bluetoothSOS.sendSOSViaBluetooth(
        position: _currentPosition!,
        userName: userName,
        codeWord: 'HELP',
        customMessage: 'DEMO: SOS sent via Bluetooth in low network area',
      );

      if (success) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('SOS Sent!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ SOS successfully sent via Bluetooth!'),
                SizedBox(height: 16),
                Text(
                  'This demonstrates how the app works in low network areas.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: $e',
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth SOS Demo'),
        backgroundColor: Colors.pink,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'How It Works',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'When network is unavailable, the app automatically sends SOS via Bluetooth to nearby devices.',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Perfect for low network areas!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Location Status
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _currentPosition != null
                          ? Icons.location_on
                          : Icons.location_off,
                      color: _currentPosition != null
                          ? Colors.green
                          : Colors.grey,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location Status',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _currentPosition != null
                                ? '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}'
                                : 'Not available',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Scan Button
            ElevatedButton.icon(
              onPressed: _isScanning ? null : _scanForDevices,
              icon: _isScanning
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.bluetooth_searching),
              label: Text(_isScanning ? 'Scanning...' : 'Scan for Devices'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            SizedBox(height: 16),

            // Nearby Devices
            if (_nearbyDevices.isNotEmpty) ...[
              Text(
                'Nearby Devices (${_nearbyDevices.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              ..._nearbyDevices.map((device) => Card(
                    child: ListTile(
                      leading: Icon(Icons.bluetooth, color: Colors.blue),
                      title: Text(
                        device.name.isNotEmpty ? device.name : 'Unknown Device',
                      ),
                      subtitle: Text(device.id.toString()),
                      trailing: Icon(Icons.check_circle, color: Colors.green),
                    ),
                  )),
              SizedBox(height: 24),
            ],

            // Send SOS Button
            ElevatedButton.icon(
              onPressed: (_isSending || _currentPosition == null)
                  ? null
                  : _sendSOSDemo,
              icon: _isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.sos),
              label: Text(_isSending ? 'Sending SOS...' : 'Send SOS Demo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                minimumSize: Size(double.infinity, 50),
              ),
            ),

            SizedBox(height: 24),

            // Demo Instructions
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Demo Instructions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text('1. Enable Bluetooth on your device'),
                    Text('2. Click "Scan for Devices"'),
                    Text('3. Make sure another device is nearby'),
                    Text('4. Click "Send SOS Demo"'),
                    Text('5. SOS will be broadcast to nearby devices'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

