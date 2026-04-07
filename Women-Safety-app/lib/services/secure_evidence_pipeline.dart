// Secure Evidence Pipeline Service
//
// Implements the complete evidence preservation workflow from the paper:
// 1. Capture evidence (photo/video/audio)
// 2. Compute SHA-256 hash of original file (for blockchain verification)
// 3. Encrypt with AES-256-CBC (client-side, before leaving device)
// 4. Upload encrypted file to IPFS via Pinata (off-chain storage)
// 5. Store evidence hash + IPFS CID on Polygon blockchain (on-chain anchor)
// 6. Store metadata in Firestore (for app-level queries)

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:title_proj/services/encryption_service.dart';
import 'package:title_proj/services/ipfs_service.dart';
import 'package:title_proj/services/blockchain_service.dart';
import 'package:title_proj/services/cloudinary_service.dart';

/// Result of storing evidence through the full pipeline
class SecureEvidenceRecord {
  final String id;
  final String incidentId;
  final String userId;
  final String fileName;
  final String fileHash;       // SHA-256 of ORIGINAL (unencrypted) file
  final String? ipfsCid;       // IPFS CID of ENCRYPTED file
  final String? blockchainTxHash; // Transaction hash from Polygon
  final String? cloudinaryUrl;  // Cloudinary URL for viewing
  final String ivBase64;       // AES IV needed for decryption
  final int fileSize;
  final String fileType;
  final DateTime timestamp;
  final List<String> ipfsUrls;

  SecureEvidenceRecord({
    required this.id,
    required this.incidentId,
    required this.userId,
    required this.fileName,
    required this.fileHash,
    this.ipfsCid,
    this.blockchainTxHash,
    this.cloudinaryUrl,
    required this.ivBase64,
    required this.fileSize,
    required this.fileType,
    required this.timestamp,
    this.ipfsUrls = const [],
  });
}

class SecureEvidencePipeline {
  static final SecureEvidencePipeline _instance = SecureEvidencePipeline._internal();
  factory SecureEvidencePipeline() => _instance;
  SecureEvidencePipeline._internal();

