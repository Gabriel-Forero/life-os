import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/features/habits/database/habits_dao.dart';
import 'package:life_os/core/widgets/animated_list_item.dart';
import 'package:life_os/core/widgets/pressable_card.dart';

// ---------------------------------------------------------------------------
// Pantalla principal del dashboard de habitos
// ---------------------------------------------------------------------------

/// Dashboard de habitos del dia con lista de pendientes y completados,
/// barra de progreso cuantitativa y racha de dias consecutivos.
///
/// Accesibilidad: A11Y-HAB-01 — cada fila de habito tiene etiqueta semantica
/// con nombre, estado y racha.
class HabitsDashboardScreen extends ConsumerStatefulWidget {
  const HabitsDashboardScreen({super.key});

  @override
  ConsumerState<HabitsDashboardScreen> createState() =>
      _HabitsDashboardScreenState();
}

class _HabitsDashboardScreenState
    extends ConsumerState<HabitsDashboardScreen> {
  final DateTime _today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  Future<void> _toggleHabit(Habit habit, bool isCompleted) async {
    final notifier = ref.read(habitsNotifierProvider);
    if (isCompleted) {
      await notifier.uncheckIn(habit.id, _today);
    } else {
      await notifier.checkIn(habit.id);
    }
  }

  Future<void> _incrementQuantitative(Habit habit, double current) async {
    final notifier = ref.read(habitsNotifierProvider);
    final next = current + 1;
    final target = habit.quantitativeTarget ?? 1.0;
    final clamped = next.clamp(0.0, target);
    await notifier.checkIn(habit.id, value: clamped);
  }

  @override
  Widget build(BuildContext context) {
    final dao = ref.watch(habitsDaoProvider);

    return Scaffold(
      key: const ValueKey('habits-dashboard-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Semantics(
          header: true,
          child: const Text('Habitos'),
        ),
        actions: [
          Semantics(
            label: 'Ver estadisticas de habitos',
            button: true,
            child: IconButton(
              key: const ValueKey('habits-stats-button'),
              icon: const Icon(Icons.bar_chart_outlined),
              onPressed: () {},
              tooltip: 'Estadisticas',
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Habit>>(
        stream: dao.watchActiveHabits(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final habits = snapshot.data ?? [];

          return _HabitsDashboardBody(
            key: const ValueKey('habits-dashboard-body'),
            habits: habits,
            today: _today,
            onToggle: _toggleHabit,
            onIncrement: _incrementQuantitative,
          );
        },
      ),
      floatingActionButton: Semantics(
        label: 'Agregar nuevo habito',
        button: true,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (context, value, child) =>
              Transform.scale(scale: value, child: child),
          child: FloatingActionButton(
            key: const ValueKey('habits-add-fab'),
            backgroundColor: AppColors.habits,
            foregroundColor: Colors.white,
            onPressed: () => GoRouter.of(context).push('/habits/add'),
            tooltip: 'Agregar habito',
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: cuerpo del dashboard (separado para poder leer logs por habito)
// ---------------------------------------------------------------------------

class _HabitsDashboardBody extends ConsumerWidget {
  const _HabitsDashboardBody({
    super.key,
    required this.habits,
    required this.today,
    required this.onToggle,
    required this.onIncrement,
  });

  final List<Habit> habits;
  final DateTime today;
  final Future<void> Function(Habit, bool) onToggle;
  final Future<void> Function(Habit, double) onIncrement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dao = ref.watch(habitsDaoProvider);

    // Stream all habit logs for today — rebuilds whenever a log is added/removed
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return StreamBuilder<List<HabitLog>>(
      stream: _watchAllLogsForToday(dao, todayStart, todayEnd),
      builder: (context, logsSnapshot) {
        final todayLogs = logsSnapshot.data ?? [];
        final statusMap = <int, _HabitStatus>{};
        for (final habit in habits) {
          final log = todayLogs.where((l) => l.habitId == habit.id).firstOrNull;
          statusMap[habit.id] = _HabitStatus(
            isCompleted: log != null,
            currentValue: log?.value ?? 0.0,
            streak: 0, // Streaks loaded separately if needed
          );
        }

        final pending = habits
            .where((h) => !(statusMap[h.id]?.isCompleted ?? false))
            .toList();
        final completed = habits
            .where((h) => statusMap[h.id]?.isCompleted ?? false)
            .toList();
        final allDone = habits.isNotEmpty && completed.length == habits.length;

        return RefreshIndicator(
          color: AppColors.habits,
          onRefresh: () async {},
          child: ListView(
            key: const ValueKey('habits-dashboard-list'),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            children: [
              // --- Progreso del dia ---
              _DayProgressHeader(
                key: const ValueKey('habits-day-progress'),
                completed: completed.length,
                total: habits.length,
                allDone: allDone,
              ),
              const SizedBox(height: 20),

              // --- Mensaje de celebracion ---
              if (allDone)
                _CelebrationBanner(
                  key: const ValueKey('habits-celebration-banner'),
                ),

              // --- Seccion Pendientes ---
              if (pending.isNotEmpty) ...[
                _SectionHeader(
                  key: const ValueKey('habits-pending-header'),
                  title: 'Pendientes',
                  count: pending.length,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(height: 8),
                ...pending.asMap().entries.map(
                  (entry) {
                    final habit = entry.value;
                    final status = statusMap[habit.id];
                    return AnimatedListItem(
                      index: entry.key,
                      child: _HabitRow(
                        key: ValueKey('habit-row-${habit.id}'),
                        habit: habit,
                        isCompleted: false,
                        currentValue: status?.currentValue ?? 0,
                        streakDays: status?.streak ?? 0,
                        onToggle: () => onToggle(habit, false),
                        onIncrement: habit.isQuantitative
                            ? () => onIncrement(
                                  habit,
                                  status?.currentValue ?? 0,
                                )
                            : null,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

              // --- Seccion Completados ---
              if (completed.isNotEmpty) ...[
                _SectionHeader(
                  key: const ValueKey('habits-completed-header'),
                  title: 'Completados',
                  count: completed.length,
                  color: AppColors.success,
                ),
                const SizedBox(height: 8),
                ...completed.asMap().entries.map(
                  (entry) {
                    final habit = entry.value;
                    final status = statusMap[habit.id];
                    return AnimatedListItem(
                      index: pending.length + entry.key,
                      child: _HabitRow(
                        key: ValueKey('habit-row-${habit.id}'),
                        habit: habit,
                        isCompleted: true,
                        currentValue: status?.currentValue ?? 0,
                        streakDays: status?.streak ?? 0,
                        onToggle: () => onToggle(habit, true),
                        onIncrement: null,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Stream<List<HabitLog>> _watchAllLogsForToday(
    HabitsDao dao,
    DateTime start,
    DateTime end,
  ) {
    // Watch logs for all habits combined — any insert/delete triggers rebuild
    if (habits.isEmpty) return Stream.value([]);
    // Use the first habit's stream as trigger, but load all
    return dao.watchHabitLogs(habits.first.id, start, end).asyncMap((_) async {
      final allLogs = <HabitLog>[];
      for (final h in habits) {
        final log = await dao.getLogForDate(h.id, start);
        if (log != null) allLogs.add(log);
      }
      return allLogs;
    });
  }

  // Keep for potential future use
  Future<Map<int, _HabitStatus>> _loadAllStatuses(
    dynamic dao,
  ) async {
    final Map<int, _HabitStatus> map = {};
    for (final habit in habits) {
      final log = await (dao as dynamic).getLogForDate(habit.id, today);
      final isCompleted = log != null;
      final currentValue = (log?.value as double?) ?? 0.0;
      final streak = await dao.streakCount(habit.id, today);
      map[habit.id] = _HabitStatus(
        isCompleted: isCompleted,
        currentValue: currentValue,
        streak: streak as int,
      );
    }
    return map;
  }
}

class _HabitStatus {
  const _HabitStatus({
    required this.isCompleted,
    required this.currentValue,
    required this.streak,
  });

  final bool isCompleted;
  final double currentValue;
  final int streak;
}

// ---------------------------------------------------------------------------
// Widget: encabezado de progreso del dia
// ---------------------------------------------------------------------------

class _DayProgressHeader extends StatelessWidget {
  const _DayProgressHeader({
    super.key,
    required this.completed,
    required this.total,
    required this.allDone,
  });

  final int completed;
  final int total;
  final bool allDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = total == 0 ? 0.0 : completed / total;

    return Semantics(
      label: 'Progreso del dia: $completed de $total habitos completados',
      child: Container(
        key: const ValueKey('habits-progress-container'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.habits.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.habits.withAlpha(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Hoy',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '$completed / $total',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.habits,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  key: const ValueKey('habits-day-progress-bar'),
                  value: value,
                  minHeight: 10,
                  backgroundColor: AppColors.habits.withAlpha(30),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.habits),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: banner de celebracion
// ---------------------------------------------------------------------------

class _CelebrationBanner extends StatelessWidget {
  const _CelebrationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Felicitaciones, completaste todos tus habitos del dia',
      child: Container(
        key: const ValueKey('habits-all-done-banner'),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.habits.withAlpha(40),
              AppColors.success.withAlpha(40),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.habits.withAlpha(60)),
        ),
        child: Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dia perfecto',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.habits,
                    ),
                  ),
                  Text(
                    'Completaste todos tus habitos de hoy.',
                    style: theme.textTheme.bodySmall,
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
// Widget: encabezado de seccion
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    super.key,
    required this.title,
    required this.count,
    required this.color,
  });

  final String title;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: fila de habito
// TODO: Extract to separate widget file
// ---------------------------------------------------------------------------

class _HabitRow extends StatelessWidget {
  const _HabitRow({
    super.key,
    required this.habit,
    required this.isCompleted,
    required this.currentValue,
    required this.streakDays,
    required this.onToggle,
    this.onIncrement,
  });

  final Habit habit;
  final bool isCompleted;
  final double currentValue;
  final int streakDays;
  final VoidCallback onToggle;
  final VoidCallback? onIncrement;

  Color get _habitColor => Color(habit.color);

  IconData get _habitIcon {
    // Parse stored icon name to IconData codePoint
    final cp = int.tryParse(habit.icon);
    if (cp != null) {
      return IconData(cp, fontFamily: 'MaterialIcons');
    }
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isQuantitative = habit.isQuantitative;
    final target = habit.quantitativeTarget ?? 1.0;
    final progress = isQuantitative
        ? (currentValue / target).clamp(0.0, 1.0)
        : 0.0;

    final semanticLabel = '${habit.name}, '
        '${isCompleted ? 'completado' : 'pendiente'}, '
        'racha de $streakDays dias'
        '${isQuantitative ? ', ${currentValue.toInt()} de ${target.toInt()} ${habit.quantitativeUnit ?? ''}' : ''}';

    return Semantics(
      label: semanticLabel,
      child: PressableCard(
        onTap: isQuantitative ? onIncrement : onToggle,
        child: Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
              // Icono del habito
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _habitColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_habitIcon, color: _habitColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Nombre + progreso
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: isCompleted ? theme.disabledColor : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (isQuantitative) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: TweenAnimationBuilder<double>(
                                tween:
                                    Tween<double>(begin: 0, end: progress),
                                duration:
                                    const Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                                builder: (context, value, _) =>
                                    LinearProgressIndicator(
                                  value: value,
                                  minHeight: 5,
                                  backgroundColor:
                                      _habitColor.withAlpha(25),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                    _habitColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${currentValue.toInt()}/${target.toInt()} ${habit.quantitativeUnit ?? ''}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _habitColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Racha badge
              _StreakBadge(
                key: ValueKey('streak-badge-${habit.id}'),
                days: streakDays,
                color: _habitColor,
              ),
              const SizedBox(width: 8),

              // Toggle / incrementar
              if (isQuantitative && onIncrement != null && !isCompleted)
                Semantics(
                  label: 'Registrar progreso en ${habit.name}',
                  button: true,
                  child: _IncrementButton(
                    key: ValueKey('habit-increment-${habit.id}'),
                    color: _habitColor,
                    onTap: onIncrement!,
                  ),
                )
              else
                Semantics(
                  label: isCompleted
                      ? 'Marcar ${habit.name} como pendiente'
                      : 'Marcar ${habit.name} como completado',
                  button: true,
                  child: _CheckToggle(
                    key: ValueKey('habit-check-${habit.id}'),
                    isChecked: isCompleted,
                    color: _habitColor,
                    onTap: onToggle,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
}

// ---------------------------------------------------------------------------
// Widget: badge de racha
// ---------------------------------------------------------------------------

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({
    super.key,
    required this.days,
    required this.color,
  });

  final int days;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (days == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            '$days',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: boton de check con animacion
// ---------------------------------------------------------------------------

class _CheckToggle extends StatefulWidget {
  const _CheckToggle({
    super.key,
    required this.isChecked,
    required this.color,
    required this.onTap,
  });

  final bool isChecked;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_CheckToggle> createState() => _CheckToggleState();
}

class _CheckToggleState extends State<_CheckToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.isChecked ? 1.0 : 0.0,
    );
    _fillAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void didUpdateWidget(_CheckToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isChecked != oldWidget.isChecked) {
      if (widget.isChecked) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _fillAnimation,
        builder: (context, _) {
          final filled = _fillAnimation.value;
          return Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Color.lerp(
                  Colors.grey.withAlpha(120),
                  widget.color,
                  filled,
                )!,
                width: 2,
              ),
              color: widget.color.withAlpha((filled * 255).toInt()),
            ),
            child: filled > 0.5
                ? Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white.withAlpha((filled * 255).toInt()),
                  )
                : null,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: boton de incremento para habitos cuantitativos
// ---------------------------------------------------------------------------

class _IncrementButton extends StatelessWidget {
  const _IncrementButton({
    super.key,
    required this.color,
    required this.onTap,
  });

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withAlpha(25),
          border: Border.all(color: color.withAlpha(80), width: 1.5),
        ),
        child: Icon(Icons.add, size: 16, color: color),
      ),
    );
  }
}
