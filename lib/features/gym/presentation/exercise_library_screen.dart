import 'package:flutter/material.dart';
import 'package:life_os/core/constants/app_colors.dart';

// ---------------------------------------------------------------------------
// Enums y modelos mock
// ---------------------------------------------------------------------------

enum _MuscleGroup {
  pecho,
  espalda,
  hombros,
  biceps,
  triceps,
  cuadriceps,
  isquiotibiales,
  gluteos,
  pantorrillas,
  core,
  cardio,
}

extension _MuscleGroupLabel on _MuscleGroup {
  String get label => switch (this) {
        _MuscleGroup.pecho => 'Pecho',
        _MuscleGroup.espalda => 'Espalda',
        _MuscleGroup.hombros => 'Hombros',
        _MuscleGroup.biceps => 'Biceps',
        _MuscleGroup.triceps => 'Triceps',
        _MuscleGroup.cuadriceps => 'Cuadriceps',
        _MuscleGroup.isquiotibiales => 'Isquiotibiales',
        _MuscleGroup.gluteos => 'Gluteos',
        _MuscleGroup.pantorrillas => 'Pantorrillas',
        _MuscleGroup.core => 'Core',
        _MuscleGroup.cardio => 'Cardio',
      };
}

enum _Equipment {
  barra,
  mancuernas,
  maquina,
  cable,
  pesoLibre,
  ninguno,
}

extension _EquipmentIcon on _Equipment {
  IconData get icon => switch (this) {
        _Equipment.barra => Icons.fitness_center,
        _Equipment.mancuernas => Icons.sports_gymnastics,
        _Equipment.maquina => Icons.precision_manufacturing_outlined,
        _Equipment.cable => Icons.cable_outlined,
        _Equipment.pesoLibre => Icons.sports_handball_outlined,
        _Equipment.ninguno => Icons.accessibility_new_outlined,
      };

  String get label => switch (this) {
        _Equipment.barra => 'Barra',
        _Equipment.mancuernas => 'Mancuernas',
        _Equipment.maquina => 'Maquina',
        _Equipment.cable => 'Cable',
        _Equipment.pesoLibre => 'Peso libre',
        _Equipment.ninguno => 'Sin equipo',
      };
}

class _MockExercise {
  const _MockExercise({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    required this.equipment,
    this.isCustom = false,
  });

  final int id;
  final String name;
  final _MuscleGroup primaryMuscle;
  final _Equipment equipment;
  final bool isCustom;
}

const _mockExercises = [
  _MockExercise(
    id: 1,
    name: 'Press de banca',
    primaryMuscle: _MuscleGroup.pecho,
    equipment: _Equipment.barra,
  ),
  _MockExercise(
    id: 2,
    name: 'Press inclinado con mancuernas',
    primaryMuscle: _MuscleGroup.pecho,
    equipment: _Equipment.mancuernas,
  ),
  _MockExercise(
    id: 3,
    name: 'Dominadas',
    primaryMuscle: _MuscleGroup.espalda,
    equipment: _Equipment.ninguno,
  ),
  _MockExercise(
    id: 4,
    name: 'Remo con barra',
    primaryMuscle: _MuscleGroup.espalda,
    equipment: _Equipment.barra,
  ),
  _MockExercise(
    id: 5,
    name: 'Press militar',
    primaryMuscle: _MuscleGroup.hombros,
    equipment: _Equipment.barra,
  ),
  _MockExercise(
    id: 6,
    name: 'Curl de biceps',
    primaryMuscle: _MuscleGroup.biceps,
    equipment: _Equipment.mancuernas,
  ),
  _MockExercise(
    id: 7,
    name: 'Extension de triceps en polea',
    primaryMuscle: _MuscleGroup.triceps,
    equipment: _Equipment.cable,
  ),
  _MockExercise(
    id: 8,
    name: 'Sentadilla',
    primaryMuscle: _MuscleGroup.cuadriceps,
    equipment: _Equipment.barra,
  ),
  _MockExercise(
    id: 9,
    name: 'Peso muerto rumano',
    primaryMuscle: _MuscleGroup.isquiotibiales,
    equipment: _Equipment.barra,
  ),
  _MockExercise(
    id: 10,
    name: 'Hip thrust',
    primaryMuscle: _MuscleGroup.gluteos,
    equipment: _Equipment.barra,
  ),
  _MockExercise(
    id: 11,
    name: 'Elevaciones de pantorrilla',
    primaryMuscle: _MuscleGroup.pantorrillas,
    equipment: _Equipment.maquina,
  ),
  _MockExercise(
    id: 12,
    name: 'Plancha',
    primaryMuscle: _MuscleGroup.core,
    equipment: _Equipment.ninguno,
  ),
  _MockExercise(
    id: 13,
    name: 'Correr en cinta',
    primaryMuscle: _MuscleGroup.cardio,
    equipment: _Equipment.maquina,
  ),
  _MockExercise(
    id: 14,
    name: 'Press de pecho en maquina',
    primaryMuscle: _MuscleGroup.pecho,
    equipment: _Equipment.maquina,
  ),
  _MockExercise(
    id: 15,
    name: 'Jalones al pecho en polea',
    primaryMuscle: _MuscleGroup.espalda,
    equipment: _Equipment.cable,
  ),
];

