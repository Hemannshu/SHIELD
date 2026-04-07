// Blockchain Service for Tamper-Proof Incident Reporting
// Uses Polygon Mumbai Testnet (FREE) - No gas fees!

import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

/// Blockchain Service for storing incident hashes on Polygon Mumbai Testnet
/// 
/// Features:
/// - FREE (testnet, no real money)
/// - Tamper-proof incident records
/// - Automatic hash verification
/// - Simple and beginner-friendly
class BlockchainService {
  static final BlockchainService _instance = BlockchainService._internal();
  factory BlockchainService() => _instance;
  BlockchainService._internal();

  // Polygon Mumbai Testnet RPC URL (FREE)
  static const String _rpcUrl = 'https://rpc-mumbai.maticvigil.com';
  
  // Contract address (will be set after deployment)
  // TODO: Replace with your deployed contract address
  static const String _contractAddress = '0x0000000000000000000000000000000000000000';
  
  // Contract ABI (Application Binary Interface)
  static const String _contractABI = '''
  [
    {
      "inputs": [{"internalType": "bytes32", "name": "_incidentHash", "type": "bytes32"}],
      "name": "recordIncident",
      "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "bytes32", "name": "_incidentHash", "type": "bytes32"}],
      "name": "verifyIncident",
      "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "getTotalIncidents",
      "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "anonymous": false,
      "inputs": [
        {"indexed": true, "internalType": "bytes32", "name": "incidentHash", "type": "bytes32"},
        {"indexed": true, "internalType": "address", "name": "userAddress", "type": "address"},
        {"indexed": false, "internalType": "uint256", "name": "timestamp", "type": "uint256"},
        {"indexed": false, "internalType": "uint256", "name": "blockNumber", "type": "uint256"}
      ],
      "name": "IncidentRecorded",
      "type": "event"
    }
  ]
  ''';

  Web3Client? _client;
  DeployedContract? _contract;
  bool _initialized = false;

  /// Initialize blockchain connection
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _client = Web3Client(_rpcUrl, http.Client());
      
      // Load contract
      final contractAddress = EthereumAddress.fromHex(_contractAddress);
      _contract = DeployedContract(
        ContractAbi.fromJson(_contractABI, 'IncidentRegistry'),
        contractAddress,
      );

      _initialized = true;
      print('✅ Blockchain service initialized (Polygon Mumbai Testnet)');
    } catch (e) {
      print('⚠️ Blockchain initialization error: $e');
      print('💡 Make sure contract is deployed and address is set');
      _initialized = false;
    }
  }

  /// Generate hash from incident data
  /// 
  /// Creates SHA-256 hash from:
  /// - Incident ID
  /// - User ID
  /// - Timestamp
  /// - Location (lat, lng)
  /// - Description
  static String generateIncidentHash({
    required String incidentId,
    required String userId,
    required DateTime timestamp,
    double? latitude,
    double? longitude,
    String? description,
  }) {
    // Combine all data into a single string
    final data = {
      'incidentId': incidentId,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude?.toString() ?? '',
      'longitude': longitude?.toString() ?? '',
      'description': description ?? '',
    };

    // Convert to JSON and hash
    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    final hash = sha256.convert(bytes);

    return hash.toString();
  }

  /// Store incident hash on blockchain
  /// 
  /// Automatically called when incident is created
  /// Returns transaction hash if successful
  Future<String?> recordIncidentOnChain({
    required String incidentId,
    required String userId,
    required DateTime timestamp,
    double? latitude,
    double? longitude,
    String? description,
    String? privateKey, // User's wallet private key (testnet only!)
  }) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      if (_client == null || _contract == null) {
        print('⚠️ Blockchain not initialized');
        return null;
      }

      // Generate hash
      final incidentHash = generateIncidentHash(
        incidentId: incidentId,
        userId: userId,
        timestamp: timestamp,
        latitude: latitude,
        longitude: longitude,
        description: description,
      );

      // Convert hash to bytes32
      final hashBytes = Uint8List.fromList(
        List<int>.generate(32, (i) {
          if (i < incidentHash.length ~/ 2) {
            return int.parse(
              incidentHash.substring(i * 2, i * 2 + 2),
              radix: 16,
            );
          }
          return 0;
        }),
      );
      final hashBytes32 = hashBytes.sublist(0, 32);

      // If no private key provided, use read-only mode (simulation)
      if (privateKey == null || privateKey.isEmpty) {
        print('⚠️ No private key provided - using read-only mode');
        print('💡 Hash generated: ${incidentHash.substring(0, 16)}...');
        print('💡 To store on-chain, provide wallet private key');
        return null;
      }

      // Create credentials from private key
      final credentials = EthPrivateKey.fromHex(privateKey);
      final address = await credentials.extractAddress();

      // Get contract function
      final recordFunction = _contract!.function('recordIncident');
      
      // Estimate gas (optional, for testnet)
      final gasPrice = await _client!.getGasPrice();
      
      // Send transaction
      final transaction = Transaction.callContract(
        contract: _contract!,
        function: recordFunction,
        parameters: [hashBytes32],
        maxGas: 100000,
        gasPrice: gasPrice,
      );

      final txHash = await _client!.sendTransaction(
        credentials,
        transaction,
        chainId: 80001, // Polygon Mumbai chain ID
      );

      print('✅ Incident hash recorded on blockchain!');
      print('📝 Transaction hash: $txHash');
      print('🔗 View on PolygonScan: https://mumbai.polygonscan.com/tx/$txHash');

      return txHash;
    } catch (e) {
      print('❌ Error recording incident on blockchain: $e');
      return null;
    }
  }

  /// Verify if incident hash exists on blockchain
  Future<bool> verifyIncidentHash(String incidentHash) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      if (_client == null || _contract == null) {
        return false;
      }

      // Convert hash to bytes32
      final hashBytes = Uint8List.fromList(
        List<int>.generate(32, (i) {
          if (i < incidentHash.length ~/ 2) {
            return int.parse(
              incidentHash.substring(i * 2, i * 2 + 2),
              radix: 16,
            );
          }
          return 0;
        }),
      );
      final hashBytes32 = hashBytes.sublist(0, 32);

      // Call verify function
      final verifyFunction = _contract!.function('verifyIncident');
      final result = await _client!.call(
        contract: _contract!,
        function: verifyFunction,
        params: [hashBytes32],
      );

      return result[0] as bool;
    } catch (e) {
      print('❌ Error verifying incident hash: $e');
      return false;
    }
  }

  /// Get total incidents recorded on blockchain
  Future<int?> getTotalIncidents() async {
    try {
      if (!_initialized) {
        await initialize();
      }

      if (_client == null || _contract == null) {
        return null;
      }

      final function = _contract!.function('getTotalIncidents');
      final result = await _client!.call(
        contract: _contract!,
        function: function,
        params: [],
      );

      return (result[0] as BigInt).toInt();
    } catch (e) {
      print('❌ Error getting total incidents: $e');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _client?.dispose();
    _initialized = false;
  }
}