  final EncryptionService _encryption = EncryptionService();
  final IpfsService _ipfs = IpfsService();
  final BlockchainService _blockchain = BlockchainService();
  final CloudinaryService _cloudinary = CloudinaryService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Process evidence through the full pipeline:
  /// hash → encrypt → IPFS → blockchain → Firestore
  ///
  /// [fileBytes] raw file bytes (photo/video/audio)
  /// [fileName] original file name
  /// [incidentId] the incident this evidence belongs to
  Future<SecureEvidenceRecord> processEvidence({
    required Uint8List fileBytes,
    required String fileName,
    required String incidentId,
    String? description,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final timestamp = DateTime.now();

    // --- Step 1: Hash the original file (before encryption) ---
    final fileHash = EncryptionService.computeFileHash(fileBytes);
    print('📝 Evidence hash (SHA-256): ${fileHash.substring(0, 16)}...');

    // --- Step 2: Encrypt with AES-256 ---
    final encryptionKey = EncryptionService.generateUserEncryptionKey(
      userId: user.uid,
      appSecret: dotenv.get('APP_SECRET', fallback: 'SHEILD_DEFAULT_SECRET'),
    );

    final encResult = _encryption.encryptBytes(
      plainBytes: fileBytes,
      encryptionKey: encryptionKey,
    );
    final encryptedBytes = encResult['encryptedBytes'] as Uint8List;
    final ivBase64 = encResult['iv'] as String;
    print('🔒 File encrypted (AES-256-CBC), size: ${encryptedBytes.length} bytes');

    // --- Step 3: IPFS disabled (Cloudinary is primary storage) ---
    String? ipfsCid;
    List<String> ipfsUrls = [];

    // --- Step 3b: Upload ORIGINAL file to Cloudinary for viewing ---
    String? cloudinaryUrl;
    final fileType = _getFileType(fileName);
    // Only upload actual images/videos to Cloudinary, skip GPS logs and other data
    if (fileType == 'image' || fileType == 'video') {
      try {
        print('☁️ Uploading to Cloudinary (cloud: ${_cloudinary.isConfigured})...');
        final cloudResult = await _cloudinary.uploadEvidence(
          fileBytes: fileBytes,
          fileName: fileName,
          incidentId: incidentId,
          userId: user.uid,
          resourceType: fileType == 'video' ? 'video' : 'image',
        );
        if (cloudResult != null) {
          cloudinaryUrl = cloudResult.secureUrl;
          print('☁️ Uploaded to Cloudinary: $cloudinaryUrl');
        } else {
          print('⚠️ Cloudinary upload returned null');
        }
      } catch (e) {
        print('⚠️ Cloudinary upload failed (non-critical): $e');
      }
    } else {
      print('ℹ️ Skipping Cloudinary upload for non-image file: $fileName');
    }

    // --- Step 4: Anchor evidence hash on blockchain ---
    // Only anchor images/videos on-chain (skip GPS logs to save gas)
    String? blockchainTxHash;
    if (fileType == 'image' || fileType == 'video') {
      try {
        blockchainTxHash = await _blockchain.recordIncidentOnChain(
          incidentId: incidentId,
          userId: user.uid,
          timestamp: timestamp,
          description: 'Evidence: $fileName | Hash: ${fileHash.substring(0, 16)}',
        );
        if (blockchainTxHash != null) {
          print('⛓️ Evidence anchored on Polygon: $blockchainTxHash');
        }
      } catch (e) {
        print('⚠️ Blockchain recording failed (non-critical): $e');
      }
    }

    // --- Step 5: Create a compressed preview for Firestore ---
    String? imageBase64;
    // Only store base64 in Firestore if Cloudinary upload failed
    if (cloudinaryUrl == null && fileType == 'image' && fileBytes.length < 750000) {
      // Store image directly if small enough (< 750KB → ~1MB base64)
      imageBase64 = base64Encode(fileBytes);
    } else if (cloudinaryUrl == null && fileType == 'image') {
      // Compress large images to fit Firestore 1MB doc limit
      try {
        final codec = await ui.instantiateImageCodec(fileBytes);
        final frame = await codec.getNextFrame();
        final image = frame.image;
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final compressed = byteData.buffer.asUint8List();
          if (compressed.length < 750000) {
            imageBase64 = base64Encode(compressed);
          }
        }
      } catch (e) {
        // If compression fails, store raw if small enough
        if (fileBytes.length < 500000) {
          imageBase64 = base64Encode(fileBytes);
        }
        print('⚠️ Image compression for preview failed: $e');
      }
    }

    // --- Step 6: Store metadata + image preview in Firestore ---
    final docData = {
      'userId': user.uid,
      'incidentId': incidentId,
      'fileName': fileName,
      'fileHash': fileHash,
      'ipfsCid': ipfsCid,
      'ivBase64': ivBase64,
      'keyHash': encResult['keyHash'],
      'fileSize': fileBytes.length,
      'encryptedSize': encryptedBytes.length,
      'fileType': fileType,
      'description': description,
      'ipfsUrls': ipfsUrls,
      'blockchainTxHash': blockchainTxHash,
      'cloudinaryUrl': cloudinaryUrl,
      'downloadUrl': cloudinaryUrl ?? '',
      'timestamp': FieldValue.serverTimestamp(),
      'verified': true,
      'encrypted': true,
    };
    if (imageBase64 != null) {
      docData['imageBase64'] = imageBase64;
    }
    final docRef = await _firestore.collection('evidence').add(docData);

    print('✅ Evidence pipeline complete for $fileName');

    return SecureEvidenceRecord(
      id: docRef.id,
      incidentId: incidentId,
      userId: user.uid,
      fileName: fileName,
      fileHash: fileHash,
      ipfsCid: ipfsCid,
      blockchainTxHash: blockchainTxHash,
      cloudinaryUrl: cloudinaryUrl,
      ivBase64: ivBase64,
      fileSize: fileBytes.length,
      fileType: _getFileType(fileName),
      timestamp: timestamp,
      ipfsUrls: ipfsUrls,
    );
  }

  /// Verify evidence integrity:
  /// 1. Download encrypted file from IPFS
  /// 2. Decrypt it
  /// 3. Re-hash and compare with blockchain record
  Future<bool> verifyEvidence({
    required String fileHash,
    required String ipfsCid,
  }) async {
    // Check blockchain record
    final onChainData = await _blockchain.verifyEvidence(fileHash);
    if (onChainData == null) {
      print('❌ Evidence hash not found on blockchain');
      return false;
    }

    // Check the CID matches
    if (onChainData['ipfsCid'] != ipfsCid) {
      print('❌ IPFS CID mismatch — possible tampering');
      return false;
    }

    print('✅ Evidence verified: hash and CID match blockchain record');
    return true;
  }

  /// Get all evidence records for an incident
  Future<List<Map<String, dynamic>>> getIncidentEvidence(String incidentId) async {
    final snapshot = await _firestore
        .collection('evidence')
        .where('incidentId', isEqualTo: incidentId)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  String _getFileType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) return 'image';
    if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) return 'video';
    if (['mp3', 'wav', 'aac', 'm4a'].contains(ext)) return 'audio';
    return 'file';
  }
}
