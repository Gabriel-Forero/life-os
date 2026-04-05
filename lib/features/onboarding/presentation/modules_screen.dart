import 'package:flutter/material.dart';
import 'package:life_os/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/constants/app_constants.dart';
import 'package:life_os/features/onboarding/providers/onboarding_notifier.dart';

class ModulesScreen extends ConsumerWidget {
  const ModulesScreen({super.key});

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
          Text(l10n.modulesTitle, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(l10n.modulesSubtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: AppConstants.allModuleIds.map((moduleId) {
                final isEnabled = state.enabledModules.contains(moduleId);
                return _ModuleTile(
                  key: ValueKey('module-$moduleId'),
                  moduleId: moduleId,
                  label: _moduleLabel(l10n, moduleId),
                  icon: _moduleIcon(moduleId),
                  color: AppColors.moduleColor(moduleId),
                  enabled: isEnabled,
                  onToggle: () => notifier.toggleModule(moduleId),
                );
              }).toList(),
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
                key: const ValueKey('modules-skip-button'),
                onPressed: () => notifier.skip(),
                child: Text(l10n.onboardingSkipSetup),
              ),
              const Spacer(),
              FilledButton(
                key: const ValueKey('modules-continue-button'),
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

  String _moduleLabel(AppLocalizations l10n, String moduleId) =>
      switch (moduleId) {
        'finance' => l10n.moduleFinance,
        'gym' => l10n.moduleGym,
        'nutrition' => l10n.moduleNutrition,
        'habits' => l10n.moduleHabits,
        'sleep' => l10n.moduleSleep,
        'mental' => l10n.moduleMental,
        'goals' => l10n.moduleGoals,
        _ => moduleId,
      };

  IconData _moduleIcon(String moduleId) => switch (moduleId) {
    'finance' => Icons.account_balance_wallet_outlined,
    'gym' => Icons.fitness_center_outlined,
    'nutrition' => Icons.restaurant_outlined,
    'habits' => Icons.check_circle_outline,
    'sleep' => Icons.bedtime_outlined,
    'mental' => Icons.psychology_outlined,
    'goals' => Icons.flag_outlined,
    _ => Icons.extension_outlined,
  };
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    super.key,
    required this.moduleId,
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onToggle,
  });

  final String moduleId;
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$label ${enabled ? "activado" : "desactivado"}',
      toggled: enabled,
      child: Card(
        color: enabled ? color.withAlpha(25) : null,
        child: ListTile(
          leading: Icon(icon, color: color),
          title: Text(label, style: theme.textTheme.titleMedium),
          trailing: Switch(
            value: enabled,
            activeTrackColor: color,
            onChanged: (_) => onToggle(),
          ),
          onTap: onToggle,
        ),
      ),
    );
  }
}
