import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/constants/app_breakpoints.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/router/app_router.dart';
import 'package:life_os/features/mental/database/mental_dao.dart';
import 'package:life_os/features/sleep/database/sleep_dao.dart';

/// Wellness hub — desktop shows a dashboard with mood/sleep/energy history.
/// Action buttons in the header handle navigation to input forms.
/// Phone layout shows quick action cards for navigation.
class WellnessHubScreen extends ConsumerWidget {
  const WellnessHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sleepDao = ref.watch(sleepDaoProvider);
    final mentalDao = ref.watch(mentalDaoProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= AppBreakpoints.compact) {
            return _DesktopDashboard(theme: theme, sleepDao: sleepDao, mentalDao: mentalDao, today: today, weekAgo: weekAgo);
          }
          return _PhoneLayout(theme: theme, sleepDao: sleepDao, mentalDao: mentalDao, today: today);
        },
      ),
    );
  }
}

// =============================================================================
// DESKTOP — Dashboard with charts and history
// =============================================================================

class _DesktopDashboard extends StatelessWidget {
  const _DesktopDashboard({required this.theme, required this.sleepDao, required this.mentalDao, required this.today, required this.weekAgo});
  final ThemeData theme;
  final SleepDao sleepDao;
  final MentalDao mentalDao;
  final DateTime today;
  final DateTime weekAgo;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Top row: 3 stat cards ---
          Row(
            children: [
              Expanded(child: _sleepTodayCard(context)),
              const SizedBox(width: 12),
              Expanded(child: _moodTodayCard(context)),
              const SizedBox(width: 12),
              Expanded(child: _breathingTodayCard(context)),
            ],
          ),
          const SizedBox(height: 20),
          // --- Two columns: mood history + sleep history ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _moodWeekCard(context)),
              const SizedBox(width: 16),
              Expanded(child: _sleepWeekCard(context)),
            ],
          ),
          const SizedBox(height: 16),
          // --- Energy week ---
          _energyWeekCard(context),
        ],
      ),
    );
  }

  // --- Stat card: Sleep today ---
  Widget _sleepTodayCard(BuildContext context) {
    return StreamBuilder<List<SleepLog>>(
      stream: sleepDao.watchSleepLogs(today.subtract(const Duration(days: 1)), today),
      builder: (ctx, snap) {
        final logs = snap.data ?? [];
        final hasData = logs.isNotEmpty;
        final hours = hasData ? logs.first.wakeTime.difference(logs.first.bedTime).inMinutes / 60 : 0.0;
        final score = hasData ? logs.first.sleepScore : 0;
        return _StatCard(
          icon: Icons.bedtime,
          color: AppColors.sleep,
          title: 'Sueno anoche',
          value: hasData ? '${hours.toStringAsFixed(1)}h' : '—',
          subtitle: hasData ? 'Score $score/100' : 'Sin registro',
          onTap: () => GoRouter.of(context).push(AppRoutes.sleepHistory),
        );
      },
    );
  }

  // --- Stat card: Mood today ---
  Widget _moodTodayCard(BuildContext context) {
    return StreamBuilder<List<MoodLog>>(
      stream: mentalDao.watchMoodLogs(today, today.add(const Duration(days: 1))),
      builder: (ctx, snap) {
        final logs = snap.data ?? [];
        final hasData = logs.isNotEmpty;
        final emoji = hasData ? ['', '😫', '😔', '😐', '😊', '🔥'][logs.first.valence.clamp(1, 5)] : '—';
        return _StatCard(
          icon: Icons.mood,
          color: AppColors.mental,
          title: 'Mood hoy',
          value: emoji,
          subtitle: hasData ? 'Valence ${logs.first.valence}/5 • Energia ${logs.first.energy}/5' : 'Sin registro',
          onTap: () => GoRouter.of(context).push(AppRoutes.mentalHistory),
        );
      },
    );
  }

  // --- Stat card: Breathing today ---
  Widget _breathingTodayCard(BuildContext context) {
    return StreamBuilder<List<BreathingSession>>(
      stream: mentalDao.watchBreathingSessions(today, today.add(const Duration(days: 1))),
      builder: (ctx, snap) {
        final sessions = snap.data ?? [];
        final totalMin = sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds) ~/ 60;
        return _StatCard(
          icon: Icons.self_improvement,
          color: AppColors.mental,
          title: 'Respiracion hoy',
          value: sessions.isEmpty ? '—' : '${totalMin}min',
          subtitle: sessions.isEmpty ? 'Sin sesiones' : '${sessions.length} sesion(es)',
          onTap: () => GoRouter.of(context).push(AppRoutes.breathing),
        );
      },
    );
  }

  // --- Mood week chart card ---
  Widget _moodWeekCard(BuildContext context) {
    return StreamBuilder<List<MoodLog>>(
      stream: mentalDao.watchMoodLogs(weekAgo, today.add(const Duration(days: 1))),
      builder: (ctx, snap) {
        final logs = snap.data ?? [];
        return _DashCard(
          title: 'Mood — ultimos 7 dias',
          icon: Icons.mood,
          color: AppColors.mental,
          onTitleTap: () => GoRouter.of(context).push(AppRoutes.mentalHistory),
          child: logs.isEmpty
              ? const _EmptyHint(text: 'Registra tu mood para ver tendencias')
              : _MoodWeekBars(logs: logs, today: today),
        );
      },
    );
  }

  // --- Sleep week chart card ---
  Widget _sleepWeekCard(BuildContext context) {
    return StreamBuilder<List<SleepLog>>(
      stream: sleepDao.watchSleepLogs(weekAgo, today),
      builder: (ctx, snap) {
        final logs = snap.data ?? [];
        return _DashCard(
          title: 'Sueno — ultimos 7 dias',
          icon: Icons.bedtime,
          color: AppColors.sleep,
          onTitleTap: () => GoRouter.of(context).push(AppRoutes.sleepHistory),
          child: logs.isEmpty
              ? const _EmptyHint(text: 'Registra tu sueno para ver tendencias')
              : _SleepWeekBars(logs: logs, today: today),
        );
      },
    );
  }

  // --- Energy week card ---
  Widget _energyWeekCard(BuildContext context) {
    return StreamBuilder<List<EnergyLog>>(
      stream: sleepDao.watchEnergyLogs(weekAgo, today.add(const Duration(days: 1))),
      builder: (ctx, snap) {
        final logs = snap.data ?? [];
        return _DashCard(
          title: 'Energia — ultimos 7 dias',
          icon: Icons.bolt,
          color: AppColors.gym,
          child: logs.isEmpty
              ? const _EmptyHint(text: 'Registra tu energia para ver tendencias')
              : _EnergyWeekBars(logs: logs, today: today),
        );
      },
    );
  }
}

