import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/router/app_router.dart';
import 'package:life_os/features/habits/database/habits_dao.dart';
import 'package:life_os/core/widgets/animated_list_item.dart';
import 'package:life_os/core/widgets/pressable_card.dart';

// ---------------------------------------------------------------------------
// Pantalla principal del dashboard de habitos — UI mejorada
// ---------------------------------------------------------------------------

/// Dashboard de habitos con anillo de progreso, tarjetas enriquecidas,
/// racha con fuego, barra de completitud mensual y vista mini semanal.
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

          if (habits.isEmpty) {
            return _EmptyHabitsState(
              key: const ValueKey('habits-empty-state'),
              onAdd: () => GoRouter.of(context).push('/habits/add'),
            );
          }

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
// Widget: empty state
// ---------------------------------------------------------------------------

class _EmptyHabitsState extends StatelessWidget {
  const _EmptyHabitsState({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.habits.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.track_changes_outlined,
                size: 52,
                color: AppColors.habits,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Crea tu primer habito',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los habitos son la base del progreso',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const ValueKey('habits-create-first-button'),
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.habits,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                '+ Crear habito',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: cuerpo del dashboard
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
    final dao = ref.watch(habitsDaoProvider);

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
            streak: 0,
          );
        }

        final pending = habits
            .where((h) => !(statusMap[h.id]?.isCompleted ?? false))
            .toList();
        final completed = habits
            .where((h) => statusMap[h.id]?.isCompleted ?? false)
            .toList();
        final allDone = habits.isNotEmpty && completed.length == habits.length;

        // Compute monthly completion rate for each habit
        final monthStart = DateTime(today.year, today.month, 1);
        final monthEnd = DateTime(today.year, today.month + 1, 0);

