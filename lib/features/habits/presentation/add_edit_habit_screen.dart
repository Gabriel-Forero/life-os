import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/features/habits/domain/habits_input.dart';

// ---------------------------------------------------------------------------
// Constantes y datos de configuracion
// ---------------------------------------------------------------------------

/// Frecuencia de repeticion del habito.
enum _Frequency { daily, weekly, custom }

extension _FrequencyLabel on _Frequency {
  String get label => switch (this) {
        _Frequency.daily => 'Diario',
        _Frequency.weekly => 'Semanal',
        _Frequency.custom => 'Personalizado',
      };
}

/// Dias de la semana para selector de dias.
const _weekDays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
const _weekDayLabels = [
  'Lunes',
  'Martes',
  'Miercoles',
  'Jueves',
  'Viernes',
  'Sabado',
  'Domingo',
];

/// Iconos disponibles para el selector de icono.
const _availableIcons = <IconData>[
  Icons.self_improvement,
  Icons.menu_book_outlined,
  Icons.water_drop_outlined,
  Icons.fitness_center,
  Icons.no_food_outlined,
  Icons.bedtime_outlined,
  Icons.directions_run_outlined,
  Icons.favorite_border_outlined,
  Icons.spa_outlined,
  Icons.music_note_outlined,
  Icons.brush_outlined,
  Icons.code_outlined,
  Icons.restaurant_outlined,
  Icons.local_drink_outlined,
  Icons.medication_outlined,
  Icons.savings_outlined,
  Icons.school_outlined,
  Icons.language_outlined,
  Icons.camera_alt_outlined,
  Icons.park_outlined,
];

/// Colores disponibles para el selector de color.
const _availableColors = <Color>[
  AppColors.habits,
  AppColors.finance,
  AppColors.gym,
  AppColors.nutrition,
  AppColors.sleep,
  AppColors.mental,
  AppColors.goals,
  Color(0xFFF43F5E),
  Color(0xFFEF4444),
  Color(0xFFF97316),
  Color(0xFFEAB308),
  Color(0xFF84CC16),
  Color(0xFF22C55E),
  Color(0xFF14B8A6),
  Color(0xFF3B82F6),
  Color(0xFF6366F1),
];

// ---------------------------------------------------------------------------
// Pantalla: agregar / editar habito
// ---------------------------------------------------------------------------

/// Pantalla de alta o edicion de habito con selector de icono, color,
/// frecuencia, objetivo cuantitativo y recordatorio.
///
/// Shell de presentacion — la integracion con Riverpod se realizara en un
/// paso posterior.
///
/// Accesibilidad: A11Y-HAB-02 — todos los campos y controles tienen etiquetas
/// semanticas.
class AddEditHabitScreen extends ConsumerStatefulWidget {
  const AddEditHabitScreen({
    super.key,
    this.habitId,
  });

  /// Si se proporciona, la pantalla opera en modo edicion.
  final String? habitId;

  @override
  ConsumerState<AddEditHabitScreen> createState() =>
      _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends ConsumerState<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _unitController = TextEditingController();

  IconData _selectedIcon = Icons.self_improvement;
  Color _selectedColor = AppColors.habits;
  _Frequency _frequency = _Frequency.daily;
  int _weeklyTarget = 3;
  final Set<int> _selectedDays = {0, 2, 4}; // L, X, V por defecto
  bool _isQuantitative = false;
  TimeOfDay? _reminderTime;
  bool _autoComplete = false;
  bool _isSaving = false;

