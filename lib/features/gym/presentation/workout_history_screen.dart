import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/router/app_router.dart';
import 'package:life_os/core/widgets/animated_list_item.dart';
import 'package:life_os/core/widgets/chart_card.dart';
import 'package:life_os/core/widgets/pressable_card.dart';

// ---------------------------------------------------------------------------
// Pantalla: historial de entrenamientos
// ---------------------------------------------------------------------------

/// Historial de sesiones de entrenamiento completadas. Toca una sesion para
/// ver el detalle de todos los ejercicios y series.
///
/// Accesibilidad: A11Y-GYM-04 — cada tarjeta de sesion tiene etiqueta
/// semantica con el resumen del entrenamiento.
class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(gymDaoProvider);

    return Scaffold(
      key: const ValueKey('workout-history-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.gym,
        title: Semantics(
          header: true,
          child: const Text('Historial de entrenamientos'),
        ),
        actions: [
          Semantics(
            label: 'Medidas corporales',
            button: true,
            child: IconButton(
              key: const ValueKey('workout-history-measurements-button'),
              icon: const Icon(Icons.monitor_weight_outlined),
              onPressed: () =>
                  GoRouter.of(context).push(AppRoutes.gymMeasurements),
              tooltip: 'Medidas corporales',
            ),
          ),
          Semantics(
            label: 'Filtrar historial',
            button: true,
            child: IconButton(
              key: const ValueKey('workout-history-filter-button'),
              icon: const Icon(Icons.filter_list_outlined),
              onPressed: () {},
              tooltip: 'Filtrar',
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Workout>>(
        stream: dao.watchWorkouts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final workouts = snapshot.data ?? [];

          if (workouts.isEmpty) {
            return _EmptyHistory(
                key: const ValueKey('workout-history-empty'));
          }

          return CustomScrollView(
            key: const ValueKey('workout-history-scroll'),
            slivers: [
              // Charts section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _WorkoutChartsSection(
                    key: const ValueKey('workout-charts-section'),
                    workouts: workouts,
                    dao: dao,
                  ),
                ),
              ),
              // History list
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final workout = workouts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AnimatedListItem(
                          index: index,
                          child: _WorkoutSessionCard(
                            key: ValueKey('workout-session-card-${workout.id}'),
                            workout: workout,
                            onTap: () => _openDetail(context, workout),
                          ),
                        ),
                      );
                    },
                    childCount: workouts.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openDetail(BuildContext context, Workout workout) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => _WorkoutDetailScreen(workout: workout),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: tarjeta de sesion de entrenamiento
// ---------------------------------------------------------------------------

class _WorkoutSessionCard extends ConsumerWidget {
  const _WorkoutSessionCard({
    super.key,
    required this.workout,
    required this.onTap,
  });

  final Workout workout;
  final VoidCallback onTap;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Hoy';
    if (d == yesterday) return 'Ayer';

    final months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDuration(Workout w) {
    if (w.finishedAt == null) return '—';
    final minutes = w.finishedAt!.difference(w.startedAt).inMinutes;
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dao = ref.watch(gymDaoProvider);

    return StreamBuilder<List<WorkoutSet>>(
      stream: dao.watchWorkoutSets(workout.id),
      builder: (context, snapshot) {
        final sets = snapshot.data ?? [];
        final workSets = sets.where((s) => !s.isWarmup).toList();
        final exerciseIds = sets.map((s) => s.exerciseId).toSet().length;
        final totalVolume = workSets
            .where((s) => s.weightKg != null)
            .fold<double>(0.0, (sum, s) => sum + s.weightKg! * s.reps);
        final label = _formatDate(workout.startedAt);
        final semanticLabel = '$label, duracion ${_formatDuration(workout)}, '
            '$exerciseIds ejercicios, ${sets.length} series';

        return Semantics(
          label: semanticLabel,
          button: true,
          child: PressableCard(
            onTap: onTap,
            child: Card(
              margin: EdgeInsets.zero,
              child: InkWell(
                key: ValueKey('workout-session-item-${workout.id}'),
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado: fecha + icono
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.gym.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.fitness_center,
                              color: AppColors.gym,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  _formatDuration(workout),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_outlined,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Estadisticas rapidas
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _StatChip(
                            icon: Icons.fitness_center,
                            label: '$exerciseIds ejerc.',
                          ),
                          _StatChip(
                            icon: Icons.repeat_outlined,
                            label: '${sets.length} series',
                          ),
                          if (totalVolume > 0)
                            _StatChip(
                              icon: Icons.monitor_weight_outlined,
                              label: '${totalVolume.toStringAsFixed(0)} kg',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: chip de estadistica
// ---------------------------------------------------------------------------

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.gym),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pantalla: detalle de sesion de entrenamiento
// ---------------------------------------------------------------------------

class _WorkoutDetailScreen extends ConsumerWidget {
  const _WorkoutDetailScreen({required this.workout});

  final Workout workout;

  String _formatDate(DateTime date) {
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  String _formatDuration(Workout w) {
    if (w.finishedAt == null) return '—';
    final minutes = w.finishedAt!.difference(w.startedAt).inMinutes;
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dao = ref.watch(gymDaoProvider);

    return Scaffold(
      key: const ValueKey('workout-detail-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.gym,
        title: Semantics(
          header: true,
          child: Text(_formatDate(workout.startedAt)),
        ),
        leading: Semantics(
          label: 'Volver al historial',
          button: true,
          child: IconButton(
            key: const ValueKey('workout-detail-back-button'),
            icon: const Icon(Icons.arrow_back_outlined),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Volver',
          ),
        ),
      ),
      body: StreamBuilder<List<WorkoutSet>>(
        stream: dao.watchWorkoutSets(workout.id),
        builder: (context, snapshot) {
          final sets = snapshot.data ?? [];
          final workSets = sets.where((s) => !s.isWarmup).toList();
          final totalVolume = workSets
              .where((s) => s.weightKg != null)
              .fold<double>(0.0, (sum, s) => sum + s.weightKg! * s.reps);
          final exerciseIds = sets.map((s) => s.exerciseId).toSet();

          // Group sets by exerciseId preserving order
          final Map<int, List<WorkoutSet>> byExercise = {};
          for (final s in sets) {
            byExercise.putIfAbsent(s.exerciseId, () => []).add(s);
          }

          return ListView(
            key: const ValueKey('workout-detail-list'),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              // Resumen de la sesion
              Card(
                key: const ValueKey('workout-detail-summary-card'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          _formatDate(workout.startedAt),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppColors.gym,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _DetailStat(
                              label: 'Duracion',
                              value: _formatDuration(workout),
                              icon: Icons.timer_outlined,
                            ),
                          ),
                          Expanded(
                            child: _DetailStat(
                              label: 'Ejercicios',
                              value: '${exerciseIds.length}',
                              icon: Icons.fitness_center,
                            ),
                          ),
                          Expanded(
                            child: _DetailStat(
                              label: 'Volumen',
                              value: totalVolume > 0
                                  ? '${totalVolume.toStringAsFixed(0)} kg'
                                  : '—',
                              icon: Icons.monitor_weight_outlined,
                            ),
                          ),
                        ],
                      ),
                      if (workout.note != null &&
                          workout.note!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          workout.note!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Ejercicios agrupados
              ...byExercise.entries.map((entry) {
                final exerciseId = entry.key;
                final exSets = entry.value;
                final exVolume = exSets
                    .where((s) => !s.isWarmup && s.weightKg != null)
                    .fold<double>(
                        0.0, (sum, s) => sum + s.weightKg! * s.reps);

                return Padding(
                  key: ValueKey('detail-exercise-$exerciseId'),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Encabezado del ejercicio
                          StreamBuilder(
                            stream: dao.watchExercises(),
                            builder: (ctx, snap) {
                              final exName = snap.data
                                      ?.where((e) => e.id == exerciseId)
                                      .firstOrNull
                                      ?.name ??
                                  'Ejercicio $exerciseId';
                              return Row(
                                children: [
                                  Expanded(
                                    child: Semantics(
                                      header: true,
                                      child: Text(
                                        exName,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  if (exVolume > 0)
                                    _StatChip(
                                      icon: Icons.monitor_weight_outlined,
                                      label:
                                          '${exVolume.toStringAsFixed(0)} kg',
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          // Cabecera columnas
                          Row(
                            children: [
                              SizedBox(
                                  width: 28,
                                  child: Text('#',
                                      style: theme.textTheme.labelSmall)),
                              Expanded(
                                child: Text('Peso (kg)',
                                    style: theme.textTheme.labelSmall,
                                    textAlign: TextAlign.center),
                              ),
                              Expanded(
                                child: Text('Reps',
                                    style: theme.textTheme.labelSmall,
                                    textAlign: TextAlign.center),
                              ),
                              const SizedBox(width: 40),
                            ],
                          ),
                          const Divider(),
                          ...exSets.map(
                            (set) => Semantics(
                              label:
                                  '${set.isWarmup ? 'Calentamiento' : 'Serie ${set.setNumber}'}: '
                                  '${set.weightKg != null ? '${set.weightKg} kg, ' : ''}'
                                  '${set.reps} repeticiones',
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      child: Container(
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: set.isWarmup
                                              ? Colors.blue.withAlpha(25)
                                              : AppColors.gym.withAlpha(20),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          set.isWarmup
                                              ? 'C'
                                              : '${set.setNumber}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: set.isWarmup
                                                ? Colors.blue
                                                : AppColors.gym,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        set.weightKg != null
                                            ? '${set.weightKg}'
                                            : '—',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${set.reps}',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: AppColors.gym,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: estadistica del detalle
// ---------------------------------------------------------------------------

class _DetailStat extends StatelessWidget {
  const _DetailStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: AppColors.gym, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: estado vacio de historial
// ---------------------------------------------------------------------------

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_outlined,
              size: 64,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin entrenamientos',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Completa tu primer entrenamiento para ver el historial aqui.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Charts section: weekly volume + workouts per week
// ---------------------------------------------------------------------------

class _WorkoutChartsSection extends ConsumerWidget {
  const _WorkoutChartsSection({
    super.key,
    required this.workouts,
    required this.dao,
  });

  final List<Workout> workouts;
  final dynamic dao;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymDao = ref.watch(gymDaoProvider);

    return StreamBuilder<List<Workout>>(
      stream: gymDao.watchWorkouts(),
      builder: (context, snapshot) {
        final allWorkouts = snapshot.data ?? [];

        // Build weekly data — last 12 weeks
        final now = DateTime.now();
        final weekData = <({String label, int count, double volumeKg})>[];

        for (int w = 11; w >= 0; w--) {
          final weekEnd = now.subtract(Duration(days: now.weekday - 1 + w * 7));
          final weekStart = weekEnd.subtract(const Duration(days: 6));
          final label = '${weekStart.day}/${weekStart.month}';

          final weekWorkouts = allWorkouts.where((wo) {
            if (wo.finishedAt == null) return false;
            final d = wo.finishedAt!;
            return d.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
                d.isBefore(weekEnd.add(const Duration(days: 1)));
          }).toList();

          weekData.add((
            label: label,
            count: weekWorkouts.length,
            volumeKg: 0, // Volume computed per-workout below
          ));
        }

        // Workouts per week bar chart
        final hasWorkoutData = weekData.any((w) => w.count > 0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChartCard(
              key: const ValueKey('workouts-per-week-chart'),
              title: 'Entrenamientos por semana',
              child: hasWorkoutData
                  ? _WeeklyWorkoutsBarChart(weekData: weekData)
                  : const Center(child: Text('Sin datos suficientes')),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class _WeeklyWorkoutsBarChart extends StatelessWidget {
  const _WeeklyWorkoutsBarChart({required this.weekData});

  final List<({String label, int count, double volumeKg})> weekData;

  @override
  Widget build(BuildContext context) {
    final maxY = weekData.map((w) => w.count.toDouble()).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: maxY < 1 ? 5 : maxY * 1.3,
          barTouchData: BarTouchData(enabled: false),
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
                reservedSize: 20,
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
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: Color(0x1A9E9E9E),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: weekData.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.count.toDouble(),
                  color: e.value.count > 0
                      ? AppColors.gym
                      : AppColors.gym.withAlpha(30),
                  width: 14,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
