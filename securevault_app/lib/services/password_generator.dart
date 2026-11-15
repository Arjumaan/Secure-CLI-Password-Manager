import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum PasswordStrength { weak, moderate, strong, military }

class PasswordStrengthResult {
  final double score; // 0.0 to 1.0
  final PasswordStrength strength;
  final String label;
  final Color color;

  const PasswordStrengthResult({
    required this.score,
    required this.strength,
    required this.label,
    required this.color,
  });
}

class PasswordGenerator {
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _digits = '0123456789';
  static const String _symbols = '!@#\$%^&*()-_=+[]{}|;:,.<>?';
  static const String _ambiguous = 'Il1O0';

  static String generate({
    int length = 16,
    bool useUpper = true,
    bool useDigits = true,
    bool useSymbols = true,
    bool avoidAmbiguous = true,
  }) {
    final effectiveLength = max(8, length);
    String allowedChars = _lowercase;

    if (useUpper) allowedChars += _uppercase;
    if (useDigits) allowedChars += _digits;
    if (useSymbols) allowedChars += _symbols;

    if (avoidAmbiguous) {
      for (final char in _ambiguous.split('')) {
        allowedChars = allowedChars.replaceAll(char, '');
      }
    }

    final random = Random.secure();
    final buffer = StringBuffer();
    for (int i = 0; i < effectiveLength; i++) {
      final index = random.nextInt(allowedChars.length);
      buffer.write(allowedChars[index]);
    }

    return buffer.toString();
  }

  static PasswordStrengthResult evaluateStrength(String password) {
    if (password.isEmpty) {
      return const PasswordStrengthResult(
        score: 0.0,
        strength: PasswordStrength.weak,
        label: 'Empty',
        color: AppColors.textMuted,
      );
    }

    double entropy = 0.0;
    int poolSize = 0;

    if (RegExp(r'[a-z]').hasMatch(password)) poolSize += 26;
    if (RegExp(r'[A-Z]').hasMatch(password)) poolSize += 26;
    if (RegExp(r'[0-9]').hasMatch(password)) poolSize += 10;
    if (RegExp(r'[!@#\$%^&*()-_=+[\]{}|;:,.<>?/]').hasMatch(password)) poolSize += 30;

    if (poolSize > 0) {
      entropy = password.length * (log(poolSize) / ln2);
    }

    if (entropy < 40 || password.length < 8) {
      return const PasswordStrengthResult(
        score: 0.25,
        strength: PasswordStrength.weak,
        label: 'Weak',
        color: AppColors.danger,
      );
    } else if (entropy < 60) {
      return const PasswordStrengthResult(
        score: 0.50,
        strength: PasswordStrength.moderate,
        label: 'Moderate',
        color: AppColors.securityAmber,
      );
    } else if (entropy < 85) {
      return const PasswordStrengthResult(
        score: 0.75,
        strength: PasswordStrength.strong,
        label: 'Strong',
        color: AppColors.securityGreen,
      );
    } else {
      return const PasswordStrengthResult(
        score: 1.0,
        strength: PasswordStrength.military,
        label: 'Military-Grade',
        color: Color(0xFF047857),
      );
    }
  }
}
