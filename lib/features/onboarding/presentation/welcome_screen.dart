import 'package:flutter/material.dart';
import 'package:life_os/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/features/onboarding/providers/onboarding_notifier.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Semantics(
            label: 'LifeOS logo',
            child: Container(
              key: const ValueKey('welcome-logo'),
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.finance.withAlpha(25),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 48,
                color: AppColors.finance,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.onboardingWelcomeTitle,
            style: theme.textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingWelcomeSubtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 3),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              key: const ValueKey('welcome-start-button'),
              onPressed: () {
                final notifier =
                    ref.read(onboardingNotifierProvider.notifier);
                notifier.detectSystemLanguage();
                notifier.nextStep();
              },
              child: Text(l10n.onboardingStart),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
