import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/widgets/empty_state_view.dart';
import 'package:life_os/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Pantalla de vision general de presupuestos por categoria.
///
/// Muestra una lista de categorias con barras de utilizacion del presupuesto.
/// Al tocar una fila se puede establecer o editar el monto del presupuesto.
///
/// Accesibilidad: A11Y-FIN-01 — cada barra de progreso tiene etiqueta semantica.
class BudgetOverviewScreen extends ConsumerWidget {
  const BudgetOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final theme = Theme.of(context);
    final monthLabel = DateFormat('MMMM yyyy', 'es').format(now);
    final dao = ref.watch(financeDaoProvider);

    return Scaffold(
      key: const ValueKey('budget-overview-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.finance,
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
              onPressed: () => _showSetBudgetDialog(context, ref, null),
              tooltip: 'Nuevo presupuesto',
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Budget>>(
        stream: dao.watchBudgets(now.month, now.year),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final budgets = snapshot.data ?? [];

          if (budgets.isEmpty) {
            return EmptyStateView(
              key: const ValueKey('budget-empty-state'),
              icon: Icons.account_balance_wallet_outlined,
              title: 'Sin presupuestos',
              message:
                  'Define un presupuesto por categoria para controlar tus gastos',
              actionLabel: 'Crear presupuesto',
              actionColor: AppColors.finance,
              onAction: () => _showSetBudgetDialog(context, ref, null),
            );
          }

          final totalBudget =
              budgets.fold<int>(0, (s, b) => s + b.amountCents);

          return FutureBuilder<List<int>>(
            future: Future.wait(
              budgets.map(
                (b) => dao.spentInBudget(b.categoryId, now.month, now.year),
              ),
            ),
            builder: (context, spentSnap) {
              final spentList = spentSnap.data ??
                  List.filled(budgets.length, 0);
              final totalSpent =
                  spentList.fold<int>(0, (s, v) => s + v);

              return ListView(
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
                    totalBudgetCents: totalBudget,
                    totalSpentCents: totalSpent,
                  ),
                  const SizedBox(height: 16),

                  // --- Lista de presupuestos por categoria ---
                  ...List.generate(budgets.length, (i) {
                    final budget = budgets[i];
                    final spent =
                        i < spentList.length ? spentList[i] : 0;
                    return _BudgetCategoryRow(
                      key: ValueKey('budget-row-${budget.id}'),
                      budget: budget,
                      spentCents: spent,
                      onTap: () =>
                          _showSetBudgetDialog(context, ref, budget),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showSetBudgetDialog(
      BuildContext context, WidgetRef ref, Budget? existing) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _SetBudgetDialog(existing: existing, ref: ref),
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
                          color: overBudget
                              ? AppColors.error
                              : AppColors.finance,
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
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: utilization),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => LinearProgressIndicator(
                    key: const ValueKey('budget-total-bar'),
                    value: value,
                    minHeight: 8,
                    backgroundColor: theme.dividerColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      overBudget ? AppColors.error : AppColors.finance,
                    ),
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
    required this.spentCents,
    required this.onTap,
  });

  final Budget budget;
  final int spentCents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat('#,##0', 'es_CO');
    final utilization = budget.amountCents > 0
        ? (spentCents / budget.amountCents).clamp(0.0, 1.0)
        : 0.0;
    final pct = (utilization * 100).round();
    final isOverBudget = spentCents > budget.amountCents;
    final barColor = isOverBudget
        ? AppColors.error
        : utilization >= 0.8
            ? AppColors.warning
            : AppColors.finance;

    return Semantics(
      label: '${budget.categoryId}: $pct% del presupuesto utilizado. '
          'Gastado \$${formatter.format(spentCents)} '
          'de \$${formatter.format(budget.amountCents)}. '
          'Toca para editar.',
      button: true,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          key: ValueKey('budget-row-tap-${budget.id}'),
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
                      child:
                          Icon(Icons.label_outline, size: 18, color: barColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Categoria #${budget.categoryId}',
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            budget.amountCents > 0
                                ? '\$${formatter.format(spentCents)} / \$${formatter.format(budget.amountCents)}'
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
                        if (isOverBudget)
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
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: utilization),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: theme.dividerColor,
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    ),
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
  const _SetBudgetDialog({this.existing, required this.ref});

  final Budget? existing;
  final WidgetRef ref;

  @override
  State<_SetBudgetDialog> createState() => _SetBudgetDialogState();
}

class _SetBudgetDialogState extends State<_SetBudgetDialog> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null && widget.existing!.amountCents > 0) {
      _amountController.text = widget.existing!.amountCents.toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final now = DateTime.now();
    final notifier = widget.ref.read(financeNotifierProvider);
    final categoryId =
        widget.existing?.categoryId ?? 1; // fallback to first category

    await notifier.setBudget(
      categoryId: categoryId,
      amountCents: int.parse(_amountController.text),
      month: now.month,
      year: now.year,
    );

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Guardado!')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.existing != null
        ? 'Editar presupuesto'
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
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Monto',
              prefixText: '\$',
              hintText: '0',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.validationRequired;
              }
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
          onPressed: _isSaving ? null : _save,
          child: Text(_isSaving ? 'Guardando...' : l10n.commonSave),
        ),
      ],
    );
  }
}
