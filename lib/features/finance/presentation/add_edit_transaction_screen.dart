import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/l10n/app_localizations.dart';

/// Categorias de ejemplo usadas como placeholder hasta que el notifier sea conectado.
class _MockCategory {
  const _MockCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
  });

  final int id;
  final String name;
  final IconData icon;
  final String type;
}

const _expenseCategories = [
  _MockCategory(id: 1, name: 'Alimentacion', icon: Icons.restaurant, type: 'expense'),
  _MockCategory(id: 2, name: 'Transporte', icon: Icons.directions_car_outlined, type: 'expense'),
  _MockCategory(id: 3, name: 'Entretenimiento', icon: Icons.movie_outlined, type: 'expense'),
  _MockCategory(id: 4, name: 'Salud', icon: Icons.local_hospital_outlined, type: 'expense'),
  _MockCategory(id: 5, name: 'Hogar', icon: Icons.home_outlined, type: 'expense'),
  _MockCategory(id: 6, name: 'Educacion', icon: Icons.school_outlined, type: 'expense'),
  _MockCategory(id: 7, name: 'Ropa', icon: Icons.checkroom_outlined, type: 'expense'),
  _MockCategory(id: 8, name: 'Otros', icon: Icons.category_outlined, type: 'expense'),
];

const _incomeCategories = [
  _MockCategory(id: 9, name: 'Salario', icon: Icons.payments_outlined, type: 'income'),
  _MockCategory(id: 10, name: 'Freelance', icon: Icons.work_outline, type: 'income'),
  _MockCategory(id: 11, name: 'Inversiones', icon: Icons.account_balance_outlined, type: 'income'),
  _MockCategory(id: 12, name: 'General', icon: Icons.receipt_long_outlined, type: 'income'),
];

/// Pantalla de alta/edicion de transaccion.
///
/// Es un shell de presentacion. La integracion con FinanceNotifier y los
/// providers de Riverpod se realizara en un paso posterior.
///
/// Accesibilidad: A11Y-FIN-02 — cada campo tiene etiqueta semantica y
/// teclado numerico para importes.
class AddEditTransactionScreen extends StatefulWidget {
  const AddEditTransactionScreen({
    super.key,
    this.transactionId,
  });

  /// Si se proporciona, la pantalla opera en modo edicion.
  final int? transactionId;

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _type = 'expense';
  _MockCategory? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  bool get _isEditing => widget.transactionId != null;

  List<_MockCategory> get _categoriesForType =>
      _type == 'expense' ? _expenseCategories : _incomeCategories;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleTypeChange(String newType) {
    if (newType == _type) return;
    setState(() {
      _type = newType;
      _selectedCategory = null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Seleccionar fecha',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.finance,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;
    // TODO: Conectar con FinanceNotifier.addTransaction / editTransaction
    // cuando se realice la integracion de Riverpod.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      key: const ValueKey('add-edit-transaction-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Semantics(
          header: true,
          child: Text(
            _isEditing ? 'Editar transaccion' : 'Nueva transaccion',
          ),
        ),
        leading: Semantics(
          label: 'Volver',
          button: true,
          child: IconButton(
            key: const ValueKey('add-edit-tx-back-button'),
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
            // --- Selector tipo: Ingreso / Gasto ---
            Semantics(
              label: 'Tipo de transaccion',
              child: _TypeToggle(
                key: const ValueKey('add-edit-tx-type-toggle'),
                selectedType: _type,
                onChanged: _handleTypeChange,
              ),
            ),
            const SizedBox(height: 20),

            // --- Importe ---
            Semantics(
              label: 'Monto de la transaccion',
              textField: true,
              child: TextFormField(
                key: const ValueKey('add-edit-tx-amount-field'),
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                  signed: false,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  hintText: '0',
                  prefixIcon: Icon(Icons.attach_money_outlined),
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.finance, width: 2),
                  ),
                ),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: _type == 'expense'
                      ? AppColors.error
                      : AppColors.finance,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.validationRequired;
                  }
                  final parsed = int.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return 'El monto debe ser mayor a \$0';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // --- Categoria ---
            Semantics(
              label: 'Categoria de la transaccion',
              child: DropdownButtonFormField<_MockCategory>(
                key: const ValueKey('add-edit-tx-category-dropdown'),
                initialValue: _selectedCategory,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Categoria',
                  prefixIcon: Icon(
                    _selectedCategory?.icon ?? Icons.category_outlined,
                  ),
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.finance, width: 2),
                  ),
                ),
                hint: const Text('Seleccionar categoria'),
                items: _categoriesForType
                    .map(
                      (cat) => DropdownMenuItem<_MockCategory>(
                        key: ValueKey('category-option-${cat.id}'),
                        value: cat,
                        child: Row(
                          children: [
                            Icon(cat.icon, size: 18, color: AppColors.finance),
                            const SizedBox(width: 8),
                            Text(cat.name),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (cat) => setState(() => _selectedCategory = cat),
                validator: (value) {
                  if (value == null) return l10n.validationRequired;
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // --- Fecha ---
            Semantics(
              label: 'Fecha de la transaccion',
              button: true,
              child: InkWell(
                key: const ValueKey('add-edit-tx-date-picker'),
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: AppColors.finance, width: 2),
                    ),
                  ),
                  child: Text(
                    _formatDate(_selectedDate),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Nota (opcional) ---
            Semantics(
              label: 'Nota opcional para la transaccion',
              textField: true,
              child: TextFormField(
                key: const ValueKey('add-edit-tx-note-field'),
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Nota (opcional)',
                  hintText: 'Agrega un detalle...',
                  prefixIcon: Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(),
                ),
                maxLength: 200,
                maxLines: 2,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value != null && value.length > 200) {
                    return l10n.validationMaxLength(200);
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),

            // --- Boton guardar ---
            Semantics(
              label: _isEditing
                  ? 'Guardar cambios de transaccion'
                  : 'Guardar nueva transaccion',
              button: true,
              child: FilledButton.icon(
                key: const ValueKey('add-edit-tx-save-button'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.finance,
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: _handleSave,
                icon: const Icon(Icons.check),
                label: Text(
                  l10n.commonSave,
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

  String _formatDate(DateTime date) {
    final months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ---------------------------------------------------------------------------
// Widget privado: toggle Ingreso / Gasto
// ---------------------------------------------------------------------------

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  final String selectedType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TypeButton(
            key: const ValueKey('type-toggle-expense'),
            label: 'Gasto',
            icon: Icons.arrow_downward_rounded,
            isSelected: selectedType == 'expense',
            selectedColor: AppColors.error,
            onTap: () => onChanged('expense'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TypeButton(
            key: const ValueKey('type-toggle-income'),
            label: 'Ingreso',
            icon: Icons.arrow_upward_rounded,
            isSelected: selectedType == 'income',
            selectedColor: AppColors.finance,
            onTap: () => onChanged('income'),
          ),
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      selected: isSelected,
      button: true,
      label: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withAlpha(30) : Colors.transparent,
          border: Border.all(
            color: isSelected ? selectedColor : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? selectedColor : theme.iconTheme.color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isSelected ? selectedColor : null,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
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
