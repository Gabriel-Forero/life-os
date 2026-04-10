import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/features/dashboard/domain/models/life_snapshot_model.dart';
import 'package:life_os/features/gym/domain/gym_validators.dart';
import 'package:life_os/features/gym/domain/models/body_measurement_model.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Modelos internos
// ---------------------------------------------------------------------------

class _ExercisePR {
  const _ExercisePR({
    required this.name,
    required this.exerciseId,
    required this.weightKg,
    required this.oneRM,
  });

  final String name;
  final String exerciseId;
  final double? weightKg;
  final double? oneRM;
}

class _GymMetrics {
  const _GymMetrics({
    required this.prs,
    required this.weeklyWorkouts,
    required this.monthlyWorkouts,
    required this.weeklyVolumeKg,
    required this.monthlyVolumeKg,
    required this.avgVolumePerWorkout,
    required this.latestMeasurement,
  });

  final List<_ExercisePR> prs;
  final int weeklyWorkouts;
  final int monthlyWorkouts;
  final double weeklyVolumeKg;
  final double monthlyVolumeKg;
  final double avgVolumePerWorkout;
  final BodyMeasurementModel? latestMeasurement;
}

// ---------------------------------------------------------------------------
// Pantalla: Valoracion Gym
// ---------------------------------------------------------------------------

/// Valoracion integral del modulo Gym. Muestra metricas de fuerza, volumen
/// y cuerpo comparadas con la ultima valoracion guardada.
class GymValuationScreen extends ConsumerStatefulWidget {
  const GymValuationScreen({super.key});

  @override
  ConsumerState<GymValuationScreen> createState() => _GymValuationScreenState();
}

class _GymValuationScreenState extends ConsumerState<GymValuationScreen> {
  _GymMetrics? _current;
  Map<String, dynamic>? _previousData;
  bool _loading = true;
  bool _saving = false;

