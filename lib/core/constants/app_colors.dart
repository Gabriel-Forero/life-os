import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Primary accent ──────────────────────────────────────────────────────
  static const Color primary = Color(0xFF3B82F6);

  // ── Module accent colors (fixed, same in dark and light) ────────────────
  static const Color finance = Color(0xFF10B981);
  static const Color gym = Color(0xFFF59E0B);
  static const Color nutrition = Color(0xFFF97316);
  static const Color habits = Color(0xFF8B5CF6);
  static const Color sleep = Color(0xFF6366F1);
  static const Color mental = Color(0xFFEC4899);
  static const Color goals = Color(0xFF06B6D4);
  static const Color dayScore = Color(0xFFEAB308);

  // ── Module gradient end colors ──────────────────────────────────────────
  static const Color financeEnd = Color(0xFF059669);
  static const Color gymEnd = Color(0xFFD97706);
  static const Color nutritionEnd = Color(0xFFEA580C);
  static const Color habitsEnd = Color(0xFF7C3AED);
  static const Color sleepEnd = Color(0xFF4F46E5);
  static const Color mentalEnd = Color(0xFFDB2777);
  static const Color goalsEnd = Color(0xFF0891B2);
  static const Color dayScoreEnd = Color(0xFFCA8A04);

  // ── Dark theme surfaces ─────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF09090B);
  static const Color darkSurface = Color(0xFF111113);
  static const Color darkSurfaceVariant = Color(0xFF1A1A1E);
  static const Color darkCard = Color(0xFF151517);
  static const Color darkBorder = Color(0xFF27272A);
  static const Color darkCardHover = Color(0xFF1C1C20);

  // ── Light theme surfaces ────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightCardHover = Color(0xFFF8FAFC);

  // ── Text colors ─────────────────────────────────────────────────────────
  static const Color darkTextPrimary = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // ── High contrast overrides ─────────────────────────────────────────────
  static const Color highContrastDarkText = Color(0xFFFFFFFF);
  static const Color highContrastLightText = Color(0xFF000000);

  // ── Semantic colors ─────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ── Module color lookup ─────────────────────────────────────────────────
  static Color moduleColor(String moduleId) => switch (moduleId) {
    'finance' => finance,
    'gym' => gym,
    'nutrition' => nutrition,
    'habits' => habits,
    'sleep' => sleep,
    'mental' => mental,
    'goals' => goals,
    _ => info,
  };

  /// Returns a gradient for a given module.
  static LinearGradient moduleGradient(String moduleId) {
    final start = moduleColor(moduleId);
    final end = switch (moduleId) {
      'finance' => financeEnd,
      'gym' => gymEnd,
      'nutrition' => nutritionEnd,
      'habits' => habitsEnd,
      'sleep' => sleepEnd,
      'mental' => mentalEnd,
      'goals' => goalsEnd,
      _ => start,
    };
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [start, end],
    );
  }

  /// Returns a gradient for the DayScore ring.
  static const LinearGradient dayScoreGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [dayScore, dayScoreEnd],
  );

  // ── Theme-aware helpers (pass brightness from context) ──────────────────

  static Color cardBackground(Brightness brightness) =>
      brightness == Brightness.dark ? darkCard : lightCard;

  static Color surfaceBackground(Brightness brightness) =>
      brightness == Brightness.dark ? darkBackground : lightBackground;

  static Color borderColor(Brightness brightness) =>
      brightness == Brightness.dark ? darkBorder : lightBorder;

  static Color textPrimary(Brightness brightness) =>
      brightness == Brightness.dark ? darkTextPrimary : lightTextPrimary;

  static Color textSecondary(Brightness brightness) =>
      brightness == Brightness.dark ? darkTextSecondary : lightTextSecondary;
}
