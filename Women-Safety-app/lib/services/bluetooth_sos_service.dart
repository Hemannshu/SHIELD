// Enhanced Bluetooth SOS Service
// Automatically sends SOS via Bluetooth when network is unavailable
// Perfect for low network areas!

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Enhanced Bluetooth SOS Service
/// 
/// Features:
/// - Automatic fallback from network to Bluetooth
/// - Broadcast SOS to nearby devices
/// - Works in low/no network areas
/// - Perfect for emergency situations
class BluetoothSOSService {
  static final BluetoothSOSService _instance = BluetoothSOSService._internal();
  factory BluetoothSOSService() => _instance;
  BluetoothSOSService._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _sosCharacteristic;
  bool _isScanning = false;
  List<BluetoothDevice> _nearbyDevices = [];

  /// Check if Bluetooth is available
  Future<bool> isBluetoothAvailable() async {
    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      return adapterState == BluetoothAdapterState.on;
    } catch (e) {
      return false;
    }
  }

  /// Request all necessary permissions
  Future<bool> requestPermissions() async {
    try {
      // Request Bluetooth permissions
      final bluetoothStatus = await Permission.bluetooth.request();
      final bluetoothScanStatus = await Permission.bluetoothScan.request();
      final bluetoothConnectStatus = await Permission.bluetoothConnect.request();
      final locationStatus = await Permission.location.request();

      return bluetoothStatus.isGranted &&
          bluetoothScanStatus.isGranted &&
          bluetoothConnectStatus.isGranted &&
          locationStatus.isGranted;
    } catch (e) {
      print('Permission error: $e');
      return false;
    }
  }

  /// Scan for nearby devices (for SOS broadcast)
  Future<List<BluetoothDevice>> scanForNearbyDevices({Duration timeout = const Duration(seconds: 5)}) async {
    if (_isScanning) {
      return _nearbyDevices;
    }

    _isScanning = true;
    _nearbyDevices.clear();

    try {
      // Check if Bluetooth is on
      if (!await isBluetoothAvailable()) {
        Fluttertoast.showToast(
          msg: 'Please enable Bluetooth',
          backgroundColor: Colors.orange,
        );
        return [];
      }

      // Start scanning
      await FlutterBluePlus.startScan(timeout: timeout);

      // Listen to scan results
      final subscription = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          if (!_nearbyDevices.contains(result.device)) {
            _nearbyDevices.add(result.device);
          }
        }
      });

      // Wait for scan to complete
      await Future.delayed(timeout);

      // Stop scanning
      await FlutterBluePlus.stopScan();
      await subscription.cancel();

      print('📡 Found ${_nearbyDevices.length} nearby devices');
      return _nearbyDevices;
    } catch (e) {
      print('Error scanning: $e');
      return [];
    } finally {
      _isScanning = false;
    }
  }

  /// Send SOS via Bluetooth (broadcast to nearby devices)
  /// 
  /// This is perfect for low network areas!
  /// Broadcasts SOS to all nearby devices
  Future<bool> sendSOSViaBluetooth({
    required Position position,
    String? userName,
    String? codeWord,
    String? customMessage,
  }) async {
    try {
      // Check permissions
      if (!await requestPermissions()) {
        Fluttertoast.showToast(
          msg: 'Bluetooth permissions required',
          backgroundColor: Colors.red,
        );
        return false;
      }

      // Check Bluetooth
      if (!await isBluetoothAvailable()) {
        Fluttertoast.showToast(
          msg: 'Please enable Bluetooth',
          backgroundColor: Colors.orange,
        );
        return false;
      }

      // Build SOS message
      final sosMessage = _buildSOSMessage(
        position: position,
        userName: userName,
        codeWord: codeWord,
        customMessage: customMessage,
      );

      // Scan for nearby devices
      Fluttertoast.showToast(
        msg: '📡 Scanning for nearby devices...',
        backgroundColor: Colors.blue,
      );

      final devices = await scanForNearbyDevices(timeout: Duration(seconds: 3));

      if (devices.isEmpty) {
        Fluttertoast.showToast(
          msg: '⚠️ No nearby devices found',
          backgroundColor: Colors.orange,
        );
        return false;
      }

      // Try to send to all nearby devices
      int successCount = 0;
      for (final device in devices) {
        try {
          final sent = await _sendToDevice(device, sosMessage);
          if (sent) successCount++;
        } catch (e) {
          print('Failed to send to ${device.name}: $e');
        }
      }

      if (successCount > 0) {
        Fluttertoast.showToast(
          msg: '✅ SOS sent to $successCount device(s) via Bluetooth!',
          backgroundColor: Colors.green,
          toastLength: Toast.LENGTH_LONG,
        );
        return true;
      } else {
        Fluttertoast.showToast(
          msg: '⚠️ Could not send SOS via Bluetooth',
          backgroundColor: Colors.orange,
        );
        return false;
      }
    } catch (e) {
      print('Error sending SOS via Bluetooth: $e');
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        backgroundColor: Colors.red,
      );
      return false;
    }
  }

  /// Build SOS message with all necessary information
  String _buildSOSMessage({
    required Position position,
    String? userName,
    String? codeWord,
    String? customMessage,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'unknown';
    final timestamp = DateTime.now().toIso8601String();
    final locationUrl = 'https://maps.google.com/?q=${position.latitude},${position.longitude}';

    // Format: SOS|userId|timestamp|lat,lng|userName|codeWord|message
    final message = customMessage ??
        'EMERGENCY SOS!\n'
        'User: ${userName ?? "Unknown"}\n'
        'Location: $locationUrl\n'
        'Coordinates: ${position.latitude}, ${position.longitude}\n'
        'Time: ${DateTime.now().toString()}\n'
        '${codeWord != null ? "Code Word: $codeWord\n" : ""}'
        'Sent via Bluetooth (Low Network Area)';

    // Create structured data for parsing
    final structuredData = {
      'type': 'SOS',
      'userId': userId,
      'timestamp': timestamp,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'userName': userName,
      'codeWord': codeWord,
      'message': message,
      'source': 'bluetooth',
    };

    return jsonEncode(structuredData);
  }

  /// Send message to a specific device
  Future<bool> _sendToDevice(BluetoothDevice device, String message) async {
    try {
      // Try to connect (with timeout)
      await device.connect(timeout: Duration(seconds: 2)).timeout(
        Duration(seconds: 3),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      // Discover services
      final services = await device.discoverServices().timeout(
        Duration(seconds: 3),
      );

      // Find writable characteristic
      BluetoothCharacteristic? writableChar;
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            writableChar = characteristic;
            break;
          }
        }
        if (writableChar != null) break;
      }

      if (writableChar == null) {
        await device.disconnect();
        return false;
      }

      // Send message
      final messageBytes = utf8.encode(message);
      await writableChar.write(messageBytes, withoutResponse: false);

      // Disconnect
      await device.disconnect();

      print('✅ SOS sent to ${device.name}');
      return true;
    } catch (e) {
      print('❌ Failed to send to ${device.name}: $e');
      // Try to disconnect if still connected
      try {
        await device.disconnect();
      } catch (_) {}
      return false;
    }
  }

  /// Connect to a specific device (for manual connection)
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      _connectedDevice = device;

      // Discover services
      final services = await device.discoverServices();
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            _sosCharacteristic = characteristic;
            break;
          }
        }
        if (_sosCharacteristic != null) break;
      }

      return _sosCharacteristic != null;
    } catch (e) {
      print('Connection error: $e');
      return false;
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _sosCharacteristic = null;
    }
  }

  /// Get connected device
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// Check if connected
  bool get isConnected => _connectedDevice != null && _connectedDevice!.isConnected;
}

