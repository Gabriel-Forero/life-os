import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/features/finance/domain/finance_input.dart';
import 'package:life_os/l10n/app_localizations.dart';

/// Pantalla de alta/edicion de transaccion.
///
/// Accesibilidad: A11Y-FIN-02 — cada campo tiene etiqueta semantica y
/// teclado numerico para importes.
class AddEditTransactionScreen extends ConsumerStatefulWidget {
  const AddEditTransactionScreen({
    super.key,
    this.transactionId,
  });

  /// Si se proporciona, la pantalla opera en modo edicion.
  final int? transactionId;

  @override
  ConsumerState<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState
    extends ConsumerState<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _type = 'expense';
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  bool get _isEditing => widget.transactionId != null;

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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final notifier = ref.read(financeNotifierProvider);
    final input = TransactionInput(
      type: _type,
      amountCents: int.parse(_amountController.text),
      categoryId: _selectedCategory?.id,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      date: _selectedDate,
    );

    if (_isEditing) {
      await notifier.editTransaction(widget.transactionId!, input);
    } else {
      await notifier.addTransaction(input);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Guardado!')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dao = ref.watch(financeDaoProvider);

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
      body: StreamBuilder<List<Category>>(
        stream: dao.watchCategories(),
        builder: (context, snapshot) {
          final allCategories = snapshot.data ?? [];
          final categoriesForType = allCategories
              .where((c) => c.type == _type || c.type == 'both')
              .toList();

          // Reset selected category if it no longer matches the type
          if (_selectedCategory != null &&
              !categoriesForType.any((c) => c.id == _selectedCategory!.id)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedCategory = null);
            });
          }

          return Form(
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
                        borderSide:
                            BorderSide(color: AppColors.finance, width: 2),
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
                  child: DropdownButtonFormField<Category>(
                    key: const ValueKey('add-edit-tx-category-dropdown'),
                    value: _selectedCategory,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      prefixIcon: Icon(Icons.category_outlined),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.finance, width: 2),
                      ),
                    ),
                    hint: const Text('Seleccionar categoria'),
                    items: categoriesForType
                        .map(
                          (cat) => DropdownMenuItem<Category>(
                            key: ValueKey('category-option-${cat.id}'),
                            value: cat,
                            child: Row(
                              children: [
                                Icon(Icons.label_outline,
                                    size: 18, color: AppColors.finance),
                                const SizedBox(width: 8),
                                Text(cat.name),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (cat) =>
                        setState(() => _selectedCategory = cat),
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
                    onPressed: _isSaving ? null : _handleSave,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      _isSaving ? 'Guardando...' : l10n.commonSave,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
