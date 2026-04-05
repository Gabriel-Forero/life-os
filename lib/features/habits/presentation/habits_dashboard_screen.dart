import 'package:flutter/material.dart';
import 'package:life_os/core/constants/app_colors.dart';

// ---------------------------------------------------------------------------
// Enums y modelos mock
// ---------------------------------------------------------------------------

/// Tipo de frecuencia de un habito.
enum _HabitFrequency { daily, weekly, custom }

/// Tipo de habito: binario (hecho / no hecho) o cuantitativo.
enum _HabitKind { binary, quantitative }

class _MockHabit {
  _MockHabit({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.frequency,
    required this.kind,
    this.targetValue,
    this.unit,
    this.currentValue = 0,
    this.streakDays = 0,
    this.isCompleted = false,
  });

  final int id;
  final String name;
  final IconData icon;
  final Color color;
  final _HabitFrequency frequency;
  final _HabitKind kind;
  final double? targetValue;
  final String? unit;
  double currentValue;
  int streakDays;
  bool isCompleted;
}

final _mockHabits = [
  _MockHabit(
    id: 1,
    name: 'Meditar',
    icon: Icons.self_improvement,
    color: AppColors.habits,
    frequency: _HabitFrequency.daily,
    kind: _HabitKind.binary,
    streakDays: 14,
    isCompleted: true,
  ),
  _MockHabit(
    id: 2,
    name: 'Leer',
    icon: Icons.menu_book_outlined,
    color: const Color(0xFF06B6D4),
    frequency: _HabitFrequency.daily,
    kind: _HabitKind.quantitative,
    targetValue: 30,
    unit: 'min',
    currentValue: 20,
    streakDays: 7,
  ),
  _MockHabit(
    id: 3,
    name: 'Beber agua',
    icon: Icons.water_drop_outlined,
    color: const Color(0xFF3B82F6),
    frequency: _HabitFrequency.daily,
    kind: _HabitKind.quantitative,
    targetValue: 8,
    unit: 'vasos',
    currentValue: 8,
    streakDays: 21,
    isCompleted: true,
  ),
  _MockHabit(
    id: 4,
    name: 'Ejercicio',
    icon: Icons.fitness_center,
    color: AppColors.gym,
    frequency: _HabitFrequency.daily,
    kind: _HabitKind.binary,
    streakDays: 3,
  ),
  _MockHabit(
    id: 5,
    name: 'Sin azucar',
    icon: Icons.no_food_outlined,
    color: AppColors.nutrition,
    frequency: _HabitFrequency.daily,
    kind: _HabitKind.binary,
    streakDays: 5,
  ),
];

// ---------------------------------------------------------------------------
// Pantalla principal del dashboard de habitos
// ---------------------------------------------------------------------------

/// Dashboard de habitos del dia con lista de pendientes y completados,
/// barra de progreso cuantitativa y racha de dias consecutivos.
///
/// Shell de presentacion — la integracion con Riverpod se realizara en un
/// paso posterior.
///
/// Accesibilidad: A11Y-HAB-01 — cada fila de habito tiene etiqueta semantica
/// con nombre, estado y racha.
class HabitsDashboardScreen extends StatefulWidget {
  const HabitsDashboardScreen({super.key});

  @override
  State<HabitsDashboardScreen> createState() => _HabitsDashboardScreenState();
}

class _HabitsDashboardScreenState extends State<HabitsDashboardScreen> {
  final List<_MockHabit> _habits = _mockHabits;

  List<_MockHabit> get _pending =>
      _habits.where((h) => !h.isCompleted).toList();

  List<_MockHabit> get _completed =>
      _habits.where((h) => h.isCompleted).toList();

  bool get _allDone => _habits.every((h) => h.isCompleted);

  void _toggleHabit(_MockHabit habit) {
    setState(() {
      if (habit.kind == _HabitKind.binary) {
        habit.isCompleted = !habit.isCompleted;
        if (habit.isCompleted) habit.streakDays++;
      }
    });
  }

