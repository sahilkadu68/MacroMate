import 'package:flutter/material.dart';

class AppColors {
  // Distinctive Brand Forest & Teal Identity
  static const Color primary = Color(0xFF0D5C3A); // Deep Forest Green
  static const Color primaryLight = Color(0xFF349C6D); // Medium Forest
  static const Color primaryDark = Color(0xFF073824); // Dark Forest
  static const Color primaryContainer = Color(0xFFE6F4ED); // Soft Forest Tint

  // Budget / Financial Identity (Warm Rupee Amber)
  static const Color secondary = Color(0xFFD97706); // Warm Amber 600
  static const Color secondaryLight = Color(0xFFFBBF24); // Amber 400
  static const Color secondaryDark = Color(0xFFB45309); // Amber 700
  static const Color secondaryContainer = Color(0xFFFEF3C7); // Soft Amber Tint

  // Nutritional Macro Identity
  static const Color protein = Color(0xFF4F46E5); // Indigo 600
  static const Color proteinLight = Color(0xFFEEF2FF);
  static const Color carbs = Color(0xFFD97706); // Amber 600
  static const Color carbsLight = Color(0xFFFFFBEB);
  static const Color fat = Color(0xFFE11D48); // Rose 600
  static const Color fatLight = Color(0xFFFFF1F2);
  static const Color calories = Color(0xFFEA580C); // Warm Orange 600
  static const Color caloriesLight = Color(0xFFFFEDD5);
  static const Color water = Color(0xFF0284C7); // Sky Blue 600
  static const Color waterLight = Color(0xFFE0F2FE);

  // Status & Feedback
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  // Protein Efficiency Tier Badges (g/₹)
  static const Color highEfficiency = Color(0xFF0D5C3A); // > 1.2 g/₹
  static const Color midEfficiency = Color(0xFFD97706); // 0.6 - 1.2 g/₹
  static const Color lowEfficiency = Color(0xFF64748B); // < 0.6 g/₹

  // Light Mode Surfaces & Neutrals (Warm Off-White & Crisp Border)
  static const Color backgroundLight = Color(0xFFF8FAF9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F5F2);
  static const Color textPrimaryLight = Color(0xFF142018);
  static const Color textSecondaryLight = Color(0xFF506256);
  static const Color textTertiaryLight = Color(0xFF829488);
  static const Color borderLight = Color(0xFFE2E8E4);

  // Dark Mode Surfaces & Neutrals (Deep Forest Slate)
  static const Color backgroundDark = Color(0xFF0B1410);
  static const Color surfaceDark = Color(0xFF14221C);
  static const Color surfaceVariantDark = Color(0xFF1E3229);
  static const Color textPrimaryDark = Color(0xFFF3F7F4);
  static const Color textSecondaryDark = Color(0xFFA1B3A7);
  static const Color textTertiaryDark = Color(0xFF6C8072);
  static const Color borderDark = Color(0xFF253D32);

  // Dietary Classification Badges
  static const Color vegGreen = Color(0xFF15803D); // Green 700
  static const Color eggYellow = Color(0xFFB45309); // Amber 700
  static const Color nonVegRed = Color(0xFFBE123C); // Rose 700
}
