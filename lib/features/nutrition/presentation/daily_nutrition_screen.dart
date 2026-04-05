import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';

// ---------------------------------------------------------------------------
// Helpers de tipo de comida
// ---------------------------------------------------------------------------

const _mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];

String _mealTypeLabel(String type) => switch (type) {
      'breakfast' => 'Desayuno',
      'lunch' => 'Almuerzo',
      'dinner' => 'Cena',
      'snack' => 'Snack',
      _ => type,
    };

IconData _mealTypeIcon(String type) => switch (type) {
      'breakfast' => Icons.wb_sunny_outlined,
      'lunch' => Icons.restaurant_outlined,
      'dinner' => Icons.nightlight_outlined,
      'snack' => Icons.apple_outlined,
      _ => Icons.restaurant_menu_outlined,
    };

// Macro data class
class _Macro {
  const _Macro({
    required this.label,
    required this.current,
    required this.goal,
    required this.unit,
    required this.color,
  });

  final String label;
  final double current;
  final double goal;
  final String unit;
  final Color color;

  double get progress => goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
}

// ---------------------------------------------------------------------------
// Pantalla principal de nutricion diaria
// ---------------------------------------------------------------------------

/// Pantalla de nutricion diaria con anillos de macros, lista de comidas por
/// tipo y rastreador de agua.
///
/// Accesibilidad: A11Y-NUT-01 — todos los controles e indicadores tienen
/// etiquetas semanticas.
class DailyNutritionScreen extends ConsumerStatefulWidget {
  const DailyNutritionScreen({super.key});

  @override
  ConsumerState<DailyNutritionScreen> createState() =>
      _DailyNutritionScreenState();
}

