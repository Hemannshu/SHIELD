// Example Blockchain Service Implementation
// This is a template - customize based on your chosen blockchain

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple Blockchain Service for SHEild App
/// 
/// This service provides a simple way to store incident data on blockchain
/// Currently uses a mock implementation - replace with actual blockchain calls
class BlockchainService {
  static final BlockchainService _instance = BlockchainService._internal();
  factory BlockchainService() => _instance;
  BlockchainService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // For production, use actual blockchain RPC URL
  // Example: 'https://polygon-rpc.com' for Polygon
  static const String _blockchainRpcUrl = 'YOUR_BLOCKCHAIN_RPC_URL';
  
  // For production, use actual contract address
  static const String _contractAddress = 'YOUR_CONTRACT_ADDRESS';

  /// Store an incident on blockchain
  /// 
  /// Creates a hash of the incident data and stores it on blockchain
  /// Returns the transaction hash
  Future<String> logIncident({
    required String userId,
    required double latitude,
    required double longitude,
    required DateTime timestamp,
    required String incidentType, // "SOS", "Shake", "Voice", "Geofence"
    String? additionalData,
  }) async {
    try {
      // 1. Create incident data
      final incidentData = {
        'userId': userId,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
        'type': incidentType,
        if (additionalData != null) 'additionalData': additionalData,
      };

      // 2. Create hash of the data
      final dataString = jsonEncode(incidentData);
      final hash = sha256.convert(utf8.encode(dataString)).toString();

      // 3. Store on blockchain (mock implementation)
      // TODO: Replace with actual blockchain transaction
      final txHash = await _storeOnBlockchain(hash, incidentData);

      // 4. Store reference in Firestore for quick access
      await _firestore.collection('blockchain_incidents').add({
        'userId': userId,
        'blockchainHash': hash,
        'transactionHash': txHash,
        'timestamp': FieldValue.serverTimestamp(),
        'type': incidentType,
        'location': GeoPoint(latitude, longitude),
        // Store encrypted data in Firestore (not on blockchain)
        'data': incidentData,
      });

      return txHash;
    } catch (e) {
      print('Error storing incident on blockchain: $e');
      rethrow;
    }
  }

  /// Verify an incident exists on blockchain
  Future<bool> verifyIncident(String transactionHash) async {
    try {
      // TODO: Implement actual blockchain verification
      // Check if transaction exists on blockchain
      return await _verifyOnBlockchain(transactionHash);
    } catch (e) {
      print('Error verifying incident: $e');
      return false;
    }
  }

  /// Get all incidents for a user from blockchain
  Future<List<Map<String, dynamic>>> getUserIncidents(String userId) async {
    try {
      // Get from Firestore (which has blockchain hashes)
      final snapshot = await _firestore
          .collection('blockchain_incidents')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting user incidents: $e');
      return [];
    }
  }

  /// Store evidence (photo/video) hash on blockchain
  Future<String> storeEvidenceHash({
    required String userId,
    required String incidentId,
    required String fileHash, // Hash of the file
    required String fileType, // "photo", "video", "audio"
    String? description,
  }) async {
    try {
      final evidenceData = {
        'userId': userId,
        'incidentId': incidentId,
        'fileHash': fileHash,
        'fileType': fileType,
        'timestamp': DateTime.now().toIso8601String(),
        if (description != null) 'description': description,
      };

      final dataString = jsonEncode(evidenceData);
      final hash = sha256.convert(utf8.encode(dataString)).toString();

      // Store on blockchain
      final txHash = await _storeOnBlockchain(hash, evidenceData);

      // Store in Firestore
      await _firestore.collection('blockchain_evidence').add({
        'userId': userId,
        'incidentId': incidentId,
        'blockchainHash': hash,
        'transactionHash': txHash,
        'fileHash': fileHash,
        'fileType': fileType,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return txHash;
    } catch (e) {
      print('Error storing evidence on blockchain: $e');
      rethrow;
    }
  }

  // ========== PRIVATE METHODS ==========

  /// Mock blockchain storage - Replace with actual implementation
  Future<String> _storeOnBlockchain(String hash, Map<String, dynamic> data) async {
    // TODO: Implement actual blockchain transaction
    // Example for Polygon/Ethereum:
    // 1. Connect to blockchain using web3dart
    // 2. Call smart contract method
    // 3. Wait for transaction confirmation
    // 4. Return transaction hash

    // Mock implementation - returns a fake hash
    // In production, this would be an actual blockchain transaction
    await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
    
    // Generate a mock transaction hash
    final mockTxHash = sha256.convert(utf8.encode('$hash${DateTime.now().millisecondsSinceEpoch}')).toString();
    
    print('📦 Stored on blockchain: $mockTxHash');
    print('   Hash: $hash');
    print('   Data: ${jsonEncode(data)}');
    
    return '0x$mockTxHash';
  }

  /// Mock blockchain verification - Replace with actual implementation
  Future<bool> _verifyOnBlockchain(String transactionHash) async {
    // TODO: Implement actual blockchain verification
    // Example:
    // 1. Query blockchain for transaction
    // 2. Check if transaction exists and is confirmed
    // 3. Return verification result

    // Mock implementation
    await Future.delayed(Duration(milliseconds: 300));
    return transactionHash.startsWith('0x'); // Simple check
  }
}

/// Usage Example:
/// 
/// ```dart
/// final blockchain = BlockchainService();
/// 
/// // Store SOS incident
/// final txHash = await blockchain.logIncident(
///   userId: user.uid,
///   latitude: position.latitude,
///   longitude: position.longitude,
///   timestamp: DateTime.now(),
///   incidentType: 'SOS',
/// );
/// 
/// print('Incident stored: $txHash');
/// 
/// // Verify incident
/// final verified = await blockchain.verifyIncident(txHash);
/// print('Verified: $verified');
/// ```

