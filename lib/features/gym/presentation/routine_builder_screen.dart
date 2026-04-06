import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/features/gym/domain/gym_input.dart';

// ---------------------------------------------------------------------------
// Modelo local: ejercicio dentro de un dia del programa
// ---------------------------------------------------------------------------

class _ExerciseRef {
  _ExerciseRef({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    required this.sets,
    required this.reps,
    required this.restSeconds,
  });

  final int id;
  final String name;
  final String primaryMuscle;
  int sets;
  int reps;
  int restSeconds;
}

// ---------------------------------------------------------------------------
// Modelo local: un dia del programa
// ---------------------------------------------------------------------------

class _DayState {
  _DayState({
    required this.dayNumber,
    this.dayLabel = '',
    List<_ExerciseRef>? exercises,
  }) : exercises = exercises ?? [];

  final int dayNumber;
  String dayLabel; // "Push", "Pull", etc. — optional
  final List<_ExerciseRef> exercises;
}

// ---------------------------------------------------------------------------
// Pantalla: constructor de programa/rutina multi-dia
// ---------------------------------------------------------------------------

/// Constructor de programas con nombre, descripcion, dias configurables (1-7)
/// y lista reordenable de ejercicios por dia.
///
/// Accesibilidad: A11Y-GYM-02 — todos los campos y botones tienen etiquetas
/// semanticas.
class RoutineBuilderScreen extends ConsumerStatefulWidget {
  const RoutineBuilderScreen({
    super.key,
    this.routineId,
  });

  /// Si se proporciona, la pantalla opera en modo edicion.
  final int? routineId;

  @override
  ConsumerState<RoutineBuilderScreen> createState() =>
      _RoutineBuilderScreenState();
}

