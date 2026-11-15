import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../services/password_generator.dart';
import '../widgets/frosted_glass_card.dart';
import '../widgets/neumorphic_box.dart';
import '../widgets/tactile_button.dart';

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({Key? key}) : super(key: key);

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  int _length = 16;
  bool _useUpper = true;
  bool _useDigits = true;
  bool _useSymbols = true;
  bool _avoidAmbiguous = true;
  String _generatedPassword = '';

  @override
  void initState() {
    super.initState();
    _regenerate();
  }

  void _regenerate() {
    setState(() {
      _generatedPassword = PasswordGenerator.generate(
        length: _length,
        useUpper: _useUpper,
        useDigits: _useDigits,
        useSymbols: _useSymbols,
        avoidAmbiguous: _avoidAmbiguous,
      );
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generatedPassword));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password copied! Clipboard will auto-clear in 30s.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strength = PasswordGenerator.evaluateStrength(_generatedPassword);

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
                    'Password Generator',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Generate cryptographically secure passwords tailored to your requirements.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  // Display & Strength Card
                  FrostedGlassCard(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Password Text
                        SelectableText(
                          _generatedPassword,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Strength Meter & Badge
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: strength.score,
                                  minHeight: 8,
                                  backgroundColor: AppColors.sunkenShadow.withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(strength.color),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: strength.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: strength.color.withOpacity(0.3)),
                              ),
                              child: Text(
                                strength.label,
                                style: TextStyle(
                                  color: strength.color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: TactileButton(
                                onPressed: _regenerate,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.refresh, size: 18, color: AppColors.textPrimary),
                                    SizedBox(width: 8),
                                    Text('Regenerate', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TactileButton(
                                isPrimary: true,
                                onPressed: _copyToClipboard,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.copy, size: 18, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Copy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Options Neomorphic Box
                  NeumorphicBox(
                    padding: const EdgeInsets.all(22.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Length Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Length',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_length characters',
                                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _length.toDouble(),
                          min: 8,
                          max: 48,
                          divisions: 40,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.sunkenShadow.withOpacity(0.3),
                          onChanged: (val) {
                            setState(() => _length = val.round());
                            _regenerate();
                          },
                        ),
                        const Divider(height: 24),

                        _buildToggleRow('Include Uppercase (A-Z)', _useUpper, (v) {
                          setState(() => _useUpper = v);
                          _regenerate();
                        }),
                        _buildToggleRow('Include Digits (0-9)', _useDigits, (v) {
                          setState(() => _useDigits = v);
                          _regenerate();
                        }),
                        _buildToggleRow('Include Symbols (!@#\$)', _useSymbols, (v) {
                          setState(() => _useSymbols = v);
                          _regenerate();
                        }),
                        _buildToggleRow('Avoid Ambiguous (Il1O0)', _avoidAmbiguous, (v) {
                          setState(() => _avoidAmbiguous = v);
                          _regenerate();
                        }),
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

  Widget _buildToggleRow(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          Switch.adaptive(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
