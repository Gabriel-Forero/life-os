import 'package:flutter/material.dart';
import 'package:life_os/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/router/app_router.dart';
import 'package:life_os/core/services/theme_notifier.dart';

class LifeOsApp extends ConsumerWidget {
  const LifeOsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeNotifierProvider);
    final router = ref.watch(appRouterProvider);
    final themeNotifier = ref.read(themeNotifierProvider.notifier);

    return MaterialApp.router(
      title: 'LifeOS',
      debugShowCheckedModeBanner: false,
      themeMode: themeState.themeMode,
      theme: themeNotifier.buildLightTheme(),
      darkTheme: themeNotifier.buildDarkTheme(),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
    );
  }
}
