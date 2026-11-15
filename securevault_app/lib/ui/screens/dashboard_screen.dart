import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/credential.dart';
import '../../services/auth_service.dart';
import '../../services/vault_service.dart';
import '../widgets/frosted_glass_card.dart';
import '../widgets/neumorphic_box.dart';
import '../widgets/neumorphic_input.dart';
import '../widgets/tactile_button.dart';
import 'credential_sheet.dart';
import 'generator_screen.dart';
import 'sync_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _searchController = TextEditingController();
  int _navIndex = 0; // 0: Vault, 1: Generator, 2: Wi-Fi Sync

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCredentialSheet([Credential? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CredentialSheet(existingCredential: existing),
    );
  }

  Future<void> _copyPassword(Credential cred) async {
    final auth = context.read<AuthService>();
    final vault = context.read<VaultService>();
    final key = auth.activeKey;

    if (key == null) return;

    final pass = await vault.decryptPassword(cred, key);
    Clipboard.setData(ClipboardData(text: pass));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password copied! Clipboard auto-clears in 30 seconds.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _copyUsername(Credential cred) {
    Clipboard.setData(ClipboardData(text: cred.username));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Username copied to clipboard.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _exportCsv() async {
    final auth = context.read<AuthService>();
    final vault = context.read<VaultService>();
    final key = auth.activeKey;
    if (key == null) return;

    final csv = await vault.exportToCsv(key);
    Clipboard.setData(ClipboardData(text: csv));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Decrypted CSV copied to clipboard (handle with caution)!'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
      bottomNavigationBar: isDesktop ? null : _buildMobileBottomNav(),
      floatingActionButton: (!isDesktop && _navIndex == 0)
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => _openCredentialSheet(),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // --- DESKTOP LAYOUT (Windows .exe) ---
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Frosted Sidebar
        Container(
          width: 240,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.glassSurface,
            border: const Border(right: BorderSide(color: AppColors.glassBorder, width: 1.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo Header
              const Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.primary, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'SecureVault',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              _buildSidebarItem(0, Icons.lock_outline, 'My Vault'),
              const SizedBox(height: 10),
              _buildSidebarItem(1, Icons.auto_awesome, 'Generator'),
              const SizedBox(height: 10),
              _buildSidebarItem(2, Icons.wifi_sync, 'Wi-Fi Sync'),
              const Spacer(),

              // Quick Export CSV
              ListTile(
                dense: true,
                leading: const Icon(Icons.download_outlined, size: 20, color: AppColors.textSecondary),
                title: const Text('Export CSV', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                onTap: _exportCsv,
              ),

              const Divider(color: AppColors.glassBorder),
              const SizedBox(height: 8),

              // Lock Vault Button
              TactileButton(
                onPressed: () => context.read<AuthService>().lock(),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, size: 16, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Text('Lock Vault', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Main Content Area
        Expanded(
          child: IndexedStack(
            index: _navIndex,
            children: [
              _buildVaultContent(isDesktop: true),
              const GeneratorScreen(),
              const SyncScreen(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String title) {
    final isSelected = _navIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _navIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.shadowDark.withOpacity(0.2),
                    offset: const Offset(2, 4),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MOBILE LAYOUT (Android .apk) ---
  Widget _buildMobileLayout() {
    return IndexedStack(
      index: _navIndex,
      children: [
        _buildVaultContent(isDesktop: false),
        const GeneratorScreen(),
        const SyncScreen(),
      ],
    );
  }

  Widget _buildMobileBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        border: const Border(top: BorderSide(color: AppColors.glassBorder, width: 1.5)),
      ),
      child: NavigationBar(
        selectedIndex: _navIndex,
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.primary.withOpacity(0.15),
        onDestinationSelected: (idx) => setState(() => _navIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.lock_outline),
            selectedIcon: Icon(Icons.lock, color: AppColors.primary),
            label: 'Vault',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome, color: AppColors.primary),
            label: 'Generator',
          ),
          NavigationDestination(
            icon: Icon(Icons.wifi_sync),
            selectedIcon: Icon(Icons.wifi_sync, color: AppColors.primary),
            label: 'Sync',
          ),
        ],
      ),
    );
  }

  // --- VAULT LIST VIEW ---
  Widget _buildVaultContent({required bool isDesktop}) {
    final vault = context.watch<VaultService>();
    final entries = vault.search(_searchController.text);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 36.0 : 20.0,
        vertical: 24.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Passwords',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    '${entries.length} items securely stored',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              if (isDesktop)
                TactileButton(
                  isPrimary: true,
                  onPressed: () => _openCredentialSheet(),
                  child: const Row(
                    children: [
                      Icon(Icons.add, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Add Credential', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                  onPressed: () => context.read<AuthService>().lock(),
                  tooltip: 'Lock vault',
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Search Bar
          NeumorphicInput(
            controller: _searchController,
            hintText: 'Search websites or accounts...',
            prefixIcon: Icons.search,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // Credential Card List
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        const Text(
                          'No credentials found',
                          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (ctx, index) {
                      final cred = entries[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: FrostedGlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          onTap: () => _openCredentialSheet(cred),
                          child: Row(
                            children: [
                              // Avatar / Icon
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.shadowDark.withOpacity(0.2),
                                      offset: const Offset(2, 3),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    cred.website.isNotEmpty ? cred.website[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Website & Username
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cred.website,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      cred.username,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Quick Copy Actions
                              IconButton(
                                icon: const Icon(Icons.person_outline, size: 20, color: AppColors.textSecondary),
                                onPressed: () => _copyUsername(cred),
                                tooltip: 'Copy username',
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20, color: AppColors.primary),
                                onPressed: () => _copyPassword(cred),
                                tooltip: 'Copy password',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
