import 'package:flutter/material.dart';
import 'package:life_os/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/features/onboarding/providers/onboarding_notifier.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(l10n.languageSelectionTitle,
              style: theme.textTheme.headlineMedium),
          const SizedBox(height: 32),
          _LanguageCard(
            key: const ValueKey('language-es'),
            label: l10n.languageSpanish,
            flag: '🇨🇴',
            selected: state.language == 'es',
            onTap: () => notifier.setLanguage('es'),
          ),
          const SizedBox(height: 12),
          _LanguageCard(
            key: const ValueKey('language-en'),
            label: l10n.languageEnglish,
            flag: '🇺🇸',
            selected: state.language == 'en',
            onTap: () => notifier.setLanguage('en'),
          ),
          const Spacer(),
          Row(
            children: [
              TextButton(
                key: const ValueKey('language-skip-button'),
                onPressed: () => notifier.skip(),
                child: Text(l10n.onboardingSkipSetup),
              ),
              const Spacer(),
              FilledButton(
                key: const ValueKey('language-continue-button'),
                onPressed: notifier.nextStep,
                child: Text(l10n.onboardingContinue),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    super.key,
    required this.label,
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String flag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$label ${selected ? "seleccionado" : ""}',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.dividerColor,
              width: selected ? 2 : 1,
            ),
            color: selected
                ? theme.colorScheme.primary.withAlpha(25)
                : null,
          ),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Text(label, style: theme.textTheme.titleLarge),
              const Spacer(),
              if (selected)
                Icon(Icons.check_circle, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
