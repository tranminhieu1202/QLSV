import 'package:flutter/material.dart';

/// Central color palette + theme, inspired by a university portal (deep red).
class AppColors {
  static const Color primary = Color(0xFFA4161A);
  static const Color primaryDark = Color(0xFF6A040F);
  static const Color accent = Color(0xFFD4A017);
  static const Color bg = Color(0xFFF5F6F8);
  static const Color surface = Colors.white;
  static const Color tableHeader = Color(0xFFDCE6F5);
  static const Color textDark = Color(0xFF1F2933);
  static const Color textMuted = Color(0xFF6B7280);

  // Warning colors
  static const Color ok = Color(0xFF2E7D32);
  static const Color warn = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFC62828);
  static const Color info = Color(0xFF1565C0);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: 'Segoe UI',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      dividerTheme: const DividerThemeData(space: 1, thickness: 1),
    );
  }
}
