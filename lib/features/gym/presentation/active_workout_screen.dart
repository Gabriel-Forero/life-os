import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/router/app_router.dart';
import 'package:life_os/features/gym/domain/gym_input.dart';
import 'package:life_os/features/gym/providers/rest_timer_notifier.dart';

// ---------------------------------------------------------------------------
// Local UI models (not DB models — used for pending sets before confirm)
// ---------------------------------------------------------------------------

class _PendingSet {
  _PendingSet({
    required this.setNumber,
    this.weightKg,
    this.reps,
    this.isWarmup = false,
    this.isConfirmed = false,
  });

  final int setNumber;
  double? weightKg;
  int? reps;
  bool isWarmup;
  bool isConfirmed;
}

class _WorkoutExercise {
  _WorkoutExercise({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    required List<_PendingSet> sets,
    this.lastWeightKg,
    this.restSeconds = 90,
  }) : sets = sets;

  final int id;
  final String name;
  final String primaryMuscle;
  final List<_PendingSet> sets;
  final double? lastWeightKg;
  final int restSeconds;
}

// ---------------------------------------------------------------------------
// Pantalla: entrenamiento activo
// ---------------------------------------------------------------------------

/// Pantalla de entrenamiento activo con temporizador, lista de ejercicios y
/// series. Incluye overlay de descanso entre series.
///
/// Accesibilidad: A11Y-GYM-03 — todos los inputs y controles tienen etiquetas
/// semanticas.
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({
    super.key,
    this.routineName,
    this.routineId,
    this.dayNumber,
  });

  /// Nombre de la rutina en curso. Nulo si es un entrenamiento libre.
  final String? routineName;
  final int? routineId;

  /// If set, only exercises belonging to this day of the multi-day program are
  /// loaded. When null, all exercises of the routine are loaded (single-day).
  final int? dayNumber;

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  final List<_WorkoutExercise> _exercises = [];
  late final Stopwatch _stopwatch;
  late final Timer _elapsedTimer;

  int? _workoutId;

  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed = _stopwatch.elapsed);
    });
    _startWorkout();
  }

  Future<void> _startWorkout() async {
    final notifier = ref.read(gymNotifierProvider);
    final result =
        await notifier.startWorkout(routineId: widget.routineId);
    if (result.isSuccess && mounted) {
      setState(() => _workoutId = result.valueOrNull);
      // Pre-populate exercises from routine if routineId provided
      if (widget.routineId != null) {
        await _loadRoutineExercises(widget.routineId!);
      }
    }
  }

  Future<void> _loadRoutineExercises(int routineId) async {
    final dao = ref.read(gymDaoProvider);
    // If a specific day is requested, load only that day's exercises.
    final routineExercises = widget.dayNumber != null
        ? await dao
            .watchRoutineExercisesForDay(routineId, widget.dayNumber!)
            .first
        : await dao.watchRoutineExercises(routineId).first;
    if (!mounted) return;
    final List<_WorkoutExercise> loaded = [];
    for (final re in routineExercises) {
      // Fetch the exercise record by id
      final allExercises = await dao.watchExercises().first;
      final ex = allExercises.where((e) => e.id == re.exerciseId).firstOrNull;
      if (ex == null) continue;

      // Look up last-session weight for reference
      final lastWeightPR = await dao.getWeightPR(re.exerciseId);

      final sets = List.generate(
        re.defaultSets,
        (i) => _PendingSet(
          setNumber: i + 1,
          weightKg: re.defaultWeightKg ?? lastWeightPR,
          reps: re.defaultReps,
        ),
      );
      loaded.add(_WorkoutExercise(
        id: ex.id,
        name: ex.name,
        primaryMuscle: ex.primaryMuscle,
        sets: sets,
        lastWeightKg: lastWeightPR,
        restSeconds: re.restSeconds,
      ));
    }
    if (mounted) {
      setState(() {
        _exercises.addAll(loaded);
      });
    }
  }

  Future<void> _openExercisePicker() async {
    final result =
        await showModalBottomSheet<({int id, String name, String muscle})>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _ExercisePickerSheet(),
    );
    if (result != null && mounted) {
      final dao = ref.read(gymDaoProvider);
      final lastWeight = await dao.getWeightPR(result.id);
      setState(() {
        _exercises.add(_WorkoutExercise(
          id: result.id,
          name: result.name,
          primaryMuscle: result.muscle,
          sets: [
            _PendingSet(setNumber: 1, weightKg: lastWeight),
          ],
          lastWeightKg: lastWeight,
          restSeconds: 90,
        ));
      });
    }
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _elapsedTimer.cancel();
    // Reset timer when leaving the screen
    ref.read(restTimerProvider).skip();
    super.dispose();
  }

  Future<void> _confirmSet(_WorkoutExercise exercise, _PendingSet set,
      {int restSeconds = 90}) async {
    final wId = _workoutId;
    if (wId == null) return;
    if (set.reps == null || set.reps! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa las repeticiones')),
      );
      return;
    }

    final notifier = ref.read(gymNotifierProvider);
    await notifier.logSet(
      wId,
      exercise.id,
      SetInput(
        reps: set.reps!,
        weightKg: set.weightKg,
        isWarmup: set.isWarmup,
      ),
    );

    if (mounted) {
      setState(() => set.isConfirmed = true);
      ref.read(restTimerProvider).start(restSeconds);
    }
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const ValueKey('discard-workout-dialog'),
        title: const Text('Salir del entrenamiento'),
        content: const Text(
          'Se perdera el progreso del entrenamiento actual. ¿Deseas salir?',
        ),
        actions: [
          TextButton(
            key: const ValueKey('discard-workout-cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuar entrenando'),
          ),
          TextButton(
            key: const ValueKey('discard-workout-confirm'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _discardWorkout() async {
    final confirmed = await _confirmDiscard();
    if (!confirmed || !mounted) return;
    final wId = _workoutId;
    if (wId != null) {
      await ref.read(gymNotifierProvider).discardWorkout(wId);
    }
    if (mounted) GoRouter.of(context).go(AppRoutes.gym);
  }

  Future<void> _finishWorkout() async {
    final wId = _workoutId;
    if (wId != null) {
      await ref.read(gymNotifierProvider).finishWorkout(wId);
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Entrenamiento guardado!')));
      GoRouter.of(context).go(AppRoutes.gym);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timerNotifier = ref.watch(restTimerProvider);
    final isTimerActive = timerNotifier.state == TimerState.running ||
        timerNotifier.state == TimerState.paused ||
        timerNotifier.state == TimerState.expired;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _discardWorkout();
      },
      child: Scaffold(
        key: const ValueKey('active-workout-screen'),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Semantics(
            header: true,
            child: Text(widget.routineName ?? 'Entrenamiento libre'),
          ),
          centerTitle: false,
          actions: [
            // Temporizador de tiempo transcurrido
            Semantics(
              label: 'Tiempo de entrenamiento: ${_formatElapsed(_elapsed)}',
              child: Container(
                key: const ValueKey('active-workout-elapsed-timer'),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.gym.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: AppColors.gym),
                    const SizedBox(width: 4),
                    Text(
                      _formatElapsed(_elapsed),
                      style: const TextStyle(
                        color: AppColors.gym,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            // --- Lista de ejercicios ---
            ListView(
              key: const ValueKey('active-workout-exercise-list'),
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 140),
              children: [
                ..._exercises.asMap().entries.map(
                  (entry) => _WorkoutExerciseSection(
                    key: ValueKey(
                        'workout-exercise-section-${entry.value.id}'),
                    exercise: entry.value,
                    onConfirmSet: (set) =>
                        _confirmSet(entry.value, set,
                            restSeconds: entry.value.restSeconds),
                    onWarmupToggled: (set, value) =>
                        setState(() => set.isWarmup = value),
                    onWeightChanged: (set, value) =>
                        setState(() => set.weightKg = value),
                    onRepsChanged: (set, value) =>
                        setState(() => set.reps = value),
                    onAddSet: () => setState(
                      () => entry.value.sets.add(
                        _PendingSet(
                          setNumber: entry.value.sets.length + 1,
                          weightKg: entry.value.sets.isNotEmpty
                              ? entry.value.sets.last.weightKg
                              : null,
                          reps: entry.value.sets.isNotEmpty
                              ? entry.value.sets.last.reps
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),

                // Boton agregar ejercicio al vuelo
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Semantics(
                    label: 'Agregar ejercicio al entrenamiento',
                    button: true,
                    child: OutlinedButton.icon(
                      key: const ValueKey(
                          'active-workout-add-exercise-button'),
                      onPressed: _openExercisePicker,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gym,
                        side: const BorderSide(color: AppColors.gym),
                        minimumSize: const Size.fromHeight(44),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar ejercicio'),
                    ),
                  ),
                ),
              ],
            ),

            // --- Botones de finalizar / descartar ---
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(color: theme.dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: 'Descartar entrenamiento actual',
                        button: true,
                        child: OutlinedButton.icon(
                          key: const ValueKey(
                              'active-workout-discard-button'),
                          onPressed: _discardWorkout,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Descartar'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Semantics(
                        label: 'Finalizar y guardar entrenamiento',
                        button: true,
                        child: FilledButton.icon(
                          key: const ValueKey(
                              'active-workout-finish-button'),
                          onPressed: _finishWorkout,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.gym,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                            'Finalizar',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Overlay temporizador de descanso ---
            if (isTimerActive)
              _RestTimerOverlay(
                key: const ValueKey('active-workout-rest-overlay'),
                timerNotifier: timerNotifier,
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: seccion de ejercicio con sus series
// ---------------------------------------------------------------------------

class _WorkoutExerciseSection extends StatelessWidget {
  const _WorkoutExerciseSection({
    super.key,
    required this.exercise,
    required this.onConfirmSet,
    required this.onWarmupToggled,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onAddSet,
  });

  final _WorkoutExercise exercise;
  final void Function(_PendingSet) onConfirmSet;
  final void Function(_PendingSet, bool) onWarmupToggled;
  final void Function(_PendingSet, double?) onWeightChanged;
  final void Function(_PendingSet, int?) onRepsChanged;
  final VoidCallback onAddSet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado de ejercicio
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.gym.withAlpha(25),
                child: const Icon(
                  Icons.fitness_center,
                  size: 14,
                  color: AppColors.gym,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      exercise.primaryMuscle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.gym,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (exercise.lastWeightKg != null)
                      Text(
                        'Ultima vez: ${exercise.lastWeightKg} kg',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(120),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Cabecera de columnas
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Row(
            children: [
              const SizedBox(width: 32),
              Expanded(
                flex: 2,
                child: Text(
                  'Peso (kg)',
                  style: theme.textTheme.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Reps',
                  style: theme.textTheme.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 36),
              const SizedBox(width: 48),
            ],
          ),
        ),

        // Filas de series
        ...exercise.sets.map(
          (set) => _SetRow(
            key: ValueKey('set-row-${exercise.id}-${set.setNumber}'),
            exerciseId: exercise.id,
            set: set,
            onConfirm: () => onConfirmSet(set),
            onWarmupToggled: (v) => onWarmupToggled(set, v),
            onWeightChanged: (v) => onWeightChanged(set, v),
            onRepsChanged: (v) => onRepsChanged(set, v),
          ),
        ),

        // Boton agregar serie
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Semantics(
            label: 'Agregar serie a ${exercise.name}',
            button: true,
            child: TextButton.icon(
              key: ValueKey('workout-add-set-${exercise.id}'),
              onPressed: onAddSet,
              style: TextButton.styleFrom(foregroundColor: AppColors.gym),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Agregar serie'),
            ),
          ),
        ),

        const Divider(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: fila de serie
// ---------------------------------------------------------------------------

class _SetRow extends StatefulWidget {
  const _SetRow({
    super.key,
    required this.exerciseId,
    required this.set,
    required this.onConfirm,
    required this.onWarmupToggled,
    required this.onWeightChanged,
    required this.onRepsChanged,
  });

  final int exerciseId;
  final _PendingSet set;
  final VoidCallback onConfirm;
  final ValueChanged<bool> onWarmupToggled;
  final ValueChanged<double?> onWeightChanged;
  final ValueChanged<int?> onRepsChanged;

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.set.weightKg?.toString() ?? '',
    );
    _repsController = TextEditingController(
      text: widget.set.reps?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final set = widget.set;
    final isConfirmed = set.isConfirmed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: isConfirmed ? AppColors.gym.withAlpha(12) : Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          // Numero de serie / indicador de calentamiento
          Semantics(
            label: set.isWarmup
                ? 'Calentamiento ${set.setNumber}'
                : 'Serie ${set.setNumber}',
            child: GestureDetector(
              onTap: () => widget.onWarmupToggled(!set.isWarmup),
              child: Tooltip(
                message: set.isWarmup ? 'Calentamiento' : 'Serie ${set.setNumber}',
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: set.isWarmup
                        ? Colors.blue.withAlpha(30)
                        : AppColors.gym.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    set.isWarmup ? 'C' : '${set.setNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: set.isWarmup ? Colors.blue : AppColors.gym,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Peso (kg)
          Expanded(
            flex: 2,
            child: Semantics(
              label: 'Peso en kg, serie ${set.setNumber}',
              textField: true,
              child: TextField(
                key: ValueKey(
                  'set-weight-${widget.exerciseId}-${set.setNumber}',
                ),
                controller: _weightController,
                enabled: !isConfirmed,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isConfirmed ? AppColors.gym : null,
                  fontWeight: isConfirmed ? FontWeight.w600 : null,
                ),
                decoration: InputDecoration(
                  hintText: '—',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.gym, width: 2),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.gym.withAlpha(60),
                    ),
                  ),
                ),
                onChanged: (v) =>
                    widget.onWeightChanged(double.tryParse(v)),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Reps
          Expanded(
            flex: 2,
            child: Semantics(
              label: 'Repeticiones, serie ${set.setNumber}',
              textField: true,
              child: TextField(
                key: ValueKey(
                  'set-reps-${widget.exerciseId}-${set.setNumber}',
                ),
                controller: _repsController,
                enabled: !isConfirmed,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isConfirmed ? AppColors.gym : null,
                  fontWeight: isConfirmed ? FontWeight.w600 : null,
                ),
                decoration: InputDecoration(
                  hintText: '—',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.gym, width: 2),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.gym.withAlpha(60),
                    ),
                  ),
                ),
                onChanged: (v) => widget.onRepsChanged(int.tryParse(v)),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Toggle calentamiento
          Semantics(
            label:
                '${set.isWarmup ? 'Desactivar' : 'Activar'} calentamiento en serie ${set.setNumber}',
            button: true,
            child: Tooltip(
              message: 'Calentamiento',
              child: IconButton(
                key: ValueKey(
                  'set-warmup-toggle-${widget.exerciseId}-${set.setNumber}',
                ),
                onPressed: () => widget.onWarmupToggled(!set.isWarmup),
                icon: Icon(
                  set.isWarmup ? Icons.whatshot : Icons.whatshot_outlined,
                  size: 18,
                  color: set.isWarmup ? Colors.orange : Colors.grey,
                ),
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ),
          ),

          // Boton confirmar
          Semantics(
            label: isConfirmed
                ? 'Serie ${set.setNumber} confirmada'
                : 'Confirmar serie ${set.setNumber}',
            button: true,
            child: IconButton(
              key: ValueKey(
                'set-confirm-${widget.exerciseId}-${set.setNumber}',
              ),
              onPressed: isConfirmed ? null : widget.onConfirm,
              icon: Icon(
                isConfirmed
                    ? Icons.check_circle
                    : Icons.check_circle_outline,
                color: isConfirmed ? AppColors.gym : Colors.grey,
              ),
              tooltip: isConfirmed ? 'Completada' : 'Confirmar',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet: selector de ejercicio durante entrenamiento activo
// ---------------------------------------------------------------------------

class _ExercisePickerSheet extends ConsumerStatefulWidget {
  const _ExercisePickerSheet();

  @override
  ConsumerState<_ExercisePickerSheet> createState() =>
      _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<_ExercisePickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dao = ref.watch(gymDaoProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Agregar ejercicio',
                style: theme.textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Semantics(
                label: 'Buscar ejercicio',
                textField: true,
                child: TextField(
                  key: const ValueKey('active-exercise-picker-search'),
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar...',
                    prefixIcon: Icon(Icons.search_outlined),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder(
                stream: dao.watchExercises(
                    query: _query.isEmpty ? null : _query),
                builder: (context, snapshot) {
                  final exercises = snapshot.data ?? [];
                  return ListView.separated(
                    controller: scrollController,
                    itemCount: exercises.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final ex = exercises[index];
                      return Semantics(
                        label: '${ex.name}, ${ex.primaryMuscle}',
                        button: true,
                        child: ListTile(
                          key: ValueKey('active-exercise-item-${ex.id}'),
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.gym.withAlpha(25),
                            child: const Icon(
                              Icons.fitness_center,
                              color: AppColors.gym,
                              size: 16,
                            ),
                          ),
                          title: Text(
                            ex.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            ex.primaryMuscle,
                            style: const TextStyle(
                                color: AppColors.gym, fontSize: 12),
                          ),
                          trailing: const Icon(Icons.add_circle_outline),
                          onTap: () => Navigator.of(context).pop((
                            id: ex.id,
                            name: ex.name,
                            muscle: ex.primaryMuscle,
                          )),
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
}

// ---------------------------------------------------------------------------
// Widget: overlay temporizador de descanso (full-featured)
// ---------------------------------------------------------------------------

class _RestTimerOverlay extends ConsumerWidget {
  const _RestTimerOverlay({
    super.key,
    required this.timerNotifier,
  });

  final RestTimerNotifier timerNotifier;

  String _formatSeconds(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _showTimePicker(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: timerNotifier.remainingSeconds.toString(),
    );
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar tiempo'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Segundos',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(controller.text);
              Navigator.of(ctx).pop(v);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (result != null && result > 0) {
      ref.read(restTimerProvider).setTime(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpired = timerNotifier.state == TimerState.expired;
    final isPaused = timerNotifier.state == TimerState.paused;
    final progress = timerNotifier.totalSeconds > 0
        ? timerNotifier.remainingSeconds / timerNotifier.totalSeconds
        : 0.0;

    // Full-width banner when expired
    if (isExpired) {
      return Positioned(
        bottom: 90,
        left: 0,
        right: 0,
        child: Semantics(
          liveRegion: true,
          label: 'Descanso terminado',
          child: GestureDetector(
            onTap: () => ref.read(restTimerProvider).skip(),
            child: Material(
              key: const ValueKey('rest-timer-expired-banner'),
              elevation: 12,
              color: AppColors.gym,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_active, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      '¡Descanso terminado!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Toca para cerrar',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Running / paused overlay card with circular progress
    return Positioned(
      bottom: 90,
      left: 16,
      right: 16,
      child: Semantics(
        label:
            'Tiempo de descanso: ${_formatSeconds(timerNotifier.remainingSeconds)} restantes',
        liveRegion: true,
        child: Material(
          key: const ValueKey('rest-timer-overlay'),
          elevation: 8,
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF1A1A2E),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Row(
              children: [
                // Circular progress + countdown number
                GestureDetector(
                  onTap: () => _showTimePicker(context, ref),
                  child: Tooltip(
                    message: 'Toca para editar el tiempo',
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background circle
                          SizedBox(
                            width: 72,
                            height: 72,
                            child: CircularProgressIndicator(
                              value: 1.0,
                              strokeWidth: 5,
                              color: AppColors.gym.withAlpha(40),
                            ),
                          ),
                          // Foreground progress
                          SizedBox(
                            width: 72,
                            height: 72,
                            child: CircularProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              strokeWidth: 5,
                              color: AppColors.gym,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          // Countdown text
                          Text(
                            _formatSeconds(timerNotifier.remainingSeconds),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Descanso',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPaused ? 'Pausado' : 'En curso...',
                        style: TextStyle(
                          color: isPaused ? Colors.orange : AppColors.gym,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // -30s button
                Semantics(
                  label: 'Restar 30 segundos',
                  button: true,
                  child: IconButton(
                    key: const ValueKey('rest-timer-minus30'),
                    onPressed: () => ref.read(restTimerProvider).addTime(-30),
                    icon: const Text(
                      '-30s',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    tooltip: '-30s',
                  ),
                ),

                // +30s button
                Semantics(
                  label: 'Agregar 30 segundos',
                  button: true,
                  child: IconButton(
                    key: const ValueKey('rest-timer-plus30'),
                    onPressed: () => ref.read(restTimerProvider).addTime(30),
                    icon: const Text(
                      '+30s',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    tooltip: '+30s',
                  ),
                ),

                // Pause / Resume button
                Semantics(
                  label: isPaused ? 'Reanudar descanso' : 'Pausar descanso',
                  button: true,
                  child: IconButton(
                    key: const ValueKey('rest-timer-pause-resume'),
                    onPressed: () {
                      final t = ref.read(restTimerProvider);
                      if (isPaused) {
                        t.resume();
                      } else {
                        t.pause();
                      }
                    },
                    icon: Icon(
                      isPaused ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                    ),
                    tooltip: isPaused ? 'Reanudar' : 'Pausar',
                  ),
                ),

                // Skip button
                Semantics(
                  label: 'Saltar descanso',
                  button: true,
                  child: TextButton(
                    key: const ValueKey('rest-timer-skip-button'),
                    onPressed: () => ref.read(restTimerProvider).skip(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                    child: const Text('Saltar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
