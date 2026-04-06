import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Modelos internos
// ---------------------------------------------------------------------------

class _DayNutrition {
  const _DayNutrition({
    required this.date,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.waterMl,
  });

  final DateTime date;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int waterMl;
}

class _NutritionMetrics {
  const _NutritionMetrics({
    required this.avgCalories,
    required this.avgProteinG,
    required this.avgCarbsG,
    required this.avgFatG,
    required this.daysLogged,
    required this.totalDays,
    required this.daysOnCalorieTarget,
    required this.longestStreak,
    required this.avgWaterMl,
    required this.daysMetWaterGoal,
    required this.bestWaterDay,
    required this.worstWaterDay,
    required this.goalCalories,
    required this.goalProteinG,
    required this.goalCarbsG,
    required this.goalFatG,
    required this.goalWaterMl,
  });

  final double avgCalories;
  final double avgProteinG;
  final double avgCarbsG;
  final double avgFatG;
  final int daysLogged;
  final int totalDays;
  final int daysOnCalorieTarget;
  final int longestStreak;
  final double avgWaterMl;
  final int daysMetWaterGoal;
  final DateTime? bestWaterDay;
  final DateTime? worstWaterDay;
  final int goalCalories;
  final double goalProteinG;
  final double goalCarbsG;
  final double goalFatG;
  final int goalWaterMl;
}

// ---------------------------------------------------------------------------
// Pantalla: Valoracion Nutricion
// ---------------------------------------------------------------------------

/// Valoracion integral del modulo Nutricion. Muestra metricas de macros,
/// consistencia e hidratacion comparadas con la ultima valoracion guardada.
class NutritionValuationScreen extends ConsumerStatefulWidget {
  const NutritionValuationScreen({super.key});

  @override
  ConsumerState<NutritionValuationScreen> createState() =>
      _NutritionValuationScreenState();
}

