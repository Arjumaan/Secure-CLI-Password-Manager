import 'dart:async';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import '../core/crypto/vault_crypto.dart';
import 'vault_storage.dart';

enum AuthState { locked, unlocked, needsSetup }

class AuthService extends ChangeNotifier {
  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthState _state = AuthState.locked;
  SecretKey? _activeKey;
  Timer? _autoLockTimer;
  int _lockTimeoutSeconds = 300; // 5 minutes default
  int _failedAttempts = 0;
  static const int maxAttempts = 3;

  AuthState get state => _state;
  bool get isUnlocked => _state == AuthState.unlocked;
  SecretKey? get activeKey => _activeKey;
  int get remainingAttempts => maxAttempts - _failedAttempts;

  Future<void> initialize() async {
    final firstTime = await VaultStorage.isFirstLaunch();
    if (firstTime) {
      _state = AuthState.needsSetup;
    } else {
      _state = AuthState.locked;
    }
    notifyListeners();
  }

  /// Sets up initial master password
  Future<bool> setupMasterPassword(String password) async {
    if (password.length < 6) return false;

    final saltBytes = VaultCrypto.generateRandomBytes(16);
    final saltBase64 = base64Url.encode(saltBytes);

    final verifierHash = await VaultCrypto.hashMasterPassword(password, saltBytes);
    await VaultStorage.saveMasterConfig(
      saltBase64: saltBase64,
      verifierHash: verifierHash,
    );

    _activeKey = await VaultCrypto.deriveKey(password, saltBytes);
    _state = AuthState.unlocked;
    _failedAttempts = 0;
    _resetAutoLockTimer();
    notifyListeners();
    return true;
  }

  /// Verifies master password
  Future<bool> verifyMasterPassword(String password) async {
    if (_failedAttempts >= maxAttempts) return false;

    final config = await VaultStorage.loadMasterConfig();
    if (config == null) return false;

    final saltBytes = base64Url.decode(config['salt']!);
    final expectedHash = config['verifier_hash']!;

    final computedHash = await VaultCrypto.hashMasterPassword(password, saltBytes);

    if (computedHash == expectedHash) {
      _activeKey = await VaultCrypto.deriveKey(password, saltBytes);
      _state = AuthState.unlocked;
      _failedAttempts = 0;
      _resetAutoLockTimer();
      notifyListeners();
      return true;
    } else {
      _failedAttempts++;
      notifyListeners();
      return false;
    }
  }

  /// Attempts Biometric unlock (Fingerprint / Face ID / Windows Hello)
  Future<bool> authenticateWithBiometrics() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) return false;

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Scan fingerprint to unlock SecureVault',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return didAuthenticate;
    } catch (_) {
      return false;
    }
  }

  /// Activity tracking for auto-lock timer
  void registerUserActivity() {
    if (isUnlocked) {
      _resetAutoLockTimer();
    }
  }

  void _resetAutoLockTimer() {
    _autoLockTimer?.cancel();
    _autoLockTimer = Timer(Duration(seconds: _lockTimeoutSeconds), () {
      lock();
    });
  }

  /// Locks the vault and clears the encryption key from memory
  void lock() {
    _activeKey = null;
    _autoLockTimer?.cancel();
    _state = AuthState.locked;
    notifyListeners();
  }
}