  // Ejercicios principales a mostrar (nombre del ejercicio en BD)
  static const _mainExercises = [
    'Bench Press',
    'Squat',
    'Deadlift',
    'Overhead Press',
    'Barbell Row',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final gymRepo = ref.read(gymRepositoryProvider);
      final dashRepo = ref.read(dashboardRepositoryProvider);

      // --- PRs de ejercicios principales ---
      final allExercises = await gymRepo.watchExercises().first;
      final prs = <_ExercisePR>[];

      for (final name in _mainExercises) {
        final match = allExercises
            .where((e) => e.name.toLowerCase().contains(name.toLowerCase()))
            .toList();
        if (match.isNotEmpty) {
          final ex = match.first;
          final weightPR = await gymRepo.getWeightPR(ex.id);
          // Use Epley 1RM estimate from last PR set (reps=1 for simplest estimate)
          final oneRM = weightPR != null ? calculate1RM(weightPR, 5) : null;
          prs.add(_ExercisePR(
            name: ex.name,
            exerciseId: ex.id,
            weightKg: weightPR,
            oneRM: oneRM,
          ));
        }
      }

      // --- Volumen y frecuencia ---
      final now = DateTime.now();
      final weekStart = now.subtract(const Duration(days: 7));
      final monthStart = DateTime(now.year, now.month, 1);

      final allWorkouts = await gymRepo.watchWorkouts().first;
      final weekWorkouts = allWorkouts
          .where((w) =>
              w.finishedAt != null && w.startedAt.isAfter(weekStart))
          .toList();
      final monthWorkouts = allWorkouts
          .where((w) =>
              w.finishedAt != null && w.startedAt.isAfter(monthStart))
          .toList();

      double weekVol = 0;
      double monthVol = 0;

      for (final w in weekWorkouts) {
        final sets = await gymRepo.watchWorkoutSets(w.id).first;
        for (final s in sets) {
          if (!s.isWarmup && s.weightKg != null) {
            weekVol += s.weightKg! * s.reps;
          }
        }
      }

      for (final w in monthWorkouts) {
        final sets = await gymRepo.watchWorkoutSets(w.id).first;
        for (final s in sets) {
          if (!s.isWarmup && s.weightKg != null) {
            monthVol += s.weightKg! * s.reps;
          }
        }
      }

      final avgVol = weekWorkouts.isNotEmpty ? weekVol / weekWorkouts.length : 0.0;

      // --- Ultima medicion corporal ---
      final latestMeasurement = await gymRepo.getLatestMeasurement();

      final metrics = _GymMetrics(
        prs: prs,
        weeklyWorkouts: weekWorkouts.length,
        monthlyWorkouts: monthWorkouts.length,
        weeklyVolumeKg: weekVol,
        monthlyVolumeKg: monthVol,
        avgVolumePerWorkout: avgVol,
        latestMeasurement: latestMeasurement,
      );

      // --- Ultima valoracion previa ---
      final snapshots = await dashRepo.getAllSnapshots();
      Map<String, dynamic>? prevData;
      for (final snap in snapshots) {
        try {
          final decoded = jsonDecode(snap.metricsJson) as Map<String, dynamic>;
          if (decoded['moduleKey'] == 'gym') {
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
      'weeklyWorkouts': m.weeklyWorkouts,
      'monthlyWorkouts': m.monthlyWorkouts,
      'weeklyVolumeKg': m.weeklyVolumeKg,
      'monthlyVolumeKg': m.monthlyVolumeKg,
      'avgVolumePerWorkout': m.avgVolumePerWorkout,
      'prs': {
        for (final pr in m.prs)
          pr.name: {
            'weightKg': pr.weightKg,
            'oneRM': pr.oneRM,
          },
      },
      if (m.latestMeasurement != null) ...{
        'weightKg': m.latestMeasurement!.weightKg,
        'bodyFatPercent': m.latestMeasurement!.bodyFatPercent,
        'armCm': m.latestMeasurement!.armCm,
        'waistCm': m.latestMeasurement!.waistCm,
        'chestCm': m.latestMeasurement!.chestCm,
      },
    };
  }

  Future<void> _saveValuation() async {
    if (_current == null || _saving) return;
    setState(() => _saving = true);
    try {
      final dashRepo = ref.read(dashboardRepositoryProvider);
      final data = _serializeMetrics();
      await dashRepo.insertValuationSnapshot(
        moduleKey: 'gym',
        data: data,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            key: ValueKey('gym-valuation-saved-snackbar'),
            content: Text('Valoracion guardada!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Reload to show as previous
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
        builder: (_) => const _GymValuationHistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('gym-valuation-screen'),
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: const Text('Valoracion Gym'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.gym,
        actions: [
          Semantics(
            label: 'Ver historial de valoraciones',
            button: true,
            child: IconButton(
              key: const ValueKey('gym-valuation-history-button'),
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
      key: const ValueKey('gym-valuation-list'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        if (prev != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Comparando con ultima valoracion guardada',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.gym,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        // --- Seccion Fuerza ---
        _SectionHeader(
          key: const ValueKey('gym-val-fuerza-header'),
          icon: Icons.fitness_center,
          title: 'Fuerza',
          color: AppColors.gym,
        ),
        if (m.prs.isEmpty)
          const _EmptyHint(text: 'Sin registros de PR todavia.')
        else
          ...m.prs.map((pr) {
            double? prevWeight;
            double? prevOneRM;
            if (prev != null) {
              final prevPrs = prev['prs'] as Map<String, dynamic>?;
              if (prevPrs != null && prevPrs.containsKey(pr.name)) {
                final p = prevPrs[pr.name] as Map<String, dynamic>;
                prevWeight = (p['weightKg'] as num?)?.toDouble();
                prevOneRM = (p['oneRM'] as num?)?.toDouble();
              }
            }
            return _PRRow(
              key: ValueKey('gym-val-pr-${pr.name}'),
              name: pr.name,
              weightKg: pr.weightKg,
              oneRM: pr.oneRM,
              prevWeightKg: prevWeight,
              prevOneRM: prevOneRM,
            );
          }),

        const SizedBox(height: 20),

        // --- Seccion Volumen ---
        _SectionHeader(
          key: const ValueKey('gym-val-volumen-header'),
          icon: Icons.bar_chart_outlined,
          title: 'Volumen',
          color: AppColors.gym,
        ),
        _MetricRow(
          key: const ValueKey('gym-val-workouts-week'),
          label: 'Entrenamientos esta semana',
          value: '${m.weeklyWorkouts}',
          previousValue: prev != null
              ? '${(prev['weeklyWorkouts'] as num?)?.toInt() ?? 0}'
              : null,
          higherIsBetter: true,
        ),
        _MetricRow(
          key: const ValueKey('gym-val-workouts-month'),
          label: 'Entrenamientos este mes',
          value: '${m.monthlyWorkouts}',
          previousValue: prev != null
              ? '${(prev['monthlyWorkouts'] as num?)?.toInt() ?? 0}'
              : null,
          higherIsBetter: true,
        ),
        _MetricRow(
          key: const ValueKey('gym-val-volume-week'),
          label: 'Volumen semanal',
          value: _fmtKg(m.weeklyVolumeKg),
          previousValue: prev != null
              ? _fmtKg((prev['weeklyVolumeKg'] as num?)?.toDouble() ?? 0)
              : null,
          higherIsBetter: true,
          numericCurrent: m.weeklyVolumeKg,
          numericPrevious: (prev?['weeklyVolumeKg'] as num?)?.toDouble(),
        ),
        _MetricRow(
          key: const ValueKey('gym-val-avg-volume'),
          label: 'Volumen promedio/entrenamiento',
          value: _fmtKg(m.avgVolumePerWorkout),
          previousValue: prev != null
              ? _fmtKg(
                  (prev['avgVolumePerWorkout'] as num?)?.toDouble() ?? 0)
              : null,
          higherIsBetter: true,
          numericCurrent: m.avgVolumePerWorkout,
          numericPrevious:
              (prev?['avgVolumePerWorkout'] as num?)?.toDouble(),
        ),

        const SizedBox(height: 20),

        // --- Seccion Cuerpo ---
        _SectionHeader(
          key: const ValueKey('gym-val-cuerpo-header'),
          icon: Icons.monitor_weight_outlined,
          title: 'Cuerpo',
          color: AppColors.gym,
        ),
        if (m.latestMeasurement == null)
          const _EmptyHint(text: 'Sin mediciones corporales registradas.')
        else ...[
          _MetricRow(
            key: const ValueKey('gym-val-weight'),
            label: 'Peso',
            value: m.latestMeasurement!.weightKg != null
                ? '${m.latestMeasurement!.weightKg!.toStringAsFixed(1)} kg'
                : 'N/A',
            previousValue: prev?['weightKg'] != null
                ? '${(prev!['weightKg'] as num).toStringAsFixed(1)} kg'
                : null,
            higherIsBetter: false,
            numericCurrent: m.latestMeasurement!.weightKg,
            numericPrevious: (prev?['weightKg'] as num?)?.toDouble(),
          ),
          _MetricRow(
            key: const ValueKey('gym-val-fat'),
            label: 'Grasa corporal',
            value: m.latestMeasurement!.bodyFatPercent != null
                ? '${m.latestMeasurement!.bodyFatPercent!.toStringAsFixed(1)}%'
                : 'N/A',
            previousValue: prev?['bodyFatPercent'] != null
                ? '${(prev!['bodyFatPercent'] as num).toStringAsFixed(1)}%'
                : null,
            higherIsBetter: false,
            numericCurrent: m.latestMeasurement!.bodyFatPercent,
            numericPrevious: (prev?['bodyFatPercent'] as num?)?.toDouble(),
          ),
          if (m.latestMeasurement!.weightKg != null &&
              m.latestMeasurement!.heightCm != null)
            _MetricRow(
              key: const ValueKey('gym-val-bmi'),
              label: 'IMC',
              value: _bmi(
                m.latestMeasurement!.weightKg!,
                m.latestMeasurement!.heightCm!,
              ),
              previousValue: null,
              higherIsBetter: false,
            ),
          _MetricRow(
            key: const ValueKey('gym-val-arm'),
            label: 'Brazo',
            value: m.latestMeasurement!.armCm != null
                ? '${m.latestMeasurement!.armCm!.toStringAsFixed(1)} cm'
                : 'N/A',
            previousValue: prev?['armCm'] != null
                ? '${(prev!['armCm'] as num).toStringAsFixed(1)} cm'
                : null,
            higherIsBetter: true,
            numericCurrent: m.latestMeasurement!.armCm,
            numericPrevious: (prev?['armCm'] as num?)?.toDouble(),
          ),
          _MetricRow(
            key: const ValueKey('gym-val-chest'),
            label: 'Pecho',
            value: m.latestMeasurement!.chestCm != null
                ? '${m.latestMeasurement!.chestCm!.toStringAsFixed(1)} cm'
                : 'N/A',
            previousValue: prev?['chestCm'] != null
                ? '${(prev!['chestCm'] as num).toStringAsFixed(1)} cm'
                : null,
            higherIsBetter: true,
            numericCurrent: m.latestMeasurement!.chestCm,
            numericPrevious: (prev?['chestCm'] as num?)?.toDouble(),
          ),
          _MetricRow(
            key: const ValueKey('gym-val-waist'),
            label: 'Cintura',
            value: m.latestMeasurement!.waistCm != null
                ? '${m.latestMeasurement!.waistCm!.toStringAsFixed(1)} cm'
                : 'N/A',
            previousValue: prev?['waistCm'] != null
                ? '${(prev!['waistCm'] as num).toStringAsFixed(1)} cm'
                : null,
            higherIsBetter: false,
            numericCurrent: m.latestMeasurement!.waistCm,
            numericPrevious: (prev?['waistCm'] as num?)?.toDouble(),
          ),
        ],
      ],
    );
  }

  String _fmtKg(double kg) {
    if (kg >= 1000) {
      return '${(kg / 1000).toStringAsFixed(1)} t';
    }
    return '${kg.toStringAsFixed(0)} kg';
  }

  String _bmi(double weightKg, double heightCm) {
    final h = heightCm / 100;
    final bmi = weightKg / (h * h);
    String label;
    if (bmi < 18.5) {
      label = 'Bajo peso';
    } else if (bmi < 25) {
      label = 'Normal';
    } else if (bmi < 30) {
      label = 'Sobrepeso';
    } else {
      label = 'Obesidad';
    }
    return '${bmi.toStringAsFixed(1)} ($label)';
  }
}

// ---------------------------------------------------------------------------
// Historial de valoraciones Gym
// ---------------------------------------------------------------------------

class _GymValuationHistoryScreen extends ConsumerWidget {
  const _GymValuationHistoryScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ValuationHistoryScreen(
      moduleKey: 'gym',
      title: 'Historial Valoracion Gym',
      color: AppColors.gym,
      summaryBuilder: (data) {
        final weekWorkouts = (data['weeklyWorkouts'] as num?)?.toInt() ?? 0;
        final weekVol = (data['weeklyVolumeKg'] as num?)?.toDouble() ?? 0;
        return '$weekWorkouts entrenamientos · ${weekVol.toStringAsFixed(0)} kg volumen';
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets compartidos
// ---------------------------------------------------------------------------

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

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
      ),
    );
  }
}

class _PRRow extends StatelessWidget {
  const _PRRow({
    super.key,
    required this.name,
    required this.weightKg,
    required this.oneRM,
    required this.prevWeightKg,
    required this.prevOneRM,
  });

  final String name;
  final double? weightKg;
  final double? oneRM;
  final double? prevWeightKg;
  final double? prevOneRM;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasData = weightKg != null;
    final deltaWidget = (hasData && prevWeightKg != null)
        ? _DeltaWidget(
            current: weightKg!,
            previous: prevWeightKg!,
            higherIsBetter: true,
            unit: 'kg',
          )
        : null;

    return Semantics(
      label: '$name: PR ${weightKg?.toStringAsFixed(1) ?? "sin dato"} kg',
      child: Card(
        key: key,
        margin: const EdgeInsets.only(bottom: 6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.fitness_center, size: 16, color: AppColors.gym),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (hasData)
                      Text(
                        'PR: ${weightKg!.toStringAsFixed(1)} kg'
                        '${oneRM != null ? '  ·  1RM est: ${oneRM!.toStringAsFixed(0)} kg' : ''}',
                        style: theme.textTheme.bodySmall,
                      )
                    else
                      Text('Sin PR registrado',
                          style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (deltaWidget != null) deltaWidget,
            ],
          ),
        ),
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
  });

  final String label;
  final String value;
  final String? previousValue;
  final bool higherIsBetter;
  final double? numericCurrent;
  final double? numericPrevious;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showDelta =
        numericCurrent != null && numericPrevious != null;

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
          isNeutral ? 'sin cambio' : absStr,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
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
                  key: const ValueKey('gym-valuation-save-button'),
                  onPressed: onSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gym,
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
                key: const ValueKey('gym-valuation-history-bottom-button'),
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
// Pantalla generica de historial de valoraciones
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
  List<LifeSnapshotModel> _snapshots = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dashRepo = ref.read(dashboardRepositoryProvider);
    final all = await dashRepo.getAllSnapshots();
    final filtered = all.where((s) {
      try {
        final decoded = jsonDecode(s.metricsJson) as Map<String, dynamic>;
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
        centerTitle: true,
        foregroundColor: AppColors.gym,
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
                  key: ValueKey('${widget.moduleKey}-valuation-history-list'),
                  padding: const EdgeInsets.all(16),
                  itemCount: _snapshots.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final snap = _snapshots[index];
                    Map<String, dynamic>? data;
                    try {
                      final decoded =
                          jsonDecode(snap.metricsJson) as Map<String, dynamic>;
                      data = decoded['data'] as Map<String, dynamic>?;
                    } on Exception {
                      data = null;
                    }
                    final summary =
                        data != null ? widget.summaryBuilder(data) : '';
                    final dateStr = DateFormat('d MMM yyyy · HH:mm', 'es')
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
