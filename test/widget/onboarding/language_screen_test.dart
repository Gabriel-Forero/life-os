import 'package:flutter/material.dart';
import 'package:life_os/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/features/onboarding/presentation/language_screen.dart';

Widget _buildTestApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('LanguageScreen', () {
    testWidgets('shows two language options', (tester) async {
      await tester.pumpWidget(_buildTestApp(const LanguageScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('language-es')), findsOneWidget);
      expect(find.byKey(const ValueKey('language-en')), findsOneWidget);
    });

    testWidgets('shows skip and continue buttons', (tester) async {
      await tester.pumpWidget(_buildTestApp(const LanguageScreen()));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('language-skip-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('language-continue-button')),
        findsOneWidget,
      );
    });

    testWidgets('tapping language card changes selection', (tester) async {
      await tester.pumpWidget(_buildTestApp(const LanguageScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('language-en')));
      await tester.pumpAndSettle();

      // English card should now show check icon
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}
