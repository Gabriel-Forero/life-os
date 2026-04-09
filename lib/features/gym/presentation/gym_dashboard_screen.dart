import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/router/app_router.dart';
import 'package:life_os/core/widgets/animated_list_item.dart';
import 'package:life_os/core/widgets/pressable_card.dart';
import 'package:life_os/features/gym/database/gym_dao.dart';
import 'package:life_os/features/gym/presentation/active_workout_screen.dart';
import 'package:life_os/features/gym/presentation/routine_day_picker_screen.dart';

// ---------------------------------------------------------------------------
// Pantalla: dashboard del modulo Gym
// ---------------------------------------------------------------------------

/// Pantalla principal del modulo de gimnasio. Muestra:
///  - Accesos rapidos (entrenamiento libre, historial, ejercicios, medidas)
///  - Programas/rutinas guardadas con acceso rapido por dia
///  - Historial reciente de sesiones
class GymDashboardScreen extends ConsumerWidget {
  const GymDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(gymDaoProvider);
    final theme = Theme.of(context);

    return Scaffold(
      key: const ValueKey('gym-dashboard-screen'),
      body: CustomScrollView(
        key: const ValueKey('gym-dashboard-scroll'),
        slivers: [
          // --- Seccion: Mis Programas ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Row(
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Mis Programas',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Semantics(
                    label: 'Crear nuevo programa',
                    button: true,
                    child: TextButton.icon(
                      key: const ValueKey('gym-dashboard-new-routine'),
                      onPressed: () => GoRouter.of(context)
                          .push(AppRoutes.gymRoutineBuilder),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.gym),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nuevo'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: StreamBuilder<List<Routine>>(
              stream: dao.watchRoutines(),
              builder: (context, snapshot) {
                final routines = snapshot.data ?? [];
                if (routines.isEmpty) {
                  return _EmptyRoutines(
                    key: const ValueKey('gym-no-routines'),
                    onCreateRoutine: () => GoRouter.of(context)
                        .push(AppRoutes.gymRoutineBuilder),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: routines.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final routine = routines[index];
                    return AnimatedListItem(
                      index: index,
                      child: _RoutineCard(
                        key: ValueKey('routine-card-${routine.id}'),
                        routine: routine,
                        dao: dao,
                        onTap: () => _openRoutine(context, routine),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // --- Seccion: Historial reciente ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Row(
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Historial reciente',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Semantics(
                    label: 'Ver todo el historial',
                    button: true,
                    child: TextButton(
                      key: const ValueKey('gym-dashboard-see-all-history'),
                      onPressed: () =>
                          GoRouter.of(context).push(AppRoutes.gymHistory),
                      child: const Text('Ver todo'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: StreamBuilder<List<Workout>>(
              stream: dao.watchWorkouts(limit: 5),
              builder: (context, snapshot) {
                final workouts = snapshot.data ?? [];
                if (workouts.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Text(
                      'Sin entrenamientos aun. Inicia tu primera sesion!',
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: workouts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final workout = workouts[index];
                    return AnimatedListItem(
                      index: index,
                      child: _RecentWorkoutCard(
                        key: ValueKey('recent-workout-${workout.id}'),
                        workout: workout,
                        dao: dao,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
      floatingActionButton: Semantics(
        label: 'Iniciar entrenamiento libre',
        button: true,
        child: FloatingActionButton.extended(
          key: const ValueKey('gym-dashboard-start-workout-fab'),
          onPressed: () => _startFreeWorkout(context),
          backgroundColor: AppColors.gym,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Iniciar'),
        ),
      ),
    );
  }

  void _startFreeWorkout(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => const ActiveWorkoutScreen(),
      ),
    );
  }

  void _openRoutine(BuildContext context, Routine routine) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => RoutineDayPickerScreen(routine: routine),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: chip de accion rapida
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Widget: tarjeta de programa/rutina con dias
// ---------------------------------------------------------------------------

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    super.key,
    required this.routine,
    required this.dao,
    required this.onTap,
  });

  final Routine routine;
  final GymDao dao;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<RoutineExercise>>(
      stream: dao.watchRoutineExercises(routine.id),
      builder: (context, snapshot) {
        final exercises = snapshot.data ?? [];

        // Collect distinct days (sorted)
        final seenDays = <int>{};
        final days = <int>[];
        for (final ex in exercises) {
          if (seenDays.add(ex.dayNumber)) days.add(ex.dayNumber);
        }
        days.sort();

        final totalExercises = exercises.length;
        final isMultiDay = days.length > 1;

        return Semantics(
          label: '${routine.name}, $totalExercises ejercicios, '
              '${isMultiDay ? '${days.length} dias' : '1 dia'}',
          button: true,
          child: PressableCard(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: InkWell(
                key: ValueKey('routine-card-tap-${routine.id}'),
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.gym.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.calendar_view_week_outlined,
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
                                  routine.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                if (isMultiDay)
                                  Text(
                                    '${days.length} dias · $totalExercises ejercicios',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.gym,
                                    ),
                                  )
                                else
                                  Text(
                                    '$totalExercises ejercicios',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.gym,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            isMultiDay
                                ? Icons.view_day_outlined
                                : Icons.play_circle_outline,
                            color: AppColors.gym,
                          ),
                        ],
                      ),

                      // Day labels row (only for multi-day)
                      if (isMultiDay) ...[
                        const SizedBox(height: 10),
                        _buildDayLabels(context, exercises, days),
                      ],
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

  Widget _buildDayLabels(
    BuildContext context,
    List<RoutineExercise> exercises,
    List<int> days,
  ) {
    final theme = Theme.of(context);
    // Build day -> name map from the first exercise of each day
    final Map<int, String?> dayNames = {};
    for (final ex in exercises) {
      dayNames.putIfAbsent(ex.dayNumber, () => ex.dayName);
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: days.map((d) {
        final name = dayNames[d];
        final label = (name != null && name.isNotEmpty) ? name : 'Dia $d';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.gym.withAlpha(15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gym.withAlpha(60)),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.gym,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: tarjeta de entrenamiento reciente (compacta)
// ---------------------------------------------------------------------------

class _RecentWorkoutCard extends StatelessWidget {
  const _RecentWorkoutCard({
    super.key,
    required this.workout,
    required this.dao,
  });

  final Workout workout;
  final GymDao dao;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Hoy';
    if (d == yesterday) return 'Ayer';
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _formatDuration(Workout w) {
    if (w.finishedAt == null) return '';
    final m = w.finishedAt!.difference(w.startedAt).inMinutes;
    if (m < 60) return '$m min';
    final h = m ~/ 60;
    final rem = m % 60;
    return rem == 0 ? '${h}h' : '${h}h ${rem}min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<WorkoutSet>>(
      stream: dao.watchWorkoutSets(workout.id),
      builder: (context, snapshot) {
        final sets = snapshot.data ?? [];
        final exerciseCount = sets.map((s) => s.exerciseId).toSet().length;
        final workSets = sets.where((s) => !s.isWarmup).toList();
        final volume = workSets
            .where((s) => s.weightKg != null)
            .fold<double>(
                0.0, (sum, s) => sum + s.weightKg! * s.reps);

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
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
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(workout.startedAt),
                        style: theme.textTheme.bodyMedium?.copyWith(
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
                if (exerciseCount > 0) ...[
                  _MiniStat(
                    icon: Icons.fitness_center,
                    label: '$exerciseCount ejrc.',
                  ),
                  const SizedBox(width: 8),
                ],
                _MiniStat(
                  icon: Icons.repeat,
                  label: '${sets.length} series',
                ),
                if (volume > 0) ...[
                  const SizedBox(width: 8),
                  _MiniStat(
                    icon: Icons.monitor_weight_outlined,
                    label: '${volume.toStringAsFixed(0)} kg',
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.gym),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.gym),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: estado vacio de rutinas
// ---------------------------------------------------------------------------

class _EmptyRoutines extends StatelessWidget {
  const _EmptyRoutines({
    super.key,
    required this.onCreateRoutine,
  });

  final VoidCallback onCreateRoutine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.playlist_add_outlined,
                size: 48,
                color: theme.disabledColor,
              ),
              const SizedBox(height: 12),
              Text(
                'Sin programas todavia',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Crea tu primer programa de entrenamiento con uno o varios dias.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey('gym-dashboard-create-first-routine'),
                onPressed: onCreateRoutine,
                style:
                    FilledButton.styleFrom(backgroundColor: AppColors.gym),
                icon: const Icon(Icons.add),
                label: const Text('Crear programa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
