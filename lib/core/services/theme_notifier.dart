import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/constants/app_typography.dart';

class ThemeState {
  const ThemeState({
    required this.themeMode,
    required this.highContrast,
  });

  final ThemeMode themeMode;
  final bool highContrast;

  ThemeState copyWith({ThemeMode? themeMode, bool? highContrast}) =>
      ThemeState(
        themeMode: themeMode ?? this.themeMode,
        highContrast: highContrast ?? this.highContrast,
      );
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier()
      : super(
          const ThemeState(themeMode: ThemeMode.dark, highContrast: false),
        );

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void setThemeModeFromString(String mode) {
    final themeMode = switch (mode) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
    state = state.copyWith(themeMode: themeMode);
  }

  void setHighContrast(bool value) {
    state = state.copyWith(highContrast: value);
  }

  ThemeData buildDarkTheme() {
    final textTheme = AppTypography.textTheme(Brightness.dark);
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.darkSurface,
        surfaceContainerHighest: AppColors.darkSurfaceVariant,
        primary: AppColors.finance,
        error: AppColors.error,
      ),
      cardColor: AppColors.darkCard,
      dividerColor: AppColors.darkBorder,
      textTheme: textTheme,
      useMaterial3: true,
    );
  }

  ThemeData buildLightTheme() {
    final textTheme = AppTypography.textTheme(Brightness.light);
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        surface: AppColors.lightSurface,
        surfaceContainerHighest: AppColors.lightSurfaceVariant,
        primary: AppColors.finance,
        error: AppColors.error,
      ),
      cardColor: AppColors.lightCard,
      dividerColor: AppColors.lightBorder,
      textTheme: textTheme,
      useMaterial3: true,
    );
  }
}

final themeNotifierProvider =
    StateNotifierProvider<ThemeNotifier, ThemeState>(
  (ref) => ThemeNotifier(),
);