  bool get _isEditing => widget.habitId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Seleccionar hora del recordatorio',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: _selectedColor,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  void _clearReminderTime() {
    setState(() => _reminderTime = null);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_frequency == _Frequency.custom && _selectedDays.isEmpty) return;

    setState(() => _isSaving = true);

    final reminderStr = _reminderTime != null
        ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
        : null;

    final input = HabitInput(
      name: _nameController.text.trim(),
      icon: _selectedIcon.codePoint.toString(),
      color: _selectedColor.value,
      frequencyType: _frequency.name,
      weeklyTarget: _frequency == _Frequency.weekly ? _weeklyTarget : 1,
      customDays: _frequency == _Frequency.custom
          ? (_selectedDays.toList()..sort())
          : null,
      isQuantitative: _isQuantitative,
      quantitativeTarget: _isQuantitative
          ? double.tryParse(_targetController.text)
          : null,
      quantitativeUnit:
          _isQuantitative ? _unitController.text.trim() : null,
      reminderTime: reminderStr,
    );

    final notifier = ref.read(habitsNotifierProvider);
    final result = await notifier.addHabit(input);

    if (!mounted) return;
    setState(() => _isSaving = false);

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardado!')),
        );
        Navigator.of(context).pop();
      },
      failure: (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.userMessage)),
        );
      },
    );
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: const ValueKey('add-edit-habit-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.habits,
        title: Semantics(
          header: true,
          child: Text(_isEditing ? 'Editar habito' : 'Nuevo habito'),
        ),
        leading: Semantics(
          label: 'Volver',
          button: true,
          child: IconButton(
            key: const ValueKey('add-edit-habit-back-button'),
            icon: const Icon(Icons.arrow_back_outlined),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Volver',
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- Preview del habito ---
            _HabitPreview(
              key: const ValueKey('add-edit-habit-preview'),
              icon: _selectedIcon,
              color: _selectedColor,
              name: _nameController.text.isEmpty
                  ? 'Nombre del habito'
                  : _nameController.text,
            ),
            const SizedBox(height: 20),

            // --- Nombre ---
            Semantics(
              label: 'Nombre del habito',
              textField: true,
              child: TextFormField(
                key: const ValueKey('add-edit-habit-name-field'),
                controller: _nameController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej: Meditar, Leer, Beber agua...',
                  prefixIcon: const Icon(Icons.edit_outlined),
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _selectedColor, width: 2),
                  ),
                ),
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 60,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // --- Selector de icono ---
            _SectionLabel(
              key: const ValueKey('add-edit-habit-icon-label'),
              label: 'Icono',
            ),
            const SizedBox(height: 8),
            Semantics(
              label: 'Seleccionar icono del habito',
              child: _IconPicker(
                key: const ValueKey('add-edit-habit-icon-picker'),
                icons: _availableIcons,
                selected: _selectedIcon,
                activeColor: _selectedColor,
                onSelected: (icon) => setState(() => _selectedIcon = icon),
              ),
            ),
            const SizedBox(height: 16),

            // --- Selector de color ---
            _SectionLabel(
              key: const ValueKey('add-edit-habit-color-label'),
              label: 'Color',
            ),
            const SizedBox(height: 8),
            Semantics(
              label: 'Seleccionar color del habito',
              child: _ColorPicker(
                key: const ValueKey('add-edit-habit-color-picker'),
                colors: _availableColors,
                selected: _selectedColor,
                onSelected: (color) => setState(() => _selectedColor = color),
              ),
            ),
            const SizedBox(height: 16),

            // --- Frecuencia ---
            _SectionLabel(
              key: const ValueKey('add-edit-habit-frequency-label'),
              label: 'Frecuencia',
            ),
            const SizedBox(height: 8),
            Semantics(
              label: 'Selector de frecuencia del habito',
              child: _FrequencySelector(
                key: const ValueKey('add-edit-habit-frequency-selector'),
                selected: _frequency,
                activeColor: _selectedColor,
                onChanged: (f) => setState(() => _frequency = f),
              ),
            ),
            const SizedBox(height: 12),

            // --- Objetivo semanal (solo si weekly) ---
            if (_frequency == _Frequency.weekly) ...[
              _SectionLabel(
                key: const ValueKey('add-edit-habit-weekly-target-label'),
                label: 'Dias por semana',
              ),
              const SizedBox(height: 8),
              Semantics(
                label:
                    'Cantidad de dias por semana: $_weeklyTarget',
                child: _WeeklyTargetSelector(
                  key: const ValueKey(
                      'add-edit-habit-weekly-target-selector'),
                  value: _weeklyTarget,
                  color: _selectedColor,
                  onChanged: (v) => setState(() => _weeklyTarget = v),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // --- Selector de dias (solo si custom) ---
            if (_frequency == _Frequency.custom) ...[
              _SectionLabel(
                key: const ValueKey('add-edit-habit-days-label'),
                label: 'Dias de la semana',
              ),
              const SizedBox(height: 8),
              Semantics(
                label: 'Seleccionar dias de la semana para el habito',
                child: _DayOfWeekSelector(
                  key: const ValueKey('add-edit-habit-days-selector'),
                  selectedDays: _selectedDays,
                  activeColor: _selectedColor,
                  onToggle: (index) {
                    setState(() {
                      if (_selectedDays.contains(index)) {
                        _selectedDays.remove(index);
                      } else {
                        _selectedDays.add(index);
                      }
                    });
                  },
                ),
              ),
              if (_frequency == _Frequency.custom &&
                  _selectedDays.isEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Selecciona al menos un dia',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],

            // --- Toggle habito cuantitativo ---
            Semantics(
              label: 'Activar objetivo cuantitativo',
              toggled: _isQuantitative,
              child: SwitchListTile(
                key: const ValueKey('add-edit-habit-quantitative-toggle'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Habito cuantitativo'),
                subtitle: const Text('Define un objetivo con valor numerico'),
                value: _isQuantitative,
                activeColor: _selectedColor,
                onChanged: (v) => setState(() => _isQuantitative = v),
              ),
            ),

            // --- Campos cuantitativos ---
            if (_isQuantitative) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Semantics(
                      label: 'Valor objetivo del habito',
                      textField: true,
                      child: TextFormField(
                        key: const ValueKey('add-edit-habit-target-field'),
                        controller: _targetController,
                        decoration: InputDecoration(
                          labelText: 'Objetivo',
                          hintText: '0',
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: _selectedColor, width: 2),
                          ),
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d*')),
                        ],
                        validator: (value) {
                          if (!_isQuantitative) return null;
                          if (value == null || value.trim().isEmpty) {
                            return 'Requerido';
                          }
                          final parsed = double.tryParse(value);
                          if (parsed == null || parsed <= 0) {
                            return 'Mayor a 0';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Semantics(
                      label: 'Unidad de medida del objetivo',
                      textField: true,
                      child: TextFormField(
                        key: const ValueKey('add-edit-habit-unit-field'),
                        controller: _unitController,
                        decoration: InputDecoration(
                          labelText: 'Unidad',
                          hintText: 'vasos, min, km...',
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: _selectedColor, width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.none,
                        validator: (value) {
                          if (!_isQuantitative) return null;
                          if (value == null || value.trim().isEmpty) {
                            return 'Requerido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],

            const SizedBox(height: 4),

            // --- Recordatorio ---
            Semantics(
              label: _reminderTime == null
                  ? 'Agregar recordatorio'
                  : 'Recordatorio a las ${_formatTime(_reminderTime!)}',
              button: true,
              child: InkWell(
                key: const ValueKey('add-edit-habit-reminder-picker'),
                onTap: _pickReminderTime,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Recordatorio',
                    prefixIcon: const Icon(Icons.alarm_outlined),
                    suffixIcon: _reminderTime != null
                        ? Semantics(
                            label: 'Quitar recordatorio',
                            button: true,
                            child: IconButton(
                              key: const ValueKey(
                                  'add-edit-habit-reminder-clear'),
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: _clearReminderTime,
                              tooltip: 'Quitar',
                            ),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: _selectedColor, width: 2),
                    ),
                  ),
                  child: Text(
                    _reminderTime == null
                        ? 'Sin recordatorio'
                        : _formatTime(_reminderTime!),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _reminderTime == null
                          ? theme.hintColor
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // --- Auto-completar vinculado a evento ---
            Semantics(
              label: 'Completar automaticamente si hay un evento vinculado',
              toggled: _autoComplete,
              child: SwitchListTile(
                key: const ValueKey('add-edit-habit-autocomplete-toggle'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto-completar'),
                subtitle: const Text(
                    'Se marca automaticamente al completar un evento vinculado'),
                value: _autoComplete,
                activeColor: _selectedColor,
                onChanged: (v) => setState(() => _autoComplete = v),
              ),
            ),
            const SizedBox(height: 24),

            // --- Boton guardar ---
            Semantics(
              label: _isEditing
                  ? 'Guardar cambios del habito'
                  : 'Guardar nuevo habito',
              button: true,
              child: FilledButton.icon(
                key: const ValueKey('add-edit-habit-save-button'),
                style: FilledButton.styleFrom(
                  backgroundColor: _selectedColor,
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: _isSaving ? null : _handleSave,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _isEditing ? 'Guardar cambios' : 'Crear habito',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: preview del habito
// ---------------------------------------------------------------------------

class _HabitPreview extends StatelessWidget {
  const _HabitPreview({
    super.key,
    required this.icon,
    required this.color,
    required this.name,
  });

  final IconData icon;
  final Color color;
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(60), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: name == 'Nombre del habito'
                      ? theme.hintColor
                      : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Vista previa',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
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
// Widget: etiqueta de seccion
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: selector de icono en grid
// TODO: Extract to separate widget file
// ---------------------------------------------------------------------------

class _IconPicker extends StatelessWidget {
  const _IconPicker({
    super.key,
    required this.icons,
    required this.selected,
    required this.activeColor,
    required this.onSelected,
  });

  final List<IconData> icons;
  final IconData selected;
  final Color activeColor;
  final ValueChanged<IconData> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: const ValueKey('habit-icon-grid'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final icon = icons[index];
        final isSelected = icon == selected;
        return Semantics(
          label: 'Icono ${index + 1}',
          selected: isSelected,
          button: true,
          child: GestureDetector(
            key: ValueKey('habit-icon-option-$index'),
            onTap: () => onSelected(icon),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withAlpha(30)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? activeColor
                      : Colors.grey.withAlpha(60),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? activeColor : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: selector de color en paleta
// TODO: Extract to separate widget file
// ---------------------------------------------------------------------------

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    super.key,
    required this.colors,
    required this.selected,
    required this.onSelected,
  });

  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const ValueKey('habit-color-palette'),
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        final isSelected = color.value == selected.value;
        return Semantics(
          label: 'Color ${colors.indexOf(color) + 1}',
          selected: isSelected,
          button: true,
          child: GestureDetector(
            key: ValueKey('habit-color-option-${color.value}'),
            onTap: () => onSelected(color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withAlpha(100),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: selector de frecuencia con chips
// TODO: Extract to separate widget file
// ---------------------------------------------------------------------------

class _FrequencySelector extends StatelessWidget {
  const _FrequencySelector({
    super.key,
    required this.selected,
    required this.activeColor,
    required this.onChanged,
  });

  final _Frequency selected;
  final Color activeColor;
  final ValueChanged<_Frequency> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: _Frequency.values.map((freq) {
        final isSelected = freq == selected;
        return Semantics(
          selected: isSelected,
          button: true,
          label: freq.label,
          child: ChoiceChip(
            key: ValueKey('habit-frequency-chip-${freq.name}'),
            label: Text(freq.label),
            selected: isSelected,
            selectedColor: activeColor.withAlpha(30),
            labelStyle: TextStyle(
              color: isSelected ? activeColor : null,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            side: BorderSide(
              color: isSelected ? activeColor : Colors.grey.withAlpha(80),
              width: isSelected ? 1.5 : 1,
            ),
            onSelected: (_) => onChanged(freq),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: selector de cantidad de dias por semana
// ---------------------------------------------------------------------------

class _WeeklyTargetSelector extends StatelessWidget {
  const _WeeklyTargetSelector({
    super.key,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Semantics(
          label: 'Reducir dias por semana',
          button: true,
          child: IconButton(
            key: const ValueKey('habit-weekly-target-decrease'),
            icon: const Icon(Icons.remove_circle_outline),
            color: value > 1 ? color : theme.disabledColor,
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            tooltip: 'Reducir',
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$value dia${value == 1 ? '' : 's'}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Semantics(
          label: 'Aumentar dias por semana',
          button: true,
          child: IconButton(
            key: const ValueKey('habit-weekly-target-increase'),
            icon: const Icon(Icons.add_circle_outline),
            color: value < 7 ? color : theme.disabledColor,
            onPressed: value < 7 ? () => onChanged(value + 1) : null,
            tooltip: 'Aumentar',
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: selector de dia de la semana
// ---------------------------------------------------------------------------

class _DayOfWeekSelector extends StatelessWidget {
  const _DayOfWeekSelector({
    super.key,
    required this.selectedDays,
    required this.activeColor,
    required this.onToggle,
  });

  final Set<int> selectedDays;
  final Color activeColor;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(_weekDays.length, (index) {
        final isSelected = selectedDays.contains(index);
        return Semantics(
          label: _weekDayLabels[index],
          selected: isSelected,
          button: true,
          child: GestureDetector(
            key: ValueKey('habit-day-chip-$index'),
            onTap: () => onToggle(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? activeColor
                    : activeColor.withAlpha(15),
                border: Border.all(
                  color: isSelected
                      ? activeColor
                      : activeColor.withAlpha(60),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _weekDays[index],
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected ? Colors.white : activeColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
