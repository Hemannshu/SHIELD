// IPFS Storage Service using Pinata (Free Tier: 1GB)
//
// Setup (free):
// 1. Create free account at https://app.pinata.cloud/
// 2. Generate API key (JWT) from API Keys page
// 3. Add PINATA_JWT to .env file
//
// Free tier limits: 1GB storage, 100 pin requests/day

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class IpfsService {
  static final IpfsService _instance = IpfsService._internal();
  factory IpfsService() => _instance;
  IpfsService._internal();

  static const String _pinataUploadUrl = 'https://api.pinata.cloud/pinning/pinFileToIPFS';
  static const String _pinataPinJsonUrl = 'https://api.pinata.cloud/pinning/pinJSONToIPFS';

  // Public gateways for retrieval (no auth required)
  static const List<String> publicGateways = [
    'https://gateway.pinata.cloud/ipfs/',
    'https://ipfs.io/ipfs/',
    'https://cloudflare-ipfs.com/ipfs/',
    'https://dweb.link/ipfs/',
  ];

  String get _jwt => dotenv.get('PINATA_JWT', fallback: '');
  bool get isConfigured => _jwt.isNotEmpty;

  /// Upload encrypted file bytes to IPFS via Pinata.
  /// Returns the IPFS CID (Content Identifier) on success.
  Future<String?> uploadFile({
    required Uint8List fileBytes,
    required String fileName,
    Map<String, String>? metadata,
  }) async {
    if (!isConfigured) {
      print('⚠️ Pinata JWT not configured — skipping IPFS upload');
      return null;
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_pinataUploadUrl));

      request.headers['Authorization'] = 'Bearer $_jwt';

      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );

      // Pinata metadata for searching/filtering later
      final pinataMetadata = {
        'name': fileName,
        'keyvalues': {
          'app': 'SHEILD',
          'type': 'evidence',
          ...?metadata,
        },
      };
      request.fields['pinataMetadata'] = jsonEncode(pinataMetadata);

      // Pin options — SHEILD data should persist
      request.fields['pinataOptions'] = jsonEncode({'cidVersion': 1});

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final cid = json['IpfsHash'] as String;
        print('✅ File pinned to IPFS: $cid');
        return cid;
      } else {
        print('❌ Pinata upload failed (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ IPFS upload error: $e');
      return null;
    }
  }

  /// Download file from IPFS using public gateways (tries multiple).
  Future<Uint8List?> downloadFile(String cid) async {
    for (final gateway in publicGateways) {
      try {
        final response = await http
            .get(Uri.parse('$gateway$cid'))
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
      } catch (e) {
        print('Gateway $gateway failed for $cid: $e');
        continue;
      }
    }
    print('❌ All IPFS gateways failed for CID: $cid');
    return null;
  }

  /// Generate retrieval URLs for a CID across all public gateways
  List<String> getGatewayUrls(String cid) {
    return publicGateways.map((g) => '$g$cid').toList();
  }
}
