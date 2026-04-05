import 'package:flutter/material.dart';
import 'package:life_os/core/constants/app_colors.dart';

// ---------------------------------------------------------------------------
// Modelos mock
// ---------------------------------------------------------------------------

class _MockHistorySet {
  const _MockHistorySet({
    required this.setNumber,
    this.weightKg,
    required this.reps,
    this.isWarmup = false,
  });

  final int setNumber;
  final double? weightKg;
  final int reps;
  final bool isWarmup;
}

class _MockHistoryExercise {
  const _MockHistoryExercise({
    required this.name,
    required this.primaryMuscle,
    required this.sets,
  });

  final String name;
  final String primaryMuscle;
  final List<_MockHistorySet> sets;
}

class _MockWorkoutSession {
  const _MockWorkoutSession({
    required this.id,
    required this.date,
    this.routineName,
    required this.durationMinutes,
    required this.exercises,
  });

  final int id;
  final DateTime date;
  final String? routineName;
  final int durationMinutes;
  final List<_MockHistoryExercise> exercises;

  int get exerciseCount => exercises.length;

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);
}

final _mockHistory = [
  _MockWorkoutSession(
    id: 1,
    date: DateTime.now().subtract(const Duration(days: 1)),
    routineName: 'Pecho y Triceps',
    durationMinutes: 68,
    exercises: const [
      _MockHistoryExercise(
        name: 'Press de banca',
        primaryMuscle: 'Pecho',
        sets: [
          _MockHistorySet(setNumber: 1, weightKg: 60, reps: 10, isWarmup: true),
          _MockHistorySet(setNumber: 2, weightKg: 80, reps: 8),
          _MockHistorySet(setNumber: 3, weightKg: 80, reps: 7),
          _MockHistorySet(setNumber: 4, weightKg: 80, reps: 6),
        ],
      ),
      _MockHistoryExercise(
        name: 'Press inclinado con mancuernas',
        primaryMuscle: 'Pecho',
        sets: [
          _MockHistorySet(setNumber: 1, weightKg: 24, reps: 12),
          _MockHistorySet(setNumber: 2, weightKg: 24, reps: 11),
          _MockHistorySet(setNumber: 3, weightKg: 24, reps: 10),
        ],
      ),
      _MockHistoryExercise(
        name: 'Extension de triceps en polea',
        primaryMuscle: 'Triceps',
        sets: [
          _MockHistorySet(setNumber: 1, weightKg: 20, reps: 15),
          _MockHistorySet(setNumber: 2, weightKg: 20, reps: 14),
          _MockHistorySet(setNumber: 3, weightKg: 20, reps: 12),
        ],
      ),
    ],
  ),
  _MockWorkoutSession(
    id: 2,
    date: DateTime.now().subtract(const Duration(days: 3)),
    routineName: 'Espalda y Biceps',
    durationMinutes: 55,
    exercises: const [
      _MockHistoryExercise(
        name: 'Dominadas',
        primaryMuscle: 'Espalda',
        sets: [
          _MockHistorySet(setNumber: 1, reps: 10),
          _MockHistorySet(setNumber: 2, reps: 9),
          _MockHistorySet(setNumber: 3, reps: 7),
        ],
      ),
      _MockHistoryExercise(
        name: 'Remo con barra',
        primaryMuscle: 'Espalda',
        sets: [
          _MockHistorySet(setNumber: 1, weightKg: 70, reps: 8),
          _MockHistorySet(setNumber: 2, weightKg: 70, reps: 8),
          _MockHistorySet(setNumber: 3, weightKg: 70, reps: 7),
        ],
      ),
      _MockHistoryExercise(
        name: 'Curl de biceps',
        primaryMuscle: 'Biceps',
        sets: [
          _MockHistorySet(setNumber: 1, weightKg: 14, reps: 12),
          _MockHistorySet(setNumber: 2, weightKg: 14, reps: 12),
          _MockHistorySet(setNumber: 3, weightKg: 14, reps: 10),
        ],
      ),
    ],
  ),
  _MockWorkoutSession(
    id: 3,
    date: DateTime.now().subtract(const Duration(days: 5)),
    durationMinutes: 42,
    exercises: const [
      _MockHistoryExercise(
        name: 'Sentadilla',
        primaryMuscle: 'Cuadriceps',
        sets: [
          _MockHistorySet(setNumber: 1, weightKg: 100, reps: 5, isWarmup: true),
          _MockHistorySet(setNumber: 2, weightKg: 120, reps: 5),
          _MockHistorySet(setNumber: 3, weightKg: 120, reps: 5),
          _MockHistorySet(setNumber: 4, weightKg: 120, reps: 4),
        ],
      ),
      _MockHistoryExercise(
        name: 'Peso muerto rumano',
        primaryMuscle: 'Isquiotibiales',
        sets: [
          _MockHistorySet(setNumber: 1, weightKg: 80, reps: 10),
          _MockHistorySet(setNumber: 2, weightKg: 80, reps: 10),
          _MockHistorySet(setNumber: 3, weightKg: 80, reps: 9),
        ],
      ),
    ],
  ),
  _MockWorkoutSession(
    id: 4,
    date: DateTime.now().subtract(const Duration(days: 10)),
    routineName: 'Cardio HIIT',
    durationMinutes: 30,
    exercises: const [
      _MockHistoryExercise(
        name: 'Correr en cinta',
        primaryMuscle: 'Cardio',
        sets: [
          _MockHistorySet(setNumber: 1, reps: 1),
        ],
      ),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Pantalla: historial de entrenamientos
// ---------------------------------------------------------------------------

/// Historial de sesiones de entrenamiento completadas. Toca una sesion para
/// ver el detalle de todos los ejercicios y series.
///
/// Shell de presentacion — la integracion con Riverpod se realizara en un
/// paso posterior.
///
/// Accesibilidad: A11Y-GYM-04 — cada tarjeta de sesion tiene etiqueta
/// semantica con el resumen del entrenamiento.
class WorkoutHistoryScreen extends StatelessWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('workout-history-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Semantics(
          header: true,
          child: const Text('Historial de entrenamientos'),
        ),
        actions: [
          Semantics(
            label: 'Filtrar historial',
            button: true,
            child: IconButton(
              key: const ValueKey('workout-history-filter-button'),
              icon: const Icon(Icons.filter_list_outlined),
              onPressed: () {
                // TODO: abrir filtros cuando se conecte
              },
              tooltip: 'Filtrar',
            ),
          ),
        ],
      ),
      body: _mockHistory.isEmpty
          ? _EmptyHistory(key: const ValueKey('workout-history-empty'))
          : ListView.separated(
              key: const ValueKey('workout-history-list'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: _mockHistory.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final session = _mockHistory[index];
                return _WorkoutSessionCard(
                  key: ValueKey('workout-session-card-${session.id}'),
                  session: session,
                  onTap: () => _openDetail(context, session),
                );
              },
            ),
    );
  }

  void _openDetail(BuildContext context, _MockWorkoutSession session) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => _WorkoutDetailScreen(session: session),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: tarjeta de sesion de entrenamiento