class _DailyNutritionScreenState
    extends ConsumerState<DailyNutritionScreen> {
  final Set<String> _expandedMeals = {'breakfast', 'lunch'};
  static const double _mlPerGlass = 250;

  void _toggleMeal(String type) {
    setState(() {
      if (_expandedMeals.contains(type)) {
        _expandedMeals.remove(type);
      } else {
        _expandedMeals.add(type);
      }
    });
  }

  Future<void> _addWater() async {
    await ref
        .read(nutritionNotifierProvider)
        .logWater(_mlPerGlass.toInt());
  }

  Future<void> _removeWater(List<WaterLog> todayLogs) async {
    if (todayLogs.isEmpty) return;
    // Remove the most recent log
    await ref
        .read(nutritionNotifierProvider)
        .removeWaterLog(todayLogs.first.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dao = ref.watch(nutritionDaoProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Scaffold(
      key: const ValueKey('daily-nutrition-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Semantics(
          header: true,
          child: const Text('Nutricion'),
        ),
        actions: [
          Semantics(
            label: 'Ver historial de nutricion',
            button: true,
            child: IconButton(
              key: const ValueKey('nutrition-history-button'),
              icon: const Icon(Icons.history_outlined),
              onPressed: () {},
              tooltip: 'Historial',
            ),
          ),
          Semantics(
            label: 'Configurar metas nutricionales',
            button: true,
            child: IconButton(
              key: const ValueKey('nutrition-goals-nav-button'),
              icon: const Icon(Icons.tune_outlined),
              onPressed: () =>
                  GoRouter.of(context).push('/nutrition/goals'),
              tooltip: 'Metas',
            ),
          ),
        ],
      ),
      floatingActionButton: Semantics(
        label: 'Agregar comida al registro de hoy',
        button: true,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (context, value, child) =>
              Transform.scale(scale: value, child: child),
          child: FloatingActionButton(
            key: const ValueKey('nutrition-add-meal-fab'),
            onPressed: () => GoRouter.of(context).push('/nutrition/log'),
            backgroundColor: AppColors.nutrition,
            foregroundColor: Colors.white,
            tooltip: 'Agregar comida',
            child: const Icon(Icons.add),
          ),
        ),
      ),
      body: StreamBuilder<NutritionGoal?>(
        stream: dao.watchActiveGoal(),
        builder: (context, goalSnapshot) {
          final goal = goalSnapshot.data;

          return StreamBuilder<List<MealLog>>(
            stream: dao.watchMealLogs(today),
            builder: (context, mealsSnapshot) {
              final mealLogs = mealsSnapshot.data ?? [];

              return StreamBuilder<List<WaterLog>>(
                stream: dao.watchWaterLogs(today),
                builder: (context, waterSnapshot) {
                  final waterLogs = waterSnapshot.data ?? [];
                  final totalWaterMl = waterLogs.fold<int>(
                    0,
                    (sum, w) => sum + w.amountMl,
                  );
                  final waterGlasses =
                      (totalWaterMl / _mlPerGlass).floor();
                  final waterGoalGlasses = goal != null
                      ? (goal.waterMl / _mlPerGlass).round()
                      : 8;

                  // Build macro data from meal logs + goal
                  // For now, totals from meal logs require joining with food items
                  // Use goal values as targets, current = 0 (no denormalized totals)
                  final macros = [
                    _Macro(
                      label: 'Calorias',
                      current: 0,
                      goal: goal?.caloriesKcal.toDouble() ?? 2000,
                      unit: 'kcal',
                      color: AppColors.nutrition,
                    ),
                    _Macro(
                      label: 'Proteina',
                      current: 0,
                      goal: goal?.proteinG ?? 150,
                      unit: 'g',
                      color: const Color(0xFF3B82F6),
                    ),
                    _Macro(
                      label: 'Carbos',
                      current: 0,
                      goal: goal?.carbsG ?? 250,
                      unit: 'g',
                      color: const Color(0xFF10B981),
                    ),
                    _Macro(
                      label: 'Grasa',
                      current: 0,
                      goal: goal?.fatG ?? 65,
                      unit: 'g',
                      color: const Color(0xFFEC4899),
                    ),
                  ];

                  return RefreshIndicator(
                    color: AppColors.nutrition,
                    onRefresh: () async {},
                    child: ListView(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      children: [
                        // --- Anillos de macros ---
                        Semantics(
                          label: 'Resumen de macros diarios',
                          child: _MacroRingsSection(
                            key: const ValueKey(
                                'nutrition-macro-rings'),
                            macros: macros,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --- Lista de comidas agrupadas por tipo ---
                        Semantics(
                          header: true,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Comidas de hoy',
                              style:
                                  theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                        ..._mealTypes.map(
                          (type) {
                            final logsForType = mealLogs
                                .where((m) => m.mealType == type)
                                .toList();
                            return _MealSection(
                              key: ValueKey(
                                  'nutrition-meal-section-$type'),
                              mealType: type,
                              logs: logsForType,
                              isExpanded:
                                  _expandedMeals.contains(type),
                              onToggle: () => _toggleMeal(type),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // --- Rastreador de agua ---
                        Semantics(
                          label:
                              'Rastreador de agua: $waterGlasses de $waterGoalGlasses vasos consumidos',
                          child: _WaterTrackerCard(
                            key: const ValueKey(
                                'nutrition-water-tracker'),
                            glasses: waterGlasses,
                            goalGlasses: waterGoalGlasses,
                            mlPerGlass: _mlPerGlass,
                            onIncrement: _addWater,
                            onDecrement: () =>
                                _removeWater(waterLogs),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: anillos de macros
// TODO: Extract to separate widget file
// ---------------------------------------------------------------------------

class _MacroRingsSection extends StatelessWidget {
  const _MacroRingsSection({
    super.key,
    required this.macros,
  });

  final List<_Macro> macros;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: macros
              .map(
                (macro) => _MacroRing(
                  key: ValueKey('macro-ring-${macro.label}'),
                  macro: macro,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _MacroRing extends StatelessWidget {
  const _MacroRing({
    super.key,
    required this.macro,
  });

  final _Macro macro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label:
          '${macro.label}: ${macro.current.toStringAsFixed(0)} de ${macro.goal.toStringAsFixed(0)} ${macro.unit}, ${(macro.progress * 100).round()}%',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 68,
            height: 68,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: macro.progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => CustomPaint(
                painter: _RingPainter(
                  progress: value,
                  color: macro.color,
                  backgroundColor: theme.dividerColor.withAlpha(60),
                ),
                child: child,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      macro.current.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: macro.color,
                      ),
                    ),
                    Text(
                      macro.unit,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            macro.label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'meta: ${macro.goal.toStringAsFixed(0)}',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  final double progress;
  final Color color;
  final Color backgroundColor;

  static const double _strokeWidth = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - _strokeWidth / 2;
    const startAngle = -math.pi / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * math.pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.backgroundColor != backgroundColor;
}

// ---------------------------------------------------------------------------
// Widget: seccion de comida expandible
// ---------------------------------------------------------------------------

class _MealSection extends ConsumerWidget {
  const _MealSection({
    super.key,
    required this.mealType,
    required this.logs,
    required this.isExpanded,
    required this.onToggle,
  });

  final String mealType;
  final List<MealLog> logs;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final label = _mealTypeLabel(mealType);
    final icon = _mealTypeIcon(mealType);
    final count = logs.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          // Encabezado de comida
          Semantics(
            label: '$label: $count comidas. '
                '${isExpanded ? 'Toca para colapsar' : 'Toca para expandir'}',
            button: true,
            child: InkWell(
              key: ValueKey('nutrition-meal-header-$mealType'),
              onTap: onToggle,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.nutrition.withAlpha(25),
                      child: Icon(icon, color: AppColors.nutrition, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$count comida${count != 1 ? 's' : ''} registrada${count != 1 ? 's' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.nutrition,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      label: 'Agregar alimento a $label',
                      button: true,
                      child: IconButton(
                        key: ValueKey('nutrition-add-to-meal-$mealType'),
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        color: AppColors.nutrition,
                        onPressed: () =>
                            GoRouter.of(context).push('/nutrition/log'),
                        tooltip: 'Agregar a $label',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.expand_more, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Items de la comida
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                if (logs.isNotEmpty) ...[
                  const Divider(height: 1),
                  ...logs.map(
                    (log) => _MealLogTile(
                      key: ValueKey('nutrition-meal-log-${log.id}'),
                      log: log,
                    ),
                  ),
                ],
              ],
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: tile de log de comida
// ---------------------------------------------------------------------------

class _MealLogTile extends ConsumerWidget {
  const _MealLogTile({super.key, required this.log});

  final MealLog log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Comida registrada el ${log.date.day}/${log.date.month}',
      child: ListTile(
        key: ValueKey('nutrition-meal-log-tile-${log.id}'),
        dense: true,
        contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
        title: Text(
          _mealTypeLabel(log.mealType),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: log.note != null && log.note!.isNotEmpty
            ? Text(
                log.note!,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              )
            : null,
        trailing: Semantics(
          label: 'Eliminar comida',
          button: true,
          child: IconButton(
            key: ValueKey('nutrition-remove-meal-${log.id}'),
            icon: const Icon(Icons.remove_circle_outline, size: 18),
            color: Colors.grey,
            onPressed: () async {
              final result = await ref
                  .read(nutritionNotifierProvider)
                  .deleteMeal(log.id);
              if (!context.mounted) return;
              if (result.isFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text(result.failureOrNull!.userMessage)),
                );
              }
            },
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: rastreador de agua
// TODO: Extract to separate widget file
// ---------------------------------------------------------------------------

class _WaterTrackerCard extends StatelessWidget {
  const _WaterTrackerCard({
    super.key,
    required this.glasses,
    required this.goalGlasses,
    required this.mlPerGlass,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int glasses;
  final int goalGlasses;
  final double mlPerGlass;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (glasses / goalGlasses).clamp(0.0, 1.0);
    final totalMl = glasses * mlPerGlass;
    final goalMl = goalGlasses * mlPerGlass;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              children: [
                const Icon(Icons.water_drop_outlined, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                Semantics(
                  header: true,
                  child: Text(
                    'Agua',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${totalMl.toStringAsFixed(0)} / ${goalMl.toStringAsFixed(0)} ml',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF3B82F6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Vasos visuales
            Semantics(
              label: '$glasses de $goalGlasses vasos consumidos',
              child: Wrap(
                key: const ValueKey('nutrition-water-glasses'),
                spacing: 6,
                runSpacing: 6,
                children: List.generate(goalGlasses, (i) {
                  final filled = i < glasses;
                  return Semantics(
                    label: 'Vaso ${i + 1}: ${filled ? 'lleno' : 'vacio'}',
                    child: Icon(
                      filled ? Icons.water_drop : Icons.water_drop_outlined,
                      color: filled
                          ? const Color(0xFF3B82F6)
                          : theme.dividerColor,
                      size: 22,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),

            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                key: const ValueKey('nutrition-water-progress-bar'),
                value: progress,
                backgroundColor: theme.dividerColor,
                color: const Color(0xFF3B82F6),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),

            // Controles +/-
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  label: 'Quitar un vaso de agua',
                  button: true,
                  child: IconButton(
                    key: const ValueKey('nutrition-water-decrement'),
                    onPressed: glasses > 0 ? onDecrement : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: glasses > 0
                        ? const Color(0xFF3B82F6)
                        : Colors.grey,
                    iconSize: 28,
                    tooltip: 'Quitar vaso',
                  ),
                ),
                const SizedBox(width: 16),
                Semantics(
                  label: '$glasses vasos',
                  child: Text(
                    '$glasses vasos',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Semantics(
                  label: 'Agregar un vaso de agua',
                  button: true,
                  child: IconButton(
                    key: const ValueKey('nutrition-water-increment'),
                    onPressed: onIncrement,
                    icon: const Icon(Icons.add_circle_outline),
                    color: const Color(0xFF3B82F6),
                    iconSize: 28,
                    tooltip: 'Agregar vaso',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
