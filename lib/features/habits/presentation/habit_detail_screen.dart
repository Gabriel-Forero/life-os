import 'package:flutter/material.dart';
import 'package:life_os/core/constants/app_colors.dart';

// ---------------------------------------------------------------------------
// Enums y modelos mock
// ---------------------------------------------------------------------------

/// Estado de un dia en el calendario del habito.
enum _DayStatus {
  completed,
  missed,
  notApplicable,
  todayPending,
  future,
}

class _MockCalendarDay {
  const _MockCalendarDay({
    required this.date,
    required this.status,
  });

  final DateTime date;
  final _DayStatus status;
}

class _MockHabitDetail {
  const _MockHabitDetail({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.currentStreak,
    required this.bestStreak,
    required this.totalCheckIns,
    required this.completionRate,
    required this.calendarDays,
    this.isArchived = false,
  });

  final int id;
  final String name;
  final IconData icon;
  final Color color;
  final int currentStreak;
  final int bestStreak;
  final int totalCheckIns;
  final double completionRate;
  final List<_MockCalendarDay> calendarDays;
  final bool isArchived;
}

/// Genera un mes de dias mock con estados variados para visualizacion.
List<_MockCalendarDay> _buildMockCalendar() {
  final today = DateTime.now();
  final firstDay = DateTime(today.year, today.month, 1);
  final daysInMonth =
      DateTime(today.year, today.month + 1, 0).day;

  return List.generate(daysInMonth, (i) {
    final date = firstDay.add(Duration(days: i));
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final isFuture = date.isAfter(today);

    if (isFuture) {
      return _MockCalendarDay(date: date, status: _DayStatus.future);
    }
    if (isToday) {
      return _MockCalendarDay(date: date, status: _DayStatus.todayPending);
    }

    // Distribucion mock: 70% completados, 15% perdidos, 15% N/A
    final mod = i % 20;
    if (mod >= 17) {
      return _MockCalendarDay(date: date, status: _DayStatus.notApplicable);
    }
    if (mod >= 14) {
      return _MockCalendarDay(date: date, status: _DayStatus.missed);
    }
    return _MockCalendarDay(date: date, status: _DayStatus.completed);
  });
}

final _mockHabitDetail = _MockHabitDetail(
  id: 1,
  name: 'Meditar',
  icon: Icons.self_improvement,
  color: AppColors.habits,
  currentStreak: 14,
  bestStreak: 32,
  totalCheckIns: 87,
  completionRate: 0.78,
  calendarDays: _buildMockCalendar(),
);

// ---------------------------------------------------------------------------
// Pantalla: detalle de habito
// ---------------------------------------------------------------------------

/// Detalle de un habito con calendario mensual de cumplimiento, estadisticas
/// y acciones de archivar y editar.
///
/// Shell de presentacion — la integracion con Riverpod se realizara en un
/// paso posterior.
///
/// Accesibilidad: A11Y-HAB-03 — el calendario tiene descripcion semantica y
/// cada dia tiene etiqueta con fecha y estado.
class HabitDetailScreen extends StatefulWidget {
  const HabitDetailScreen({
    super.key,
    this.habitId,
  });

  final int? habitId;

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  // En produccion se obtendria del provider por habitId.
  final _habit = _mockHabitDetail;

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