// =============================================================================
// PHONE layout — navigation cards (unchanged)
// =============================================================================

class _PhoneLayout extends StatelessWidget {
  const _PhoneLayout({required this.theme, required this.sleepDao, required this.mentalDao, required this.today});
  final ThemeData theme;
  final SleepDao sleepDao;
  final MentalDao mentalDao;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Acciones rapidas', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.4, children: [
        _NavCard(icon: Icons.mood, label: 'Estado de animo', sub: 'Registrar mood', color: AppColors.mental, onTap: () => GoRouter.of(context).push(AppRoutes.mood)),
        _NavCard(icon: Icons.self_improvement, label: 'Respiracion', sub: 'Ejercicio guiado', color: AppColors.mental, onTap: () => GoRouter.of(context).push(AppRoutes.breathing)),
        _NavCard(icon: Icons.favorite, label: 'Gratitud', sub: '3 cosas buenas', color: AppColors.mental, onTap: () => GoRouter.of(context).push(AppRoutes.gratitude)),
        _NavCard(icon: Icons.bedtime, label: 'Sueno', sub: 'Registrar noche', color: AppColors.sleep, onTap: () => GoRouter.of(context).push(AppRoutes.sleep)),
        _NavCard(icon: Icons.bolt, label: 'Energia', sub: 'Check-in rapido', color: AppColors.gym, onTap: () => GoRouter.of(context).push(AppRoutes.energy)),
        _NavCard(icon: Icons.psychology, label: 'Patrones IA', sub: 'Analisis cruzado', color: AppColors.goals, onTap: () => GoRouter.of(context).push(AppRoutes.mentalInsights)),
      ]),
      const SizedBox(height: 24),
      Text('Resumen de hoy', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      _buildSleepSummary(context, sleepDao, today),
      const SizedBox(height: 8),
      _buildMoodSummary(context, mentalDao, today),
      const SizedBox(height: 24),
      Text('Historiales', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      ListTile(leading: Icon(Icons.nights_stay, color: AppColors.sleep), title: const Text('Historial de sueno'), trailing: const Icon(Icons.chevron_right), onTap: () => GoRouter.of(context).push(AppRoutes.sleepHistory)),
      ListTile(leading: Icon(Icons.show_chart, color: AppColors.sleep), title: const Text('Ritmo circadiano'), trailing: const Icon(Icons.chevron_right), onTap: () => GoRouter.of(context).push(AppRoutes.circadian)),
      ListTile(leading: Icon(Icons.calendar_month, color: AppColors.mental), title: const Text('Calendario emocional'), trailing: const Icon(Icons.chevron_right), onTap: () => GoRouter.of(context).push(AppRoutes.mentalHistory)),
    ]);
  }

  Widget _buildSleepSummary(BuildContext ctx, SleepDao dao, DateTime todayStart) {
    return StreamBuilder<List<SleepLog>>(
      stream: dao.watchSleepLogs(todayStart.subtract(const Duration(days: 1)), todayStart),
      builder: (_, snap) {
        final logs = snap.data ?? [];
        if (logs.isEmpty) return _SummaryTile(icon: Icons.bedtime, color: AppColors.sleep, title: 'Sueno', value: 'Sin registro', onTap: () => GoRouter.of(ctx).push(AppRoutes.sleep));
        final l = logs.first;
        final h = l.wakeTime.difference(l.bedTime).inMinutes / 60;
        return _SummaryTile(icon: Icons.bedtime, color: AppColors.sleep, title: 'Sueno anoche', value: '${h.toStringAsFixed(1)}h — Score ${l.sleepScore}/100', onTap: () => GoRouter.of(ctx).push(AppRoutes.sleepHistory));
      },
    );
  }

  Widget _buildMoodSummary(BuildContext ctx, MentalDao dao, DateTime todayStart) {
    return StreamBuilder<List<MoodLog>>(
      stream: dao.watchMoodLogs(todayStart, todayStart.add(const Duration(days: 1))),
      builder: (_, snap) {
        final logs = snap.data ?? [];
        if (logs.isEmpty) return _SummaryTile(icon: Icons.mood, color: AppColors.mental, title: 'Mood', value: 'Sin registro hoy', onTap: () => GoRouter.of(ctx).push(AppRoutes.mood));
        final l = logs.first;
        final e = ['', '😫', '😔', '😐', '😊', '🔥'][l.valence.clamp(1, 5)];
        return _SummaryTile(icon: Icons.mood, color: AppColors.mental, title: 'Mood hoy', value: '$e ${l.valence}/5', onTap: () => GoRouter.of(ctx).push(AppRoutes.mentalHistory));
      },
    );
  }
}

