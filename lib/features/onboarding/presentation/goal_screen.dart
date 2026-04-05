import 'package:flutter/material.dart';
import 'package:life_os/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/features/onboarding/providers/onboarding_notifier.dart';

class GoalScreen extends ConsumerWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final goals = [
      _GoalOption(
        id: 'save_money',
        label: l10n.goalSaveMoney,
        icon: Icons.savings_outlined,
        color: AppColors.finance,
      ),
      _GoalOption(
        id: 'get_fit',
        label: l10n.goalGetFit,
        icon: Icons.fitness_center_outlined,
        color: AppColors.gym,
      ),
      _GoalOption(
        id: 'be_disciplined',
        label: l10n.goalBeDisciplined,
        icon: Icons.check_circle_outline,
        color: AppColors.habits,
      ),
      _GoalOption(
        id: 'balance',
        label: l10n.goalBalance,
        icon: Icons.balance_outlined,
        color: AppColors.dayScore,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(l10n.goalTitle, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: goals
                  .map(
                    (goal) => _GoalCard(
                      key: ValueKey('goal-${goal.id}'),
                      option: goal,
                      selected: state.primaryGoal == goal.id,
                      onTap: () => notifier.setGoal(goal.id),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (state.error != null) ...[
            Text(
              state.error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              TextButton(
                key: const ValueKey('goal-skip-button'),
                onPressed: () => notifier.skip(),
                child: Text(l10n.onboardingSkipSetup),
              ),
              const Spacer(),
              FilledButton(
                key: const ValueKey('goal-continue-button'),
                onPressed: state.primaryGoal != null
                    ? notifier.nextStep
                    : null,
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

class _GoalOption {
  const _GoalOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _GoalOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '${option.label} ${selected ? "seleccionado" : ""}',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? option.color : theme.dividerColor,
              width: selected ? 2 : 1,
            ),
            color: selected ? option.color.withAlpha(25) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(option.icon, color: option.color, size: 36),
              const SizedBox(height: 8),
              Text(
                option.label,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
