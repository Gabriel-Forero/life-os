import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';

// ---------------------------------------------------------------------------
// Muscle group filter labels (string-based, matching DB values)
// ---------------------------------------------------------------------------

const _muscleGroups = [
  'pecho',
  'espalda',
  'hombros',
  'biceps',
  'triceps',
  'cuadriceps',
  'isquiotibiales',
  'gluteos',
  'pantorrillas',
  'core',
  'cardio',
];

String _muscleLabel(String muscle) => switch (muscle) {
      'pecho' => 'Pecho',
      'espalda' => 'Espalda',
      'hombros' => 'Hombros',
      'biceps' => 'Biceps',
      'triceps' => 'Triceps',
      'cuadriceps' => 'Cuadriceps',
      'isquiotibiales' => 'Isquiotibiales',
      'gluteos' => 'Gluteos',
      'pantorrillas' => 'Pantorrillas',
      'core' => 'Core',
      'cardio' => 'Cardio',
      _ => muscle,
    };

const _equipmentOptions = [
  'barra',
  'mancuernas',
  'maquina',
  'cable',
  'peso_libre',
  'ninguno',
];

String _equipmentLabel(String eq) => switch (eq) {
      'barra' => 'Barra',
      'mancuernas' => 'Mancuernas',
      'maquina' => 'Maquina',
      'cable' => 'Cable',
      'peso_libre' => 'Peso libre',
      'ninguno' => 'Sin equipo',
      _ => eq,
    };

// ---------------------------------------------------------------------------
// Pantalla: biblioteca de ejercicios
// ---------------------------------------------------------------------------