// =============================================================================
// Shared widgets
// =============================================================================

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.color, required this.title, required this.value, required this.subtitle, this.onTap});
  final IconData icon; final Color color; final String title; final String value; final String subtitle; final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.lightTextSecondary)),
            ]),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(subtitle, style: theme.textTheme.bodySmall),
          ]),
        ),
      ),
    );
  }
}

class _DashCard extends StatelessWidget {
  const _DashCard({required this.title, required this.icon, required this.color, required this.child, this.onTitleTap});
  final String title; final IconData icon; final Color color; final Widget child; final VoidCallback? onTitleTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(
            onTap: onTitleTap,
            child: Row(children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              if (onTitleTap != null) ...[const Spacer(), Icon(Icons.open_in_new, size: 14, color: AppColors.lightTextSecondary)],
            ]),
          ),
          const SizedBox(height: 16),
          child,
        ]),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Center(child: Text(text, style: TextStyle(color: AppColors.lightTextSecondary, fontSize: 13))),
  );
}

// =============================================================================
// Week bar charts (simple custom widgets, no fl_chart dependency)
// =============================================================================

class _MoodWeekBars extends StatelessWidget {
  const _MoodWeekBars({required this.logs, required this.today});
  final List<MoodLog> logs; final DateTime today;

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((d) {
          final dayLogs = logs.where((l) => l.date.year == d.year && l.date.month == d.month && l.date.day == d.day).toList();
          final hasData = dayLogs.isNotEmpty;
          final valence = hasData ? dayLogs.first.valence : 0;
          final fraction = hasData ? valence / 5.0 : 0.0;
          final emoji = hasData ? ['', '😫', '😔', '😐', '😊', '🔥'][valence.clamp(1, 5)] : '';

          return Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (hasData) Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                height: hasData ? 80 * fraction : 4,
                decoration: BoxDecoration(
                  color: hasData ? AppColors.mental.withAlpha(180) : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Text(dayLabels[d.weekday - 1], style: TextStyle(fontSize: 11, color: AppColors.lightTextSecondary)),
            ]),
          ));
        }).toList(),
      ),
    );
  }
}

