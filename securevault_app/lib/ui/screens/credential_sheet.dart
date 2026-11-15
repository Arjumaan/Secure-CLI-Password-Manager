import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/credential.dart';
import '../../services/auth_service.dart';
import '../../services/password_generator.dart';
import '../../services/vault_service.dart';
import '../widgets/frosted_glass_card.dart';
import '../widgets/neumorphic_input.dart';
import '../widgets/tactile_button.dart';

class CredentialSheet extends StatefulWidget {
  final Credential? existingCredential;

  const CredentialSheet({Key? key, this.existingCredential}) : super(key: key);

  @override
  State<CredentialSheet> createState() => _CredentialSheetState();
}

class _CredentialSheetState extends State<CredentialSheet> {
  final _websiteController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  bool get isEditing => widget.existingCredential != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final cred = widget.existingCredential!;
      _websiteController.text = cred.website;
      _usernameController.text = cred.username;
      _passwordController.text = cred.decryptedPassword ?? '';
      _notesController.text = cred.decryptedNotes ?? '';
    }
  }

  @override
  void dispose() {
    _websiteController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    final pass = PasswordGenerator.generate(length: 16);
    setState(() {
      _passwordController.text = pass;
    });
  }

  Future<void> _handleSave() async {
    final website = _websiteController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final notes = _notesController.text.trim();

    if (website.isEmpty || username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Website, username, and password are required.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = context.read<AuthService>();
    final vault = context.read<VaultService>();
    final key = auth.activeKey;

    if (key == null) {
      setState(() {
        _isLoading = false;
        _error = 'Vault session expired. Please re-authenticate.';
      });
      return;
    }

    if (isEditing) {
      await vault.updateCredential(
        id: widget.existingCredential!.id,
        website: website,
        username: username,
        password: password,
        notes: notes,
        key: key,
      );
    } else {
      await vault.addCredential(
        website: website,
        username: username,
        password: password,
        notes: notes,
        key: key,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Delete Credential'),
        content: Text('Are you sure you want to delete ${widget.existingCredential!.website}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<VaultService>().deleteCredential(widget.existingCredential!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Credential' : 'New Credential',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (isEditing)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                      onPressed: _handleDelete,
                      tooltip: 'Delete credential',
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Inputs
              NeumorphicInput(
                controller: _websiteController,
                hintText: 'Website or Service (e.g. github.com)',
                prefixIcon: Icons.language,
              ),
              const SizedBox(height: 14),

              NeumorphicInput(
                controller: _usernameController,
                hintText: 'Username or Email',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: NeumorphicInput(
                      controller: _passwordController,
                      hintText: 'Password',
                      prefixIcon: Icons.key_outlined,
                      isPassword: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  TactileButton(
                    onPressed: _generatePassword,
                    padding: const EdgeInsets.all(12),
                    child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              NeumorphicInput(
                controller: _notesController,
                hintText: 'Optional secure notes',
                prefixIcon: Icons.note_outlined,
              ),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              ],

              const SizedBox(height: 24),

              TactileButton(
                isPrimary: true,
                onPressed: _isLoading ? null : _handleSave,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isEditing ? 'Save Changes' : 'Add to Vault',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
