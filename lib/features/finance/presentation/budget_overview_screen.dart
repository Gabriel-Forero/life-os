import 'package:flutter/material.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/widgets/empty_state_view.dart';
import 'package:life_os/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Datos de presupuesto de ejemplo hasta que Riverpod este conectado.
class _MockBudget {
  const _MockBudget({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.budgetCents,
    required this.spentCents,
  });

  final int categoryId;
  final String categoryName;
  final IconData categoryIcon;
  final int budgetCents;
  final int spentCents;

  double get utilization =>
      budgetCents > 0 ? (spentCents / budgetCents).clamp(0.0, 1.0) : 0.0;

  bool get isOverBudget => spentCents > budgetCents;
}

const _mockBudgets = [
  _MockBudget(
    categoryId: 1,
    categoryName: 'Alimentacion',
    categoryIcon: Icons.restaurant,
    budgetCents: 60000000,
    spentCents: 45000000,
  ),
  _MockBudget(
    categoryId: 2,
    categoryName: 'Transporte',
    categoryIcon: Icons.directions_car_outlined,
    budgetCents: 20000000,
    spentCents: 21500000,
  ),
  _MockBudget(
    categoryId: 3,
    categoryName: 'Entretenimiento',
    categoryIcon: Icons.movie_outlined,
    budgetCents: 15000000,
    spentCents: 8000000,
  ),
  _MockBudget(
    categoryId: 4,
    categoryName: 'Salud',
    categoryIcon: Icons.local_hospital_outlined,
    budgetCents: 10000000,
    spentCents: 0,
  ),
];

/// Pantalla de vision general de presupuestos por categoria.
///
/// Muestra una lista de categorias con barras de utilizacion del presupuesto.
/// Al tocar una fila se puede establecer o editar el monto del presupuesto.
///
/// Es un shell de presentacion. La integracion con FinanceNotifier y los
/// providers de Riverpod se realizara en un paso posterior.
///
/// Accesibilidad: A11Y-FIN-01 — cada barra de progreso tiene etiqueta semantica.
class BudgetOverviewScreen extends StatelessWidget {
  const BudgetOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final monthLabel = DateFormat('MMMM yyyy', 'es').format(now);

    return Scaffold(
      key: const ValueKey('budget-overview-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Semantics(
          header: true,
          child: const Text('Presupuestos'),
        ),
        actions: [
          Semantics(
            label: 'Agregar presupuesto de categoria',
            button: true,
            child: IconButton(
              key: const ValueKey('budget-add-button'),
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                // TODO: abrir dialogo de nueva categoria/presupuesto cuando se conecte
                _showSetBudgetDialog(context, null);
              },
              tooltip: 'Nuevo presupuesto',
            ),
          ),
        ],
      ),
      body: _mockBudgets.isEmpty
          ? EmptyStateView(
              key: const ValueKey('budget-empty-state'),
              icon: Icons.account_balance_wallet_outlined,
              title: 'Sin presupuestos',
              message:
                  'Define un presupuesto por categoria para controlar tus gastos',
              actionLabel: 'Crear presupuesto',
              onAction: () {
                // TODO: abrir dialogo cuando se conecte
              },
            )
          : ListView(
              key: const ValueKey('budget-list'),
              padding: const EdgeInsets.all(16),
              children: [
                // --- Encabezado del mes ---
                Semantics(
                  header: true,
                  child: Text(
                    monthLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // --- Resumen total ---
                _BudgetSummaryCard(
                  key: const ValueKey('budget-summary-card'),
                  totalBudgetCents: _mockBudgets.fold(
                    0,
                    (sum, b) => sum + b.budgetCents,
                  ),
                  totalSpentCents: _mockBudgets.fold(
                    0,
                    (sum, b) => sum + b.spentCents,
                  ),
                ),
                const SizedBox(height: 16),

                // --- Lista de presupuestos por categoria ---
                ..._mockBudgets.map(
                  (budget) => _BudgetCategoryRow(
                    key: ValueKey('budget-row-${budget.categoryId}'),
                    budget: budget,
                    onTap: () => _showSetBudgetDialog(context, budget),
                  ),
                ),
              ],
            ),
    );
  }

  void _showSetBudgetDialog(BuildContext context, _MockBudget? existing) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _SetBudgetDialog(existing: existing),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de resumen total
