import 'package:uuid/uuid.dart';

class Credential {
  final String id;
  final String website;
  final String username;
  final String encryptedPassword;
  final String? encryptedNotes;
  final DateTime updatedAt;
  final bool isDeleted;

  // Transient in-memory decrypted fields (not stored on disk or synced)
  String? decryptedPassword;
  String? decryptedNotes;

  Credential({
    String? id,
    required this.website,
    required this.username,
    required this.encryptedPassword,
    this.encryptedNotes,
    DateTime? updatedAt,
    this.isDeleted = false,
    this.decryptedPassword,
    this.decryptedNotes,
  })  : id = id ?? const Uuid().v4(),
        updatedAt = updatedAt ?? DateTime.now().toUtc();

  Credential copyWith({
    String? id,
    String? website,
    String? username,
    String? encryptedPassword,
    String? encryptedNotes,
    DateTime? updatedAt,
    bool? isDeleted,
    String? decryptedPassword,
    String? decryptedNotes,
  }) {
    return Credential(
      id: id ?? this.id,
      website: website ?? this.website,
      username: username ?? this.username,
      encryptedPassword: encryptedPassword ?? this.encryptedPassword,
      encryptedNotes: encryptedNotes ?? this.encryptedNotes,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      decryptedPassword: decryptedPassword ?? this.decryptedPassword,
      decryptedNotes: decryptedNotes ?? this.decryptedNotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'website': website,
      'username': username,
      'encryptedPassword': encryptedPassword,
      'encryptedNotes': encryptedNotes,
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  factory Credential.fromJson(Map<String, dynamic> json) {
    return Credential(
      id: json['id'] as String,
      website: json['website'] as String,
      username: json['username'] as String,
      encryptedPassword: json['encryptedPassword'] as String,
      encryptedNotes: json['encryptedNotes'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}