  void _incrementQuantitative(_MockHabit habit) {
    setState(() {
      final next = habit.currentValue + 1;
      habit.currentValue = next.clamp(0, habit.targetValue!);
      habit.isCompleted = habit.currentValue >= habit.targetValue!;
      if (habit.isCompleted) {
        habit.streakDays++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              onPressed: () {
                // TODO: navegar a estadisticas cuando se conecte
              },
              tooltip: 'Estadisticas',
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.habits,
        onRefresh: () async {
          await Future<void>.delayed(const Duration(milliseconds: 600));
        },
        child: ListView(
          key: const ValueKey('habits-dashboard-list'),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          children: [
            // --- Progreso del dia ---
            _DayProgressHeader(
              key: const ValueKey('habits-day-progress'),
              completed: _completed.length,
              total: _habits.length,
              allDone: _allDone,
            ),
            const SizedBox(height: 20),

            // --- Mensaje de celebracion ---
            if (_allDone)
              _CelebrationBanner(
                key: const ValueKey('habits-celebration-banner'),
              ),

            // --- Seccion Pendientes ---
            if (_pending.isNotEmpty) ...[
              _SectionHeader(
                key: const ValueKey('habits-pending-header'),
                title: 'Pendientes',
                count: _pending.length,
                color: theme.colorScheme.onSurface,
              ),
              const SizedBox(height: 8),
              ..._pending.map(
                (habit) => _HabitRow(
                  key: ValueKey('habit-row-${habit.id}'),
                  habit: habit,
                  onToggle: () => _toggleHabit(habit),
                  onIncrement: habit.kind == _HabitKind.quantitative
                      ? () => _incrementQuantitative(habit)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // --- Seccion Completados ---
            if (_completed.isNotEmpty) ...[
              _SectionHeader(
                key: const ValueKey('habits-completed-header'),
                title: 'Completados',
                count: _completed.length,
                color: AppColors.success,
              ),
              const SizedBox(height: 8),
              ..._completed.map(
                (habit) => _HabitRow(
                  key: ValueKey('habit-row-${habit.id}'),
                  habit: habit,
                  onToggle: () => _toggleHabit(habit),
                  onIncrement: null,
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: Semantics(
        label: 'Agregar nuevo habito',
        button: true,
        child: FloatingActionButton(
          key: const ValueKey('habits-add-fab'),
          backgroundColor: AppColors.habits,
          foregroundColor: Colors.white,
          onPressed: () {
            // TODO: navegar a AddEditHabitScreen cuando se conecte
          },
          tooltip: 'Agregar habito',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
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
// ---------------------------------------------------------------------------

class _HabitRow extends StatelessWidget {
  const _HabitRow({
    super.key,
    required this.habit,
    required this.onToggle,
    this.onIncrement,
  });

  final _MockHabit habit;
  final VoidCallback onToggle;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isQuantitative = habit.kind == _HabitKind.quantitative;
    final progress = isQuantitative && habit.targetValue != null
        ? (habit.currentValue / habit.targetValue!).clamp(0.0, 1.0)
        : 0.0;

    final semanticLabel = '${habit.name}, '
        '${habit.isCompleted ? 'completado' : 'pendiente'}, '
        'racha de ${habit.streakDays} dias'
        '${isQuantitative ? ', ${habit.currentValue.toInt()} de ${habit.targetValue!.toInt()} ${habit.unit}' : ''}';

    return Semantics(
      label: semanticLabel,
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
                  color: habit.color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(habit.icon, color: habit.color, size: 20),
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
                        decoration: habit.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: habit.isCompleted
                            ? theme.disabledColor
                            : null,
                      ),
                    ),
                    if (isQuantitative && habit.targetValue != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: progress),
                                duration:
                                    const Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                                builder: (context, value, _) =>
                                    LinearProgressIndicator(
                                  value: value,
                                  minHeight: 5,
                                  backgroundColor:
                                      habit.color.withAlpha(25),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                    habit.color,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${habit.currentValue.toInt()}/${habit.targetValue!.toInt()} ${habit.unit ?? ''}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: habit.color,
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
                days: habit.streakDays,
                color: habit.color,
              ),
              const SizedBox(width: 8),

              // Toggle / incrementar
              if (isQuantitative && onIncrement != null && !habit.isCompleted)
                Semantics(
                  label: 'Registrar progreso en ${habit.name}',
                  button: true,
                  child: _IncrementButton(
                    key: ValueKey('habit-increment-${habit.id}'),
                    color: habit.color,
                    onTap: onIncrement!,
                  ),
                )
              else
                Semantics(
                  label: habit.isCompleted
                      ? 'Marcar ${habit.name} como pendiente'
                      : 'Marcar ${habit.name} como completado',
                  button: true,
                  child: _CheckToggle(
                    key: ValueKey('habit-check-${habit.id}'),
                    isChecked: habit.isCompleted,
                    color: habit.color,
                    onTap: onToggle,
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
