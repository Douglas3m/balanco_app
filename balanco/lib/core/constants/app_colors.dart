import 'package:flutter/material.dart';

/// Design tokens oficiais do Sistema Balanço (Baseado no Google Stitch)
class BalancoColors {
  // Cores Primárias e Secundárias
  static const Color primary = Color(0xFF1E3A8A);       // Deep Navy
  static const Color primaryDark = Color(0xFF172554);   // Navy 950
  static const Color secondary = Color(0xFF3B82F6);     // Cobalt Blue
  static const Color secondaryLight = Color(0xFF60A5FA);

  // Estados e Semântica
  static const Color success = Color(0xFF10B981);       // Emerald Green
  static const Color successBg = Color(0xFFECFDF5);     // Emerald Tint
  static const Color danger = Color(0xFFEF4444);        // Crimson
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color warning = Color(0xFFF59E0B);       // Amber
  static const Color warningBg = Color(0xFFFFFBEB);

  // Superfícies e Fundos
  static const Color background = Color(0xFFF8FAFC);    // Slate Light Canvas
  static const Color surface = Color(0xFFFFFFFF);       // White Card Surface
  static const Color containerLow = Color(0xFFF1F5F9);  // Slate 100
  static const Color containerHigh = Color(0xFFE2E8F0); // Slate 200

  // Tipografia e Bordas
  static const Color textMain = Color(0xFF1E293B);      // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8);     // Slate 400
  static const Color border = Color(0xFFE2E8F0);        // Slate Border
  static const Color borderFocus = Color(0xFF3B82F6);   // Blue Focus Ring
}
