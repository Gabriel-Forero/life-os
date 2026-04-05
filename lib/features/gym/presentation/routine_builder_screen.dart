import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_os/core/constants/app_colors.dart';

// ---------------------------------------------------------------------------
// Modelos mock
// ---------------------------------------------------------------------------

class _MockExerciseRef {
  _MockExerciseRef({
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

/// Ejercicios disponibles en la biblioteca (subset para el picker).
const _libraryExercises = [
  (id: 1, name: 'Press de banca', muscle: 'Pecho'),
  (id: 2, name: 'Dominadas', muscle: 'Espalda'),
  (id: 3, name: 'Press militar', muscle: 'Hombros'),
  (id: 4, name: 'Curl de biceps', muscle: 'Biceps'),
  (id: 5, name: 'Extension de triceps en polea', muscle: 'Triceps'),
  (id: 6, name: 'Sentadilla', muscle: 'Cuadriceps'),
  (id: 7, name: 'Peso muerto rumano', muscle: 'Isquiotibiales'),
  (id: 8, name: 'Hip thrust', muscle: 'Gluteos'),
  (id: 9, name: 'Plancha', muscle: 'Core'),
  (id: 10, name: 'Correr en cinta', muscle: 'Cardio'),
];

// ---------------------------------------------------------------------------
// Pantalla: constructor de rutina
// ---------------------------------------------------------------------------

/// Constructor de rutinas con nombre, descripcion, lista reordenable de
/// ejercicios y configuracion de series/repeticiones/descanso por ejercicio.
///
/// Shell de presentacion — la integracion con Riverpod se realizara en un
/// paso posterior.
///
/// Accesibilidad: A11Y-GYM-02 — todos los campos y botones tienen etiquetas
/// semanticas.
class RoutineBuilderScreen extends StatefulWidget {
  const RoutineBuilderScreen({
    super.key,
    this.routineId,
  });

  /// Si se proporciona, la pantalla opera en modo edicion.
  final int? routineId;

  @override
  State<RoutineBuilderScreen> createState() => _RoutineBuilderScreenState();
}

class _RoutineBuilderScreenState extends State<RoutineBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<_MockExerciseRef> _exercises = [];

  bool get _isEditing => widget.routineId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un ejercicio para guardar la rutina'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    // TODO: llamar a GymNotifier.saveRoutine cuando se conecte
    Navigator.of(context).pop();
  }

  void _removeExercise(int index) {
    setState(() => _exercises.removeAt(index));
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, item);
    });
  }

  Future<void> _openExercisePicker() async {
    final result = await showModalBottomSheet<({int id, String name, String muscle})>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => const _ExercisePickerSheet(),
    );

    if (result != null) {
      final alreadyAdded = _exercises.any((e) => e.id == result.id);
      if (alreadyAdded) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result.name} ya esta en la rutina'),
            ),
          );
        }
        return;
      }
      setState(() {
        _exercises.add(
          _MockExerciseRef(
            id: result.id,
            name: result.name,
            primaryMuscle: result.muscle,
            sets: 3,
            reps: 10,
            restSeconds: 90,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: const ValueKey('routine-builder-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Semantics(
          header: true,
          child: Text(_isEditing ? 'Editar rutina' : 'Nueva rutina'),
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
            label: 'Guardar rutina',
            button: true,
            child: TextButton.icon(
              key: const ValueKey('routine-builder-save-button'),
              onPressed: _handleSave,
              style: TextButton.styleFrom(foregroundColor: AppColors.gym),
              icon: const Icon(Icons.check),
              label: const Text(
                'Guardar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // --- Campos de nombre y descripcion ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                children: [
                  Semantics(
                    label: 'Nombre de la rutina',
                    textField: true,
                    child: TextFormField(
                      key: const ValueKey('routine-builder-name-field'),
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre de la rutina',
                        hintText: 'Ej. Empuje — Día A',
                        prefixIcon: const Icon(Icons.drive_file_rename_outline),
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
                  const SizedBox(height: 12),
                  Semantics(
                    label: 'Descripcion de la rutina (opcional)',
                    textField: true,
                    child: TextFormField(
                      key: const ValueKey('routine-builder-description-field'),
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripcion (opcional)',
                        hintText: 'Ej. Fuerza + hipertrofia de pecho y hombros',
                        prefixIcon: Icon(Icons.notes_outlined),
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      maxLength: 200,
                    ),
                  ),
                ],
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
                      'Ejercicios (${_exercises.length})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Semantics(
                    label: 'Agregar ejercicio a la rutina',
                    button: true,
                    child: TextButton.icon(
                      key: const ValueKey('routine-builder-add-exercise-button'),
                      onPressed: _openExercisePicker,
                      style:
                          TextButton.styleFrom(foregroundColor: AppColors.gym),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Agregar'),
                    ),
                  ),
                ],
              ),
            ),

            // --- Lista reordenable de ejercicios ---
            Expanded(
              child: _exercises.isEmpty
                  ? _EmptyExerciseList(
                      key: const ValueKey('routine-builder-empty'),
                      onAddExercise: _openExercisePicker,
                    )
                  : ReorderableListView.builder(
                      key: const ValueKey('routine-builder-exercise-list'),
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
                      itemCount: _exercises.length,
                      onReorder: _onReorder,
                      buildDefaultDragHandles: false,
                      itemBuilder: (context, index) {
                        final exercise = _exercises[index];
                        return _ExerciseRow(
                          key: ValueKey('routine-exercise-row-${exercise.id}'),
                          exercise: exercise,
                          index: index,
                          onRemove: () => _removeExercise(index),
                          onSetsChanged: (v) =>
                              setState(() => exercise.sets = v),
                          onRepsChanged: (v) =>
                              setState(() => exercise.reps = v),
                          onRestChanged: (v) =>
                              setState(() => exercise.restSeconds = v),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
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

  final _MockExerciseRef exercise;
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
            // Encabezado de ejercicio
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
                Semantics(
                  label: 'Eliminar ${exercise.name} de la rutina',
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

            // Controles de series/reps/descanso
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
              'Agrega al menos un ejercicio para poder guardar la rutina.',
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

class _ExercisePickerSheet extends StatefulWidget {
  const _ExercisePickerSheet();

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
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
    final filtered = _libraryExercises
        .where(
          (e) =>
              _query.isEmpty ||
              e.name.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
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
              child: ListView.separated(
                key: const ValueKey('exercise-picker-list'),
                controller: scrollController,
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final ex = filtered[index];
                  return Semantics(
                    label: '${ex.name}, ${ex.muscle}',
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
                      title: Text(ex.name),
                      subtitle: Text(
                        ex.muscle,
                        style: const TextStyle(
                          color: AppColors.gym,
                          fontSize: 12,
                        ),
                      ),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () => Navigator.of(context).pop(ex),
                    ),
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
