import 'dart:convert';
import '../../models/credential.dart';

class SyncManifestItem {
  final String id;
  final DateTime updatedAt;

  SyncManifestItem({required this.id, required this.updatedAt});

  Map<String, dynamic> toJson() => {
        'id': id,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SyncManifestItem.fromJson(Map<String, dynamic> json) =>
      SyncManifestItem(
        id: json['id'] as String,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class SyncExchangePackage {
  final String pairingToken;
  final String deviceName;
  final List<Credential> records;

  SyncExchangePackage({
    required this.pairingToken,
    required this.deviceName,
    required this.records,
  });

  Map<String, dynamic> toJson() => {
        'pairingToken': pairingToken,
        'deviceName': deviceName,
        'records': records.map((r) => r.toJson()).toList(),
      };

  factory SyncExchangePackage.fromJson(Map<String, dynamic> json) {
    final list = json['records'] as List<dynamic>;
    return SyncExchangePackage(
      pairingToken: json['pairingToken'] as String,
      deviceName: json['deviceName'] as String,
      records: list.map((e) => Credential.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