/// Biblioteca de ejercicios con busqueda, filtros por grupo muscular y
/// listado de tarjetas de ejercicio.
///
/// Accesibilidad: A11Y-GYM-01 — todos los elementos interactivos tienen
/// etiquetas semanticas.
class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState
    extends ConsumerState<ExerciseLibraryScreen> {
  final _searchController = TextEditingController();
  String? _selectedMuscle;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dao = ref.watch(gymDaoProvider);

    return Scaffold(
      key: const ValueKey('exercise-library-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.gym,
        title: Semantics(
          header: true,
          child: const Text('Biblioteca de ejercicios'),
        ),
        actions: [
          Semantics(
            label: 'Ordenar ejercicios',
            button: true,
            child: IconButton(
              key: const ValueKey('exercise-library-sort-button'),
              icon: const Icon(Icons.sort_outlined),
              onPressed: () {},
              tooltip: 'Ordenar',
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Exercise>>(
        stream: dao.watchExercises(
          muscleGroup: _selectedMuscle,
          query: _searchQuery.isEmpty ? null : _searchQuery,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final exercises = snapshot.data ?? [];

          return Column(
            children: [
              // --- Barra de busqueda ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Semantics(
                  label: 'Buscar ejercicio',
                  textField: true,
                  child: SearchBar(
                    key: const ValueKey('exercise-library-search-bar'),
                    controller: _searchController,
                    hintText: 'Buscar ejercicio...',
                    leading: const Icon(Icons.search_outlined),
                    trailing: [
                      if (_searchQuery.isNotEmpty)
                        Semantics(
                          label: 'Limpiar busqueda',
                          button: true,
                          child: IconButton(
                            key: const ValueKey(
                                'exercise-library-search-clear'),
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _searchQuery = value),
                    backgroundColor: WidgetStateProperty.all(
                      theme.colorScheme.surfaceContainerHighest,
                    ),
                    elevation: WidgetStateProperty.all(0),
                  ),
                ),
              ),

              // --- Chips de filtro por grupo muscular ---
              SizedBox(
                height: 44,
                child: Semantics(
                  label: 'Filtrar por grupo muscular',
                  child: ListView(
                    key: const ValueKey('exercise-library-muscle-filter'),
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Semantics(
                          selected: _selectedMuscle == null,
                          button: true,
                          label: 'Todos los grupos musculares',
                          child: FilterChip(
                            key: const ValueKey('muscle-chip-all'),
                            label: const Text('Todos'),
                            selected: _selectedMuscle == null,
                            onSelected: (_) =>
                                setState(() => _selectedMuscle = null),
                            selectedColor: AppColors.gym.withAlpha(30),
                            checkmarkColor: AppColors.gym,
                            labelStyle: TextStyle(
                              color: _selectedMuscle == null
                                  ? AppColors.gym
                                  : null,
                              fontWeight: _selectedMuscle == null
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      ..._muscleGroups.map(
                        (muscle) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Semantics(
                            selected: _selectedMuscle == muscle,
                            button: true,
                            label: 'Filtrar por ${_muscleLabel(muscle)}',
                            child: FilterChip(
                              key: ValueKey('muscle-chip-$muscle'),
                              label: Text(_muscleLabel(muscle)),
                              selected: _selectedMuscle == muscle,
                              onSelected: (_) => setState(
                                () => _selectedMuscle =
                                    _selectedMuscle == muscle ? null : muscle,
                              ),
                              selectedColor: AppColors.gym.withAlpha(30),
                              checkmarkColor: AppColors.gym,
                              labelStyle: TextStyle(
                                color: _selectedMuscle == muscle
                                    ? AppColors.gym
                                    : null,
                                fontWeight: _selectedMuscle == muscle
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // --- Conteo de resultados ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Row(
                  children: [
                    Text(
                      '${exercises.length} ejercicio${exercises.length == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // --- Lista de ejercicios ---
              Expanded(
                child: exercises.isEmpty
                    ? _EmptySearchState(
                        key: const ValueKey('exercise-library-empty'),
                        query: _searchQuery,
                        selectedMuscle: _selectedMuscle,
                        onClearFilters: () => setState(() {
                          _selectedMuscle = null;
                          _searchQuery = '';
                          _searchController.clear();
                        }),
                      )
                    : ListView.separated(
                        key: const ValueKey('exercise-library-list'),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: exercises.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final exercise = exercises[index];
                          return _ExerciseCard(
                            key: ValueKey('exercise-card-${exercise.id}'),
                            exercise: exercise,
                            onTap: () {},
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Semantics(
        label: 'Agregar ejercicio personalizado',
        button: true,
        child: FloatingActionButton.extended(
          key: const ValueKey('exercise-library-add-fab'),
          backgroundColor: AppColors.gym,
          foregroundColor: Colors.white,
          onPressed: () => _showAddCustomExerciseDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Personalizado'),
          tooltip: 'Agregar ejercicio personalizado',
        ),
      ),
    );
  }

  void _showAddCustomExerciseDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _AddCustomExerciseDialog(ref: ref),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: tarjeta de ejercicio
// ---------------------------------------------------------------------------

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    super.key,
    required this.exercise,
    required this.onTap,
  });

  final Exercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muscleLabel = _muscleLabel(exercise.primaryMuscle);
    final equipLabel =
        exercise.equipment != null ? _equipmentLabel(exercise.equipment!) : '';

    return Semantics(
      label: '${exercise.name}, $muscleLabel, $equipLabel',
      button: true,
      child: ListTile(
        key: ValueKey('exercise-item-${exercise.id}'),
        onTap: onTap,
        leading: Semantics(
          label: 'Equipo: $equipLabel',
          child: CircleAvatar(
            backgroundColor: AppColors.gym.withAlpha(25),
            child: const Icon(
              Icons.fitness_center,
              color: AppColors.gym,
              size: 20,
            ),
          ),
        ),
        title: Text(
          exercise.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.gym.withAlpha(20),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                muscleLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.gym,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (equipLabel.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                equipLabel,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (exercise.isCustom) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gym.withAlpha(15),
                  border: Border.all(color: AppColors.gym.withAlpha(80)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Custom',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.gym,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right_outlined),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: estado vacio
// ---------------------------------------------------------------------------

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({
    super.key,
    required this.query,
    required this.selectedMuscle,
    required this.onClearFilters,
  });

  final String query;
  final String? selectedMuscle;
  final VoidCallback onClearFilters;

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
              Icons.fitness_center_outlined,
              size: 64,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin resultados',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Ningun ejercicio coincide con tu busqueda.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Semantics(
              button: true,
              label: 'Limpiar filtros de busqueda',
              child: OutlinedButton.icon(
                key: const ValueKey('exercise-library-clear-filters'),
                onPressed: onClearFilters,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.gym,
                  side: const BorderSide(color: AppColors.gym),
                ),
                icon: const Icon(Icons.clear_all),
                label: const Text('Limpiar filtros'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialogo: agregar ejercicio personalizado
// ---------------------------------------------------------------------------

class _AddCustomExerciseDialog extends StatefulWidget {
  const _AddCustomExerciseDialog({required this.ref});

  final WidgetRef ref;

  @override
  State<_AddCustomExerciseDialog> createState() =>
      _AddCustomExerciseDialogState();
}

class _AddCustomExerciseDialogState extends State<_AddCustomExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedMuscle;
  String? _selectedEquipment;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final notifier = widget.ref.read(gymNotifierProvider);
    await notifier.addCustomExercise(
      name: _nameController.text.trim(),
      primaryMuscle: _selectedMuscle!,
      equipment: _selectedEquipment,
    );

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Guardado!')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('add-custom-exercise-dialog'),
      title: const Text('Ejercicio personalizado'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: 'Nombre del ejercicio',
                textField: true,
                child: TextFormField(
                  key: const ValueKey('custom-exercise-name-field'),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ej. Press de pecho en banco',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'El nombre es requerido'
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'Grupo muscular principal',
                child: DropdownButtonFormField<String>(
                  key: const ValueKey('custom-exercise-muscle-dropdown'),
                  value: _selectedMuscle,
                  decoration: const InputDecoration(
                    labelText: 'Grupo muscular',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Seleccionar'),
                  items: _muscleGroups
                      .map(
                        (m) => DropdownMenuItem(
                          key: ValueKey('muscle-option-$m'),
                          value: m,
                          child: Text(_muscleLabel(m)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedMuscle = v),
                  validator: (v) =>
                      v == null ? 'Selecciona un grupo muscular' : null,
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'Equipo requerido',
                child: DropdownButtonFormField<String>(
                  key: const ValueKey('custom-exercise-equipment-dropdown'),
                  value: _selectedEquipment,
                  decoration: const InputDecoration(
                    labelText: 'Equipo',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Seleccionar'),
                  items: _equipmentOptions
                      .map(
                        (e) => DropdownMenuItem(
                          key: ValueKey('equipment-option-$e'),
                          value: e,
                          child: Row(
                            children: [
                              const Icon(Icons.fitness_center,
                                  size: 16, color: AppColors.gym),
                              const SizedBox(width: 8),
                              Text(_equipmentLabel(e)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedEquipment = v),
                  validator: (v) => v == null ? 'Selecciona el equipo' : null,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('custom-exercise-cancel-button'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const ValueKey('custom-exercise-save-button'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.gym),
          onPressed: _isSaving ? null : _save,
          child: Text(_isSaving ? 'Guardando...' : 'Guardar'),
        ),
      ],
    );
  }
}
