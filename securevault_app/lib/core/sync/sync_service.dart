import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../../models/credential.dart';
import '../../services/vault_service.dart';
import 'sync_payload.dart';

class SyncService extends ChangeNotifier {
  HttpServer? _server;
  String? _localIp;
  int _port = 52443;
  String? _pairingToken;
  bool _isHosting = false;
  bool _isSyncing = false;
  String? _lastSyncStatus;
  DateTime? _lastSyncTime;

  bool get isHosting => _isHosting;
  bool get isSyncing => _isSyncing;
  String? get localIp => _localIp;
  int get port => _port;
  String? get pairingToken => _pairingToken;
  String? get lastSyncStatus => _lastSyncStatus;
  DateTime? get lastSyncTime => _lastSyncTime;

  String? get qrCodePayload {
    if (_localIp == null || _pairingToken == null) return null;
    return 'securevault://sync?ip=$_localIp&port=$_port&token=$_pairingToken';
  }

  /// Discover primary local network IP address (Wi-Fi)
  Future<String?> _getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.address.startsWith(RegExp(r'192\.168\.|10\.|172\.'))) {
            return addr.address;
          }
        }
      }
      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        return interfaces.first.addresses.first.address;
      }
    } catch (_) {}
    return '127.0.0.1';
  }

  /// Start Local Sync Server (Typically on Desktop / Laptop)
  Future<bool> startHostServer(VaultService vaultService) async {
    if (_isHosting) return true;

    try {
      _localIp = await _getLocalIpAddress();
      _pairingToken = _generateRandomToken(8);

      final router = Router();

      // Ping check
      router.get('/ping', (Request request) {
        return Response.ok(jsonEncode({'status': 'ready', 'app': 'SecureVault'}));
      });

      // Sync exchange endpoint
      router.post('/sync', (Request request) async {
        final bodyString = await request.readAsString();
        final body = jsonDecode(bodyString) as Map<String, dynamic>;

        final incomingToken = body['pairingToken'] as String?;
        if (incomingToken != _pairingToken) {
          return Response.forbidden(jsonEncode({'error': 'Invalid pairing token'}));
        }

        final package = SyncExchangePackage.fromJson(body);
        
        // Merge incoming records from the mobile client
        await vaultService.mergeSyncEntries(package.records);

        // Respond with host's full records (all entries + tombstones)
        final hostRecords = vaultService.allEntriesWithTombstones;
        final responsePayload = SyncExchangePackage(
          pairingToken: _pairingToken!,
          deviceName: Platform.localHostname,
          records: hostRecords,
        );

        _lastSyncTime = DateTime.now();
        _lastSyncStatus = 'Synced with ${package.deviceName}';
        notifyListeners();

        return Response.ok(
          jsonEncode(responsePayload.toJson()),
          headers: {'content-type': 'application/json'},
        );
      });

      final handler = const Pipeline().addMiddleware(logRequests()).addHandler(router);
      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, _port);
      _isHosting = true;
      notifyListeners();
      return true;
    } catch (e) {
      _lastSyncStatus = 'Failed to start sync host: $e';
      notifyListeners();
      return false;
    }
  }

  /// Stop host server
  Future<void> stopHostServer() async {
    await _server?.close(force: true);
    _server = null;
    _isHosting = false;
    notifyListeners();
  }

  /// Mobile Client: Connect to Host and execute bidirectional sync
  Future<bool> syncWithHost({
    required String hostIp,
    required int port,
    required String token,
    required VaultService vaultService,
  }) async {
    _isSyncing = true;
    _lastSyncStatus = 'Connecting to $hostIp:$port...';
    notifyListeners();

    try {
      final uri = Uri.parse('http://$hostIp:$port/sync');
      final outboundPackage = SyncExchangePackage(
        pairingToken: token,
        deviceName: Platform.isAndroid ? 'Android Device' : Platform.localHostname,
        records: vaultService.allEntriesWithTombstones,
      );

      final response = await http
          .post(
            uri,
            headers: {'content-type': 'application/json'},
            body: jsonEncode(outboundPackage.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final incomingPackage = SyncExchangePackage.fromJson(decoded);

        final mergedCount = await vaultService.mergeSyncEntries(incomingPackage.records);
        _lastSyncTime = DateTime.now();
        _lastSyncStatus = 'Sync successful ($mergedCount items merged)';
        _isSyncing = false;
        notifyListeners();
        return true;
      } else {
        _lastSyncStatus = 'Sync failed: Server returned ${response.statusCode}';
        _isSyncing = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _lastSyncStatus = 'Sync error: $e';
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  String _generateRandomToken(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
