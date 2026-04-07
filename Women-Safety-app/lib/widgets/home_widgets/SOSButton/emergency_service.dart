import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:another_telephony/telephony.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
// Switch between demo and real blockchain:
// import 'package:title_proj/services/blockchain_service.dart'; // Real blockchain
import 'package:title_proj/services/blockchain_service_demo.dart' as blockchain; // Demo blockchain
import 'package:title_proj/services/bluetooth_sos_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class EmergencyService {
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();

  final Telephony _telephony = Telephony.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Handle emergency and return incident ID for evidence storage
  Future<String> handleEmergency(Position position, {String? customMessage}) async {
    try {
      // Create incident ID first
      final incidentId = DateTime.now().millisecondsSinceEpoch.toString();
      final user = _auth.currentUser;
      
      // 1. Get emergency contact exactly as done in ProfilePage
      final recipient = await _getEmergencyContact();
      if (recipient == null || recipient.isEmpty) {
        throw Exception('No valid emergency contact available');
      }

      // 2. Build message (same format as ProfilePage)
      final message = await _buildEmergencyMessage(position, customMessage: customMessage);

      // 3. Try to send SMS first (if network available)
      bool success = false;
      bool networkAvailable = false;

      // Check network connectivity
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        networkAvailable = connectivityResult != ConnectivityResult.none;
      } catch (e) {
        print('Connectivity check error: $e');
      }

      if (networkAvailable) {
        // Try SMS first (normal flow)
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
            // Bluetooth SOS sent successfully
            success = true;
            print('✅ SOS sent via Bluetooth (low network area)');
          } else {
            // Both SMS and Bluetooth failed
            throw Exception('Failed to send via SMS and Bluetooth');
          }
        } catch (e) {
          print('Bluetooth SOS error: $e');
          // If Bluetooth also fails, throw error
          if (!success) {
            throw Exception('Failed to send emergency alert via SMS and Bluetooth');
          }
        }
      }

      // 4. Store incident in Firestore for evidence linking
      if (user != null) {
        final timestamp = DateTime.now();
        
        await _firestore.collection('incidents').doc(incidentId).set({
          'userId': user.uid,
          'location': GeoPoint(position.latitude, position.longitude),
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'SOS',
          'message': message,
          'recipient': recipient,
        });

        // 5. Store incident hash on blockchain (automatic, tamper-proof)
        try {
          final blockchainService = blockchain.BlockchainServiceDemo();
          final incidentHash = blockchain.BlockchainServiceDemo.generateIncidentHash(
            incidentId: incidentId,
            userId: user.uid,
            timestamp: timestamp,
            latitude: position.latitude,
            longitude: position.longitude,
            description: 'SOS Emergency',
          );

          // Store hash in Firestore (for reference)
          await _firestore.collection('incidents').doc(incidentId).update({
            'blockchainHash': incidentHash,
            'blockchainRecorded': false, // Will be true after on-chain storage
          });

          // Record on blockchain (async, non-blocking)
          // Note: Requires wallet private key for testnet
          // For now, hash is generated and stored in Firestore
          // User can enable blockchain storage later
          blockchainService.recordIncidentOnChain(
            incidentId: incidentId,
            userId: user.uid,
            timestamp: timestamp,
            latitude: position.latitude,
            longitude: position.longitude,
            description: 'SOS Emergency',
            privateKey: null, // TODO: Get from user settings if enabled
          ).then((txHash) {
            if (txHash != null) {
              // Update Firestore with blockchain confirmation
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
          // Don't fail emergency if blockchain fails
        }
      }

      Fluttertoast.showToast(
        msg: 'Emergency alert sent!',
        backgroundColor: Colors.green,
      );

      return incidentId; // Return incident ID for evidence storage

    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Emergency alert failed: ${e.toString().replaceAll('Exception:', '')}',
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
      rethrow;
    }
  }

  // EXACT COPY FROM PROFILEPAGE IMPLEMENTATION
  Future<bool> _sendEmergencySMS(String recipient, String message) async {
    try {
      final hasPermission = await _telephony.requestSmsPermissions;
      if (hasPermission != true) {
        throw Exception('SMS permission not granted');
      }

      await _telephony.sendSms(to: recipient, message: message);
      return true;
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