import 'package:flutter/material.dart';
import 'package:life_os/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/features/onboarding/providers/onboarding_notifier.dart';

class FirstDataScreen extends ConsumerWidget {
  const FirstDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final hasFinance = state.enabledModules.contains('finance');
    final hasHabits = state.enabledModules.contains('habits');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(l10n.firstDataTitle, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),
          if (hasFinance)
            _FirstDataCard(
              key: const ValueKey('first-data-budget'),
              icon: Icons.account_balance_wallet_outlined,
              label: l10n.firstDataCreateBudget,
              color: AppColors.finance,
              onTap: () {
                // Budget creation will be implemented in Finance unit
                // For now, skip to completion
                notifier.completeOnboarding();
              },
            ),
          if (hasHabits) ...[
            if (hasFinance) const SizedBox(height: 12),
            _FirstDataCard(
              key: const ValueKey('first-data-habit'),
              icon: Icons.check_circle_outline,
              label: l10n.firstDataCreateHabit,
              color: AppColors.habits,
              onTap: () {
                // Habit creation will be implemented in Habits unit
                // For now, skip to completion
                notifier.completeOnboarding();
              },
            ),
          ],
          if (state.error != null) ...[
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
          const Spacer(),
          if (state.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                TextButton(
                  key: const ValueKey('first-data-skip-button'),
                  onPressed: () => notifier.completeOnboarding(),
                  child: Text(l10n.onboardingSkipForNow),
                ),
                const Spacer(),
              ],
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _FirstDataCard extends StatelessWidget {
  const _FirstDataCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Text(label, style: theme.textTheme.titleMedium),
              ),
              Icon(Icons.chevron_right, color: theme.textTheme.bodySmall?.color),
            ],
          ),
        ),
      ),
    );
  }
}
