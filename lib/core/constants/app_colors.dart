import 'package:flutter/material.dart';

abstract final class AppColors {
  // Module accent colors (fixed, same in dark and light)
  static const Color finance = Color(0xFF10B981);
  static const Color gym = Color(0xFFF59E0B);
  static const Color nutrition = Color(0xFFF97316);
  static const Color habits = Color(0xFF8B5CF6);
  static const Color sleep = Color(0xFF6366F1);
  static const Color mental = Color(0xFFEC4899);
  static const Color goals = Color(0xFF06B6D4);
  static const Color dayScore = Color(0xFFEAB308);

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkSurfaceVariant = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBorder = Color(0xFF2A2A2A);

  // Light theme surfaces
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F3F5);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE0E0E0);

  // Text colors
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6B7280);

  // High contrast overrides
  static const Color highContrastDarkText = Color(0xFFFFFFFF);
  static const Color highContrastLightText = Color(0xFF000000);

  // Semantic colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

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
}