  void _handleArchive() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const ValueKey('habit-archive-dialog'),
        title: const Text('Archivar habito'),
        content: Text(
          'Archivar "${_habit.name}" lo ocultara del dashboard pero '
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
              backgroundColor: AppColors.warning,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              // TODO: conectar con HabitsNotifier.archiveHabit cuando se integre
            },
            child: const Text('Archivar'),
          ),
        ],
      ),
    );
  }

  void _handleEdit() {
    // TODO: navegar a AddEditHabitScreen con habitId cuando se integre
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    final monthLabel =
        '${months[_displayedMonth.month - 1]} ${_displayedMonth.year}';

    return Scaffold(
      key: const ValueKey('habit-detail-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Semantics(
          header: true,
          child: Text(_habit.name),
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
            label: 'Editar habito ${_habit.name}',
            button: true,
            child: IconButton(
              key: const ValueKey('habit-detail-edit-button'),
              icon: const Icon(Icons.edit_outlined),
              onPressed: _handleEdit,
              tooltip: 'Editar',
            ),
          ),
          Semantics(
            label: 'Archivar habito ${_habit.name}',
            button: true,
            child: IconButton(
              key: const ValueKey('habit-detail-archive-button'),
              icon: const Icon(Icons.archive_outlined),
              onPressed: _handleArchive,
              tooltip: 'Archivar',
            ),
          ),
        ],
      ),
      body: ListView(
        key: const ValueKey('habit-detail-list'),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          // --- Encabezado: icono + nombre + rachas ---
          _HabitHeader(
            key: const ValueKey('habit-detail-header'),
            habit: _habit,
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
                          key: const ValueKey('habit-calendar-prev-month'),
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _previousMonth,
                          tooltip: 'Mes anterior',
                        ),
                      ),
                      Expanded(
                        child: Text(
                          monthLabel,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Semantics(
                        label: 'Mes siguiente',
                        button: true,
                        child: IconButton(
                          key: const ValueKey('habit-calendar-next-month'),
                          icon: Icon(
                            Icons.chevron_right,
                            color: _canGoNext ? null : theme.disabledColor,
                          ),
                          onPressed: _canGoNext ? _nextMonth : null,
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
                    label: 'Calendario de cumplimiento de $monthLabel',
                    child: _CalendarGrid(
                      key: const ValueKey('habit-calendar-grid'),
                      habit: _habit,
                      displayedMonth: _displayedMonth,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Leyenda
                  _CalendarLegend(
                    key: const ValueKey('habit-calendar-legend'),
                    color: _habit.color,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- Estadisticas ---
          Semantics(
            label: 'Estadisticas del habito ${_habit.name}',
            child: _StatsGrid(
              key: const ValueKey('habit-detail-stats-grid'),
              habit: _habit,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: encabezado del habito
// ---------------------------------------------------------------------------

class _HabitHeader extends StatelessWidget {
  const _HabitHeader({super.key, required this.habit});

  final _MockHabitDetail habit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '${habit.name}, racha actual ${habit.currentStreak} dias, '
          'mejor racha ${habit.bestStreak} dias',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: habit.color.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: habit.color.withAlpha(40)),
        ),
        child: Row(
          children: [
            // Icono
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: habit.color.withAlpha(30),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(habit.icon, color: habit.color, size: 32),
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
                        days: habit.currentStreak,
                        color: habit.color,
                        icon: Icons.local_fire_department,
                      ),
                      const SizedBox(width: 16),
                      _StreakCounter(
                        key: const ValueKey('habit-best-streak'),
                        label: 'Mejor racha',
                        days: habit.bestStreak,
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
// ---------------------------------------------------------------------------

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    super.key,
    required this.habit,
    required this.displayedMonth,
  });

  final _MockHabitDetail habit;
  final DateTime displayedMonth;

  Color _dayColor(_DayStatus status, Color habitColor) => switch (status) {
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
    final firstDay = DateTime(displayedMonth.year, displayedMonth.month, 1);
    // weekday: 1=Lunes ... 7=Domingo
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth =
        DateTime(displayedMonth.year, displayedMonth.month + 1, 0).day;

    // Filtrar dias del mes visible
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    List<_MockCalendarDay?> gridCells =
        List.filled(startOffset, null, growable: true);

    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(displayedMonth.year, displayedMonth.month, d);
      final isCurrentMonth =
          displayedMonth.year == now.year &&
          displayedMonth.month == now.month;

      _DayStatus status;
      if (isCurrentMonth) {
        // Usar los dias mock del habito (solo para el mes actual)
        final idx = d - 1;
        if (idx < habit.calendarDays.length) {
          status = habit.calendarDays[idx].status;
        } else {
          status = date.isAfter(today)
              ? _DayStatus.future
              : _DayStatus.notApplicable;
        }
      } else if (date.isAfter(today)) {
        status = _DayStatus.future;
      } else {
        // Meses anteriores: patron mock
        final mod = d % 20;
        if (mod >= 17) {
          status = _DayStatus.notApplicable;
        } else if (mod >= 14) {
          status = _DayStatus.missed;
        } else {
          status = _DayStatus.completed;
        }
      }

      gridCells.add(_MockCalendarDay(date: date, status: status));
    }

    // Padding al final para completar la ultima semana
    while (gridCells.length % 7 != 0) {
      gridCells.add(null);
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
      itemCount: gridCells.length,
      itemBuilder: (context, index) {
        final cell = gridCells[index];
        if (cell == null) return const SizedBox.shrink();

        final day = cell.date.day;
        final bgColor = _dayColor(cell.status, habit.color);
        final isFuture = cell.status == _DayStatus.future;
        final isTodayPending = cell.status == _DayStatus.todayPending;

        return Semantics(
          label: _daySemanticLabel(day, cell.status),
          child: Container(
            key: ValueKey(
                'habit-calendar-day-${cell.date.toIso8601String().substring(0, 10)}'),
            decoration: BoxDecoration(
              color: isFuture ? Colors.transparent : bgColor.withAlpha(30),
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
// ---------------------------------------------------------------------------

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({super.key, required this.habit});

  final _MockHabitDetail habit;

  @override
  Widget build(BuildContext context) {
    final completionPct =
        '${(habit.completionRate * 100).round()}%';

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
          color: habit.color,
        ),
        _StatCard(
          key: const ValueKey('habit-stat-total-checkins'),
          icon: Icons.check_circle_outline,
          value: '${habit.totalCheckIns}',
          label: 'Check-ins totales',
          color: AppColors.success,
        ),
        _StatCard(
          key: const ValueKey('habit-stat-current-streak'),
          icon: Icons.local_fire_department,
          value: '${habit.currentStreak}d',
          label: 'Racha actual',
          color: habit.color,
        ),
        _StatCard(
          key: const ValueKey('habit-stat-best-streak'),
          icon: Icons.emoji_events_outlined,
          value: '${habit.bestStreak}d',
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