class _SleepWeekBars extends StatelessWidget {
  const _SleepWeekBars({required this.logs, required this.today});
  final List<SleepLog> logs; final DateTime today;

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((d) {
          // Sleep logs for this night (bedTime day matches d-1 or d)
          final dayLogs = logs.where((l) {
            final bed = DateTime(l.bedTime.year, l.bedTime.month, l.bedTime.day);
            final wake = DateTime(l.wakeTime.year, l.wakeTime.month, l.wakeTime.day);
            return bed == d || wake == d || bed == d.subtract(const Duration(days: 1));
          }).toList();
          final hasData = dayLogs.isNotEmpty;
          final hours = hasData ? dayLogs.first.wakeTime.difference(dayLogs.first.bedTime).inMinutes / 60.0 : 0.0;
          final fraction = (hours / 10.0).clamp(0.0, 1.0); // 10h = full bar

          return Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (hasData) Text('${hours.toStringAsFixed(1)}h', style: TextStyle(fontSize: 10, color: AppColors.sleep, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                height: hasData ? 80 * fraction : 4,
                decoration: BoxDecoration(
                  color: hasData ? AppColors.sleep.withAlpha(180) : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Text(dayLabels[d.weekday - 1], style: TextStyle(fontSize: 11, color: AppColors.lightTextSecondary)),
            ]),
          ));
        }).toList(),
      ),
    );
  }
}

class _EnergyWeekBars extends StatelessWidget {
  const _EnergyWeekBars({required this.logs, required this.today});
  final List<EnergyLog> logs; final DateTime today;

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((d) {
          final dayLogs = logs.where((l) => l.date.year == d.year && l.date.month == d.month && l.date.day == d.day).toList();
          final hasData = dayLogs.isNotEmpty;
          final avg = hasData ? dayLogs.fold<int>(0, (s, l) => s + l.level) / dayLogs.length : 0.0;
          final fraction = (avg / 10.0).clamp(0.0, 1.0);

          return Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (hasData) Text(avg.toStringAsFixed(0), style: TextStyle(fontSize: 10, color: AppColors.gym, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                height: hasData ? 80 * fraction : 4,
                decoration: BoxDecoration(
                  color: hasData ? AppColors.gym.withAlpha(180) : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Text(dayLabels[d.weekday - 1], style: TextStyle(fontSize: 11, color: AppColors.lightTextSecondary)),
            ]),
          ));
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// Small widgets
// =============================================================================

class _NavCard extends StatelessWidget {
  const _NavCard({required this.icon, required this.label, required this.sub, required this.color, required this.onTap});
  final IconData icon; final String label; final String sub; final Color color; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withAlpha(60)), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withAlpha(30), color.withAlpha(8)])),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 28), const Spacer(),
        Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        Text(sub, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha(160))),
      ]),
    ));
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.icon, required this.color, required this.title, required this.value, this.onTap});
  final IconData icon; final Color color; final String title; final String value; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
      CircleAvatar(backgroundColor: color.withAlpha(25), child: Icon(icon, color: color, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: theme.textTheme.bodySmall),
        Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      ])),
      if (onTap != null) Icon(Icons.chevron_right, color: theme.textTheme.bodySmall?.color),
    ]))));
  }
}