// ---------------------------------------------------------------------------
// Pantalla: biblioteca de ejercicios
// ---------------------------------------------------------------------------

/// Biblioteca de ejercicios con busqueda, filtros por grupo muscular y
/// listado de tarjetas de ejercicio.
///
/// Shell de presentacion — la integracion con Riverpod se realizara en un
/// paso posterior.
///
/// Accesibilidad: A11Y-GYM-01 — todos los elementos interactivos tienen
/// etiquetas semanticas.
class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final _searchController = TextEditingController();
  _MuscleGroup? _selectedMuscle;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_MockExercise> get _filteredExercises {
    return _mockExercises.where((e) {
      final matchesSearch = _searchQuery.isEmpty ||
          e.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesMuscle =
          _selectedMuscle == null || e.primaryMuscle == _selectedMuscle;
      return matchesSearch && matchesMuscle;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredExercises;

    return Scaffold(
      key: const ValueKey('exercise-library-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
              onPressed: () {
                // TODO: mostrar opciones de ordenamiento cuando se conecte
              },
              tooltip: 'Ordenar',
            ),
          ),
        ],
      ),
      body: Column(
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
                        key: const ValueKey('exercise-library-search-clear'),
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _searchQuery = value),
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
                  ..._MuscleGroup.values.map(
                    (muscle) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Semantics(
                        selected: _selectedMuscle == muscle,
                        button: true,
                        label: 'Filtrar por ${muscle.label}',
                        child: FilterChip(
                          key: ValueKey('muscle-chip-${muscle.name}'),
                          label: Text(muscle.label),
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
                  '${filtered.length} ejercicio${filtered.length == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // --- Lista de ejercicios ---
          Expanded(
            child: filtered.isEmpty
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
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final exercise = filtered[index];
                      return _ExerciseCard(
                        key: ValueKey('exercise-card-${exercise.id}'),
                        exercise: exercise,
                        onTap: () {
                          // TODO: abrir detalle del ejercicio cuando se conecte
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Semantics(
        label: 'Agregar ejercicio personalizado',
        button: true,
        child: FloatingActionButton.extended(
          key: const ValueKey('exercise-library-add-fab'),
          backgroundColor: AppColors.gym,
          foregroundColor: Colors.white,
          onPressed: () {
            // TODO: abrir formulario de ejercicio personalizado cuando se conecte
            _showAddCustomExerciseDialog(context);
          },
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
      builder: (ctx) => const _AddCustomExerciseDialog(),
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

  final _MockExercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label:
          '${exercise.name}, ${exercise.primaryMuscle.label}, ${exercise.equipment.label}',
      button: true,
      child: ListTile(
        key: ValueKey('exercise-item-${exercise.id}'),
        onTap: onTap,
        leading: Semantics(
          label: 'Equipo: ${exercise.equipment.label}',
          child: CircleAvatar(
            backgroundColor: AppColors.gym.withAlpha(25),
            child: Icon(
              exercise.equipment.icon,
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
                exercise.primaryMuscle.label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.gym,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              exercise.equipment.label,
              style: theme.textTheme.bodySmall,
            ),
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
  final _MuscleGroup? selectedMuscle;
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
  const _AddCustomExerciseDialog();

  @override
  State<_AddCustomExerciseDialog> createState() =>
      _AddCustomExerciseDialogState();
}

class _AddCustomExerciseDialogState extends State<_AddCustomExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  _MuscleGroup? _selectedMuscle;
  _Equipment? _selectedEquipment;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'El nombre es requerido'
                          : null,
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'Grupo muscular principal',
                child: DropdownButtonFormField<_MuscleGroup>(
                  key: const ValueKey('custom-exercise-muscle-dropdown'),
                  value: _selectedMuscle,
                  decoration: const InputDecoration(
                    labelText: 'Grupo muscular',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Seleccionar'),
                  items: _MuscleGroup.values
                      .map(
                        (m) => DropdownMenuItem(
                          key: ValueKey('muscle-option-${m.name}'),
                          value: m,
                          child: Text(m.label),
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
                child: DropdownButtonFormField<_Equipment>(
                  key: const ValueKey('custom-exercise-equipment-dropdown'),
                  value: _selectedEquipment,
                  decoration: const InputDecoration(
                    labelText: 'Equipo',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Seleccionar'),
                  items: _Equipment.values
                      .map(
                        (e) => DropdownMenuItem(
                          key: ValueKey('equipment-option-${e.name}'),
                          value: e,
                          child: Row(
                            children: [
                              Icon(e.icon, size: 16, color: AppColors.gym),
                              const SizedBox(width: 8),
                              Text(e.label),
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // TODO: llamar a GymNotifier.addCustomExercise cuando se conecte
              Navigator.of(context).pop();
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
