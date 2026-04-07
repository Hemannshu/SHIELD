// AES-256 Client-Side Encryption Service
// Encrypts evidence files before upload (as described in research paper)
// Uses AES-256-CBC with PKCS7 padding

import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

/// AES-256 Encryption Service for client-side evidence protection.
///
/// As described in the SHEILD research paper:
/// - Evidence is encrypted on-device before leaving the phone
/// - Uses AES-256-CBC with random IV per encryption
/// - Encryption key derived from user credentials + app secret
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  /// Encrypt file bytes with AES-256-CBC.
  ///
  /// Returns a map containing:
  /// - 'encryptedBytes': The encrypted file data (Uint8List)
  /// - 'iv': The initialization vector used (base64 string)
  /// - 'keyHash': SHA-256 hash of the key used (for verification, not the key itself)
  Map<String, dynamic> encryptBytes({
    required Uint8List plainBytes,
    required String encryptionKey,
  }) {
    final key = _deriveKey(encryptionKey);
    final iv = encrypt.IV.fromSecureRandom(16);

    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
    );

    final encrypted = encrypter.encryptBytes(plainBytes, iv: iv);

    return {
      'encryptedBytes': Uint8List.fromList(encrypted.bytes),
      'iv': iv.base64,
      'keyHash': sha256.convert(utf8.encode(encryptionKey)).toString(),
    };
  }

  /// Decrypt file bytes with AES-256-CBC.
  Uint8List decryptBytes({
    required Uint8List encryptedBytes,
    required String encryptionKey,
    required String ivBase64,
  }) {
    final key = _deriveKey(encryptionKey);
    final iv = encrypt.IV.fromBase64(ivBase64);

    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
    );

    final encrypted = encrypt.Encrypted(encryptedBytes);
    final decrypted = encrypter.decryptBytes(encrypted, iv: iv);

    return Uint8List.fromList(decrypted);
  }

  /// Derive a 256-bit AES key from a passphrase using SHA-256.
  encrypt.Key _deriveKey(String passphrase) {
    final hash = sha256.convert(utf8.encode(passphrase));
    return encrypt.Key(Uint8List.fromList(hash.bytes));
  }

  /// Generate a secure encryption key for a user.
  ///
  /// Combines userId + app secret + timestamp salt to create
  /// a unique per-user encryption key.
  static String generateUserEncryptionKey({
    required String userId,
    required String appSecret,
  }) {
    final combined = '$userId:$appSecret:SHEILD_AES256';
    return sha256.convert(utf8.encode(combined)).toString();
  }

  /// Compute SHA-256 hash of raw (unencrypted) file bytes.
  ///
  /// This hash is what gets stored on the blockchain for
  /// tamper-proof verification. The hash is computed BEFORE
  /// encryption so that verifiers can decrypt and re-hash
  /// to confirm integrity.
  static String computeFileHash(Uint8List fileBytes) {
    return sha256.convert(fileBytes).toString();
  }
}
