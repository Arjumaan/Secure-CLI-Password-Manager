import 'package:flutter/material.dart';

class AppColors {
  // Base Canvas & Neomorphic Surfaces
  static const Color background = Color(0xFFF0F3F8);
  static const Color surface = Color(0xFFF4F7FB);
  static const Color surfaceElevated = Color(0xFFFAFBFD);

  // Frosted Glassmorphism Tokens
  static const Color glassSurface = Color(0x94FFFFFF); // ~58% opacity white
  static const Color glassBorder = Color(0xC0FFFFFF);  // ~75% opacity white
  static const Color glassHighlight = Color(0xE0FFFFFF); // ~88% opacity highlight

  // Soft Neomorphic Shadows
  static const Color shadowDark = Color(0x66A6AFC3);   // Soft ambient drop
  static const Color shadowLight = Color(0xF2FFFFFF);  // Specular top reflection
  static const Color sunkenShadow = Color(0x7FA6AFC3); // Inset groove drop

  // Accent & Brand Colors
  static const Color primary = Color(0xFF2563EB);        // Cobalt Royal Blue
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color securityGreen = Color(0xFF059669);  // Emerald status indicator
  static const Color securityAmber = Color(0xFFD97706);  // Medium strength / Warning
  static const Color danger = Color(0xFFDC2626);         // Red for delete / weak

  // Typography
  static const Color textPrimary = Color(0xFF0F172A);    // Slate 900
  static const Color textSecondary = Color(0xFF475569);  // Slate 600
  static const Color textMuted = Color(0xFF94A3B8);      // Slate 400
}
