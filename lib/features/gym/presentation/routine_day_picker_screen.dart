import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/features/gym/domain/models/routine_exercise_model.dart';
import 'package:life_os/features/gym/domain/models/routine_model.dart';
import 'package:life_os/features/gym/presentation/active_workout_screen.dart';

// ---------------------------------------------------------------------------
// Pantalla: selector de dia dentro de un programa multi-dia
// ---------------------------------------------------------------------------

/// Cuando el usuario toca una rutina que tiene multiples dias, esta pantalla
/// muestra la lista de dias disponibles con su nombre y conteo de ejercicios.
///
/// Al seleccionar un dia, navega a [ActiveWorkoutScreen] con los ejercicios
/// de ese dia pre-cargados.
class RoutineDayPickerScreen extends ConsumerWidget {
  const RoutineDayPickerScreen({
    super.key,
    required this.routine,
  });

  final RoutineModel routine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(gymRepositoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      key: const ValueKey('routine-day-picker-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.gym,
        title: Semantics(
          header: true,
          child: Text(routine.name),
        ),
        leading: Semantics(
          label: 'Volver',
          button: true,
          child: IconButton(
            key: const ValueKey('routine-day-picker-back-button'),
            icon: const Icon(Icons.arrow_back_outlined),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Volver',
          ),
        ),
      ),
      body: StreamBuilder<List<RoutineExerciseModel>>(
        stream: repo.watchRoutineExercises(routine.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allExercises = snapshot.data ?? [];

          // Build day map: dayNumber -> { dayName, exerciseCount }
          final Map<int, _DayInfo> dayMap = {};
          for (final re in allExercises) {
            dayMap.putIfAbsent(
              re.dayNumber,
              () => _DayInfo(
                dayNumber: re.dayNumber,
                dayName: re.dayName,
                count: 0,
              ),
            );
            dayMap[re.dayNumber] = _DayInfo(
              dayNumber: re.dayNumber,
              dayName: re.dayName ?? dayMap[re.dayNumber]!.dayName,
              count: dayMap[re.dayNumber]!.count + 1,
            );
          }

          final days = dayMap.values.toList()
            ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

          if (days.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Esta rutina no tiene ejercicios configurados.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Single-day: skip picker and go directly to workout
          if (days.length == 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _startWorkout(context, days.first);
            });
            return const Center(child: CircularProgressIndicator());
          }

          // Multi-day: show day picker
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Selecciona el dia de hoy',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(150),
                  ),
                ),
              ),
              if (routine.description != null &&
                  routine.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    routine.description!,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  key: const ValueKey('routine-day-list'),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: days.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    return Semantics(
                      label:
                          'Dia ${day.dayNumber}${day.dayName != null ? ': ${day.dayName}' : ''}, '
                          '${day.count} ejercicios',
                      button: true,
                      child: _DayCard(
                        key: ValueKey('day-card-${day.dayNumber}'),
                        day: day,
                        onTap: () => _startWorkout(context, day),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _startWorkout(BuildContext context, _DayInfo day) {
    final dayLabel = day.dayName != null && day.dayName!.isNotEmpty
        ? day.dayName!
        : 'Dia ${day.dayNumber}';
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => ActiveWorkoutScreen(
          routineId: routine.id,
          routineName: '${routine.name} — $dayLabel',
          dayNumber: day.dayNumber,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Model local
// ---------------------------------------------------------------------------

class _DayInfo {
  const _DayInfo({
    required this.dayNumber,
    required this.dayName,
    required this.count,
  });

  final int dayNumber;
  final String? dayName;
  final int count;
}

// ---------------------------------------------------------------------------
// Widget: tarjeta de dia
// ---------------------------------------------------------------------------

class _DayCard extends StatelessWidget {
  const _DayCard({
    super.key,
    required this.day,
    required this.onTap,
  });

  final _DayInfo day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLabel = day.dayName != null && day.dayName!.isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('day-card-tap-${day.dayNumber}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Numero del dia
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.gym.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Dia',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.gym,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${day.dayNumber}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.gym,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasLabel)
                      Text(
                        day.dayName!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        'Dia ${day.dayNumber}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      '${day.count} ${day.count == 1 ? 'ejercicio' : 'ejercicios'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.play_circle_outline,
                color: AppColors.gym,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
