import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/router/app_router.dart';
import 'package:life_os/features/nutrition/domain/nutrition_input.dart';

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
/// Accesibilidad: A11Y-NUT-01
class DailyNutritionScreen extends ConsumerStatefulWidget {
  const DailyNutritionScreen({super.key});

  @override
  ConsumerState<DailyNutritionScreen> createState() =>
      _DailyNutritionScreenState();
}

class _DailyNutritionScreenState
    extends ConsumerState<DailyNutritionScreen> with TickerProviderStateMixin {
  final Set<String> _expandedMeals = {'breakfast', 'lunch'};
  static const double _mlPerGlass = 250;
  bool _waterGoalCelebrated = false;
  late AnimationController _celebrationController;
  late Animation<double> _celebrationScale;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _celebrationScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 40),
    ]).animate(_celebrationController);
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  void _toggleMeal(String type) {
    setState(() {
      if (_expandedMeals.contains(type)) {
        _expandedMeals.remove(type);
      } else {
        _expandedMeals.add(type);
      }
    });
  }

  Future<void> _addWater(int goalGlasses, int currentGlasses) async {
    await ref
        .read(nutritionNotifierProvider)
        .logWater(_mlPerGlass.toInt());
    // Celebrate when goal is reached
    if (!_waterGoalCelebrated && currentGlasses + 1 >= goalGlasses) {
      setState(() => _waterGoalCelebrated = true);
      _celebrationController.forward(from: 0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meta de agua alcanzada! Excelente hidratacion!'),
            backgroundColor: Color(0xFF3B82F6),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _removeWater(List<WaterLog> todayLogs) async {
    if (todayLogs.isEmpty) return;
    await ref
        .read(nutritionNotifierProvider)
        .removeWaterLog(todayLogs.first.id);
    setState(() => _waterGoalCelebrated = false);
  }

  void _showTemplatesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _TemplatesBottomSheet(
        onTemplateApplied: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plantilla aplicada!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
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
          // Camera / Photo Analysis
          Semantics(
            label: 'Analizar comida con foto',
            button: true,
            child: IconButton(
              key: const ValueKey('nutrition-photo-analysis-button'),
              icon: const Icon(Icons.camera_alt_outlined),
              onPressed: () => GoRouter.of(context).push(AppRoutes.photoAnalysis),
              tooltip: 'Analizar foto',
            ),
          ),
          // Templates
          Semantics(
            label: 'Ver plantillas de comidas',
            button: true,
            child: IconButton(
              key: const ValueKey('nutrition-templates-button'),
              icon: const Icon(Icons.dashboard_customize_outlined),
              onPressed: () => _showTemplatesSheet(context),
              tooltip: 'Plantillas',
            ),
          ),
          // Goals / Settings
          Semantics(
            label: 'Configurar metas nutricionales',
            button: true,
            child: IconButton(
              key: const ValueKey('nutrition-goals-nav-button'),
              icon: const Icon(Icons.track_changes_outlined),
              onPressed: () =>
                  GoRouter.of(context).push(AppRoutes.nutritionGoals),
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
            onPressed: () => GoRouter.of(context).push(AppRoutes.nutritionSearch),
            backgroundColor: AppColors.nutrition,
            foregroundColor: Colors.white,
            tooltip: 'Agregar comida rapido',
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

                  // Check water goal and reset celebration flag if below goal
                  if (waterGlasses < waterGoalGlasses && _waterGoalCelebrated) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _waterGoalCelebrated = false);
                    });
                  }

                  // -------------------------------------------------------
                  // Build macro totals from meal logs via joining food items
                  // We read the totals via a separate FutureBuilder below,
                  // but for simplicity we show 0 if no data yet.
                  // -------------------------------------------------------
                  return _MacroStreamBody(
                    key: ValueKey('macro-body-${mealLogs.length}'),
                    dao: dao,
                    today: today,
                    goal: goal,
                    mealLogs: mealLogs,
                    waterLogs: waterLogs,
                    waterGlasses: waterGlasses,
                    waterGoalGlasses: waterGoalGlasses,
                    expandedMeals: _expandedMeals,
                    onToggleMeal: _toggleMeal,
                    onAddWater: () => _addWater(waterGoalGlasses, waterGlasses),
                    onRemoveWater: () => _removeWater(waterLogs),
                    celebrationController: _celebrationController,
                    celebrationScale: _celebrationScale,
                    waterGoalCelebrated: _waterGoalCelebrated,
                    theme: theme,
                    onAddFoodToMeal: (mealType) =>
                        GoRouter.of(context).push(AppRoutes.nutritionSearch),
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
// Widget that loads per-meal-log food items for macro totals
// ---------------------------------------------------------------------------

class _MacroStreamBody extends ConsumerStatefulWidget {
  const _MacroStreamBody({
    super.key,
    required this.dao,
    required this.today,
    required this.goal,
    required this.mealLogs,
    required this.waterLogs,
    required this.waterGlasses,
    required this.waterGoalGlasses,
    required this.expandedMeals,
    required this.onToggleMeal,
    required this.onAddWater,
    required this.onRemoveWater,
    required this.celebrationController,
    required this.celebrationScale,
    required this.waterGoalCelebrated,
    required this.theme,
    required this.onAddFoodToMeal,
  });

  final dynamic dao;
  final DateTime today;
  final NutritionGoal? goal;
  final List<MealLog> mealLogs;
  final List<WaterLog> waterLogs;
  final int waterGlasses;
  final int waterGoalGlasses;
  final Set<String> expandedMeals;
  final ValueChanged<String> onToggleMeal;
  final VoidCallback onAddWater;
  final VoidCallback onRemoveWater;
  final AnimationController celebrationController;
  final Animation<double> celebrationScale;
  final bool waterGoalCelebrated;
  final ThemeData theme;
  final ValueChanged<String> onAddFoodToMeal;

  @override
  ConsumerState<_MacroStreamBody> createState() => _MacroStreamBodyState();
}

class _MacroStreamBodyState extends ConsumerState<_MacroStreamBody> {
  double _totalCalories = 0;
  double _totalProtein = 0;
  double _totalCarbs = 0;
  double _totalFat = 0;

  @override
  void didUpdateWidget(_MacroStreamBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mealLogs != widget.mealLogs) {
      _recalculateMacros();
    }
  }

  @override
  void initState() {
    super.initState();
    _recalculateMacros();
  }

  Future<void> _recalculateMacros() async {
    if (widget.mealLogs.isEmpty) {
      if (mounted) {
        setState(() {
          _totalCalories = 0;
          _totalProtein = 0;
          _totalCarbs = 0;
          _totalFat = 0;
        });
      }
      return;
    }

    double cal = 0, prot = 0, carbs = 0, fat = 0;
    final dao = ref.read(nutritionDaoProvider);

    for (final meal in widget.mealLogs) {
      final items = await dao.watchMealLogItems(meal.id).first;
      for (final item in items) {
        // Look up the food item by ID (efficient point lookup)
        final food = await dao.getFoodItemById(item.foodItemId);
        if (food != null) {
          final factor = item.quantityG / 100;
          cal += food.caloriesPer100g * factor;
          prot += food.proteinPer100g * factor;
          carbs += food.carbsPer100g * factor;
          fat += food.fatPer100g * factor;
        }
      }
    }

    if (mounted) {
      setState(() {
        _totalCalories = cal;
        _totalProtein = prot;
        _totalCarbs = carbs;
        _totalFat = fat;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final macros = [
      _Macro(
        label: 'Calorias',
        current: _totalCalories,
        goal: goal?.caloriesKcal.toDouble() ?? 2000,
        unit: 'kcal',
        color: AppColors.nutrition,
      ),
      _Macro(
        label: 'Proteina',
        current: _totalProtein,
        goal: goal?.proteinG ?? 150,
        unit: 'g',
        color: const Color(0xFF3B82F6),
      ),
      _Macro(
        label: 'Carbos',
        current: _totalCarbs,
        goal: goal?.carbsG ?? 250,
        unit: 'g',
        color: const Color(0xFF10B981),
      ),
      _Macro(
        label: 'Grasa',
        current: _totalFat,
        goal: goal?.fatG ?? 65,
        unit: 'g',
        color: const Color(0xFFEC4899),
      ),
    ];

    return RefreshIndicator(
      color: AppColors.nutrition,
      onRefresh: () async => _recalculateMacros(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          // --- Anillos de macros ---
          Semantics(
            label: 'Resumen de macros diarios',
            child: _MacroRingsSection(
              key: const ValueKey('nutrition-macro-rings'),
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
                style: widget.theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          ..._mealTypes.map(
            (type) {
              final logsForType = widget.mealLogs
                  .where((m) => m.mealType == type)
                  .toList();
              return _MealSection(
                key: ValueKey('nutrition-meal-section-$type'),
                mealType: type,
                logs: logsForType,
                isExpanded: widget.expandedMeals.contains(type),
                onToggle: () => widget.onToggleMeal(type),
                onAddFood: () => widget.onAddFoodToMeal(type),
              );
            },
          ),
          const SizedBox(height: 20),

          // --- Rastreador de agua ---
          Semantics(
            label:
                'Rastreador de agua: ${widget.waterGlasses} de ${widget.waterGoalGlasses} vasos consumidos',
            child: ScaleTransition(
              scale: widget.celebrationScale,
              child: _WaterTrackerCard(
                key: const ValueKey('nutrition-water-tracker'),
                glasses: widget.waterGlasses,
                goalGlasses: widget.waterGoalGlasses,
                mlPerGlass: _DailyNutritionScreenState._mlPerGlass,
                goalReached: widget.waterGoalCelebrated,
                onIncrement: widget.onAddWater,
                onDecrement: widget.onRemoveWater,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: anillos de macros
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
    required this.onAddFood,
  });

  final String mealType;
  final List<MealLog> logs;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onAddFood;

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
                        onPressed: onAddFood,
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
// Widget: templates bottom sheet (Feature 2)
// ---------------------------------------------------------------------------

class _TemplatesBottomSheet extends ConsumerWidget {
  const _TemplatesBottomSheet({required this.onTemplateApplied});

  final VoidCallback onTemplateApplied;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dao = ref.watch(nutritionDaoProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Plantillas de comidas',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<List<MealTemplate>>(
                stream: dao.watchMealTemplates(),
                builder: (context, snapshot) {
                  final templates = snapshot.data ?? [];
                  if (templates.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.dashboard_customize_outlined,
                              size: 56,
                              color: theme.disabledColor,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No tienes plantillas aun',
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Despues de registrar una comida, podras guardarla como plantilla para usarla rapidamente.',
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: templates.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final template = templates[i];
                      return ListTile(
                        key: ValueKey('template-tile-${template.id}'),
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.nutrition.withAlpha(25),
                          child: Icon(
                            _mealTypeIcon(template.mealType),
                            color: AppColors.nutrition,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          template.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _mealTypeLabel(template.mealType),
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.play_arrow_outlined),
                              color: AppColors.nutrition,
                              tooltip: 'Aplicar plantilla',
                              onPressed: () async {
                                await _applyTemplate(
                                    context, ref, template);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  onTemplateApplied();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              color: Colors.grey,
                              tooltip: 'Eliminar plantilla',
                              onPressed: () async {
                                await ref
                                    .read(nutritionDaoProvider)
                                    .deleteMealTemplate(template.id);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _applyTemplate(
    BuildContext context,
    WidgetRef ref,
    MealTemplate template,
  ) async {
    try {
      final rawItems = jsonDecode(template.itemsJson) as List<dynamic>;
      final items = rawItems
          .map((e) {
            final map = e as Map<String, dynamic>;
            return MealItemInput(
              foodItemId: (map['foodItemId'] as num).toInt(),
              quantityG: (map['quantityG'] as num).toDouble(),
            );
          })
          .toList();

      if (items.isEmpty) return;

      await ref.read(nutritionNotifierProvider).logMeal(
            MealLogInput(
              mealType: template.mealType,
              items: items,
              note: 'Desde plantilla: ${template.name}',
            ),
          );
    } catch (_) {
      // Silently ignore parse errors for empty/corrupt templates
    }
  }
}

// ---------------------------------------------------------------------------
// Widget: rastreador de agua
// ---------------------------------------------------------------------------

class _WaterTrackerCard extends StatelessWidget {
  const _WaterTrackerCard({
    super.key,
    required this.glasses,
    required this.goalGlasses,
    required this.mlPerGlass,
    required this.goalReached,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int glasses;
  final int goalGlasses;
  final double mlPerGlass;
  final bool goalReached;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = goalGlasses > 0
        ? (glasses / goalGlasses).clamp(0.0, 1.0)
        : 0.0;
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
                Icon(
                  Icons.water_drop_outlined,
                  color: goalReached
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 8),
                Semantics(
                  header: true,
                  child: Text(
                    goalReached ? 'Agua - Meta alcanzada!' : 'Agua',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: goalReached
                          ? const Color(0xFF3B82F6)
                          : null,
                    ),
                  ),
                ),
                if (goalReached)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.emoji_events_outlined,
                      color: Color(0xFFFBBF24),
                      size: 18,
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
                color: goalReached
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF3B82F6),
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
