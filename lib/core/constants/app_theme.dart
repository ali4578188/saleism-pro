import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDark,
    primaryColor: AppColors.primaryOrange,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryOrange,
      secondary: AppColors.accent,
      surface: AppColors.bgCard,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(color: AppColors.primaryOrange),
    ),
    cardTheme: CardTheme(
      color: AppColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryOrange,
        side: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgInput,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textMuted),
      prefixIconColor: AppColors.textSecondary,
      suffixIconColor: AppColors.textSecondary,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bgCard,
      selectedItemColor: AppColors.primaryOrange,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 0,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 28),
      headlineMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 22),
      headlineSmall: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18),
      titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
      titleMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
      titleSmall: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 12),
      bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 15),
      bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      bodySmall: TextStyle(color: AppColors.textMuted, fontSize: 11),
      labelLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
    ),
    iconTheme: const IconThemeData(color: AppColors.textSecondary),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.bgCardLight,
      selectedColor: AppColors.primaryOrange,
      labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.bgCard,
      contentTextStyle: const TextStyle(color: AppColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
      contentTextStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
    ),
  );
}
