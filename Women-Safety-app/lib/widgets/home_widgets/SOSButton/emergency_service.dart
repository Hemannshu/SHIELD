import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:title_proj/services/blockchain_service.dart';
import 'package:title_proj/services/bluetooth_sos_service.dart';
import 'package:title_proj/services/auto_evidence_capture_service.dart';
import 'package:title_proj/services/native_sms_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class EmergencyService {
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BlockchainService _blockchain = BlockchainService();
  final AutoEvidenceCaptureService _autoEvidence = AutoEvidenceCaptureService();

  /// Handle emergency and return incident ID for evidence storage
  Future<String> handleEmergency(Position position, {String? customMessage}) async {
    try {
      final incidentId = DateTime.now().millisecondsSinceEpoch.toString();
      final user = _auth.currentUser;
      final timestamp = DateTime.now();

      // 1. Get emergency contact
      final recipient = await _getEmergencyContact();
      if (recipient == null || recipient.isEmpty) {
        throw Exception('No valid emergency contact available');
      }

      // 2. Build message
      final message = await _buildEmergencyMessage(position, customMessage: customMessage);

      // 3. Try to send SMS first (if network available)
      bool success = false;
      bool networkAvailable = false;

      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        networkAvailable = connectivityResult != ConnectivityResult.none;
      } catch (e) {
        print('Connectivity check error: $e');
      }

      if (networkAvailable) {
        success = await _sendEmergencySMS(recipient, message);
      }

      // 4. If SMS failed or no network, try Bluetooth SOS (automatic fallback)
      if (!success || !networkAvailable) {
        print('📡 Network unavailable or SMS failed - Trying Bluetooth SOS...');
        try {
          final bluetoothSOS = BluetoothSOSService();
          final userName = await _getUserName();
          final codeWord = await _getCodeWord();
          final bluetoothSuccess = await bluetoothSOS.sendSOSViaBluetooth(
            position: position,
            userName: userName,
            codeWord: codeWord,
            customMessage: message,
          );
          if (bluetoothSuccess) {
            success = true;
            print('✅ SOS sent via Bluetooth (low network area)');
          } else {
            throw Exception('Failed to send via SMS and Bluetooth');
          }
        } catch (e) {
          print('Bluetooth SOS error: $e');
          if (!success) {
            throw Exception('Failed to send emergency alert via SMS and Bluetooth');
          }
        }
      }

      // 5. Store incident in Firestore
      if (user != null) {
        await _firestore.collection('incidents').doc(incidentId).set({
          'userId': user.uid,
          'location': GeoPoint(position.latitude, position.longitude),
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'SOS',
          'message': message,
          'recipient': recipient,
        });

        // 6. Record incident hash on blockchain (real Polygon Amoy)
        try {
          final incidentHash = BlockchainService.generateIncidentHash(
            incidentId: incidentId,
            userId: user.uid,
            timestamp: timestamp,
            latitude: position.latitude,
            longitude: position.longitude,
            description: 'SOS Emergency',
          );

          // Store hash reference in Firestore immediately
          await _firestore.collection('incidents').doc(incidentId).update({
            'blockchainHash': incidentHash,
            'blockchainRecorded': false,
          });

          // Record on blockchain (async, non-blocking)
          _blockchain.recordIncidentOnChain(
            incidentId: incidentId,
            userId: user.uid,
            timestamp: timestamp,
            latitude: position.latitude,
            longitude: position.longitude,
            description: 'SOS Emergency',
          ).then((txHash) {
            if (txHash != null) {
              _firestore.collection('incidents').doc(incidentId).update({
                'blockchainTxHash': txHash,
                'blockchainRecorded': true,
                'blockchainRecordedAt': FieldValue.serverTimestamp(),
              });
              print('✅ Incident hash recorded on blockchain: $txHash');
            }
          }).catchError((e) {
            print('⚠️ Blockchain recording failed (non-critical): $e');
          });
        } catch (e) {
          print('⚠️ Blockchain service error (non-critical): $e');
        }

        // 7. Start automatic evidence capture (photo + GPS logging)
        try {
          _autoEvidence.startCapture(incidentId: incidentId).then((evidenceIds) {
            print('📸 Auto-captured ${evidenceIds.length} evidence items');
          }).catchError((e) {
            print('⚠️ Auto evidence capture error (non-critical): $e');
          });
        } catch (e) {
          print('⚠️ Evidence capture init error: $e');
        }
      }

      Fluttertoast.showToast(
        msg: 'Emergency alert sent!',
        backgroundColor: Colors.green,
      );

      return incidentId;

    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Emergency alert failed: ${e.toString().replaceAll('Exception:', '')}',
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
      rethrow;
    }
  }

  /// Stop any running automatic evidence capture
  Future<void> stopAutoCapture() async {
    await _autoEvidence.stopCapture();
  }

  // Uses native Android SmsManager via platform channel (no default SMS app required)
  Future<bool> _sendEmergencySMS(String recipient, String message) async {
    try {
      return await NativeSmsService.sendSms(phone: recipient, message: message);
    } catch (e) {
      debugPrint('SMS sending error: $e');
      return false;
    }
  }

  // Same contact fetching as ProfilePage
  Future<String?> _getEmergencyContact() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      // Exactly the same logic as ProfilePage
      return doc.data()?['emergencyContact']?.toString().trim() ?? 
             doc.data()?['phone']?.toString().trim();
    } catch (e) {
      debugPrint('Error getting emergency contact: $e');
      return null;
    }
  }

  // Similar message building as ProfilePage
  Future<String> _buildEmergencyMessage(Position position, {String? customMessage}) async {
    final locationUrl = 'https://maps.google.com?q=${position.latitude},${position.longitude}';
    final userName = await _getUserName() ?? 'User';
    final codeWord = await _getCodeWord();

    return customMessage ?? 
      'EMERGENCY! $userName needs help!\n'
      'Location: $locationUrl\n'
      '${codeWord != null ? "Codeword: $codeWord" : ""}';
  }

  Future<String?> _getUserName() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['name']?.toString();
  }

  Future<String?> _getCodeWord() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['codeWord']?.toString().trim();
  }
}