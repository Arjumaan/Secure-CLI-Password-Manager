import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import '../core/crypto/vault_crypto.dart';
import '../models/credential.dart';
import 'vault_storage.dart';

class VaultService extends ChangeNotifier {
  List<Credential> _entries = [];
  bool _isLoading = false;

  List<Credential> get entries => _entries.where((e) => !e.isDeleted).toList();
  List<Credential> get allEntriesWithTombstones => _entries;
  bool get isLoading => _isLoading;

  Future<void> loadVault() async {
    _isLoading = true;
    notifyListeners();

    _entries = await VaultStorage.loadVaultEntries();

    _isLoading = false;
    notifyListeners();
  }

  /// Adds a new credential encrypted with the active session key
  Future<bool> addCredential({
    required String website,
    required String username,
    required String password,
    String? notes,
    required SecretKey key,
  }) async {
    final encryptedPassword = await VaultCrypto.encrypt(password, key);
    String? encryptedNotes;
    if (notes != null && notes.isNotEmpty) {
      encryptedNotes = await VaultCrypto.encrypt(notes, key);
    }

    final newCredential = Credential(
      website: website.trim(),
      username: username.trim(),
      encryptedPassword: encryptedPassword,
      encryptedNotes: encryptedNotes,
      updatedAt: DateTime.now().toUtc(),
      decryptedPassword: password,
      decryptedNotes: notes,
    );

    _entries.add(newCredential);
    await VaultStorage.saveVaultEntries(_entries);
    notifyListeners();
    return true;
  }

  /// Decrypts the password for a specific credential
  Future<String> decryptPassword(Credential credential, SecretKey key) async {
    if (credential.decryptedPassword != null) {
      return credential.decryptedPassword!;
    }
    final decrypted = await VaultCrypto.decrypt(credential.encryptedPassword, key);
    credential.decryptedPassword = decrypted;
    return decrypted;
  }

  /// Decrypts notes if present
  Future<String?> decryptNotes(Credential credential, SecretKey key) async {
    if (credential.encryptedNotes == null) return null;
    if (credential.decryptedNotes != null) {
      return credential.decryptedNotes!;
    }
    final decrypted = await VaultCrypto.decrypt(credential.encryptedNotes!, key);
    credential.decryptedNotes = decrypted;
    return decrypted;
  }

  /// Updates an existing credential
  Future<bool> updateCredential({
    required String id,
    String? website,
    String? username,
    String? password,
    String? notes,
    required SecretKey key,
  }) async {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) return false;

    final existing = _entries[index];
    String encryptedPassword = existing.encryptedPassword;
    if (password != null && password.isNotEmpty) {
      encryptedPassword = await VaultCrypto.encrypt(password, key);
    }

    String? encryptedNotes = existing.encryptedNotes;
    if (notes != null) {
      encryptedNotes = notes.isNotEmpty
          ? await VaultCrypto.encrypt(notes, key)
          : null;
    }

    _entries[index] = existing.copyWith(
      website: website?.trim() ?? existing.website,
      username: username?.trim() ?? existing.username,
      encryptedPassword: encryptedPassword,
      encryptedNotes: encryptedNotes,
      updatedAt: DateTime.now().toUtc(),
      decryptedPassword: password ?? existing.decryptedPassword,
      decryptedNotes: notes ?? existing.decryptedNotes,
    );

    await VaultStorage.saveVaultEntries(_entries);
    notifyListeners();
    return true;
  }

  /// Soft deletes an entry (marks tombstone for peer sync)
  Future<bool> deleteCredential(String id) async {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) return false;

    _entries[index] = _entries[index].copyWith(
      isDeleted: true,
      updatedAt: DateTime.now().toUtc(),
    );

    await VaultStorage.saveVaultEntries(_entries);
    notifyListeners();
    return true;
  }

  /// Filter entries by website or username
  List<Credential> search(String query) {
    if (query.isEmpty) return entries;
    final lower = query.toLowerCase();
    return entries.where((e) {
      return e.website.toLowerCase().contains(lower) ||
          e.username.toLowerCase().contains(lower);
    }).toList();
  }

  /// Merges peer sync records using Last-Write-Wins CRDT strategy
  Future<int> mergeSyncEntries(List<Credential> incomingEntries) async {
    int updatedCount = 0;
    final Map<String, Credential> map = {
      for (var entry in _entries) entry.id: entry
    };

    for (var incoming in incomingEntries) {
      if (!map.containsKey(incoming.id)) {
        map[incoming.id] = incoming;
        updatedCount++;
      } else {
        final current = map[incoming.id]!;
        if (incoming.updatedAt.isAfter(current.updatedAt)) {
          map[incoming.id] = incoming;
          updatedCount++;
        }
      }
    }

    if (updatedCount > 0) {
      _entries = map.values.toList();
      await VaultStorage.saveVaultEntries(_entries);
      notifyListeners();
    }

    return updatedCount;
  }

  /// Exports decrypted vault to CSV format
  Future<String> exportToCsv(SecretKey key) async {
    final buffer = StringBuffer();
    buffer.writeln('id,website,username,password,notes,updated_at');

    for (var entry in entries) {
      final pass = await decryptPassword(entry, key);
      final notes = await decryptNotes(entry, key) ?? '';
      buffer.writeln(
        '"${entry.id}","${entry.website}","${entry.username}","$pass","$notes","${entry.updatedAt.toIso8601String()}"',
      );
    }

    return buffer.toString();
  }
}
