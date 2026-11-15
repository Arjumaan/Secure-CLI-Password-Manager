import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/vault_service.dart';
import '../widgets/frosted_glass_card.dart';
import '../widgets/neumorphic_input.dart';
import '../widgets/tactile_button.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({Key? key}) : super(key: key);

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleUnlock(AuthService auth) async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your master password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await auth.verifyMasterPassword(password);
    if (!mounted) return;

    if (success) {
      await context.read<VaultService>().loadVault();
    } else {
      setState(() {
        _isLoading = false;
        if (auth.remainingAttempts > 0) {
          _errorMessage =
              'Incorrect master password. ${auth.remainingAttempts} attempt(s) remaining.';
        } else {
          _errorMessage = 'Vault locked! Too many failed attempts.';
        }
      });
    }
  }

  Future<void> _handleSetup(AuthService auth) async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await auth.setupMasterPassword(password);
    if (!mounted) return;

    if (success) {
      await context.read<VaultService>().loadVault();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to create vault config.';
      });
    }
  }

  Future<void> _handleBiometrics(AuthService auth) async {
    final success = await auth.authenticateWithBiometrics();
    if (success && mounted) {
      // Biometrics unlocked successfully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric unlock verified!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isSetup = auth.state == AuthState.needsSetup;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: FrostedGlassCard(
                blur: 20.0,
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Shield Icon with Soft Radial Glow
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        size: 38,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'SecureVault',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSetup
                          ? 'Create your master password to protect your vault.'
                          : 'Enter your master password to unlock your vault.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),

                    // Master Password Input
                    NeumorphicInput(
                      controller: _passwordController,
                      hintText: isSetup ? 'Create Master Password' : 'Master Password',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      onSubmitted: (_) {
                        if (isSetup) {
                          _handleSetup(auth);
                        } else {
                          _handleUnlock(auth);
                        }
                      },
                    ),

                    if (isSetup) ...[
                      const SizedBox(height: 16),
                      NeumorphicInput(
                        controller: _confirmController,
                        hintText: 'Confirm Master Password',
                        prefixIcon: Icons.check_circle_outline,
                        isPassword: true,
                        onSubmitted: (_) => _handleSetup(auth),
                      ),
                    ],

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.danger.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.danger,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Unlock / Setup Action Button
                    TactileButton(
                      isPrimary: true,
                      width: double.infinity,
                      onPressed: _isLoading || auth.remainingAttempts <= 0
                          ? null
                          : () => isSetup ? _handleSetup(auth) : _handleUnlock(auth),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isSetup ? 'Create Vault' : 'Unlock Vault',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),

                    // Biometric Unlock Alternative (if not setup)
                    if (!isSetup) ...[
                      const SizedBox(height: 18),
                      TextButton.icon(
                        onPressed: () => _handleBiometrics(auth),
                        icon: const Icon(Icons.fingerprint, color: AppColors.primary),
                        label: const Text(
                          'Unlock with Biometrics',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
