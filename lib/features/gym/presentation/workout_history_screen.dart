import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/widgets/animated_list_item.dart';
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

          return ListView.separated(
            key: const ValueKey('workout-history-list'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: workouts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final workout = workouts[index];
              return AnimatedListItem(
                index: index,
                child: _WorkoutSessionCard(
                  key: ValueKey('workout-session-card-${workout.id}'),
                  workout: workout,
                  onTap: () => _openDetail(context, workout),
                ),
              );
            },
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

class _WorkoutSessionCard extends StatelessWidget {
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
    final minutes =
        w.finishedAt!.difference(w.startedAt).inMinutes;
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = 'Entrenamiento ${workout.id}';

    return Semantics(
      label: '$label, ${_formatDate(workout.startedAt)}, '
          'duracion ${_formatDuration(workout)}',
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
                            _formatDate(workout.startedAt),
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
                      label: _formatDuration(workout),
                    ),
                    if (workout.note != null && workout.note!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.notes_outlined,
                        label: workout.note!,
                      ),
                    ],
                  ],
                ),
              ],
            ),
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
        title: Semantics(
          header: true,
          child: Text('Entrenamiento ${workout.id}'),
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
                              label: 'Series',
                              value: '${sets.length}',
                              icon: Icons.repeat_outlined,
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

              // Series del entrenamiento
              if (sets.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Series realizadas',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text('#',
                                  style: theme.textTheme.labelSmall),
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
                        ...sets.map(
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
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
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