        return RefreshIndicator(
          color: AppColors.habits,
          onRefresh: () async {},
          child: ListView(
            key: const ValueKey('habits-dashboard-list'),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            children: [
              // --- Header con anillo de progreso ---
              _DayProgressHeader(
                key: const ValueKey('habits-day-progress'),
                completed: completed.length,
                total: habits.length,
                allDone: allDone,
              ),
              const SizedBox(height: 20),

              // --- Banner de celebracion ---
              if (allDone)
                const _CelebrationBanner(
                  key: ValueKey('habits-celebration-banner'),
                ),

              // --- Seccion Pendientes ---
              if (pending.isNotEmpty) ...[
                _SectionHeader(
                  key: const ValueKey('habits-pending-header'),
                  title: 'Pendientes',
                  count: pending.length,
                  color: AppColors.lightTextSecondary,
                ),
                const SizedBox(height: 8),
                ...pending.asMap().entries.map(
                  (entry) {
                    final habit = entry.value;
                    final status = statusMap[habit.id];
                    return AnimatedListItem(
                      index: entry.key,
                      child: _HabitCard(
                        key: ValueKey('habit-card-${habit.id}'),
                        habit: habit,
                        isCompleted: false,
                        currentValue: status?.currentValue ?? 0,
                        streakDays: status?.streak ?? 0,
                        dao: dao,
                        today: today,
                        monthStart: monthStart,
                        monthEnd: monthEnd,
                        onToggle: () => onToggle(habit, false),
                        onIncrement: habit.isQuantitative
                            ? () => onIncrement(habit, status?.currentValue ?? 0)
                            : null,
                        onTapName: (ctx) => GoRouter.of(ctx)
                            .push('${AppRoutes.habitsDetail}?id=${habit.id}'),
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
                  color: AppColors.habits,
                ),
                const SizedBox(height: 8),
                ...completed.asMap().entries.map(
                  (entry) {
                    final habit = entry.value;
                    final status = statusMap[habit.id];
                    return AnimatedListItem(
                      index: pending.length + entry.key,
                      child: _HabitCard(
                        key: ValueKey('habit-card-${habit.id}'),
                        habit: habit,
                        isCompleted: true,
                        currentValue: status?.currentValue ?? 0,
                        streakDays: status?.streak ?? 0,
                        dao: dao,
                        today: today,
                        monthStart: monthStart,
                        monthEnd: monthEnd,
                        onToggle: () => onToggle(habit, true),
                        onIncrement: null,
                        onTapName: (ctx) => GoRouter.of(ctx)
                            .push('${AppRoutes.habitsDetail}?id=${habit.id}'),
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
    if (habits.isEmpty) return Stream.value([]);
    return dao.watchHabitLogs(habits.first.id, start, end).asyncMap((_) async {
      final allLogs = <HabitLog>[];
      for (final h in habits) {
        final log = await dao.getLogForDate(h.id, start);
        if (log != null) allLogs.add(log);
      }
      return allLogs;
    });
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
// Widget: encabezado de progreso del dia con anillo
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Anillo de progreso circular
            _ProgressRingDisplay(
              progress: progress,
              completed: completed,
              total: total,
            ),
            const SizedBox(width: 20),
            // Texto informativo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hoy',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.lightTextSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$completed',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: AppColors.habits,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        TextSpan(
                          text: '/$total',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppColors.lightTextSecondary,
                            fontWeight: FontWeight.w400,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    total == 0
                        ? 'Sin habitos activos'
                        : completed == total
                            ? 'Todos completados!'
                            : '${total - completed} pendiente${total - completed != 1 ? 's' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: completed == total && total > 0
                          ? AppColors.habits
                          : AppColors.lightTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
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

class _ProgressRingDisplay extends StatelessWidget {
  const _ProgressRingDisplay({
    required this.progress,
    required this.completed,
    required this.total,
  });

  final double progress;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: 80,
          height: 80,
          child: CustomPaint(
            painter: _RingPainter(
              progress: value,
              color: AppColors.habits,
              backgroundColor: const Color(0xFFE5E7EB),
              strokeWidth: 7,
            ),
            child: Center(
              child: Text(
                '${(value * 100).round()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.habits,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159265358979323846 / 2,
        2 * 3.14159265358979323846 * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
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
// Widget: tarjeta de habito enriquecida
// ---------------------------------------------------------------------------

class _HabitCard extends StatefulWidget {
  const _HabitCard({
    super.key,
    required this.habit,
    required this.isCompleted,
    required this.currentValue,
    required this.streakDays,
    required this.dao,
    required this.today,
    required this.monthStart,
    required this.monthEnd,
    required this.onToggle,
    this.onIncrement,
    this.onTapName,
  });

  final Habit habit;
  final bool isCompleted;
  final double currentValue;
  final int streakDays;
  final HabitsDao dao;
  final DateTime today;
  final DateTime monthStart;
  final DateTime monthEnd;
  final VoidCallback onToggle;
  final VoidCallback? onIncrement;
  final void Function(BuildContext ctx)? onTapName;

  @override
  State<_HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<_HabitCard> {
  // Cache for week logs and monthly rate
  List<DateTime?> _weekDays = [];
  Set<String> _weekLogDates = {};
  double _monthlyRate = 0.0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadExtras();
  }

  @override
  void didUpdateWidget(_HabitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCompleted != widget.isCompleted ||
        oldWidget.currentValue != widget.currentValue) {
      _loadExtras();
    }
  }

  Future<void> _loadExtras() async {
    // Last 7 days
    final days = <DateTime?>[];
    final logDates = <String>{};
    for (var i = 6; i >= 0; i--) {
      final day = widget.today.subtract(Duration(days: i));
      days.add(day);
      final log = await widget.dao.getLogForDate(widget.habit.id, day);
      if (log != null) {
        logDates.add(
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
        );
      }
    }
    // Monthly completion rate
    final rate = await widget.dao.completionRate(
      widget.habit.id,
      widget.monthStart,
      widget.monthEnd,
    );
    if (mounted) {
      setState(() {
        _weekDays = days;
        _weekLogDates = logDates;
        _monthlyRate = rate.clamp(0.0, 1.0);
        _loaded = true;
      });
    }
  }

  Color get _habitColor => Color(widget.habit.color);

  IconData get _habitIcon {
    final cp = int.tryParse(widget.habit.icon);
    if (cp != null) {
      return IconData(cp, fontFamily: 'MaterialIcons');
    }
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habit = widget.habit;
    final isQuantitative = habit.isQuantitative;
    final target = habit.quantitativeTarget ?? 1.0;
    final progress = isQuantitative
        ? (widget.currentValue / target).clamp(0.0, 1.0)
        : 0.0;

    final semanticLabel = '${habit.name}, '
        '${widget.isCompleted ? 'completado' : 'pendiente'}, '
        'racha de ${widget.streakDays} dias'
        '${isQuantitative ? ', ${widget.currentValue.toInt()} de ${target.toInt()} ${habit.quantitativeUnit ?? ''}' : ''}';

    return Semantics(
      label: semanticLabel,
      child: PressableCard(
        onTap: isQuantitative ? widget.onIncrement : widget.onToggle,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Fila superior: icono + nombre + toggle ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icono
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _habitColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_habitIcon, color: _habitColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    // Nombre
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.onTapName != null
                            ? () => widget.onTapName!(context)
                            : null,
                        child: Text(
                          habit.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: widget.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: widget.isCompleted
                                ? AppColors.lightTextSecondary
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Toggle / incrementar
                    if (isQuantitative && widget.onIncrement != null && !widget.isCompleted)
                      Semantics(
                        label: 'Registrar progreso en ${habit.name}',
                        button: true,
                        child: _IncrementButton(
                          key: ValueKey('habit-increment-${habit.id}'),
                          color: AppColors.habits,
                          onTap: widget.onIncrement!,
                        ),
                      )
                    else
                      Semantics(
                        label: widget.isCompleted
                            ? 'Marcar ${habit.name} como pendiente'
                            : 'Marcar ${habit.name} como completado',
                        button: true,
                        child: _CheckToggle(
                          key: ValueKey('habit-check-${habit.id}'),
                          isChecked: widget.isCompleted,
                          color: AppColors.habits,
                          onTap: widget.onToggle,
                        ),
                      ),
                  ],
                ),

                // --- Racha ---
                if (widget.streakDays > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(
                        'Racha: ${widget.streakDays} dia${widget.streakDays != 1 ? 's' : ''}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.habits,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],

                // --- Progreso cuantitativo (si aplica) ---
                if (isQuantitative) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: progress),
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                                builder: (context, value, _) =>
                                    LinearProgressIndicator(
                                  value: value,
                                  minHeight: 5,
                                  backgroundColor: const Color(0xFFE5E7EB),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          AppColors.habits),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${widget.currentValue.toInt()}/${target.toInt()} ${habit.quantitativeUnit ?? ''}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.habits,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],

                // --- Barra de completitud mensual ---
                if (_loaded) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _monthlyRate,
                            minHeight: 4,
                            backgroundColor: const Color(0xFFE5E7EB),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.habits),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(_monthlyRate * 100).round()}% este mes',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),

                  // --- Mini vista semanal ---
                  const SizedBox(height: 10),
                  _WeekView(
                    weekDays: _weekDays,
                    logDates: _weekLogDates,
                    today: widget.today,
                    color: AppColors.habits,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: mini vista semanal (ultimos 7 dias)
// ---------------------------------------------------------------------------

class _WeekView extends StatelessWidget {
  const _WeekView({
    required this.weekDays,
    required this.logDates,
    required this.today,
    required this.color,
  });

  final List<DateTime?> weekDays;
  final Set<String> logDates;
  final DateTime today;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const dayNames = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: weekDays.asMap().entries.map((entry) {
        final day = entry.value;
        if (day == null) return const SizedBox(width: 32);

        final dayKey =
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final isFuture = day.isAfter(today);
        final isDone = logDates.contains(dayKey);
        final isToday = day.year == today.year &&
            day.month == today.month &&
            day.day == today.day;

        return Expanded(
          child: Column(
            children: [
              Text(
                dayNames[day.weekday - 1],
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: isToday
                      ? color
                      : AppColors.lightTextSecondary,
                  fontWeight:
                      isToday ? FontWeight.w700 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFuture
                      ? Colors.transparent
                      : isDone
                          ? color
                          : Colors.transparent,
                  border: isFuture
                      ? null
                      : Border.all(
                          color: isDone
                              ? color
                              : Colors.grey.withAlpha(100),
                          width: 1.5,
                        ),
                ),
                child: isFuture
                    ? Center(
                        child: Container(
                          width: 4,
                          height: 1.5,
                          color: Colors.grey.withAlpha(80),
                        ),
                      )
                    : isDone
                        ? const Icon(Icons.check,
                            size: 10, color: Colors.white)
                        : null,
              ),
            ],
          ),
        );
      }).toList(),
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
                  AppColors.habits,
                  filled,
                )!,
                width: 2,
              ),
              color: AppColors.habits.withAlpha((filled * 255).toInt()),
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
          color: AppColors.habits.withAlpha(25),
          border: Border.all(color: AppColors.habits.withAlpha(80), width: 1.5),
        ),
        child: const Icon(Icons.add, size: 16, color: AppColors.habits),
      ),
    );
  }
}
