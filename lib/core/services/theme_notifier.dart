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
          const ThemeState(themeMode: ThemeMode.light, highContrast: false),
        );

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void setThemeModeFromString(String mode) {
    final themeMode = switch (mode) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
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
      colorScheme: ColorScheme.light(
        surface: Colors.white,
        surfaceContainerHighest: AppColors.lightSurfaceVariant,
        primary: AppColors.primary,
        secondary: AppColors.finance,
        error: AppColors.error,
        onSurface: AppColors.lightTextPrimary,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.lightBorder),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withAlpha(25),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            );
          }
          return TextStyle(
            fontSize: 11,
            color: AppColors.lightTextSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return IconThemeData(color: AppColors.lightTextSecondary);
        }),
      ),
      dividerColor: AppColors.lightBorder,
      cardColor: Colors.white,
      textTheme: textTheme,
      useMaterial3: true,
    );
  }
}

final themeNotifierProvider =
    StateNotifierProvider<ThemeNotifier, ThemeState>(
  (ref) => ThemeNotifier(),
);
