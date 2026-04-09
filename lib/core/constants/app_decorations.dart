import 'package:flutter/material.dart';
import 'package:life_os/core/constants/app_colors.dart';

/// Shared decoration factories for consistent, theme-aware card styling.
///
/// All methods take [Brightness] so they adapt automatically to dark/light.
abstract final class AppDecorations {
  // ── Radii ───────────────────────────────────────────────────────────────
  static const double radiusLg = 20;
  static const double radiusMd = 16;
  static const double radiusSm = 12;
  static const double radiusXs = 8;

  // ── Standard card ───────────────────────────────────────────────────────
  /// Clean card with subtle border. The workhorse for most surfaces.
  static BoxDecoration card(Brightness brightness) => BoxDecoration(
    color: AppColors.cardBackground(brightness),
    borderRadius: BorderRadius.circular(radiusMd),
    border: Border.all(
      color: AppColors.borderColor(brightness),
      width: 1,
    ),
  );

  // ── Accent card (left stripe) ───────────────────────────────────────────
  /// Card with a colored left border accent — the signature LifeOS card.
  static BoxDecoration accentCard(
    Brightness brightness, {
    required Color accent,
    double stripeWidth = 3,
  }) => BoxDecoration(
    color: AppColors.cardBackground(brightness),
    borderRadius: BorderRadius.circular(radiusMd),
    border: Border(
      left: BorderSide(color: accent, width: stripeWidth),
      top: BorderSide(color: AppColors.borderColor(brightness), width: 1),
      right: BorderSide(color: AppColors.borderColor(brightness), width: 1),
      bottom: BorderSide(color: AppColors.borderColor(brightness), width: 1),
    ),
  );

  // ── Module card (gradient tint + glow shadow) ───────────────────────────
  /// Card with a subtle module-color tint and matching glow shadow.
  static BoxDecoration moduleCard(
    Brightness brightness, {
    required Color accent,
  }) {
    final isDark = brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark
          ? AppColors.darkCard
          : AppColors.lightCard,
      borderRadius: BorderRadius.circular(radiusMd),
      border: Border.all(
        color: isDark
            ? accent.withAlpha(30)
            : accent.withAlpha(20),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: accent.withAlpha(isDark ? 15 : 8),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        if (!isDark)
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
      ],
    );
  }

  // ── Glass card ──────────────────────────────────────────────────────────
  /// Semi-transparent card with subtle border glow.
  static BoxDecoration glassCard(
    Brightness brightness, {
    Color? tint,
  }) {
    final isDark = brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark
          ? const Color(0xFF151517).withAlpha(200)
          : Colors.white.withAlpha(220),
      borderRadius: BorderRadius.circular(radiusMd),
      border: Border.all(
        color: tint != null
            ? tint.withAlpha(isDark ? 40 : 25)
            : (isDark
                ? Colors.white.withAlpha(8)
                : Colors.black.withAlpha(8)),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withAlpha(40)
              : Colors.black.withAlpha(8),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // ── Elevated card ───────────────────────────────────────────────────────
  /// Card with more pronounced shadow for important content.
  static BoxDecoration elevatedCard(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return BoxDecoration(
      color: AppColors.cardBackground(brightness),
      borderRadius: BorderRadius.circular(radiusLg),
      border: Border.all(
        color: AppColors.borderColor(brightness),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withAlpha(50)
              : Colors.black.withAlpha(10),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: isDark
              ? Colors.black.withAlpha(25)
              : Colors.black.withAlpha(4),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // ── Gradient accent border ──────────────────────────────────────────────
  /// A container decoration with a gradient bottom border (for headers/heroes).
  static BoxDecoration gradientBottom(
    Brightness brightness, {
    required LinearGradient gradient,
  }) {
    return BoxDecoration(
      color: AppColors.cardBackground(brightness),
      borderRadius: BorderRadius.circular(radiusLg),
      border: Border.all(
        color: AppColors.borderColor(brightness),
        width: 1,
      ),
    );
  }

  // ── Input field decoration ──────────────────────────────────────────────
  static BoxDecoration inputField(Brightness brightness) => BoxDecoration(
    color: brightness == Brightness.dark
        ? AppColors.darkSurfaceVariant
        : AppColors.lightSurfaceVariant,
    borderRadius: BorderRadius.circular(radiusSm),
    border: Border.all(
      color: AppColors.borderColor(brightness),
      width: 1,
    ),
  );

  // ── Chip / badge decoration ─────────────────────────────────────────────
  static BoxDecoration chip(
    Brightness brightness, {
    Color? color,
    bool filled = false,
  }) {
    final accent = color ?? AppColors.primary;
    final isDark = brightness == Brightness.dark;
    return BoxDecoration(
      color: filled
          ? accent.withAlpha(isDark ? 30 : 20)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(radiusXs),
      border: Border.all(
        color: accent.withAlpha(isDark ? 50 : 35),
        width: 1,
      ),
    );
  }
}
