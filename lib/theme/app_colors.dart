import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds ──
  static const Color background = Color(0xFF0A0E17);
  static const Color surface = Color(0xFF111827);
  static const Color card = Color(0xFF1A2035);
  static const Color cardLight = Color(0xFF222B3F);
  static const Color bottomNav = Color(0xFF0E1219);
  static const Color inputFill = Color(0xFF1A2035);

  // ── Primary (Green) ──
  static const Color primary = Color(0xFF00E676);
  static const Color primaryDark = Color(0xFF00C853);
  static const Color primaryDim = Color(0xFF1B5E20);
  static const Color primarySurface = Color(0xFF0D2818);

  // ── Status ──
  static const Color error = Color(0xFFFF5252);
  static const Color errorDim = Color(0xFF5C1A1A);
  static const Color warning = Color(0xFFFFD740);
  static const Color warningDim = Color(0xFF5C4A00);
  static const Color info = Color(0xFF448AFF);

  // ── Text ──
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textTertiary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF4B5563);

  // ── Borders ──
  static const Color border = Color(0xFF1F2937);
  static const Color borderLight = Color(0xFF374151);

  // ── Chart colors ──
  static const Color chartGreen = Color(0xFF00E676);
  static const Color chartRed = Color(0xFFFF5252);
  static const Color chartAmber = Color(0xFFFFD740);
  static const Color chartBlue = Color(0xFF448AFF);
  static const Color chartPurple = Color(0xFF7C4DFF);
  static const Color chartOrange = Color(0xFFFF9100);
  static const Color chartTeal = Color(0xFF00BFA5);

  // ── Score-based colors ──
  static Color scoreColor(int score) {
    if (score >= 75) return primary;
    if (score >= 50) return warning;
    if (score >= 30) return const Color(0xFFFF9100);
    return error;
  }

  static Color scoreBgColor(int score) {
    if (score >= 75) return primarySurface;
    if (score >= 50) return warningDim;
    if (score >= 30) return const Color(0xFF5C3200);
    return errorDim;
  }

  static Color changeColor(double change) {
    if (change > 0) return primary;
    if (change < 0) return error;
    return textSecondary;
  }

  static String riskLabel(int score) {
    if (score <= 25) return 'Low';
    if (score <= 50) return 'Moderate';
    if (score <= 75) return 'High';
    return 'Critical';
  }

  static Color riskColor(int score) {
    if (score <= 25) return primary;
    if (score <= 50) return warning;
    if (score <= 75) return const Color(0xFFFF9100);
    return error;
  }
}
