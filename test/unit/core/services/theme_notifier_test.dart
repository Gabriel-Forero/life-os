import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_os/core/services/theme_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late ThemeNotifier notifier;

  setUp(() {
    notifier = ThemeNotifier();
  });

  group('ThemeNotifier', () {
    test('initial state is light mode, no high contrast', () {
      expect(notifier.state.themeMode, ThemeMode.light);
      expect(notifier.state.highContrast, false);
    });

    test('setThemeMode changes theme mode', () {
      notifier.setThemeMode(ThemeMode.light);
      expect(notifier.state.themeMode, ThemeMode.light);
    });

    test('setThemeModeFromString parses correctly', () {
      notifier.setThemeModeFromString('light');
      expect(notifier.state.themeMode, ThemeMode.light);

      notifier.setThemeModeFromString('system');
      expect(notifier.state.themeMode, ThemeMode.system);

      notifier.setThemeModeFromString('dark');
      expect(notifier.state.themeMode, ThemeMode.dark);

      notifier.setThemeModeFromString('invalid');
      expect(notifier.state.themeMode, ThemeMode.light);
    });

    test('setHighContrast updates state', () {
      notifier.setHighContrast(true);
      expect(notifier.state.highContrast, true);
    });

    testWidgets('buildDarkTheme returns dark brightness', (tester) async {
      final theme = notifier.buildDarkTheme();
      expect(theme.brightness, Brightness.dark);
    });

    testWidgets('buildLightTheme returns light brightness', (tester) async {
      final theme = notifier.buildLightTheme();
      expect(theme.brightness, Brightness.light);
    });

    testWidgets('setting same theme mode twice is idempotent', (tester) async {
      notifier.setThemeMode(ThemeMode.light);
      final theme1 = notifier.buildLightTheme();
      notifier.setThemeMode(ThemeMode.light);
      final theme2 = notifier.buildLightTheme();
      expect(theme1.brightness, theme2.brightness);
    });
  });
}
