import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/widgets/chart_card.dart';
import 'package:life_os/features/habits/database/habits_dao.dart';

// ---------------------------------------------------------------------------
// Estado de un dia en el calendario del habito.
// ---------------------------------------------------------------------------

enum _DayStatus {
  completed,
  missed,
  notApplicable,
  todayPending,
  future,
}

// ---------------------------------------------------------------------------
// Pantalla: detalle de habito
// ---------------------------------------------------------------------------

/// Detalle de un habito con calendario mensual de cumplimiento, estadisticas
/// y acciones de archivar y editar.
///
/// Accesibilidad: A11Y-HAB-03 — el calendario tiene descripcion semantica y
/// cada dia tiene etiqueta con fecha y estado.
class HabitDetailScreen extends ConsumerStatefulWidget {
  const HabitDetailScreen({
    super.key,
    this.habitId,
  });

  final int? habitId;

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  DateTime _displayedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  void _previousMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    if (_displayedMonth.isBefore(currentMonth)) {
      setState(() {
        _displayedMonth =
            DateTime(_displayedMonth.year, _displayedMonth.month + 1);
      });
    }
  }

  bool get _canGoNext {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    return _displayedMonth.isBefore(currentMonth);
  }

  void _handleArchive(Habit habit) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const ValueKey('habit-archive-dialog'),
        title: const Text('Archivar habito'),
        content: Text(
          'Archivar "${habit.name}" lo ocultara del dashboard pero '
          'conservara todo el historial.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('habit-archive-cancel-button'),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const ValueKey('habit-archive-confirm-button'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.habits,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(habitsNotifierProvider)
                  .archiveHabit(habit.id);
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('Archivar'),
          ),
        ],
      ),
    );
  }

  void _handleEdit(Habit habit) {
    GoRouter.of(context).push('/habits/${habit.id}/edit');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dao = ref.watch(habitsDaoProvider);
    final habitId = widget.habitId;

    if (habitId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Habito'), centerTitle: true, foregroundColor: AppColors.habits),
        body: const Center(child: Text('Habito no encontrado')),
      );
    }

    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    final monthLabel =
        '${months[_displayedMonth.month - 1]} ${_displayedMonth.year}';

    return StreamBuilder<List<Habit>>(
      stream: dao.watchActiveHabits(),
      builder: (context, snapshot) {
        final habits = snapshot.data ?? [];
        final habit =
            habits.where((h) => h.id == habitId).firstOrNull;

        if (snapshot.connectionState == ConnectionState.waiting &&
            habit == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (habit == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Habito'), centerTitle: true, foregroundColor: AppColors.habits),
            body: const Center(child: Text('Habito no encontrado')),
          );
        }

        return Scaffold(
          key: const ValueKey('habit-detail-screen'),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            foregroundColor: AppColors.habits,
            title: Semantics(
              header: true,
              child: Text(habit.name),
            ),
            leading: Semantics(
              label: 'Volver',
              button: true,
              child: IconButton(
                key: const ValueKey('habit-detail-back-button'),
                icon: const Icon(Icons.arrow_back_outlined),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Volver',
              ),
            ),
            actions: [
              Semantics(
                label: 'Editar habito ${habit.name}',
                button: true,
                child: IconButton(
                  key: const ValueKey('habit-detail-edit-button'),
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _handleEdit(habit),
                  tooltip: 'Editar',
                ),
              ),
              Semantics(
                label: 'Archivar habito ${habit.name}',
                button: true,
                child: IconButton(
                  key: const ValueKey('habit-detail-archive-button'),
                  icon: const Icon(Icons.archive_outlined),
                  onPressed: () => _handleArchive(habit),
                  tooltip: 'Archivar',
                ),
              ),
            ],
          ),
          body: _HabitDetailBody(
            habit: habit,
            displayedMonth: _displayedMonth,
            monthLabel: monthLabel,
            canGoNext: _canGoNext,
            onPreviousMonth: _previousMonth,
            onNextMonth: _nextMonth,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: cuerpo del detalle (carga estadisticas async)
// ---------------------------------------------------------------------------

class _HabitDetailBody extends ConsumerWidget {
  const _HabitDetailBody({
    required this.habit,
    required this.displayedMonth,
    required this.monthLabel,
    required this.canGoNext,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final Habit habit;
  final DateTime displayedMonth;
  final String monthLabel;
  final bool canGoNext;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(habitsDaoProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Load stats + calendar logs
    final from = DateTime(displayedMonth.year, displayedMonth.month, 1);
    final daysInMonth =
        DateTime(displayedMonth.year, displayedMonth.month + 1, 0).day;
    final to = DateTime(displayedMonth.year, displayedMonth.month, daysInMonth);

    return StreamBuilder<List<HabitLog>>(
      stream: dao.watchHabitLogs(habit.id, from, to),
      builder: (context, logsSnapshot) {
        final monthLogs = logsSnapshot.data ?? [];

        return FutureBuilder<(int, int, int, double)>(
          future: _loadStats(dao, today),
          builder: (context, statsSnapshot) {
            final stats = statsSnapshot.data;
            final currentStreak = stats?.$1 ?? 0;
            final bestStreak = stats?.$2 ?? 0;
            final totalCheckIns = stats?.$3 ?? 0;
            final completionRate = stats?.$4 ?? 0.0;

            return ListView(
              key: const ValueKey('habit-detail-list'),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                // --- Encabezado: icono + nombre + rachas ---
                _HabitHeader(
                  key: const ValueKey('habit-detail-header'),
                  habit: habit,
                  currentStreak: currentStreak,
                  bestStreak: bestStreak,
                ),
                const SizedBox(height: 20),

                // --- Calendario mensual ---
                Card(
                  key: const ValueKey('habit-detail-calendar-card'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Controles de navegacion del mes
                        Row(
                          children: [
                            Semantics(
                              label: 'Mes anterior',
                              button: true,
                              child: IconButton(
                                key: const ValueKey(
                                    'habit-calendar-prev-month'),
                                icon: const Icon(Icons.chevron_left),
                                onPressed: onPreviousMonth,
                                tooltip: 'Mes anterior',
                              ),
                            ),
                            Expanded(
                              child: Text(
                                monthLabel,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Semantics(
                              label: 'Mes siguiente',
                              button: true,
                              child: IconButton(
                                key: const ValueKey(
                                    'habit-calendar-next-month'),
                                icon: Icon(
                                  Icons.chevron_right,
                                  color: canGoNext
                                      ? null
                                      : Theme.of(context).disabledColor,
                                ),
                                onPressed: canGoNext ? onNextMonth : null,
                                tooltip: 'Mes siguiente',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Cabecera de dias de la semana
                        _CalendarWeekHeader(
                          key: const ValueKey('habit-calendar-week-header'),
                        ),
                        const SizedBox(height: 4),

                        // Cuadricula de dias
                        Semantics(
                          label:
                              'Calendario de cumplimiento de $monthLabel',
                          child: _CalendarGrid(
                            key: const ValueKey('habit-calendar-grid'),
                            habit: habit,
                            displayedMonth: displayedMonth,
                            monthLogs: monthLogs,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Leyenda
                        _CalendarLegend(
                          key: const ValueKey('habit-calendar-legend'),
                          color: Color(habit.color),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Estadisticas ---
                Semantics(
                  label: 'Estadisticas del habito ${habit.name}',
                  child: _StatsGrid(
                    key: const ValueKey('habit-detail-stats-grid'),
                    habit: habit,
                    currentStreak: currentStreak,
                    bestStreak: bestStreak,
                    totalCheckIns: totalCheckIns,
                    completionRate: completionRate,
                  ),
                ),
                const SizedBox(height: 16),

                // --- Grafica de tasa de cumplimiento semanal ---
                _HabitCompletionTrendChart(
                  key: const ValueKey('habit-completion-trend-chart'),
                  habitId: habit.id,
                  habitColor: Color(habit.color),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<(int, int, int, double)> _loadStats(
    dynamic dao,
    DateTime today,
  ) async {
    final currentStreak =
        await dao.streakCount(habit.id, today) as int;
    final bestStreak = await dao.longestStreak(habit.id) as int;
    final now = DateTime.now();
    final from30 = now.subtract(const Duration(days: 30));
    final rate = await dao.completionRate(
      habit.id,
      from30,
      now,
    ) as double;

    // Total check-ins: count all logs
    final allLogs = await (dao as dynamic)
        .watchHabitLogs(
          habit.id,
          DateTime(2000),
          DateTime(2100),
        )
        .first as List<HabitLog>;
    return (currentStreak, bestStreak, allLogs.length, rate);
  }
}

// ---------------------------------------------------------------------------
// Widget: encabezado del habito
// ---------------------------------------------------------------------------

class _HabitHeader extends StatelessWidget {
  const _HabitHeader({
    super.key,
    required this.habit,
    required this.currentStreak,
    required this.bestStreak,
  });

  final Habit habit;
  final int currentStreak;
  final int bestStreak;

  IconData get _habitIcon {
    final cp = int.tryParse(habit.icon);
    if (cp != null) return IconData(cp, fontFamily: 'MaterialIcons');
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(habit.color);
    return Semantics(
      label: '${habit.name}, racha actual $currentStreak dias, '
          'mejor racha $bestStreak dias',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          children: [
            // Icono
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(_habitIcon, color: color, size: 32),
            ),
            const SizedBox(width: 16),

            // Nombre y rachas
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StreakCounter(
                        key: const ValueKey('habit-current-streak'),
                        label: 'Racha actual',
                        days: currentStreak,
                        color: color,
                        icon: Icons.local_fire_department,
                      ),
                      const SizedBox(width: 16),
                      _StreakCounter(
                        key: const ValueKey('habit-best-streak'),
                        label: 'Mejor racha',
                        days: bestStreak,
                        color: AppColors.warning,
                        icon: Icons.emoji_events_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: contador de racha
// ---------------------------------------------------------------------------

class _StreakCounter extends StatelessWidget {
  const _StreakCounter({
    super.key,
    required this.label,
    required this.days,
    required this.color,
    required this.icon,
  });

  final String label;
  final int days;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              '$days dias',
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(130),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: cabecera de dias de la semana del calendario
// ---------------------------------------------------------------------------

class _CalendarWeekHeader extends StatelessWidget {
  const _CalendarWeekHeader({super.key});

  static const _labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: _labels
          .map(
            (label) => Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withAlpha(130),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: cuadricula del calendario
// TODO: Extract to separate widget file
// ---------------------------------------------------------------------------

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    super.key,
    required this.habit,
    required this.displayedMonth,
    required this.monthLogs,
  });

  final Habit habit;
  final DateTime displayedMonth;
  final List<HabitLog> monthLogs;

  Color _dayColor(_DayStatus status) => switch (status) {
        _DayStatus.completed => AppColors.success,
        _DayStatus.missed => AppColors.error,
        _DayStatus.notApplicable => Colors.grey.withAlpha(80),
        _DayStatus.todayPending => AppColors.warning,
        _DayStatus.future => Colors.transparent,
      };

  String _daySemanticLabel(int day, _DayStatus status) {
    final statusLabel = switch (status) {
      _DayStatus.completed => 'completado',
      _DayStatus.missed => 'perdido',
      _DayStatus.notApplicable => 'no aplica',
      _DayStatus.todayPending => 'hoy pendiente',
      _DayStatus.future => 'futuro',
    };
    return 'Dia $day: $statusLabel';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final firstDay =
        DateTime(displayedMonth.year, displayedMonth.month, 1);
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth =
        DateTime(displayedMonth.year, displayedMonth.month + 1, 0).day;

    // Build a set of days that have logs
    final loggedDays = <int>{};
    for (final log in monthLogs) {
      if (log.date.year == displayedMonth.year &&
          log.date.month == displayedMonth.month) {
        loggedDays.add(log.date.day);
      }
    }

    // Build grid cells
    final List<({int? day, _DayStatus status, DateTime? date})> cells = [
      for (int i = 0; i < startOffset; i++) (day: null, status: _DayStatus.future, date: null),
      for (int d = 1; d <= daysInMonth; d++) (() {
        final date = DateTime(displayedMonth.year, displayedMonth.month, d);
        _DayStatus status;
        if (date.isAfter(today)) {
          status = _DayStatus.future;
        } else if (date.year == today.year &&
            date.month == today.month &&
            date.day == today.day) {
          status = loggedDays.contains(d)
              ? _DayStatus.completed
              : _DayStatus.todayPending;
        } else {
          status = loggedDays.contains(d)
              ? _DayStatus.completed
              : _DayStatus.missed;
        }
        return (day: d, status: status, date: date);
      })(),
    ];

    // Pad to full weeks
    while (cells.length % 7 != 0) {
      cells.add((day: null, status: _DayStatus.future, date: null));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: cells.length,
      itemBuilder: (context, index) {
        final cell = cells[index];
        if (cell.day == null) return const SizedBox.shrink();

        final day = cell.day!;
        final bgColor = _dayColor(cell.status);
        final isFuture = cell.status == _DayStatus.future;
        final isTodayPending = cell.status == _DayStatus.todayPending;
        final dateStr =
            cell.date?.toIso8601String().substring(0, 10) ?? 'x-$index';

        return Semantics(
          label: _daySemanticLabel(day, cell.status),
          child: Container(
            key: ValueKey('habit-calendar-day-$dateStr'),
            decoration: BoxDecoration(
              color:
                  isFuture ? Colors.transparent : bgColor.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
              border: isTodayPending
                  ? Border.all(color: AppColors.warning, width: 1.5)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isFuture
                    ? theme.disabledColor
                    : (isTodayPending ? AppColors.warning : bgColor),
                fontWeight:
                    isTodayPending ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: leyenda del calendario
// ---------------------------------------------------------------------------

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      (color: AppColors.success, label: 'Completado'),
      (color: AppColors.error, label: 'Perdido'),
      (color: AppColors.warning, label: 'Hoy pendiente'),
      (color: Colors.grey.withAlpha(100), label: 'N/A'),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: item.color.withAlpha(50),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: item.color, width: 1),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              item.label,
              style: theme.textTheme.labelSmall,
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: grilla de estadisticas
// TODO: Extract to separate widget file
// ---------------------------------------------------------------------------

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    super.key,
    required this.habit,
    required this.currentStreak,
    required this.bestStreak,
    required this.totalCheckIns,
    required this.completionRate,
  });

  final Habit habit;
  final int currentStreak;
  final int bestStreak;
  final int totalCheckIns;
  final double completionRate;

  @override
  Widget build(BuildContext context) {
    final color = Color(habit.color);
    final completionPct = '${(completionRate * 100).round()}%';

    return GridView.count(
      key: const ValueKey('habit-stats-grid'),
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.0,
      children: [
        _StatCard(
          key: const ValueKey('habit-stat-completion-rate'),
          icon: Icons.percent_outlined,
          value: completionPct,
          label: 'Tasa de cumplimiento',
          color: color,
        ),
        _StatCard(
          key: const ValueKey('habit-stat-total-checkins'),
          icon: Icons.check_circle_outline,
          value: '$totalCheckIns',
          label: 'Check-ins totales',
          color: AppColors.success,
        ),
        _StatCard(
          key: const ValueKey('habit-stat-current-streak'),
          icon: Icons.local_fire_department,
          value: '${currentStreak}d',
          label: 'Racha actual',
          color: color,
        ),
        _StatCard(
          key: const ValueKey('habit-stat-best-streak'),
          icon: Icons.emoji_events_outlined,
          value: '${bestStreak}d',
          label: 'Mejor racha',
          color: AppColors.warning,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: tarjeta de estadistica individual
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  const _StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $value',
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Text(
                      label,
                      style: theme.textTheme.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Habit Completion Trend Chart — weekly completion rate over 12 weeks
// ---------------------------------------------------------------------------

class _HabitCompletionTrendChart extends ConsumerWidget {
  const _HabitCompletionTrendChart({
    super.key,
    required this.habitId,
    required this.habitColor,
  });

  final int habitId;
  final Color habitColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(habitsDaoProvider);
    final now = DateTime.now();

    return FutureBuilder<List<({String label, double rate})>>(
      future: _buildWeeklyRates(dao, now),
      builder: (context, snapshot) {
        final weekData = snapshot.data ?? [];
        final hasData = weekData.any((w) => w.rate > 0);

        return ChartCard(
          title: 'Cumplimiento semanal (12 semanas)',
          child: !hasData
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Sin datos suficientes'),
                  ),
                )
              : _buildChart(weekData),
        );
      },
    );
  }

  Future<List<({String label, double rate})>> _buildWeeklyRates(
    HabitsDao dao,
    DateTime now,
  ) async {
    final result = <({String label, double rate})>[];

    for (int w = 11; w >= 0; w--) {
      final weekEnd = now.subtract(Duration(days: w * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 6));
      final label = '${weekStart.day}/${weekStart.month}';
      final rate = await dao.completionRate(habitId, weekStart, weekEnd);
      result.add((label: label, rate: rate));
    }

    return result;
  }

  Widget _buildChart(List<({String label, double rate})> weekData) {
    final spots = weekData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.rate * 100);
    }).toList();

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          lineTouchData: const LineTouchData(enabled: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: Color(0x1A9E9E9E),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 2,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= weekData.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    weekData[idx].label,
                    style: const TextStyle(fontSize: 8),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: habitColor,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                  radius: 3,
                  color: habitColor,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: habitColor.withAlpha(40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
