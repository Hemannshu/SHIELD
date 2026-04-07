// Evidence Storage Service using Cloudinary (FREE: 25GB storage)
// Metadata stored in Firestore

import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:title_proj/services/cloudinary_service.dart';

// Type alias for FirebaseUser
typedef FirebaseUser = User;

/// Evidence Storage Service using Cloudinary + Firestore
/// 
/// Cloudinary free tier: 25GB storage, 25GB bandwidth/month
/// No credit card needed
class FirebaseEvidenceService {
  static final FirebaseEvidenceService _instance = FirebaseEvidenceService._internal();
  factory FirebaseEvidenceService() => _instance;
  FirebaseEvidenceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final CloudinaryService _cloudinary = CloudinaryService();

  /// Store evidence (photo/video)
  /// 
  /// Steps:
  /// 1. Pick file from camera/gallery
  /// 2. Calculate hash for verification
  /// 3. Upload to Cloudinary (free)
  /// 4. Store metadata in Firestore (free)
  Future<EvidenceRecord> storeEvidence({
    required String incidentId,
    String? description,
    ImageSource? source,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // 1. Pick image/video
      final XFile? file = await _imagePicker.pickImage(
        source: source ?? ImageSource.camera,
        imageQuality: 85,
      );

      if (file == null) throw Exception('No file selected');

      // 2. Read file and calculate hash
      final fileBytes = await file.readAsBytes();
      final fileHash = sha256.convert(fileBytes).toString();
      final fileName = file.name;
      final fileSize = fileBytes.length;
      final timestamp = DateTime.now();

      // 3. Upload to Cloudinary (FREE — 25GB)
      String downloadUrl = '';
      bool uploadFailed = false;
      
      try {
        print('☁️ Uploading to Cloudinary...');
        final cloudResult = await _cloudinary.uploadEvidence(
          fileBytes: fileBytes,
          fileName: fileName,
          incidentId: incidentId,
          userId: user.uid,
          resourceType: _getFileType(fileName) == 'video' ? 'video' : 'image',
        );
        if (cloudResult != null) {
          downloadUrl = cloudResult.secureUrl;
          print('☁️ Uploaded to Cloudinary: $downloadUrl');
        } else {
          uploadFailed = true;
          print('⚠️ Cloudinary upload returned null');
        }
      } catch (e) {
        print('⚠️ Cloudinary upload failed: $e');
        uploadFailed = true;
      }

      // 4. Store base64 fallback if Cloudinary failed and image is small enough
      String? imageBase64;
      if (uploadFailed && fileBytes.length < 750000) {
        imageBase64 = base64Encode(fileBytes);
      }

      // 5. Store metadata in Firestore
      final docData = <String, dynamic>{
        'userId': user.uid,
        'incidentId': incidentId,
        'fileName': fileName,
        'fileHash': fileHash,
        'fileSize': fileSize,
        'fileType': _getFileType(fileName),
        'description': description,
        'downloadUrl': downloadUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'verified': !uploadFailed,
        'uploadFailed': uploadFailed,
      };
      if (imageBase64 != null) {
        docData['imageBase64'] = imageBase64;
      }

      final docRef = await _firestore.collection('evidence').add(docData);

      return EvidenceRecord(
        id: docRef.id,
        userId: user.uid,
        incidentId: incidentId,
        fileName: fileName,
        fileHash: fileHash,
        downloadUrl: downloadUrl,
        fileSize: fileSize,
        fileType: _getFileType(fileName),
        description: description,
        timestamp: timestamp,
        imageBase64: imageBase64,
      );
    } catch (e) {
      print('Error storing evidence: $e');
      rethrow;
    }
  }

  /// Get evidence for an incident
  Future<List<EvidenceRecord>> getIncidentEvidence(String incidentId) async {
    try {
      final snapshot = await _firestore
          .collection('evidence')
          .where('incidentId', isEqualTo: incidentId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return EvidenceRecord(
          id: doc.id,
          userId: data['userId'] ?? '',
          incidentId: data['incidentId'] ?? '',
          fileName: data['fileName'] ?? '',
          fileHash: data['fileHash'] ?? '',
          downloadUrl: data['downloadUrl'] ?? data['cloudinaryUrl'] ?? '',
          fileSize: data['fileSize'] ?? 0,
          fileType: data['fileType'] ?? 'image',
          description: data['description'],
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          imageBase64: data['imageBase64'],
          blockchainTxHash: data['blockchainTxHash'],
        );
      }).toList();
    } catch (e) {
      print('Error getting evidence: $e');
      return [];
    }
  }

  /// Verify evidence integrity
  Future<bool> verifyEvidence(String fileHash, String downloadUrl) async {
    try {
      // Download file from Firebase Storage using http package
      final response = await http.get(Uri.parse(downloadUrl));
      
      if (response.statusCode != 200) {
        return false;
      }
      
      // Calculate hash of downloaded file
      final calculatedHash = sha256.convert(response.bodyBytes).toString();
      
      // Verify hashes match
      return calculatedHash == fileHash;
    } catch (e) {
      print('Error verifying evidence: $e');
      return false;
    }
  }

  /// Delete evidence
  Future<void> deleteEvidence(String evidenceId) async {
    try {
      await _firestore.collection('evidence').doc(evidenceId).delete();
    } catch (e) {
      print('Error deleting evidence: $e');
      rethrow;
    }
  }

  // Helper methods
  String _getFileType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      return 'image';
    } else if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) {
      return 'video';
    } else if (['mp3', 'wav', 'aac'].contains(ext)) {
      return 'audio';
    }
    return 'file';
  }
}

/// Evidence Record Model
class EvidenceRecord {
  final String id;
  final String userId;
  final String incidentId;
  final String fileName;
  final String fileHash;
  final String downloadUrl;
  final int fileSize;
  final String fileType;
  final String? description;
  final DateTime timestamp;
  final String? imageBase64;
  final String? blockchainTxHash;

  EvidenceRecord({
    required this.id,
    required this.userId,
    required this.incidentId,
    required this.fileName,
    required this.fileHash,
    required this.downloadUrl,
    required this.fileSize,
    required this.fileType,
    this.description,
    required this.timestamp,
    this.imageBase64,
    this.blockchainTxHash,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'incidentId': incidentId,
      'fileName': fileName,
      'fileHash': fileHash,
      'downloadUrl': downloadUrl,
      'fileSize': fileSize,
      'fileType': fileType,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

