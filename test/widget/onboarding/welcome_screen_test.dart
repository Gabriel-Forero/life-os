import 'package:flutter/material.dart';
import 'package:life_os/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/features/onboarding/presentation/welcome_screen.dart';

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
  group('WelcomeScreen', () {
    testWidgets('displays welcome title and start button', (tester) async {
      await tester.pumpWidget(_buildTestApp(const WelcomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Bienvenido a LifeOS'), findsOneWidget);
      expect(find.text('Comenzar'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('welcome-start-button')),
        findsOneWidget,
      );
    });

    testWidgets('displays logo icon', (tester) async {
      await tester.pumpWidget(_buildTestApp(const WelcomeScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('welcome-logo')), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('has accessibility semantics', (tester) async {
      await tester.pumpWidget(_buildTestApp(const WelcomeScreen()));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('LifeOS logo'),
        findsOneWidget,
      );
    });
  });
}
