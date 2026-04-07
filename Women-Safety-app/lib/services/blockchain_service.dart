// Blockchain Service for Tamper-Proof Incident & Evidence Recording
// Uses Polygon Amoy Testnet (FREE) via Alchemy RPC
//
// Setup (all free):
// 1. Create free Alchemy account -> get Polygon Amoy RPC URL
// 2. Get free testnet MATIC from https://faucet.polygon.technology/
// 3. Deploy IncidentRegistry.sol contract (free on testnet)
// 4. Put RPC URL, private key, contract address in .env

import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BlockchainService {
  static final BlockchainService _instance = BlockchainService._internal();
  factory BlockchainService() => _instance;
  BlockchainService._internal();

  // Polygon Amoy Testnet chain ID
  static const int _chainId = 80002;
  static const String _explorerUrl = 'https://amoy.polygonscan.com/tx/';

  // Updated ABI matching the upgraded IncidentRegistry contract
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
      "inputs": [
        {"internalType": "bytes32", "name": "_evidenceHash", "type": "bytes32"},
        {"internalType": "string", "name": "_ipfsCid", "type": "string"}
      ],
      "name": "registerEvidence",
      "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "bytes32", "name": "_evidenceHash", "type": "bytes32"}],
      "name": "verifyEvidence",
      "outputs": [
        {"internalType": "bool", "name": "exists", "type": "bool"},
        {"internalType": "uint256", "name": "evidenceId", "type": "uint256"},
        {"internalType": "string", "name": "ipfsCid", "type": "string"},
        {"internalType": "address", "name": "owner", "type": "address"},
        {"internalType": "uint256", "name": "timestamp", "type": "uint256"}
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {"internalType": "uint256", "name": "_evidenceId", "type": "uint256"},
        {"internalType": "address", "name": "_to", "type": "address"}
      ],
      "name": "grantAccess",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {"internalType": "uint256", "name": "_evidenceId", "type": "uint256"},
        {"internalType": "address", "name": "_addr", "type": "address"}
      ],
      "name": "hasAccess",
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
      "inputs": [],
      "name": "totalEvidence",
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
    },
    {
      "anonymous": false,
      "inputs": [
        {"indexed": true, "internalType": "uint256", "name": "evidenceId", "type": "uint256"},
        {"indexed": true, "internalType": "bytes32", "name": "evidenceHash", "type": "bytes32"},
        {"indexed": false, "internalType": "string", "name": "ipfsCid", "type": "string"},
        {"indexed": true, "internalType": "address", "name": "owner", "type": "address"},
        {"indexed": false, "internalType": "uint256", "name": "timestamp", "type": "uint256"}
      ],
      "name": "EvidenceRegistered",
      "type": "event"
    }
  ]
  ''';

  Web3Client? _client;
  DeployedContract? _contract;
  EthPrivateKey? _credentials;
  bool _initialized = false;
  bool _configMissing = false;

  /// Initialize blockchain connection using .env config
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      final rpcUrl = dotenv.get('BLOCKCHAIN_RPC_URL', fallback: '');
      final contractAddress = dotenv.get('BLOCKCHAIN_CONTRACT_ADDRESS', fallback: '');
      final privateKey = dotenv.get('BLOCKCHAIN_PRIVATE_KEY', fallback: '');

      if (rpcUrl.isEmpty || contractAddress.isEmpty || privateKey.isEmpty) {
        print('⚠️ Blockchain .env config incomplete — running in hash-only mode');
        _configMissing = true;
        return false;
      }

      _client = Web3Client(rpcUrl, http.Client());
      _contract = DeployedContract(
        ContractAbi.fromJson(_contractABI, 'IncidentRegistry'),
        EthereumAddress.fromHex(contractAddress),
      );
      _credentials = EthPrivateKey.fromHex(privateKey);

      _initialized = true;
      print('✅ Blockchain service initialized (Polygon Amoy Testnet)');
      return true;
    } catch (e) {
      print('⚠️ Blockchain initialization error: $e');
      _initialized = false;
      return false;
    }
  }

  /// Whether the service has a live blockchain connection
  bool get isLive => _initialized && !_configMissing;

  // ===================== HASH GENERATION =====================

  /// Generate SHA-256 hash from incident data
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
    return sha256.convert(bytes).toString();
  }

  /// Convert a hex hash string to bytes32 for the contract
  static Uint8List _hashToBytes32(String hexHash) {
    final clean = hexHash.startsWith('0x') ? hexHash.substring(2) : hexHash;
    return Uint8List.fromList(
      List<int>.generate(32, (i) {
        if (i < clean.length ~/ 2) {
          return int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16);
        }
        return 0;
      }),
    );
  }

  // ===================== INCIDENT FUNCTIONS =====================

  /// Record incident hash on Polygon blockchain.
  /// Returns transaction hash if successful, null otherwise.
  Future<String?> recordIncidentOnChain({
    required String incidentId,
    required String userId,
    required DateTime timestamp,
    double? latitude,
    double? longitude,
    String? description,
  }) async {
    final incidentHash = generateIncidentHash(
      incidentId: incidentId,
      userId: userId,
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      description: description,
    );

    if (!_initialized) await initialize();
    if (!isLive) {
      print('⚠️ Blockchain offline — hash generated: ${incidentHash.substring(0, 16)}...');
      return null;
    }

    try {
      final hashBytes32 = _hashToBytes32(incidentHash);
      final recordFunction = _contract!.function('recordIncident');

      final txHash = await _client!.sendTransaction(
        _credentials!,
        Transaction.callContract(
          contract: _contract!,
          function: recordFunction,
          parameters: [hashBytes32],
          maxGas: 150000,
        ),
        chainId: _chainId,
      );

      print('✅ Incident recorded on-chain: $txHash');
      print('🔗 $_explorerUrl$txHash');
      return txHash;
    } catch (e) {
      print('❌ Blockchain recordIncident error: $e');
      return null;
    }
  }

  /// Verify if an incident hash exists on-chain
  Future<bool> verifyIncidentHash(String incidentHash) async {
    if (!_initialized) await initialize();
    if (!isLive) return false;

    try {
      final hashBytes32 = _hashToBytes32(incidentHash);
      final result = await _client!.call(
        contract: _contract!,
        function: _contract!.function('verifyIncident'),
        params: [hashBytes32],
      );
      return result.first as bool;
    } catch (e) {
      print('❌ verifyIncident error: $e');
      return false;
    }
  }

  // ===================== EVIDENCE FUNCTIONS =====================

  /// Register evidence hash + IPFS CID on blockchain.
  /// Returns transaction hash if successful.
  Future<String?> registerEvidenceOnChain({
    required String evidenceHash,
    required String ipfsCid,
  }) async {
    if (!_initialized) await initialize();
    if (!isLive) {
      print('⚠️ Blockchain offline — evidence hash: ${evidenceHash.substring(0, 16)}...');
      return null;
    }

    try {
      final hashBytes32 = _hashToBytes32(evidenceHash);
      final registerFunction = _contract!.function('registerEvidence');

      final txHash = await _client!.sendTransaction(
        _credentials!,
        Transaction.callContract(
          contract: _contract!,
          function: registerFunction,
          parameters: [hashBytes32, ipfsCid],
          maxGas: 200000,
        ),
        chainId: _chainId,
      );

      print('✅ Evidence registered on-chain: $txHash');
      print('🔗 $_explorerUrl$txHash');
      return txHash;
    } catch (e) {
      print('❌ Blockchain registerEvidence error: $e');
      return null;
    }
  }

  /// Verify evidence by its hash — returns metadata from blockchain
  Future<Map<String, dynamic>?> verifyEvidence(String evidenceHash) async {
    if (!_initialized) await initialize();
    if (!isLive) return null;

    try {
      final hashBytes32 = _hashToBytes32(evidenceHash);
      final result = await _client!.call(
        contract: _contract!,
        function: _contract!.function('verifyEvidence'),
        params: [hashBytes32],
      );

      final exists = result[0] as bool;
      if (!exists) return null;

      return {
        'exists': true,
        'evidenceId': (result[1] as BigInt).toInt(),
        'ipfsCid': result[2] as String,
        'owner': (result[3] as EthereumAddress).hexEip55,
        'timestamp': (result[4] as BigInt).toInt(),
      };
    } catch (e) {
      print('❌ verifyEvidence error: $e');
      return null;
    }
  }

  /// Get total incidents recorded on-chain
  Future<int?> getTotalIncidents() async {
    if (!_initialized) await initialize();
    if (!isLive) return null;

    try {
      final result = await _client!.call(
        contract: _contract!,
        function: _contract!.function('getTotalIncidents'),
        params: [],
      );
      return (result.first as BigInt).toInt();
    } catch (e) {
      print('❌ getTotalIncidents error: $e');
      return null;
    }
  }

  /// Explorer URL for a transaction
  String getExplorerUrl(String txHash) => '$_explorerUrl$txHash';

  /// Dispose resources
  void dispose() {
    _client?.dispose();
    _initialized = false;
  }
}

