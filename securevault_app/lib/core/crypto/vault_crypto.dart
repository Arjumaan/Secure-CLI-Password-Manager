import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class VaultCrypto {
  static final _algorithm = AesGcm.with256Bits();
  static final _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.createSha256(),
    iterations: 480000, // Matches Python PBKDF2 iterations
    bits: 256,
  );

  /// Generates cryptographically secure random bytes
  static Uint8List generateRandomBytes(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  /// Derives a 256-bit symmetric key from master password and salt
  static Future<SecretKey> deriveKey(String masterPassword, List<int> salt) async {
    final secretKey = SecretKey(utf8.encode(masterPassword));
    final derivedKeyBytes = await _pbkdf2.deriveKey(
      secretKey: secretKey,
      nonce: salt,
    );
    return derivedKeyBytes;
  }

  /// Calculates a verification hash of the master password + salt
  static Future<String> hashMasterPassword(String masterPassword, List<int> salt) async {
    final key = await deriveKey(masterPassword, salt);
    final keyBytes = await key.extractBytes();
    final hmac = Hmac.createSha256();
    final mac = await hmac.calculateMac(
      utf8.encode("AUTH_VERIFIER"),
      secretKey: SecretKey(keyBytes),
    );
    return base64Url.encode(mac.bytes);
  }

  /// Encrypts plain text into a structured JSON string containing base64 iv, ciphertext, and tag
  static Future<String> encrypt(String plainText, SecretKey key) async {
    final nonce = _algorithm.newNonce();
    final secretBox = await _algorithm.encrypt(
      utf8.encode(plainText),
      secretKey: key,
      nonce: nonce,
    );

    final payload = {
      'iv': base64Url.encode(secretBox.nonce),
      'cipher': base64Url.encode(secretBox.cipherText),
      'tag': base64Url.encode(secretBox.mac.bytes),
    };

    return jsonEncode(payload);
  }

  /// Decrypts structured JSON payload back into plain text
  static Future<String> decrypt(String encryptedPayload, SecretKey key) async {
    try {
      final decoded = jsonDecode(encryptedPayload) as Map<String, dynamic>;
      final nonce = base64Url.decode(decoded['iv'] as String);
      final cipherText = base64Url.decode(decoded['cipher'] as String);
      final macBytes = base64Url.decode(decoded['tag'] as String);

      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(macBytes),
      );

      final clearTextBytes = await _algorithm.decrypt(
        secretBox,
        secretKey: key,
      );

      return utf8.decode(clearTextBytes);
    } catch (e) {
      throw Exception("Decryption failed. Invalid key or corrupted data: $e");
    }
  }
}
