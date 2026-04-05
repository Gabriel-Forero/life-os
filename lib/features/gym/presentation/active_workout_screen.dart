import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_os/core/constants/app_colors.dart';

// ---------------------------------------------------------------------------
// Modelos mock
// ---------------------------------------------------------------------------

class _MockSet {
  _MockSet({
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

class _MockWorkoutExercise {
  _MockWorkoutExercise({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    required List<_MockSet> sets,
  }) : sets = sets;

  final int id;
  final String name;
  final String primaryMuscle;
  final List<_MockSet> sets;
}

List<_MockWorkoutExercise> _buildMockWorkout() => [
      _MockWorkoutExercise(
        id: 1,
        name: 'Press de banca',
        primaryMuscle: 'Pecho',
        sets: [
          _MockSet(setNumber: 1, weightKg: 60, reps: 10, isWarmup: true),
          _MockSet(setNumber: 2, weightKg: 80, reps: 8),
          _MockSet(setNumber: 3, weightKg: 80, reps: 8),
        ],
      ),
      _MockWorkoutExercise(
        id: 2,
        name: 'Dominadas',
        primaryMuscle: 'Espalda',
        sets: [
          _MockSet(setNumber: 1, reps: 8),
          _MockSet(setNumber: 2, reps: 8),
          _MockSet(setNumber: 3, reps: 6),
        ],
      ),
    ];

// ---------------------------------------------------------------------------
// Pantalla: entrenamiento activo
// ---------------------------------------------------------------------------

/// Pantalla de entrenamiento activo con temporizador, lista de ejercicios y
/// series. Incluye overlay de descanso entre series.
///
/// Shell de presentacion — la integracion con Riverpod se realizara en un
/// paso posterior.
///
/// Accesibilidad: A11Y-GYM-03 — todos los inputs y controles tienen etiquetas
/// semanticas.
class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({
    super.key,
    this.routineName,
  });

  /// Nombre de la rutina en curso. Nulo si es un entrenamiento libre.
  final String? routineName;

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late final List<_MockWorkoutExercise> _exercises;
  late final Stopwatch _stopwatch;
  late final Timer _elapsedTimer;

  // Estado del temporizador de descanso
  bool _restTimerActive = false;
  int _restSecondsRemaining = 0;
  Timer? _restTimer;

  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _exercises = _buildMockWorkout();
    _stopwatch = Stopwatch()..start();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed = _stopwatch.elapsed);
    });
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _elapsedTimer.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  void _confirmSet(_MockSet set, {int restSeconds = 90}) {
    setState(() => set.isConfirmed = true);
    _startRestTimer(restSeconds);
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _restTimerActive = true;
      _restSecondsRemaining = seconds;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _restSecondsRemaining--;
        if (_restSecondsRemaining <= 0) {
          _restTimerActive = false;
          timer.cancel();
        }
      });
    });
  }

  void _dismissRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _restTimerActive = false;
      _restSecondsRemaining = 0;
    });
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Future<bool> _onWillPop() async {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) Navigator.of(context).pop();
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
                    key: ValueKey('workout-exercise-section-${entry.value.id}'),
                    exercise: entry.value,
                    onConfirmSet: (set) => _confirmSet(set),
                    onWarmupToggled: (set, value) =>
                        setState(() => set.isWarmup = value),
                    onWeightChanged: (set, value) =>
                        setState(() => set.weightKg = value),
                    onRepsChanged: (set, value) =>
                        setState(() => set.reps = value),
                    onAddSet: () => setState(
                      () => entry.value.sets.add(
                        _MockSet(
                          setNumber: entry.value.sets.length + 1,
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
                      key: const ValueKey('active-workout-add-exercise-button'),
                      onPressed: () {
                        // TODO: abrir picker de ejercicios cuando se conecte
                      },
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
                          key: const ValueKey('active-workout-discard-button'),
                          onPressed: () async {
                            final shouldPop = await _onWillPop();
                            if (shouldPop && mounted) {
                              Navigator.of(context).pop();
                            }
                          },
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
                          key: const ValueKey('active-workout-finish-button'),
                          onPressed: () {
                            // TODO: llamar a GymNotifier.finishWorkout cuando se conecte
                            Navigator.of(context).pop();
                          },
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
            if (_restTimerActive)
              _RestTimerOverlay(
                key: const ValueKey('active-workout-rest-overlay'),
                secondsRemaining: _restSecondsRemaining,
                onDismiss: _dismissRestTimer,
                onSkip: _dismissRestTimer,
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

  final _MockWorkoutExercise exercise;
  final void Function(_MockSet) onConfirmSet;
  final void Function(_MockSet, bool) onWarmupToggled;
  final void Function(_MockSet, double?) onWeightChanged;
  final void Function(_MockSet, int?) onRepsChanged;
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
            key: ValueKey(
              'set-row-${exercise.id}-${set.setNumber}',
            ),
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
  final _MockSet set;
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
// Widget: overlay temporizador de descanso
// ---------------------------------------------------------------------------

class _RestTimerOverlay extends StatelessWidget {
  const _RestTimerOverlay({
    super.key,
    required this.secondsRemaining,
    required this.onDismiss,
    required this.onSkip,
  });

  final int secondsRemaining;
  final VoidCallback onDismiss;
  final VoidCallback onSkip;

  String _formatSeconds(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      bottom: 90,
      left: 16,
      right: 16,
      child: Semantics(
        label:
            'Tiempo de descanso: ${_formatSeconds(secondsRemaining)} restantes',
        liveRegion: true,
        child: Material(
          key: const ValueKey('rest-timer-overlay'),
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          color: AppColors.gym,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Descanso',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _formatSeconds(secondsRemaining),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Semantics(
                  label: 'Omitir descanso',
                  button: true,
                  child: TextButton(
                    key: const ValueKey('rest-timer-skip-button'),
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Omitir'),
                  ),
                ),
                Semantics(
                  label: 'Cerrar temporizador de descanso',
                  button: true,
                  child: IconButton(
                    key: const ValueKey('rest-timer-dismiss-button'),
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close, color: Colors.white70),
                    tooltip: 'Cerrar',
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
