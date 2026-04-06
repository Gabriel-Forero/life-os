import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/router/app_router.dart';
import 'package:life_os/features/goals/domain/goals_input.dart';

// ---------------------------------------------------------------------------
// Add / Edit Goal Screen
// ---------------------------------------------------------------------------

class AddEditGoalScreen extends ConsumerStatefulWidget {
  const AddEditGoalScreen({
    super.key,
    this.existingGoal,
    this.existingSubGoals = const [],
    this.existingMilestones = const [],
    this.onSaveGoal,
  });

  final LifeGoal? existingGoal;
  final List<SubGoal> existingSubGoals;
  final List<GoalMilestone> existingMilestones;

  /// Optional override callback; if null, saves via provider directly.
  final void Function(GoalInput input)? onSaveGoal;

  bool get isEditing => existingGoal != null;

  @override
  ConsumerState<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends ConsumerState<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late String _selectedCategory;
  late int _selectedColor;
  DateTime? _targetDate;

  // Sub-goals builder state
  final _subGoals = <_SubGoalDraft>[];
  // Milestones builder state
  final _milestones = <_MilestoneDraft>[];

  @override
  void initState() {
    super.initState();
    final goal = widget.existingGoal;
    _nameController = TextEditingController(text: goal?.name ?? '');
    _descController =
        TextEditingController(text: goal?.description ?? '');
    _selectedCategory =
        goal?.category ?? GoalCategory.personal.name;
    _selectedColor = goal?.color ?? 0xFF06B6D4;
    _targetDate = goal?.targetDate;

    // Pre-populate sub-goals and milestones
    for (final s in widget.existingSubGoals) {
      _subGoals.add(_SubGoalDraft(
        name: s.name,
        weight: s.weight,
        linkedModule: s.linkedModule,
      ));
    }
    for (final m in widget.existingMilestones) {
      _milestones.add(_MilestoneDraft(
        name: m.name,
        targetProgress: m.targetProgress,
        targetDate: m.targetDate,
      ));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final input = GoalInput(
      name: _nameController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      category: _selectedCategory,
      icon: 'track_changes',
      color: _selectedColor,
      targetDate: _targetDate,
    );

    if (widget.onSaveGoal != null) {
      widget.onSaveGoal!(input);
    } else {
      await ref.read(goalsNotifierProvider).addGoal(input);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meta creada!')),
        );
        GoRouter.of(context).go(AppRoutes.goals);
      }
    }
  }

  void _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      helpText: 'Selecciona fecha limite',
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  double get _totalWeight =>
      _subGoals.fold(0.0, (sum, s) => sum + s.weight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.isEditing;

    return Scaffold(
      key: const ValueKey('add_edit_goal_screen'),
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.goals,
        title: Text(
          isEditing ? 'Editar Objetivo' : 'Nuevo Objetivo',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Semantics(
            label: 'Guardar objetivo',
            button: true,
            child: TextButton(
              key: const ValueKey('save_goal_button'),
              onPressed: _submit,
              child: const Text(
                'Guardar',
                style: TextStyle(
                  color: AppColors.goals,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name field
            Semantics(
              label: 'Nombre del objetivo',
              child: TextFormField(
                key: const ValueKey('goal_name_field'),
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  hintText: 'Ej: Correr un maraton',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // Description field
            Semantics(
              label: 'Descripcion del objetivo',
              child: TextFormField(
                key: const ValueKey('goal_description_field'),
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Descripcion (opcional)',
                  hintText: 'Describe tu objetivo...',
                  border: OutlineInputBorder(),
                ),
                maxLength: 500,
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 16),

            // Category picker
            Text(
              'Categoria',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _CategoryPicker(
              selectedCategory: _selectedCategory,
              onChanged: (cat) => setState(() => _selectedCategory = cat),
            ),
            const SizedBox(height: 16),

            // Color picker
            Text(
              'Color',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _ColorPicker(
              selectedColor: _selectedColor,
              onChanged: (color) => setState(() => _selectedColor = color),
            ),
            const SizedBox(height: 16),

            // Target date picker
            ListTile(
              key: const ValueKey('goal_target_date_tile'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: AppColors.goals),
              title: Text(
                _targetDate != null
                    ? 'Fecha limite: ${_formatDate(_targetDate!)}'
                    : 'Fecha limite (opcional)',
                style: theme.textTheme.bodyMedium,
              ),
              trailing: _targetDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _targetDate = null),
                    )
                  : null,
              onTap: () => _pickDate(context),
            ),
            const Divider(),

            // Sub-goals section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sub-objetivos',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Total peso: ${(_totalWeight * 100).round()}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: (_totalWeight - 1.0).abs() < 0.01
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._subGoals.asMap().entries.map((entry) {
              final idx = entry.key;
              final draft = entry.value;
              return _SubGoalDraftTile(
                key: ValueKey('sub_goal_draft_$idx'),
                draft: draft,
                onRemove: () => setState(() => _subGoals.removeAt(idx)),
              );
            }),
            TextButton.icon(
              key: const ValueKey('add_sub_goal_button'),
              onPressed: () => _showAddSubGoalDialog(context),
              icon: const Icon(Icons.add, color: AppColors.goals),
              label: const Text(
                'Agregar sub-objetivo',
                style: TextStyle(color: AppColors.goals),
              ),
            ),
            const Divider(),

            // Milestones section
            Text(
              'Hitos',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._milestones.asMap().entries.map((entry) {
              final idx = entry.key;
              final draft = entry.value;
              return ListTile(
                key: ValueKey('milestone_draft_$idx'),
                leading: const Icon(Icons.flag_outlined),
                title: Text(draft.name),
                subtitle: Text('Objetivo: ${draft.targetProgress}%'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _milestones.removeAt(idx)),
                ),
              );
            }),
            TextButton.icon(
              key: const ValueKey('add_milestone_button'),
              onPressed: () => _showAddMilestoneDialog(context),
              icon: const Icon(Icons.add, color: AppColors.goals),
              label: const Text(
                'Agregar hito',
                style: TextStyle(color: AppColors.goals),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            Semantics(
              label: isEditing ? 'Actualizar objetivo' : 'Crear objetivo',
              button: true,
              child: ElevatedButton(
                key: const ValueKey('submit_goal_button'),
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goals,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isEditing ? 'Actualizar objetivo' : 'Crear objetivo',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubGoalDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    double weight = 0.0;
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        key: const ValueKey('add_sub_goal_dialog'),
        title: const Text('Agregar sub-objetivo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('sub_goal_name_dialog_field'),
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (ctx, setSt) => Column(
                children: [
                  Text('Peso: ${(weight * 100).round()}%'),
                  Slider(
                    key: const ValueKey('sub_goal_weight_slider'),
                    value: weight,
                    min: 0,
                    max: 1,
                    divisions: 20,
                    activeColor: AppColors.goals,
                    onChanged: (v) => setSt(() => weight = v),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const ValueKey('confirm_add_sub_goal'),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty && weight > 0) {
                setState(() => _subGoals.add(_SubGoalDraft(
                      name: nameCtrl.text.trim(),
                      weight: weight,
                    )));
                Navigator.pop(dialogCtx);
              }
            },
            child: const Text(
              'Agregar',
              style: TextStyle(color: AppColors.goals),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMilestoneDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    int targetProgress = 50;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        key: const ValueKey('add_milestone_dialog'),
        title: const Text('Agregar hito'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('milestone_name_dialog_field'),
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del hito',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (ctx, setSt) => Column(
                children: [
                  Text('Progreso objetivo: $targetProgress%'),
                  Slider(
                    key: const ValueKey('milestone_progress_slider'),
                    value: targetProgress.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: AppColors.goals,
                    onChanged: (v) => setSt(() => targetProgress = v.round()),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const ValueKey('confirm_add_milestone'),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() => _milestones.add(_MilestoneDraft(
                      name: nameCtrl.text.trim(),
                      targetProgress: targetProgress,
                    )));
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Agregar',
              style: TextStyle(color: AppColors.goals),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

// ---------------------------------------------------------------------------
// Category Picker
// ---------------------------------------------------------------------------

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.selectedCategory,
    required this.onChanged,
  });

  final String selectedCategory;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const ValueKey('category_picker'),
      spacing: 8,
      runSpacing: 8,
      children: GoalCategory.values.map((cat) {
        final isSelected = selectedCategory == cat.name;
        return Semantics(
          label: 'Categoria ${cat.displayName}',
          selected: isSelected,
          button: true,
          child: ChoiceChip(
            key: ValueKey('category_chip_${cat.name}'),
            label: Text(cat.displayName),
            selected: isSelected,
            onSelected: (_) => onChanged(cat.name),
            selectedColor: AppColors.goals.withOpacity(0.2),
            labelStyle: TextStyle(
              color: isSelected ? AppColors.goals : null,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Color Picker
// ---------------------------------------------------------------------------

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    required this.selectedColor,
    required this.onChanged,
  });

  final int selectedColor;
  final ValueChanged<int> onChanged;

  static const _colors = [
    0xFF06B6D4, // Goals cyan
    0xFF10B981, // Green
    0xFF8B5CF6, // Purple
    0xFFF59E0B, // Amber
    0xFFEF4444, // Red
    0xFF3B82F6, // Blue
    0xFFF97316, // Orange
    0xFFEC4899, // Pink
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const ValueKey('color_picker'),
      spacing: 8,
      runSpacing: 8,
      children: _colors.map((color) {
        final isSelected = selectedColor == color;
        return Semantics(
          label: 'Color ${color.toRadixString(16)}',
          selected: isSelected,
          button: true,
          child: GestureDetector(
            key: ValueKey('color_swatch_$color'),
            onTap: () => onChanged(color),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(color),
                border: isSelected
                    ? Border.all(
                        color: Colors.white,
                        width: 3,
                      )
                    : null,
                boxShadow: isSelected
                    ? [BoxShadow(color: Color(color), blurRadius: 6)]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-goal draft tile
// ---------------------------------------------------------------------------

class _SubGoalDraftTile extends StatelessWidget {
  const _SubGoalDraftTile({
    super.key,
    required this.draft,
    required this.onRemove,
  });

  final _SubGoalDraft draft;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.subdirectory_arrow_right, size: 18),
      title: Text(draft.name),
      subtitle: Text('Peso: ${(draft.weight * 100).round()}%'),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: onRemove,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Draft data classes
// ---------------------------------------------------------------------------

class _SubGoalDraft {
  _SubGoalDraft({
    required this.name,
    required this.weight,
    this.linkedModule,
  });

  final String name;
  final double weight;
  final String? linkedModule;
}

class _MilestoneDraft {
  _MilestoneDraft({
    required this.name,
    required this.targetProgress,
    this.targetDate,
  });

  final String name;
  final int targetProgress;
  final DateTime? targetDate;
}