// ---------------------------------------------------------------------------

class _WorkoutSessionCard extends StatelessWidget {
  const _WorkoutSessionCard({
    super.key,
    required this.session,
    required this.onTap,
  });

  final _MockWorkoutSession session;
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

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes} min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routineName = session.routineName ?? 'Entrenamiento libre';

    return Semantics(
      label: '$routineName, ${_formatDate(session.date)}, '
          'duracion ${_formatDuration(session.durationMinutes)}, '
          '${session.exerciseCount} ejercicio${session.exerciseCount == 1 ? '' : 's'}, '
          '${session.totalSets} series en total',
      button: true,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          key: ValueKey('workout-session-item-${session.id}'),
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
                            routineName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _formatDate(session.date),
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
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.timer_outlined,
                      label: _formatDuration(session.durationMinutes),
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      icon: Icons.list_alt_outlined,
                      label:
                          '${session.exerciseCount} ejercicio${session.exerciseCount == 1 ? '' : 's'}',
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      icon: Icons.repeat_outlined,
                      label:
                          '${session.totalSets} serie${session.totalSets == 1 ? '' : 's'}',
                    ),
                  ],
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

class _WorkoutDetailScreen extends StatelessWidget {
  const _WorkoutDetailScreen({required this.session});

  final _MockWorkoutSession session;

  String _formatDate(DateTime date) {
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes} min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routineName = session.routineName ?? 'Entrenamiento libre';

    return Scaffold(
      key: const ValueKey('workout-detail-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Semantics(
          header: true,
          child: Text(routineName),
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
      body: ListView(
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
                      _formatDate(session.date),
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
                          value: _formatDuration(session.durationMinutes),
                          icon: Icons.timer_outlined,
                        ),
                      ),
                      Expanded(
                        child: _DetailStat(
                          label: 'Ejercicios',
                          value: '${session.exerciseCount}',
                          icon: Icons.fitness_center,
                        ),
                      ),
                      Expanded(
                        child: _DetailStat(
                          label: 'Series totales',
                          value: '${session.totalSets}',
                          icon: Icons.repeat_outlined,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Ejercicios realizados
          ...session.exercises.map(
            (exercise) => _ExerciseDetail(
              key: ValueKey('workout-detail-exercise-${exercise.name}'),
              exercise: exercise,
            ),
          ),
        ],
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
// Widget: detalle de ejercicio con sus series
// ---------------------------------------------------------------------------

class _ExerciseDetail extends StatelessWidget {
  const _ExerciseDetail({
    super.key,
    required this.exercise,
  });

  final _MockHistoryExercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.gym.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    size: 16,
                    color: AppColors.gym,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        exercise.primaryMuscle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.gym,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Cabecera de columnas
            Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text('#', style: theme.textTheme.labelSmall),
                ),
                Expanded(
                  child: Text(
                    'Peso (kg)',
                    style: theme.textTheme.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Reps',
                    style: theme.textTheme.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
            const Divider(),

            // Series
            ...exercise.sets.map(
              (set) => Semantics(
                label:
                    '${set.isWarmup ? 'Calentamiento' : 'Serie ${set.setNumber}'}: '
                    '${set.weightKg != null ? '${set.weightKg} kg, ' : ''}'
                    '${set.reps} repeticiones',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: set.isWarmup
                                ? Colors.blue.withAlpha(25)
                                : AppColors.gym.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            set.isWarmup ? 'C' : '${set.setNumber}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: set.isWarmup ? Colors.blue : AppColors.gym,
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
                          style: theme.textTheme.bodyMedium?.copyWith(
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