// ---------------------------------------------------------------------------

class _BudgetSummaryCard extends StatelessWidget {
  const _BudgetSummaryCard({
    super.key,
    required this.totalBudgetCents,
    required this.totalSpentCents,
  });

  final int totalBudgetCents;
  final int totalSpentCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat('#,##0', 'es_CO');
    final remaining = totalBudgetCents - totalSpentCents;
    final utilization = totalBudgetCents > 0
        ? (totalSpentCents / totalBudgetCents).clamp(0.0, 1.0)
        : 0.0;
    final overBudget = totalSpentCents > totalBudgetCents;

    return Semantics(
      label:
          'Resumen: gastado \$${formatter.format(totalSpentCents)} de \$${formatter.format(totalBudgetCents)}',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total del mes',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${formatter.format(totalSpentCents)}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: overBudget ? AppColors.error : null,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'de \$${formatter.format(totalBudgetCents)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        overBudget
                            ? 'Excedido'
                            : '\$${formatter.format(remaining)} restante',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: overBudget ? AppColors.error : AppColors.finance,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(utilization * 100).round()}% utilizado',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  key: const ValueKey('budget-total-bar'),
                  value: utilization,
                  minHeight: 8,
                  backgroundColor: theme.dividerColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    overBudget ? AppColors.error : AppColors.finance,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fila de presupuesto por categoria
// ---------------------------------------------------------------------------

class _BudgetCategoryRow extends StatelessWidget {
  const _BudgetCategoryRow({
    super.key,
    required this.budget,
    required this.onTap,
  });

  final _MockBudget budget;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat('#,##0', 'es_CO');
    final utilization = budget.utilization;
    final pct = (utilization * 100).round();
    final barColor = budget.isOverBudget
        ? AppColors.error
        : utilization >= 0.8
            ? AppColors.warning
            : AppColors.finance;

    return Semantics(
      label:
          '${budget.categoryName}: $pct% del presupuesto utilizado. '
          'Gastado \$${formatter.format(budget.spentCents)} '
          'de \$${formatter.format(budget.budgetCents)}. '
          'Toca para editar.',
      button: true,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          key: ValueKey('budget-row-tap-${budget.categoryId}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: barColor.withAlpha(25),
                      child: Icon(budget.categoryIcon, size: 18, color: barColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            budget.categoryName,
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            budget.budgetCents > 0
                                ? '\$${formatter.format(budget.spentCents)} / \$${formatter.format(budget.budgetCents)}'
                                : 'Sin presupuesto definido',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$pct%',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: barColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (budget.isOverBudget)
                          Text(
                            'Excedido',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: utilization,
                    minHeight: 6,
                    backgroundColor: theme.dividerColor,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
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

// ---------------------------------------------------------------------------
// Dialogo para establecer / editar presupuesto
// ---------------------------------------------------------------------------

class _SetBudgetDialog extends StatefulWidget {
  const _SetBudgetDialog({this.existing});

  final _MockBudget? existing;

  @override
  State<_SetBudgetDialog> createState() => _SetBudgetDialogState();
}

class _SetBudgetDialogState extends State<_SetBudgetDialog> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.existing != null && widget.existing!.budgetCents > 0) {
      _amountController.text = widget.existing!.budgetCents.toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.existing != null
        ? 'Editar presupuesto: ${widget.existing!.categoryName}'
        : 'Nuevo presupuesto';

    return AlertDialog(
      key: const ValueKey('set-budget-dialog'),
      title: Text(title),
      content: Form(
        key: _formKey,
        child: Semantics(
          label: 'Monto del presupuesto',
          textField: true,
          child: TextFormField(
            key: const ValueKey('set-budget-amount-field'),
            controller: _amountController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Monto',
              prefixText: '\$',
              hintText: '0',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return l10n.validationRequired;
              final parsed = int.tryParse(value);
              if (parsed == null || parsed <= 0) {
                return 'El presupuesto debe ser mayor a \$0';
              }
              return null;
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('set-budget-cancel-button'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const ValueKey('set-budget-save-button'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.finance),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // TODO: llamar a FinanceNotifier.setBudget cuando se conecte
              Navigator.of(context).pop();
            }
          },
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
