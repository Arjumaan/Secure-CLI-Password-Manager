import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/sync/sync_service.dart';
import '../../core/theme/app_colors.dart';
import '../../services/vault_service.dart';
import '../widgets/frosted_glass_card.dart';
import '../widgets/neumorphic_box.dart';
import '../widgets/neumorphic_input.dart';
import '../widgets/tactile_button.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({Key? key}) : super(key: key);

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _ipController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    // Default desktop to Host tab (0), mobile to Connect tab (1)
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: Platform.isAndroid ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ipController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _parseQrPayload(String raw) {
    try {
      final uri = Uri.parse(raw);
      if (uri.scheme == 'securevault') {
        final ip = uri.queryParameters['ip'];
        final token = uri.queryParameters['token'];
        if (ip != null) _ipController.text = ip;
        if (token != null) _tokenController.text = token;
        setState(() => _isScanning = false);
        _handleConnectSync();
      }
    } catch (_) {}
  }

  Future<void> _handleConnectSync() async {
    final ip = _ipController.text.trim();
    final token = _tokenController.text.trim();
    if (ip.isEmpty || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Host IP and Pairing Token')),
      );
      return;
    }

    final sync = context.read<SyncService>();
    final vault = context.read<VaultService>();
    await sync.syncWithHost(
      hostIp: ip,
      port: sync.port,
      token: token,
      vaultService: vault,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncService>();
    final vault = context.watch<VaultService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Local Wi-Fi Sync',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Synchronize your encrypted vault between your Laptop (.exe) and Phone (.apk) without any cloud server.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),

                  // Mode Tab Bar
                  NeumorphicBox(
                    padding: const EdgeInsets.all(6.0),
                    borderRadius: 14.0,
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowDark.withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      tabs: const [
                        Tab(text: 'Laptop Host Mode'),
                        Tab(text: 'Connect & Sync'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tab Views
                  SizedBox(
                    height: 480,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Host Mode
                        _buildHostTab(sync, vault),
                        // Tab 2: Connect / Scan Mode
                        _buildConnectTab(sync),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHostTab(SyncService sync, VaultService vault) {
    return FrostedGlassCard(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!sync.isHosting) ...[
            const Icon(Icons.wifi_tethering, size: 64, color: AppColors.primary),
            const SizedBox(height: 18),
            const Text(
              'Host Sync Hub',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Broadcast on your local Wi-Fi to pair with your Android device.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TactileButton(
              isPrimary: true,
              onPressed: () => sync.startHostServer(vault),
              child: const Text('Start Host Server', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ] else ...[
            Text(
              'Sync Hub Active: ${sync.localIp}:${sync.port}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.securityGreen),
            ),
            const SizedBox(height: 14),

            // QR Code
            if (sync.qrCodePayload != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppColors.shadowDark.withOpacity(0.2), blurRadius: 10),
                  ],
                ),
                child: QrImageView(
                  data: sync.qrCodePayload!,
                  version: QrVersions.auto,
                  size: 180.0,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Pairing Token: ${sync.pairingToken}',
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Open SecureVault on Android, choose "Connect & Sync", and scan this QR code.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            TactileButton(
              onPressed: () => sync.stopHostServer(),
              child: const Text('Stop Server'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectTab(SyncService sync) {
    if (_isScanning) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            MobileScanner(
              onDetect: (capture) {
                final barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _parseQrPayload(barcode.rawValue!);
                    break;
                  }
                }
              },
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => setState(() => _isScanning = false),
              ),
            ),
          ],
        ),
      );
    }

    return FrostedGlassCard(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TactileButton(
                  isPrimary: true,
                  onPressed: () => setState(() => _isScanning = true),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Scan QR on Laptop', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Center(child: Text('— OR ENTER MANUALLY —', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold))),
          const SizedBox(height: 18),

          NeumorphicInput(
            controller: _ipController,
            hintText: 'Laptop IP (e.g. 192.168.1.10)',
            prefixIcon: Icons.lan,
          ),
          const SizedBox(height: 14),

          NeumorphicInput(
            controller: _tokenController,
            hintText: 'Pairing Token',
            prefixIcon: Icons.key,
          ),
          const SizedBox(height: 20),

          TactileButton(
            onPressed: sync.isSyncing ? null : _handleConnectSync,
            child: sync.isSyncing
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Sync Now', style: TextStyle(fontWeight: FontWeight.w600)),
          ),

          if (sync.lastSyncStatus != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                sync.lastSyncStatus!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
