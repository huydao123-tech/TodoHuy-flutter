import 'package:flutter/material.dart';

class AppColors {
  // Brand & Accent (Things 3 & Linear Emerald Green)
  static const accent = Color(0xFF16A34A);
  static const accentLight = Color(0xFFDCFCE7);
  static const accentSubtle = Color(0xFFF0FDF4);
  static const accentDark = Color(0xFF15803D);

  // Neutral Backgrounds & Surfaces (Light)
  static const bg = Color(0xFFFAFAF9);       // Stone-50 background
  static const bgAlt = Color(0xFFF5F5F4);    // Slate/Stone subtle fill
  static const surface = Colors.white;       // Pure white card surface
  static const surfaceSubtle = Color(0xFFF8FAFC);
  static const border = Color(0xFFE7E5E4);   // Crisp thin border
  static const borderSubtle = Color(0xFFF1F5F9);

  // Typography Tokens
  static const text = Color(0xFF1C1917);      // Deep Slate/Stone text
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF78716C); // Subtitle / muted
  static const textFaint = Color(0xFFA8A29E); // Placeholder / disabled

  // Dark Mode Tokens
  static const darkBg = Color(0xFF09090B);        // Deep Zinc-950
  static const darkSurface = Color(0xFF18181B);   // Zinc-900
  static const darkSurfaceSubtle = Color(0xFF27272A);
  static const darkBorder = Color(0xFF27272A);
  static const darkText = Color(0xFFF4F4F5);
  static const darkTextMuted = Color(0xFFA1A1AA);
  static const darkTextFaint = Color(0xFF71717A);

  // Palette cho Task Groups (6 màu Things 3 / Notion-style)
  static const groupColors = [
    Color(0xFF16A34A), // Emerald Green
    Color(0xFF7C3AED), // Violet
    Color(0xFFD97706), // Amber
    Color(0xFF2563EB), // Blue
    Color(0xFFDC2626), // Rose/Red
    Color(0xFF0D9488), // Teal
  ];

  // Modern Shadows
  static const softShadow = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  static const elevatedShadow = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 20,
    offset: Offset(0, 6),
  );
}
