import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/router/app_router.dart';

/// Unified Wellness hub combining Sleep, Mental, Breathing, and Gratitude
/// into a single screen with quick actions and today's summary.
class WellnessHubScreen extends ConsumerWidget {
  const WellnessHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sleepDao = ref.watch(sleepDaoProvider);
    final mentalDao = ref.watch(mentalDaoProvider);
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienestar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quick Actions Grid
          Text('Acciones rapidas', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _QuickAction(
                key: const ValueKey('wellness-mood'),
                icon: Icons.mood,
                label: 'Estado de animo',
                subtitle: 'Registrar mood',
                color: AppColors.mental,
                onTap: () => GoRouter.of(context).push(AppRoutes.mood),
              ),
              _QuickAction(
                key: const ValueKey('wellness-breathing'),
                icon: Icons.self_improvement,
                label: 'Respiracion',
                subtitle: 'Ejercicio guiado',
                color: AppColors.mental,
                onTap: () => GoRouter.of(context).push(AppRoutes.breathing),
              ),
              _QuickAction(
                key: const ValueKey('wellness-gratitude'),
                icon: Icons.favorite,
                label: 'Gratitud',
                subtitle: '3 cosas buenas',
                color: AppColors.mental,
                onTap: () => GoRouter.of(context).push(AppRoutes.gratitude),
              ),
              _QuickAction(
                key: const ValueKey('wellness-sleep'),
                icon: Icons.bedtime,
                label: 'Sueno',
                subtitle: 'Registrar noche',
                color: AppColors.sleep,
                onTap: () => GoRouter.of(context).push(AppRoutes.sleep),
              ),
              _QuickAction(
                key: const ValueKey('wellness-energy'),
                icon: Icons.bolt,
                label: 'Energia',
                subtitle: 'Check-in rapido',
                color: AppColors.gym,
                onTap: () => GoRouter.of(context).push(AppRoutes.energy),
              ),
              _QuickAction(
                key: const ValueKey('wellness-insights'),
                icon: Icons.psychology,
                label: 'Patrones IA',
                subtitle: 'Analisis cruzado',
                color: AppColors.goals,
                onTap: () => GoRouter.of(context).push(AppRoutes.mentalInsights),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Today's Summary
          Text('Resumen de hoy', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Sleep summary
          StreamBuilder<List<SleepLog>>(
            stream: sleepDao.watchSleepLogs(todayStart.subtract(const Duration(days: 1)), todayStart),
            builder: (context, snapshot) {
              final logs = snapshot.data ?? [];
              if (logs.isEmpty) {
                return _SummaryCard(
                  icon: Icons.bedtime,
                  color: AppColors.sleep,
                  title: 'Sueno',
                  value: 'Sin registro',
                  subtitle: 'Toca para registrar tu noche',
                  onTap: () => GoRouter.of(context).push(AppRoutes.sleep),
                );
              }
              final log = logs.first;
              final hours = log.wakeTime.difference(log.bedTime).inMinutes / 60;
              return _SummaryCard(
                icon: Icons.bedtime,
                color: AppColors.sleep,
                title: 'Sueno anoche',
                value: '${hours.toStringAsFixed(1)}h — Score ${log.sleepScore}/100',
                subtitle: 'Calidad: ${'⭐' * log.qualityRating}',
                onTap: () => GoRouter.of(context).push(AppRoutes.sleepHistory),
              );
            },
          ),
          const SizedBox(height: 8),

          // Mood summary
          StreamBuilder<List<MoodLog>>(
            stream: mentalDao.watchMoodLogs(todayStart, todayStart.add(const Duration(days: 1))),
            builder: (context, snapshot) {
              final logs = snapshot.data ?? [];
              if (logs.isEmpty) {
                return _SummaryCard(
                  icon: Icons.mood,
                  color: AppColors.mental,
                  title: 'Estado de animo',
                  value: 'Sin registro hoy',
                  subtitle: 'Toca para hacer check-in',
                  onTap: () => GoRouter.of(context).push(AppRoutes.mood),
                );
              }
              final log = logs.first;
              final emoji = ['', '😫', '😔', '😐', '😊', '🔥'][log.valence.clamp(1, 5)];
              return _SummaryCard(
                icon: Icons.mood,
                color: AppColors.mental,
                title: 'Mood hoy',
                value: '$emoji Valence ${log.valence}/5, Energia ${log.energy}/5',
                subtitle: log.tags.isNotEmpty ? 'Tags: ${log.tags}' : null,
                onTap: () => GoRouter.of(context).push(AppRoutes.mentalHistory),
              );
            },
          ),
          const SizedBox(height: 24),

          // History links
          Text('Historiales', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListTile(
            leading: Icon(Icons.nights_stay, color: AppColors.sleep),
            title: const Text('Historial de sueno'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => GoRouter.of(context).push(AppRoutes.sleepHistory),
          ),
          ListTile(
            leading: Icon(Icons.show_chart, color: AppColors.sleep),
            title: const Text('Ritmo circadiano'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => GoRouter.of(context).push(AppRoutes.circadian),
          ),
          ListTile(
            leading: Icon(Icons.calendar_month, color: AppColors.mental),
            title: const Text('Calendario emocional'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => GoRouter.of(context).push(AppRoutes.mentalHistory),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $subtitle',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(60)),
            color: color.withAlpha(15),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const Spacer(),
              Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withAlpha(25),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.bodySmall),
                    Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    if (subtitle != null)
                      Text(subtitle!, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.textTheme.bodySmall?.color),
            ],
          ),
        ),
      ),
    );
  }
}
