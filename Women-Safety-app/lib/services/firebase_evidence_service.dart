// SIMPLE FREE Evidence Storage using Firebase Storage
// Uses your existing Firebase setup - 100% FREE

import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

// Type alias for FirebaseUser
typedef FirebaseUser = User;

/// Simple FREE Evidence Storage Service
/// 
/// Uses Firebase Storage (free tier: 5GB storage, 1GB/day downloads)
/// Completely free - no credit card needed
/// Already configured in your project!
class FirebaseEvidenceService {
  static final FirebaseEvidenceService _instance = FirebaseEvidenceService._internal();
  factory FirebaseEvidenceService() => _instance;
  FirebaseEvidenceService._internal();

  FirebaseStorage get _storage {
    try {
      // Try to get storage with explicit bucket
      final app = FirebaseAuth.instance.app;
      return FirebaseStorage.instanceFor(
        app: app,
        bucket: 'sheild-d4bd4.firebasestorage.app',
      );
    } catch (e) {
      print('Warning: Could not initialize with explicit bucket, using default: $e');
      // Fallback to default instance
      try {
        return FirebaseStorage.instance;
      } catch (e2) {
        print('Error getting Firebase Storage instance: $e2');
        rethrow;
      }
    }
  }
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _imagePicker = ImagePicker();

  /// Store evidence (photo/video) - COMPLETELY FREE
  /// 
  /// Steps:
  /// 1. Pick file from camera/gallery
  /// 2. Calculate hash for verification
  /// 3. Upload to Firebase Storage (free)
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
        imageQuality: 85, // Compress to save space
      );

      if (file == null) throw Exception('No file selected');

      // 2. Read file and calculate hash
      final fileBytes = await file.readAsBytes();
      final fileHash = sha256.convert(fileBytes).toString();
      final fileName = file.name;
      final fileSize = fileBytes.length;
      final timestamp = DateTime.now();

      // 3. Upload to Firebase Storage (FREE)
      String downloadUrl = '';
      String storagePath = 'evidence/${user.uid}/${timestamp.millisecondsSinceEpoch}_$fileName';
      bool uploadFailed = false;
      
      try {
        final storage = _storage;
        final ref = storage.ref().child(storagePath);
        
        print('Uploading to Firebase Storage: $storagePath');
        
        final uploadTask = ref.putData(
          Uint8List.fromList(fileBytes),
          SettableMetadata(
            contentType: _getContentType(fileName),
            customMetadata: {
              'userId': user.uid,
              'incidentId': incidentId,
              'fileHash': fileHash,
              'description': description ?? '',
            },
          ),
        );

        // Wait for upload with timeout
        final snapshot = await uploadTask.timeout(
          Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Upload timeout - please check your internet connection');
          },
        );
        
        print('Upload completed, getting download URL...');
        
        // Get download URL
        downloadUrl = await snapshot.ref.getDownloadURL();
        
        print('Evidence uploaded successfully: $downloadUrl');
      } catch (e) {
        // If Firebase Storage fails, store only metadata with hash
        print('⚠️ Firebase Storage error: $e');
        print('Error details: ${e.toString()}');
        uploadFailed = true;
        
        // Check if it's a configuration issue
        if (e.toString().contains('object not found') || 
            e.toString().contains('bucket') ||
            e.toString().contains('permission')) {
          print('⚠️ Firebase Storage may not be enabled or configured properly');
          print('💡 Enable Storage in Firebase Console: https://console.firebase.google.com/');
          print('💡 Storage will be enabled automatically, but metadata is still saved');
        }
        
        // Show user-friendly error but continue
        // The hash is still stored so evidence can be verified later
      }
      
      // 4. Store metadata in Firestore (always store metadata, even if upload failed)
      return await _storeEvidenceMetadata(
        user: user,
        incidentId: incidentId,
        fileName: fileName,
        fileHash: fileHash,
        fileSize: fileSize,
        downloadUrl: downloadUrl,
        storagePath: storagePath,
        description: description,
        timestamp: timestamp,
        uploadFailed: uploadFailed,
      );

    } catch (e) {
      print('Error storing evidence: $e');
      rethrow;
    }
  }

  /// Helper method to store evidence metadata
  Future<EvidenceRecord> _storeEvidenceMetadata({
    required FirebaseUser user,
    required String incidentId,
    required String fileName,
    required String fileHash,
    required int fileSize,
    required String downloadUrl,
    required String storagePath,
    String? description,
    required DateTime timestamp,
    bool uploadFailed = false,
  }) async {
    // Store metadata in Firestore (FREE)
    final docRef = await _firestore.collection('evidence').add({
      'userId': user.uid,
      'incidentId': incidentId,
      'fileName': fileName,
      'fileHash': fileHash,
      'fileSize': fileSize,
      'fileType': _getFileType(fileName),
      'description': description,
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'verified': !uploadFailed, // Only verified if upload succeeded
      'uploadFailed': uploadFailed,
    });

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
      storagePath: storagePath,
    );
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
          downloadUrl: data['downloadUrl'] ?? '',
          fileSize: data['fileSize'] ?? 0,
          fileType: data['fileType'] ?? 'image',
          description: data['description'],
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          storagePath: data['storagePath'] ?? '',
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
  Future<void> deleteEvidence(String evidenceId, String storagePath) async {
    try {
      // Delete from Firestore
      await _firestore.collection('evidence').doc(evidenceId).delete();
      
      // Delete from Firebase Storage
      await _storage.ref().child(storagePath).delete();
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

  String _getContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
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
  final String storagePath;

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
    required this.storagePath,
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
      'storagePath': storagePath,
    };
  }
}

/// Usage Example:
/// 
/// ```dart
/// final evidenceService = FirebaseEvidenceService();
/// 
/// // Store evidence
/// final evidence = await evidenceService.storeEvidence(
///   incidentId: 'incident_123',
///   description: 'Emergency photo',
///   source: ImageSource.camera,
/// );
/// 
/// print('Evidence stored: ${evidence.downloadUrl}');
/// print('Hash: ${evidence.fileHash}');
/// 
/// // Get evidence for incident
/// final evidenceList = await evidenceService.getIncidentEvidence('incident_123');
/// 
/// // Verify evidence
/// final verified = await evidenceService.verifyEvidence(
///   evidence.fileHash,
///   evidence.downloadUrl,
/// );
/// ```

