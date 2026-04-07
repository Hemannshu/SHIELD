// Cloudinary Evidence Storage Service (FREE: 25GB storage, 25GB bandwidth/month)
//
// Setup (free, no credit card):
// 1. Sign up at https://cloudinary.com (free plan)
// 2. Go to Dashboard → copy your Cloud Name
// 3. Go to Settings → Upload → Add Upload Preset:
//    - Preset name: "shield_evidence"
//    - Signing mode: "Unsigned"
//    - Folder: "evidence"
//    - Click Save
// 4. Add CLOUDINARY_CLOUD_NAME to your .env file
//
// Free tier: 25GB storage, 25GB bandwidth/month, 25K transformations

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  String get _cloudName => dotenv.get('CLOUDINARY_CLOUD_NAME', fallback: '');
  String get _uploadPreset =>
      dotenv.get('CLOUDINARY_UPLOAD_PRESET', fallback: 'shield_evidence');

  bool get isConfigured => _cloudName.isNotEmpty;

  /// Upload image/video to Cloudinary (unsigned upload — no API secret needed).
  /// Returns a [CloudinaryResult] with the secure URL and public ID.
  Future<CloudinaryResult?> uploadEvidence({
    required Uint8List fileBytes,
    required String fileName,
    required String incidentId,
    required String userId,
    String resourceType = 'image', // 'image', 'video', or 'raw'
  }) async {
    if (!isConfigured) {
      print('⚠️ Cloudinary not configured — skipping upload');
      return null;
    }

    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload',
      );

      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = 'evidence/$userId';
      request.fields['public_id'] = '${incidentId}_${DateTime.now().millisecondsSinceEpoch}';

      // Add context metadata for searching in Cloudinary dashboard
      request.fields['context'] = 'incidentId=$incidentId|userId=$userId|app=SHEILD';

      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final result = CloudinaryResult(
          secureUrl: json['secure_url'] as String,
          publicId: json['public_id'] as String,
          bytes: json['bytes'] as int,
          format: json['format'] as String? ?? '',
          resourceType: json['resource_type'] as String? ?? resourceType,
        );
        print('✅ Uploaded to Cloudinary: ${result.secureUrl}');
        return result;
      } else {
        print('❌ Cloudinary upload failed (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Cloudinary upload error: $e');
      return null;
    }
  }

  /// Get a thumbnail URL for an uploaded image (auto-compressed, 400px wide).
  String getThumbnailUrl(String secureUrl) {
    // Insert transformation before /upload/ in the URL
    return secureUrl.replaceFirst(
      '/upload/',
      '/upload/w_400,c_scale,q_auto/',
    );
  }
}

class CloudinaryResult {
  final String secureUrl;
  final String publicId;
  final int bytes;
  final String format;
  final String resourceType;

  CloudinaryResult({
    required this.secureUrl,
    required this.publicId,
    required this.bytes,
    required this.format,
    required this.resourceType,
  });
}
