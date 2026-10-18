import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Secondary
  static const Color primary = Color(0xFF059669); // Emerald 600
  static const Color primaryLight = Color(0xFF34D399); // Emerald 400
  static const Color primaryDark = Color(0xFF047857); // Emerald 700

  static const Color secondary = Color(
    0xFFD97706,
  ); // Amber 600 (Budget / Rupee)
  static const Color secondaryLight = Color(0xFFFBBF24); // Amber 400

  // Macro Color Identity
  static const Color protein = Color(0xFF6366F1); // Indigo
  static const Color proteinLight = Color(0xFFEEF2FF);
  static const Color carbs = Color(0xFFF59E0B); // Amber
  static const Color carbsLight = Color(0xFFFEF3C7);
  static const Color fat = Color(0xFFEC4899); // Pink
  static const Color fatLight = Color(0xFFFCE7F3);
  static const Color calories = Color(0xFFEF4444); // Red/Orange
  static const Color caloriesLight = Color(0xFFFEE2E2);
  static const Color water = Color(0xFF0EA5E9); // Sky Blue
  static const Color waterLight = Color(0xFFE0F2FE);

  // Efficiency / Badge Colors
  static const Color highEfficiency = Color(0xFF059669); // > 1.0 g/₹
  static const Color midEfficiency = Color(0xFFD97706); // 0.5 - 1.0 g/₹
  static const Color lowEfficiency = Color(0xFF64748B); // < 0.5 g/₹

  // Light Mode Neutrals
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Dark Mode Neutrals
  static const Color backgroundDark = Color(0xFF0B1120);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceVariantDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF334155);

  // Dietary tags
  static const Color vegGreen = Color(0xFF16A34A);
  static const Color eggYellow = Color(0xFFCA8A04);
  static const Color nonVegRed = Color(0xFFDC2626);
}