class _NutritionValuationScreenState
    extends ConsumerState<NutritionValuationScreen> {
  _NutritionMetrics? _current;
  Map<String, dynamic>? _previousData;
  bool _loading = true;
  bool _saving = false;

  // Periodo: ultimos 30 dias
  static const _periodDays = 30;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final nutritionDao = ref.read(nutritionDaoProvider);
      final dashDao = ref.read(dashboardDaoProvider);
      final now = DateTime.now();

      // --- Meta activa ---
      final today = DateTime(now.year, now.month, now.day);
      final goal = await nutritionDao.getActiveGoal(today);
      final goalCalories = goal?.caloriesKcal ?? 0;
      final goalProtein = goal?.proteinG ?? 0.0;
      final goalCarbs = goal?.carbsG ?? 0.0;
      final goalFat = goal?.fatG ?? 0.0;
      final goalWater = goal?.waterMl ?? 2000;

      // --- Datos de los ultimos 30 dias ---
      final days = <_DayNutrition>[];
      for (var i = 0; i < _periodDays; i++) {
        final date = today.subtract(Duration(days: i));
        final mealLogs = await nutritionDao.watchMealLogs(date).first;

        double cal = 0, prot = 0, carbs = 0, fat = 0;
        for (final meal in mealLogs) {
          final items = await nutritionDao.watchMealLogItems(meal.id).first;
          for (final item in items) {
            final food = await nutritionDao.getFoodItemById(item.foodItemId);
            if (food != null) {
              final factor = item.quantityG / 100.0;
              cal += food.caloriesPer100g * factor;
              prot += food.proteinPer100g * factor;
              carbs += food.carbsPer100g * factor;
              fat += food.fatPer100g * factor;
            }
          }
        }
        final water = await nutritionDao.totalWater(date);
        days.add(_DayNutrition(
          date: date,
          calories: cal,
          proteinG: prot,
          carbsG: carbs,
          fatG: fat,
          waterMl: water,
        ));
      }

      // --- Calcular metricas ---
      final daysWithData = days.where((d) => d.calories > 0).toList();
      final daysLogged = daysWithData.length;

      final avgCal = daysLogged > 0
          ? daysWithData.map((d) => d.calories).reduce((a, b) => a + b) /
              daysLogged
          : 0.0;
      final avgProt = daysLogged > 0
          ? daysWithData.map((d) => d.proteinG).reduce((a, b) => a + b) /
              daysLogged
          : 0.0;
      final avgCarbs = daysLogged > 0
          ? daysWithData.map((d) => d.carbsG).reduce((a, b) => a + b) /
              daysLogged
          : 0.0;
      final avgFat = daysLogged > 0
          ? daysWithData.map((d) => d.fatG).reduce((a, b) => a + b) /
              daysLogged
          : 0.0;

      // Dias dentro de ±10% de la meta calorica
      final daysOnTarget = goalCalories > 0
          ? daysWithData.where((d) {
              final lower = goalCalories * 0.9;
              final upper = goalCalories * 1.1;
              return d.calories >= lower && d.calories <= upper;
            }).length
          : 0;

      // Racha mas larga de dias consecutivos
      var longestStreak = 0;
      var currentStreak = 0;
      for (var i = 0; i < days.length; i++) {
        if (days[i].calories > 0) {
          currentStreak++;
          if (currentStreak > longestStreak) longestStreak = currentStreak;
        } else {
          currentStreak = 0;
        }
      }

      // Agua
      final allWater = days.map((d) => d.waterMl).toList();
      final avgWater = allWater.isNotEmpty
          ? allWater.reduce((a, b) => a + b) / allWater.length
          : 0.0;
      final daysMetWater = days.where((d) => d.waterMl >= goalWater).length;

      final sortedByWater = List<_DayNutrition>.from(days)
        ..sort((a, b) => b.waterMl.compareTo(a.waterMl));
      final bestWaterDay =
          sortedByWater.isNotEmpty && sortedByWater.first.waterMl > 0
              ? sortedByWater.first.date
              : null;
      final worstWaterDay =
          sortedByWater.isNotEmpty ? sortedByWater.last.date : null;

      final metrics = _NutritionMetrics(
        avgCalories: avgCal,
        avgProteinG: avgProt,
        avgCarbsG: avgCarbs,
        avgFatG: avgFat,
        daysLogged: daysLogged,
        totalDays: _periodDays,
        daysOnCalorieTarget: daysOnTarget,
        longestStreak: longestStreak,
        avgWaterMl: avgWater,
        daysMetWaterGoal: daysMetWater,
        bestWaterDay: bestWaterDay,
        worstWaterDay: worstWaterDay,
        goalCalories: goalCalories,
        goalProteinG: goalProtein,
        goalCarbsG: goalCarbs,
        goalFatG: goalFat,
        goalWaterMl: goalWater,
      );

      // --- Ultima valoracion previa ---
      final snapshots = await dashDao.getAllSnapshots();
      Map<String, dynamic>? prevData;
      for (final snap in snapshots) {
        try {
          final decoded =
              jsonDecode(snap.metricsJson) as Map<String, dynamic>;
          if (decoded['moduleKey'] == 'nutrition') {
            prevData = decoded['data'] as Map<String, dynamic>?;
            break;
          }
        } on Exception {
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _current = metrics;
          _previousData = prevData;
          _loading = false;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando datos: $e')),
        );
      }
    }
  }

  Map<String, dynamic> _serializeMetrics() {
    final m = _current!;
    return {
      'avgCalories': m.avgCalories,
      'avgProteinG': m.avgProteinG,
      'avgCarbsG': m.avgCarbsG,
      'avgFatG': m.avgFatG,
      'daysLogged': m.daysLogged,
      'totalDays': m.totalDays,
      'daysOnCalorieTarget': m.daysOnCalorieTarget,
      'longestStreak': m.longestStreak,
      'avgWaterMl': m.avgWaterMl,
      'daysMetWaterGoal': m.daysMetWaterGoal,
      'goalCalories': m.goalCalories,
      'goalProteinG': m.goalProteinG,
      'goalCarbsG': m.goalCarbsG,
      'goalFatG': m.goalFatG,
      'goalWaterMl': m.goalWaterMl,
    };
  }

  Future<void> _saveValuation() async {
    if (_current == null || _saving) return;
    setState(() => _saving = true);
    try {
      final dashDao = ref.read(dashboardDaoProvider);
      final data = _serializeMetrics();
      await dashDao.insertValuationSnapshot(
        moduleKey: 'nutrition',
        data: data,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            key: ValueKey('nutrition-valuation-saved-snackbar'),
            content: Text('Valoracion guardada!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _load();
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error guardando: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _NutritionValuationHistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('nutrition-valuation-screen'),
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: const Text('Valoracion Nutricion'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Semantics(
            label: 'Ver historial de valoraciones',
            button: true,
            child: IconButton(
              key: const ValueKey('nutrition-valuation-history-button'),
              icon: const Icon(Icons.history_outlined),
              onPressed: () => _showHistory(context),
              tooltip: 'Historial',
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _current == null
              ? const Center(child: Text('No se pudieron cargar los datos.'))
              : _buildBody(context),
      bottomNavigationBar: _loading || _current == null
          ? null
          : _BottomActions(
              onSave: _saving ? null : _saveValuation,
              onHistory: () => _showHistory(context),
              saving: _saving,
            ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final m = _current!;
    final prev = _previousData;

    return ListView(
      key: const ValueKey('nutrition-valuation-list'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'Periodo: ultimos $_periodDays dias',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.nutrition,
            ),
          ),
        ),
        if (prev != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Comparando con ultima valoracion guardada',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.nutrition,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        // --- Seccion Macros ---
        _SectionHeader(
          key: const ValueKey('nutrition-val-macros-header'),
          icon: Icons.restaurant_outlined,
          title: 'Macros (promedio diario)',
          color: AppColors.nutrition,
        ),
        _MacroRow(
          key: const ValueKey('nutrition-val-calories'),
          label: 'Calorias',
          value: '${m.avgCalories.toStringAsFixed(0)} kcal',
          goal: m.goalCalories > 0 ? '${m.goalCalories} kcal meta' : null,
          previousValue: prev?['avgCalories'] != null
              ? '${(prev!['avgCalories'] as num).toStringAsFixed(0)} kcal'
              : null,
          higherIsBetter: true,
          numericCurrent: m.avgCalories,
          numericPrevious: (prev?['avgCalories'] as num?)?.toDouble(),
          goalNumeric: m.goalCalories > 0 ? m.goalCalories.toDouble() : null,
          isCalories: true,
        ),
        _MacroRow(
          key: const ValueKey('nutrition-val-protein'),
          label: 'Proteina',
          value: '${m.avgProteinG.toStringAsFixed(1)} g',
          goal: m.goalProteinG > 0
              ? '${m.goalProteinG.toStringAsFixed(0)} g meta'
              : null,
          previousValue: prev?['avgProteinG'] != null
              ? '${(prev!['avgProteinG'] as num).toStringAsFixed(1)} g'
              : null,
          higherIsBetter: true,
          numericCurrent: m.avgProteinG,
          numericPrevious: (prev?['avgProteinG'] as num?)?.toDouble(),
        ),
        _MacroRow(
          key: const ValueKey('nutrition-val-carbs'),
          label: 'Carbohidratos',
          value: '${m.avgCarbsG.toStringAsFixed(1)} g',
          goal: m.goalCarbsG > 0
              ? '${m.goalCarbsG.toStringAsFixed(0)} g meta'
              : null,
          previousValue: prev?['avgCarbsG'] != null
              ? '${(prev!['avgCarbsG'] as num).toStringAsFixed(1)} g'
              : null,
          higherIsBetter: false,
          numericCurrent: m.avgCarbsG,
          numericPrevious: (prev?['avgCarbsG'] as num?)?.toDouble(),
        ),
        _MacroRow(
          key: const ValueKey('nutrition-val-fat'),
          label: 'Grasa',
          value: '${m.avgFatG.toStringAsFixed(1)} g',
          goal: m.goalFatG > 0
              ? '${m.goalFatG.toStringAsFixed(0)} g meta'
              : null,
          previousValue: prev?['avgFatG'] != null
              ? '${(prev!['avgFatG'] as num).toStringAsFixed(1)} g'
              : null,
          higherIsBetter: false,
          numericCurrent: m.avgFatG,
          numericPrevious: (prev?['avgFatG'] as num?)?.toDouble(),
        ),

        const SizedBox(height: 20),

        // --- Seccion Consistencia ---
        _SectionHeader(
          key: const ValueKey('nutrition-val-consistencia-header'),
          icon: Icons.track_changes_outlined,
          title: 'Consistencia',
          color: AppColors.nutrition,
        ),
        _MetricRow(
          key: const ValueKey('nutrition-val-days-logged'),
          label: 'Dias con registro',
          value: '${m.daysLogged} / ${m.totalDays}',
          previousValue: prev != null
              ? '${(prev['daysLogged'] as num?)?.toInt() ?? 0} / ${(prev['totalDays'] as num?)?.toInt() ?? _periodDays}'
              : null,
          higherIsBetter: true,
          numericCurrent: m.daysLogged.toDouble(),
          numericPrevious: (prev?['daysLogged'] as num?)?.toDouble(),
          unit: ' dias',
        ),
        if (m.goalCalories > 0)
          _MetricRow(
            key: const ValueKey('nutrition-val-on-target'),
            label: 'Dias en meta calorica (±10%)',
            value: '${m.daysOnCalorieTarget}',
            previousValue: prev != null
                ? '${(prev['daysOnCalorieTarget'] as num?)?.toInt() ?? 0}'
                : null,
            higherIsBetter: true,
            numericCurrent: m.daysOnCalorieTarget.toDouble(),
            numericPrevious: (prev?['daysOnCalorieTarget'] as num?)?.toDouble(),
            unit: ' dias',
          ),
        _MetricRow(
          key: const ValueKey('nutrition-val-streak'),
          label: 'Racha mas larga de dias consecutivos',
          value: '${m.longestStreak} dias',
          previousValue: prev != null
              ? '${(prev['longestStreak'] as num?)?.toInt() ?? 0} dias'
              : null,
          higherIsBetter: true,
          numericCurrent: m.longestStreak.toDouble(),
          numericPrevious: (prev?['longestStreak'] as num?)?.toDouble(),
          unit: ' dias',
        ),

        const SizedBox(height: 20),

        // --- Seccion Hidratacion ---
        _SectionHeader(
          key: const ValueKey('nutrition-val-agua-header'),
          icon: Icons.water_drop_outlined,
          title: 'Hidratacion',
          color: AppColors.nutrition,
        ),
        _MetricRow(
          key: const ValueKey('nutrition-val-avg-water'),
          label: 'Agua promedio/dia',
          value: '${m.avgWaterMl.toStringAsFixed(0)} ml',
          previousValue: prev?['avgWaterMl'] != null
              ? '${(prev!['avgWaterMl'] as num).toStringAsFixed(0)} ml'
              : null,
          higherIsBetter: true,
          numericCurrent: m.avgWaterMl,
          numericPrevious: (prev?['avgWaterMl'] as num?)?.toDouble(),
          unit: ' ml',
        ),
        _MetricRow(
          key: const ValueKey('nutrition-val-water-goal-days'),
          label: 'Dias que cumplio meta de agua',
          value: '${m.daysMetWaterGoal} / ${m.totalDays}',
          previousValue: prev != null
              ? '${(prev['daysMetWaterGoal'] as num?)?.toInt() ?? 0} / ${(prev['totalDays'] as num?)?.toInt() ?? _periodDays}'
              : null,
          higherIsBetter: true,
          numericCurrent: m.daysMetWaterGoal.toDouble(),
          numericPrevious: (prev?['daysMetWaterGoal'] as num?)?.toDouble(),
          unit: ' dias',
        ),
        if (m.bestWaterDay != null)
          _MetricRow(
            key: const ValueKey('nutrition-val-best-water'),
            label: 'Mejor dia de hidratacion',
            value: DateFormat('d MMM', 'es').format(m.bestWaterDay!),
            previousValue: null,
            higherIsBetter: true,
          ),
        if (m.worstWaterDay != null)
          _MetricRow(
            key: const ValueKey('nutrition-val-worst-water'),
            label: 'Peor dia de hidratacion',
            value: DateFormat('d MMM', 'es').format(m.worstWaterDay!),
            previousValue: null,
            higherIsBetter: false,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Historial de valoraciones Nutricion
// ---------------------------------------------------------------------------

class _NutritionValuationHistoryScreen extends ConsumerWidget {
  const _NutritionValuationHistoryScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ValuationHistoryScreen(
      moduleKey: 'nutrition',
      title: 'Historial Valoracion Nutricion',
      color: AppColors.nutrition,
      summaryBuilder: (data) {
        final cal = (data['avgCalories'] as num?)?.toDouble() ?? 0.0;
        final prot = (data['avgProteinG'] as num?)?.toDouble() ?? 0.0;
        final days = (data['daysLogged'] as num?)?.toInt() ?? 0;
        return '${cal.toStringAsFixed(0)} kcal · ${prot.toStringAsFixed(1)} g prot · $days dias registrados';
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets especificos
// ---------------------------------------------------------------------------

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    super.key,
    required this.label,
    required this.value,
    required this.goal,
    required this.previousValue,
    required this.higherIsBetter,
    required this.numericCurrent,
    required this.numericPrevious,
    this.goalNumeric,
    this.isCalories = false,
  });

  final String label;
  final String value;
  final String? goal;
  final String? previousValue;
  final bool higherIsBetter;
  final double? numericCurrent;
  final double? numericPrevious;
  final double? goalNumeric;
  final bool isCalories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showDelta = numericCurrent != null && numericPrevious != null;

    // Para calorias, "bueno" es estar cerca de la meta (neutro)
    final effectiveHigherIsBetter = isCalories ? true : higherIsBetter;

    return Semantics(
      label: '$label: $value${goal != null ? " ($goal)" : ""}${previousValue != null ? ", anterior: $previousValue" : ""}',
      child: Card(
        key: key,
        margin: const EdgeInsets.only(bottom: 6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.bodyMedium),
                    if (goal != null)
                      Text(
                        goal!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.nutrition.withAlpha(180),
                        ),
                      ),
                    if (previousValue != null)
                      Text(
                        'Anterior: $previousValue',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(120),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (showDelta) ...[
                const SizedBox(width: 8),
                _DeltaWidget(
                  current: numericCurrent!,
                  previous: numericPrevious!,
                  higherIsBetter: effectiveHigherIsBetter,
                  unit: '',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Semantics(
            header: true,
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    super.key,
    required this.label,
    required this.value,
    required this.previousValue,
    required this.higherIsBetter,
    this.numericCurrent,
    this.numericPrevious,
    this.unit = '',
  });

  final String label;
  final String value;
  final String? previousValue;
  final bool higherIsBetter;
  final double? numericCurrent;
  final double? numericPrevious;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showDelta = numericCurrent != null && numericPrevious != null;

    return Semantics(
      label: '$label: $value${previousValue != null ? ", anterior: $previousValue" : ""}',
      child: Card(
        key: key,
        margin: const EdgeInsets.only(bottom: 6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.bodyMedium),
                    if (previousValue != null)
                      Text(
                        'Anterior: $previousValue',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(120),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (showDelta) ...[
                const SizedBox(width: 8),
                _DeltaWidget(
                  current: numericCurrent!,
                  previous: numericPrevious!,
                  higherIsBetter: higherIsBetter,
                  unit: unit,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DeltaWidget extends StatelessWidget {
  const _DeltaWidget({
    required this.current,
    required this.previous,
    required this.higherIsBetter,
    required this.unit,
  });

  final double current;
  final double previous;
  final bool higherIsBetter;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final delta = current - previous;
    final isGood = higherIsBetter ? delta > 0 : delta < 0;
    final isNeutral = delta.abs() < 0.01;

    Color color;
    IconData icon;
    if (isNeutral) {
      color = Colors.grey;
      icon = Icons.remove;
    } else if (isGood) {
      color = AppColors.success;
      icon = Icons.arrow_upward;
    } else {
      color = AppColors.error;
      icon = Icons.arrow_downward;
    }

    final absStr = unit.isNotEmpty
        ? '${delta.abs().toStringAsFixed(1)}$unit'
        : delta.abs().toStringAsFixed(1);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        Text(
          isNeutral ? 'igual' : absStr,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.onSave,
    required this.onHistory,
    required this.saving,
  });

  final VoidCallback? onSave;
  final VoidCallback onHistory;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                label: 'Guardar valoracion actual',
                button: true,
                child: FilledButton.icon(
                  key: const ValueKey('nutrition-valuation-save-button'),
                  onPressed: onSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.nutrition,
                  ),
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(saving ? 'Guardando...' : 'Guardar Valoracion'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: 'Ver historial de valoraciones',
              button: true,
              child: OutlinedButton.icon(
                key: const ValueKey(
                    'nutrition-valuation-history-bottom-button'),
                onPressed: onHistory,
                icon: const Icon(Icons.history_outlined),
                label: const Text('Historial'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pantalla generica de historial
// ---------------------------------------------------------------------------

class _ValuationHistoryScreen extends ConsumerStatefulWidget {
  const _ValuationHistoryScreen({
    required this.moduleKey,
    required this.title,
    required this.color,
    required this.summaryBuilder,
  });

  final String moduleKey;
  final String title;
  final Color color;
  final String Function(Map<String, dynamic> data) summaryBuilder;

  @override
  ConsumerState<_ValuationHistoryScreen> createState() =>
      _ValuationHistoryScreenState();
}

class _ValuationHistoryScreenState
    extends ConsumerState<_ValuationHistoryScreen> {
  List<LifeSnapshot> _snapshots = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dashDao = ref.read(dashboardDaoProvider);
    final all = await dashDao.getAllSnapshots();
    final filtered = all.where((s) {
      try {
        final decoded =
            jsonDecode(s.metricsJson) as Map<String, dynamic>;
        return decoded['moduleKey'] == widget.moduleKey;
      } on Exception {
        return false;
      }
    }).toList();

    if (mounted) {
      setState(() {
        _snapshots = filtered;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: ValueKey('${widget.moduleKey}-valuation-history-screen'),
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(widget.title),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _snapshots.isEmpty
              ? Center(
                  child: Text(
                    'Sin valoraciones guardadas todavia.',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : ListView.separated(
                  key: ValueKey(
                      '${widget.moduleKey}-valuation-history-list'),
                  padding: const EdgeInsets.all(16),
                  itemCount: _snapshots.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final snap = _snapshots[index];
                    Map<String, dynamic>? data;
                    try {
                      final decoded = jsonDecode(snap.metricsJson)
                          as Map<String, dynamic>;
                      data = decoded['data'] as Map<String, dynamic>?;
                    } on Exception {
                      data = null;
                    }
                    final summary =
                        data != null ? widget.summaryBuilder(data) : '';
                    final dateStr =
                        DateFormat('d MMM yyyy · HH:mm', 'es')
                            .format(snap.date.toLocal());

                    return Semantics(
                      label: 'Valoracion del $dateStr: $summary',
                      child: Card(
                        key: ValueKey(
                            '${widget.moduleKey}-history-snap-${snap.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateStr,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: widget.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                summary,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
