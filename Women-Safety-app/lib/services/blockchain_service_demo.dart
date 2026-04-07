// DEMO Blockchain Service - Simulates blockchain without real connection
// Perfect for college project presentations!
// Switch to real blockchain_service.dart when ready for actual blockchain

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// DEMO Blockchain Service - Simulates blockchain behavior
/// 
/// Features:
/// - ✅ No wallet needed
/// - ✅ No contract deployment
/// - ✅ No testnet setup
/// - ✅ Works offline
/// - ✅ Realistic demo for presentations
/// - ✅ Easy to switch to real blockchain later
class BlockchainServiceDemo {
  static final BlockchainServiceDemo _instance = BlockchainServiceDemo._internal();
  factory BlockchainServiceDemo() => _instance;
  BlockchainServiceDemo._internal();

  // Simulated blockchain data (stored locally)
  static const String _storageKey = 'demo_blockchain_hashes';
  static const String _txStorageKey = 'demo_blockchain_transactions';
  
  // Simulated contract address (for demo)
  static const String _demoContractAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';
  
  // Simulated network info
  static const String _networkName = 'Polygon Mumbai Testnet (Demo)';
  static const String _explorerUrl = 'https://mumbai.polygonscan.com/tx/';

  /// Generate hash from incident data (same as real blockchain)
  static String generateIncidentHash({
    required String incidentId,
    required String userId,
    required DateTime timestamp,
    double? latitude,
    double? longitude,
    String? description,
  }) {
    final data = {
      'incidentId': incidentId,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude?.toString() ?? '',
      'longitude': longitude?.toString() ?? '',
      'description': description ?? '',
    };

    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    final hash = sha256.convert(bytes);

    return hash.toString();
  }

  /// Generate realistic fake transaction hash
  String _generateFakeTxHash() {
    final random = Random();
    final chars = '0123456789abcdef';
    final hash = List.generate(64, (_) => chars[random.nextInt(chars.length)]).join();
    return '0x$hash';
  }

  /// Store incident hash (simulated blockchain storage)
  /// 
  /// Returns fake transaction hash for demo purposes
  Future<String?> recordIncidentOnChain({
    required String incidentId,
    required String userId,
    required DateTime timestamp,
    double? latitude,
    double? longitude,
    String? description,
    String? privateKey, // Not used in demo, but kept for compatibility
  }) async {
    try {
      // Generate hash (same as real blockchain)
      final incidentHash = generateIncidentHash(
        incidentId: incidentId,
        userId: userId,
        timestamp: timestamp,
        latitude: latitude,
        longitude: longitude,
        description: description,
      );

      // Load existing hashes
      final prefs = await SharedPreferences.getInstance();
      final existingHashes = prefs.getStringList(_storageKey) ?? [];
      
      // Check if hash already exists (prevent duplicates)
      if (existingHashes.contains(incidentHash)) {
        print('⚠️ Hash already exists (duplicate prevented)');
        return null;
      }

      // Add new hash
      existingHashes.add(incidentHash);
      await prefs.setStringList(_storageKey, existingHashes);

      // Generate fake transaction hash
      final txHash = _generateFakeTxHash();
      
      // Store transaction info
      final txData = {
        'hash': incidentHash,
        'txHash': txHash,
        'timestamp': timestamp.toIso8601String(),
        'blockNumber': _generateFakeBlockNumber(),
        'gasUsed': '21000',
        'status': 'success',
      };
      
      final existingTxs = prefs.getStringList(_txStorageKey) ?? [];
      existingTxs.add(jsonEncode(txData));
      await prefs.setStringList(_txStorageKey, existingTxs);

      print('✅ [DEMO] Incident hash recorded on blockchain!');
      print('📝 Transaction hash: $txHash');
      print('🔗 [DEMO] View on PolygonScan: $_explorerUrl$txHash');
      print('💡 This is a DEMO - not a real blockchain transaction');

      // Show toast notification
      Fluttertoast.showToast(
        msg: '✅ Incident hash recorded on blockchain (Demo)',
        backgroundColor: Colors.green,
        toastLength: Toast.LENGTH_SHORT,
      );

      return txHash;
    } catch (e) {
      print('❌ Error recording incident (demo): $e');
      return null;
    }
  }

  /// Generate fake block number (realistic range)
  String _generateFakeBlockNumber() {
    final random = Random();
    // Polygon Mumbai block numbers are in millions
    final blockNumber = 30000000 + random.nextInt(1000000);
    return blockNumber.toString();
  }

  /// Verify if incident hash exists (simulated verification)
  Future<bool> verifyIncidentHash(String incidentHash) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingHashes = prefs.getStringList(_storageKey) ?? [];
      return existingHashes.contains(incidentHash);
    } catch (e) {
      print('❌ Error verifying incident hash (demo): $e');
      return false;
    }
  }

  /// Get total incidents recorded (simulated)
  Future<int?> getTotalIncidents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingHashes = prefs.getStringList(_storageKey) ?? [];
      return existingHashes.length;
    } catch (e) {
      print('❌ Error getting total incidents (demo): $e');
      return null;
    }
  }

  /// Get transaction details (for demo display)
  Future<Map<String, dynamic>?> getTransactionDetails(String txHash) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingTxs = prefs.getStringList(_txStorageKey) ?? [];
      
      for (final txJson in existingTxs) {
        final txData = jsonDecode(txJson) as Map<String, dynamic>;
        if (txData['txHash'] == txHash) {
          return txData;
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting transaction details: $e');
      return null;
    }
  }

  /// Get all recorded hashes (for demo display)
  Future<List<String>> getAllHashes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_storageKey) ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Clear demo data (for testing)
  Future<void> clearDemoData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_txStorageKey);
    print('🗑️ Demo blockchain data cleared');
  }

  /// Get demo network info
  Map<String, String> getNetworkInfo() {
    return {
      'name': _networkName,
      'contractAddress': _demoContractAddress,
      'explorerUrl': _explorerUrl,
      'status': 'Demo Mode',
    };
  }

  /// Initialize (no-op for demo, but kept for compatibility)
  Future<void> initialize() async {
    print('✅ [DEMO] Blockchain service initialized (Demo Mode)');
    print('💡 This is a simulation - no real blockchain connection');
  }

  /// Dispose (no-op for demo)
  void dispose() {
    // Nothing to dispose in demo mode
  }
}