class _RoutineBuilderScreenState extends ConsumerState<RoutineBuilderScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _numDays = 1;
  late List<_DayState> _days;
  late TabController _tabController;

  bool _isSaving = false;

  bool get _isEditing => widget.routineId != null;

  @override
  void initState() {
    super.initState();
    _days = [_DayState(dayNumber: 1)];
    _tabController = TabController(length: _numDays, vsync: this);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // --- Day count management ------------------------------------------------

  void _setNumDays(int newCount) {
    if (newCount < 1 || newCount > 7 || newCount == _numDays) return;
    setState(() {
      if (newCount > _numDays) {
        for (int i = _numDays + 1; i <= newCount; i++) {
          _days.add(_DayState(dayNumber: i));
        }
      } else {
        _days = _days.sublist(0, newCount);
      }
      _numDays = newCount;
      final prevIndex = _tabController.index.clamp(0, newCount - 1);
      _tabController.dispose();
      _tabController = TabController(
        length: _numDays,
        vsync: this,
        initialIndex: prevIndex,
      );
    });
  }

  // --- Save ----------------------------------------------------------------

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Check that every day has at least one exercise
    final allExercises = _days.expand((d) => d.exercises).toList();
    if (allExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un ejercicio para guardar el programa'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Check if any day is empty (warn but allow saving)
    final emptyDays =
        _days.where((d) => d.exercises.isEmpty).map((d) => d.dayNumber).toList();
    if (emptyDays.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Dias sin ejercicios'),
          content: Text(
            'Los dias ${emptyDays.join(', ')} no tienen ejercicios. '
            '¿Deseas guardar de todas formas?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _isSaving = true);

    // Build list of RoutineExerciseInput across all days
    final exerciseInputs = <RoutineExerciseInput>[];
    for (final day in _days) {
      for (final ex in day.exercises) {
        exerciseInputs.add(RoutineExerciseInput(
          exerciseId: ex.id,
          dayNumber: day.dayNumber,
          dayName: day.dayLabel.trim().isEmpty ? null : day.dayLabel.trim(),
          defaultSets: ex.sets,
          defaultReps: ex.reps,
          restSeconds: ex.restSeconds,
        ));
      }
    }

    final notifier = ref.read(gymNotifierProvider);
    await notifier.createRoutine(RoutineInput(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      exercises: exerciseInputs,
    ));

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Programa guardado!')));
      Navigator.of(context).pop();
    }
  }

  // --- Exercise picker for the current active day tab ----------------------

  Future<void> _openExercisePickerForDay(_DayState day) async {
    final result =
        await showModalBottomSheet<({int id, String name, String muscle})>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => const _ExercisePickerSheet(),
    );

    if (result != null) {
      final alreadyAdded = day.exercises.any((e) => e.id == result.id);
      if (alreadyAdded) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${result.name} ya esta en este dia')),
          );
        }
        return;
      }
      setState(() {
        day.exercises.add(_ExerciseRef(
          id: result.id,
          name: result.name,
          primaryMuscle: result.muscle,
          sets: 3,
          reps: 10,
          restSeconds: 90,
        ));
      });
    }
  }

  // --- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: const ValueKey('routine-builder-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.gym,
        title: Semantics(
          header: true,
          child: Text(_isEditing ? 'Editar programa' : 'Nuevo programa'),
        ),
        leading: Semantics(
          label: 'Volver',
          button: true,
          child: IconButton(
            key: const ValueKey('routine-builder-back-button'),
            icon: const Icon(Icons.arrow_back_outlined),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Volver',
          ),
        ),
        actions: [
          Semantics(
            label: 'Guardar programa',
            button: true,
            child: TextButton.icon(
              key: const ValueKey('routine-builder-save-button'),
              onPressed: _isSaving ? null : _handleSave,
              style: TextButton.styleFrom(foregroundColor: AppColors.gym),
              icon: const Icon(Icons.check),
              label: Text(
                _isSaving ? 'Guardando...' : 'Guardar',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
        bottom: _numDays > 1
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.gym,
                indicatorColor: AppColors.gym,
                tabs: _days
                    .map(
                      (d) => Tab(
                        text: d.dayLabel.trim().isNotEmpty
                            ? 'Dia ${d.dayNumber}: ${d.dayLabel.trim()}'
                            : 'Dia ${d.dayNumber}',
                      ),
                    )
                    .toList(),
              )
            : null,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // --- Nombre y descripcion del programa ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  Semantics(
                    label: 'Nombre del programa',
                    textField: true,
                    child: TextFormField(
                      key: const ValueKey('routine-builder-name-field'),
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del programa',
                        hintText: 'Ej. Push Pull Legs',
                        prefixIcon:
                            const Icon(Icons.drive_file_rename_outline),
                        border: const OutlineInputBorder(),
                        focusedBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: AppColors.gym, width: 2),
                        ),
                        labelStyle: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'El nombre es requerido'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Semantics(
                    label: 'Descripcion del programa (opcional)',
                    textField: true,
                    child: TextFormField(
                      key: const ValueKey('routine-builder-description-field'),
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripcion (opcional)',
                        hintText: 'Ej. Hipertrofia 4 dias por semana',
                        prefixIcon: Icon(Icons.notes_outlined),
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 1,
                      maxLength: 200,
                    ),
                  ),
                  // --- Numero de dias ---
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Numero de dias:',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _DayCountSpinner(
                        key: const ValueKey('routine-builder-day-count'),
                        value: _numDays,
                        onChanged: _setNumDays,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),
            const Divider(height: 1),

            // --- Contenido por dia ---
            Expanded(
              child: _numDays == 1
                  ? _DayExerciseList(
                      key: const ValueKey('routine-builder-day-1'),
                      day: _days[0],
                      showDayLabelField: false,
                      onAddExercise: () =>
                          _openExercisePickerForDay(_days[0]),
                      onChanged: () => setState(() {}),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: _days
                          .map(
                            (day) => _DayExerciseList(
                              key: ValueKey(
                                  'routine-builder-day-${day.dayNumber}'),
                              day: day,
                              showDayLabelField: true,
                              onAddExercise: () =>
                                  _openExercisePickerForDay(day),
                              onChanged: () => setState(() {}),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: spinner para el numero de dias
// ---------------------------------------------------------------------------

class _DayCountSpinner extends StatelessWidget {
  const _DayCountSpinner({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Disminuir dias',
            button: true,
            child: InkWell(
              onTap: value > 1 ? () => onChanged(value - 1) : null,
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.remove,
                  size: 16,
                  color: value > 1 ? AppColors.gym : Colors.grey,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$value',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Semantics(
            label: 'Aumentar dias',
            button: true,
            child: InkWell(
              onTap: value < 7 ? () => onChanged(value + 1) : null,
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.add,
                  size: 16,
                  color: value < 7 ? AppColors.gym : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: lista de ejercicios de un dia especifico
// ---------------------------------------------------------------------------

class _DayExerciseList extends StatefulWidget {
  const _DayExerciseList({
    super.key,
    required this.day,
    required this.showDayLabelField,
    required this.onAddExercise,
    required this.onChanged,
  });

  final _DayState day;
  final bool showDayLabelField;
  final VoidCallback onAddExercise;
  final VoidCallback onChanged;

  @override
  State<_DayExerciseList> createState() => _DayExerciseListState();
}

class _DayExerciseListState extends State<_DayExerciseList> {
  late final TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _labelController =
        TextEditingController(text: widget.day.dayLabel);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _removeExercise(int index) {
    setState(() => widget.day.exercises.removeAt(index));
    widget.onChanged();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = widget.day.exercises.removeAt(oldIndex);
      widget.day.exercises.insert(newIndex, item);
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final day = widget.day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Campo etiqueta del dia (solo en modo multi-dia) ---
        if (widget.showDayLabelField)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Semantics(
              label: 'Nombre del dia ${day.dayNumber} (opcional)',
              textField: true,
              child: TextField(
                key: ValueKey('routine-day-label-${day.dayNumber}'),
                controller: _labelController,
                decoration: InputDecoration(
                  labelText: 'Nombre del dia (opcional)',
                  hintText: 'Ej. Push, Pull, Piernas, Hombros',
                  prefixIcon: const Icon(Icons.label_outline),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (v) {
                  day.dayLabel = v;
                  widget.onChanged();
                },
              ),
            ),
          ),

        // --- Encabezado de ejercicios ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Ejercicios (${day.exercises.length})',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              Semantics(
                label: 'Agregar ejercicio al dia ${day.dayNumber}',
                button: true,
                child: TextButton.icon(
                  key: ValueKey(
                      'routine-builder-add-exercise-day-${day.dayNumber}'),
                  onPressed: widget.onAddExercise,
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.gym),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar'),
                ),
              ),
            ],
          ),
        ),

        // --- Lista reordenable ---
        Expanded(
          child: day.exercises.isEmpty
              ? _EmptyExerciseList(
                  key: ValueKey('routine-empty-day-${day.dayNumber}'),
                  onAddExercise: widget.onAddExercise,
                )
              : ReorderableListView.builder(
                  key: ValueKey('routine-exercise-list-day-${day.dayNumber}'),
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
                  itemCount: day.exercises.length,
                  onReorder: _onReorder,
                  buildDefaultDragHandles: false,
                  itemBuilder: (context, index) {
                    final exercise = day.exercises[index];
                    return _ExerciseRow(
                      key: ValueKey(
                          'routine-exercise-row-d${day.dayNumber}-${exercise.id}'),
                      exercise: exercise,
                      index: index,
                      onRemove: () => _removeExercise(index),
                      onSetsChanged: (v) {
                        setState(() => exercise.sets = v);
                        widget.onChanged();
                      },
                      onRepsChanged: (v) {
                        setState(() => exercise.reps = v);
                        widget.onChanged();
                      },
                      onRestChanged: (v) {
                        setState(() => exercise.restSeconds = v);
                        widget.onChanged();
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: fila de ejercicio con series/reps/descanso
// ---------------------------------------------------------------------------

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    super.key,
    required this.exercise,
    required this.index,
    required this.onRemove,
    required this.onSetsChanged,
    required this.onRepsChanged,
    required this.onRestChanged,
  });

  final _ExerciseRef exercise;
  final int index;
  final VoidCallback onRemove;
  final ValueChanged<int> onSetsChanged;
  final ValueChanged<int> onRepsChanged;
  final ValueChanged<int> onRestChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Semantics(
                    label: 'Arrastrar para reordenar ${exercise.name}',
                    child: const Icon(
                      Icons.drag_handle,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
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
                    ],
                  ),
                ),
                Semantics(
                  label: 'Eliminar ${exercise.name}',
                  button: true,
                  child: IconButton(
                    key: ValueKey('routine-remove-exercise-${exercise.id}'),
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onRemove,
                    color: AppColors.error,
                    tooltip: 'Eliminar',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SpinnerField(
                    key: ValueKey('routine-sets-${exercise.id}'),
                    label: 'Series',
                    value: exercise.sets,
                    min: 1,
                    max: 20,
                    onChanged: onSetsChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SpinnerField(
                    key: ValueKey('routine-reps-${exercise.id}'),
                    label: 'Reps',
                    value: exercise.reps,
                    min: 1,
                    max: 100,
                    onChanged: onRepsChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SpinnerField(
                    key: ValueKey('routine-rest-${exercise.id}'),
                    label: 'Descanso (s)',
                    value: exercise.restSeconds,
                    min: 0,
                    max: 600,
                    step: 15,
                    onChanged: onRestChanged,
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

// ---------------------------------------------------------------------------
// Widget: campo numerico con incremento/decremento
// ---------------------------------------------------------------------------

class _SpinnerField extends StatelessWidget {
  const _SpinnerField({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: 'Disminuir $label',
                button: true,
                child: InkWell(
                  onTap: value > min
                      ? () => onChanged((value - step).clamp(min, max))
                      : null,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.remove,
                      size: 14,
                      color: value > min ? AppColors.gym : Colors.grey,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Semantics(
                label: 'Aumentar $label',
                button: true,
                child: InkWell(
                  onTap: value < max
                      ? () => onChanged((value + step).clamp(min, max))
                      : null,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.add,
                      size: 14,
                      color: value < max ? AppColors.gym : Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: estado vacio de ejercicios
// ---------------------------------------------------------------------------

class _EmptyExerciseList extends StatelessWidget {
  const _EmptyExerciseList({
    super.key,
    required this.onAddExercise,
  });

  final VoidCallback onAddExercise;

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
              Icons.playlist_add_outlined,
              size: 64,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin ejercicios',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega ejercicios a este dia.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Semantics(
              button: true,
              label: 'Agregar primer ejercicio',
              child: FilledButton.icon(
                key: const ValueKey('routine-builder-add-first-exercise'),
                onPressed: onAddExercise,
                style: FilledButton.styleFrom(backgroundColor: AppColors.gym),
                icon: const Icon(Icons.add),
                label: const Text('Agregar ejercicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet: selector de ejercicio de la biblioteca
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
                'Seleccionar ejercicio',
                style: theme.textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Semantics(
                label: 'Buscar ejercicio en la biblioteca',
                textField: true,
                child: TextField(
                  key: const ValueKey('exercise-picker-search'),
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
                stream:
                    dao.watchExercises(query: _query.isEmpty ? null : _query),
                builder: (context, snapshot) {
                  final exercises = snapshot.data ?? [];
                  return ListView.separated(
                    key: const ValueKey('exercise-picker-list'),
                    controller: scrollController,
                    itemCount: exercises.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final ex = exercises[index];
                      return Semantics(
                        label: '${ex.name}, ${ex.primaryMuscle}',
                        button: true,
                        child: ListTile(
                          key: ValueKey('exercise-picker-item-${ex.id}'),
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
                            maxLines: 1,
                          ),
                          subtitle: Text(
                            ex.primaryMuscle,
                            style: const TextStyle(
                              color: AppColors.gym,
                              fontSize: 12,
                            ),
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
