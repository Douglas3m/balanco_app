import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();
    final headlineTheme = GoogleFonts.outfitTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: BalancoColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: BalancoColors.primary,
        primary: BalancoColors.primary,
        secondary: BalancoColors.secondary,
        surface: BalancoColors.surface,
        background: BalancoColors.background,
        error: BalancoColors.danger,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: headlineTheme.displayLarge?.copyWith(color: BalancoColors.textMain, fontWeight: FontWeight.bold),
        displayMedium: headlineTheme.displayMedium?.copyWith(color: BalancoColors.textMain, fontWeight: FontWeight.bold),
        displaySmall: headlineTheme.displaySmall?.copyWith(color: BalancoColors.textMain, fontWeight: FontWeight.bold),
        headlineLarge: headlineTheme.headlineLarge?.copyWith(color: BalancoColors.primary, fontWeight: FontWeight.bold),
        headlineMedium: headlineTheme.headlineMedium?.copyWith(color: BalancoColors.primary, fontWeight: FontWeight.w600),
        headlineSmall: headlineTheme.headlineSmall?.copyWith(color: BalancoColors.primary, fontWeight: FontWeight.w600),
        titleLarge: headlineTheme.titleLarge?.copyWith(color: BalancoColors.textMain, fontWeight: FontWeight.bold),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: BalancoColors.textMain, fontWeight: FontWeight.w600),
        titleSmall: baseTextTheme.titleSmall?.copyWith(color: BalancoColors.textSecondary, fontWeight: FontWeight.w500),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: BalancoColors.textMain),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: BalancoColors.textMain),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: BalancoColors.textSecondary),
        labelLarge: baseTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: BalancoColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardTheme(
        color: BalancoColors.surface,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: BalancoColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BalancoColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BalancoColors.textMain,
          side: const BorderSide(color: BalancoColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: BalancoColors.textSecondary, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: BalancoColors.primary, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: BalancoColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: BalancoColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: BalancoColors.borderFocus, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
