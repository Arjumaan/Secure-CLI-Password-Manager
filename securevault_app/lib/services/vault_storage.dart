import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/credential.dart';

class VaultStorage {
  static const _storage = FlutterSecureStorage();
  static const String _keySalt = 'securevault_salt';
  static const String _keyMasterVerifier = 'securevault_verifier';
  static const String _keyVaultFile = 'vault_data.json';

  static Directory? _overrideDirectory;

  static void setOverrideDirectory(Directory dir) {
    _overrideDirectory = dir;
  }

  static Future<Directory> _getAppDir() async {
    if (_overrideDirectory != null) return _overrideDirectory!;
    
    // Windows fallback: local AppData / SecureVault directory
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? Directory.current.path;
      final dir = Directory('$appData/SecureVault');
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir;
    }

    // Android/Linux/macOS default
    final dir = Directory('${Directory.systemTemp.path}/SecureVault');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Check if master password has ever been configured
  static Future<bool> isFirstLaunch() async {
    final verifier = await _storage.read(key: _keyMasterVerifier);
    if (verifier != null && verifier.isNotEmpty) return false;

    // Also check filesystem backup config
    final dir = await _getAppDir();
    final configFile = File('${dir.path}/config.json');
    return !(await configFile.exists());
  }

  /// Saves master credentials (salt + verifier hash)
  static Future<void> saveMasterConfig({
    required String saltBase64,
    required String verifierHash,
  }) async {
    await _storage.write(key: _keySalt, value: saltBase64);
    await _storage.write(key: _keyMasterVerifier, value: verifierHash);

    // Write to config.json for backup/portability
    final dir = await _getAppDir();
    final configFile = File('${dir.path}/config.json');
    final configData = {
      'salt': saltBase64,
      'verifier_hash': verifierHash,
      'configured_at': DateTime.now().toUtc().toIso8601String(),
    };
    await configFile.writeAsString(jsonEncode(configData), flush: true);
  }

  /// Loads salt and verifier
  static Future<Map<String, String>?> loadMasterConfig() async {
    final salt = await _storage.read(key: _keySalt);
    final verifier = await _storage.read(key: _keyMasterVerifier);

    if (salt != null && verifier != null) {
      return {'salt': salt, 'verifier_hash': verifier};
    }

    final dir = await _getAppDir();
    final configFile = File('${dir.path}/config.json');
    if (await configFile.exists()) {
      final content = await configFile.readAsString();
      final map = jsonDecode(content) as Map<String, dynamic>;
      return {
        'salt': map['salt'] as String,
        'verifier_hash': map['verifier_hash'] as String,
      };
    }

    return null;
  }

  /// Loads all encrypted credentials from local storage
  static Future<List<Credential>> loadVaultEntries() async {
    final dir = await _getAppDir();
    final vaultFile = File('${dir.path}/$_keyVaultFile');

    if (!await vaultFile.exists()) return [];

    try {
      final content = await vaultFile.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      return list
          .map((e) => Credential.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Saves the full list of encrypted credentials to local storage atomically
  static Future<void> saveVaultEntries(List<Credential> entries) async {
    final dir = await _getAppDir();
    final vaultFile = File('${dir.path}/$_keyVaultFile');
    final tmpFile = File('${dir.path}/$_keyVaultFile.tmp');

    final jsonString = jsonEncode(entries.map((e) => e.toJson()).toList());
    await tmpFile.writeAsString(jsonString, flush: true);
    if (await vaultFile.exists()) await vaultFile.delete();
    await tmpFile.rename(vaultFile.path);
  }
}
