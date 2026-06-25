import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const Color primaryOrange = Color(0xFFFF6B00);
  static const Color primaryOrangeDark = Color(0xFFCC5500);
  static const Color primaryOrangeLight = Color(0xFFFF8C38);
  static const Color accent = Color(0xFFFF9A3C);

  // Background Colors
  static const Color bgDark = Color(0xFF0A0A0A);
  static const Color bgCard = Color(0xFF1A1A1A);
  static const Color bgCardLight = Color(0xFF222222);
  static const Color bgInput = Color(0xFF1E1E1E);
  static const Color bgSurface = Color(0xFF141414);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textMuted = Color(0xFF666666);
  static const Color textOrange = Color(0xFFFF6B00);

  // Status Colors
  static const Color success = Color(0xFF00C853);
  static const Color successDark = Color(0xFF009624);
  static const Color warning = Color(0xFFFFAB00);
  static const Color error = Color(0xFFFF1744);
  static const Color errorDark = Color(0xFFB71C1C);
  static const Color info = Color(0xFF00B0FF);

  // Border / Divider
  static const Color border = Color(0xFF2C2C2C);
  static const Color divider = Color(0xFF1E1E1E);

  // Chart Colors
  static const Color chart1 = Color(0xFFFF6B00);
  static const Color chart2 = Color(0xFF00C853);
  static const Color chart3 = Color(0xFF00B0FF);
  static const Color chart4 = Color(0xFFFFAB00);
  static const Color chart5 = Color(0xFFFF1744);
  static const Color chart6 = Color(0xFFAA00FF);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryOrange, primaryOrangeDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1A1A), Color(0xFF141414)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
