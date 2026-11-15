import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/sync/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/vault_service.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  await authService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<VaultService>(create: (_) => VaultService()),
        ChangeNotifierProvider<SyncService>(create: (_) => SyncService()),
      ],
      child: const SecureVaultApp(),
    ),
  );
}

class SecureVaultApp extends StatelessWidget {
  const SecureVaultApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecureVault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppRootGate(),
    );
  }
}

class AppRootGate extends StatelessWidget {
  const AppRootGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    // Activity detector to reset auto-lock timeout
    return Listener(
      onPointerDown: (_) => auth.registerUserActivity(),
      child: auth.isUnlocked
          ? const DashboardScreen()
          : const LockScreen(),
    );
  }
}
