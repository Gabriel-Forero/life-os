import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/widgets/empty_state_view.dart';
import 'package:life_os/features/finance/domain/amount_formatting.dart';
import 'package:life_os/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Modelo mock
// ---------------------------------------------------------------------------

class _MockGoal {
  const _MockGoal({
    required this.id,
    required this.name,
    required this.targetCents,
    required this.currentCents,
    required this.isCompleted,
    this.deadline,
  });

  final int id;
  final String name;
  final int targetCents;
  final int currentCents;
  final bool isCompleted;
  final DateTime? deadline;

  double get progress =>
      targetCents > 0 ? (currentCents / targetCents).clamp(0.0, 1.0) : 0.0;
}

final _mockGoals = [
  _MockGoal(
    id: 1,
    name: 'Fondo de emergencia',
    targetCents: 600000000,
    currentCents: 240000000,
    isCompleted: false,
    deadline: DateTime(2025, 12, 31),
  ),
  const _MockGoal(
    id: 2,
    name: 'Viaje a Europa',
    targetCents: 500000000,
    currentCents: 500000000,
    isCompleted: true,
  ),
  _MockGoal(
    id: 3,
    name: 'Computador nuevo',
    targetCents: 400000000,
    currentCents: 80000000,
    isCompleted: false,
    deadline: DateTime(2025, 6, 1),
  ),
];

// ---------------------------------------------------------------------------
// Pantalla de metas de ahorro
// ---------------------------------------------------------------------------

/// Muestra la lista de metas de ahorro como tarjetas con barras de progreso.
/// Permite agregar nuevas metas (FAB) y contribuir a las existentes.
///
/// Shell de presentacion — la integracion con FinanceNotifier y Riverpod se
/// realizara en un paso posterior.
///
/// Accesibilidad: A11Y-FIN-01 — cada tarjeta de meta tiene Semantics con el
/// estado de progreso, monto acumulado y fecha limite.
class SavingsGoalsScreen extends StatelessWidget {
  const SavingsGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final completedCount = _mockGoals.where((g) => g.isCompleted).length;

    return Scaffold(
      key: const ValueKey('savings-goals-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Semantics(
          header: true,
          child: const Text('Metas de ahorro'),
        ),
        actions: [
          Semantics(
            label: 'Metas completadas: $completedCount de ${_mockGoals.length}',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Chip(
                key: const ValueKey('savings-completed-chip'),
                label: Text('$completedCount / ${_mockGoals.length}'),
                avatar: const Icon(Icons.check_circle_outline, size: 16),
                backgroundColor: AppColors.finance.withAlpha(25),
                labelStyle: const TextStyle(
                  color: AppColors.finance,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Semantics(
        label: 'Agregar nueva meta de ahorro',
        button: true,
        child: FloatingActionButton(
          key: const ValueKey('savings-add-goal-fab'),
          onPressed: () {
            // TODO: abrir dialogo cuando se conecte
            _showAddGoalDialog(context);
          },
          backgroundColor: AppColors.finance,
          foregroundColor: Colors.white,
          tooltip: 'Nueva meta',
          child: const Icon(Icons.add),
        ),
      ),
      body: _mockGoals.isEmpty
          ? EmptyStateView(
              key: const ValueKey('savings-empty-state'),
              icon: Icons.savings_outlined,
              title: 'Sin metas de ahorro',
              message:
                  'Crea tu primera meta de ahorro para empezar a progresar',
              actionLabel: 'Crear meta',
              onAction: () {
                // TODO: abrir dialogo cuando se conecte
              },
            )
          : ListView(
              key: const ValueKey('savings-goals-list'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                // Metas activas primero, luego completadas
                ..._mockGoals
                    .where((g) => !g.isCompleted)
                    .map(
                      (goal) => _GoalCard(
                        key: ValueKey('savings-goal-${goal.id}'),
                        goal: goal,
                        onContribute: () => _showContributeDialog(context, goal),
                      ),
                    ),
                if (_mockGoals.any((g) => g.isCompleted)) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Completadas',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ),
                  ),
                  ..._mockGoals
                      .where((g) => g.isCompleted)
                      .map(
                        (goal) => _GoalCard(
                          key: ValueKey('savings-goal-${goal.id}'),
                          goal: goal,
                          onContribute: () {},
                        ),
                      ),
                ],
              ],
            ),
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => const _AddGoalDialog(),
    );
  }

  void _showContributeDialog(BuildContext context, _MockGoal goal) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _ContributeDialog(goal: goal),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de meta de ahorro
// ---------------------------------------------------------------------------

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    super.key,
    required this.goal,
    required this.onContribute,
  });

  final _MockGoal goal;
  final VoidCallback onContribute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = goal.progress;
    final percentage = (progress * 100).round();
    final remaining = goal.targetCents - goal.currentCents;
    final hasDeadline = goal.deadline != null;

    return Semantics(
      label: '${goal.name}: '
          '${goal.currentCents.toCurrency('COP')} de ${goal.targetCents.toCurrency('COP')}, '
          '$percentage%'
          '${goal.isCompleted ? ', completada' : ''}'
          '${hasDeadline ? ', vence ${goal.deadline!.day}/${goal.deadline!.month}/${goal.deadline!.year}' : ''}',
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: goal.isCompleted ? AppColors.finance.withAlpha(15) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.finance.withAlpha(25),
                    child: Icon(
                      goal.isCompleted
                          ? Icons.check_circle
                          : Icons.savings_outlined,
                      color: AppColors.finance,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: theme.textTheme.titleMedium,
                        ),
                        if (hasDeadline)
                          Text(
                            'Vence: ${_formatDate(goal.deadline!)}',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.finance,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Barra de progreso
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  key: ValueKey('savings-goal-progress-${goal.id}'),
                  value: progress,
                  backgroundColor: theme.dividerColor,
                  color: goal.isCompleted ? AppColors.finance : AppColors.finance,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),

              // Montos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${goal.currentCents.toCurrency('COP')} / ${goal.targetCents.toCurrency('COP')}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (!goal.isCompleted)
                    Text(
                      'Faltan ${remaining.toCurrency('COP')}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.finance,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),

              // Boton contribuir
              if (!goal.isCompleted) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Semantics(
                    label: 'Contribuir a la meta ${goal.name}',
                    button: true,
                    child: OutlinedButton.icon(
                      key: ValueKey('savings-contribute-btn-${goal.id}'),
                      onPressed: onContribute,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.finance,
                        side: const BorderSide(color: AppColors.finance),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Contribuir'),
                    ),
                  ),
                ),
              ],
            ],
          ),
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
// Dialogo: agregar nueva meta
// ---------------------------------------------------------------------------

class _AddGoalDialog extends StatefulWidget {
  const _AddGoalDialog();

  @override
  State<_AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<_AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  DateTime? _deadline;

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      helpText: 'Fecha limite',
      cancelText: 'Sin fecha',
      confirmText: 'Aceptar',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.finance),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      key: const ValueKey('add-goal-dialog'),
      title: const Text('Nueva meta de ahorro'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: 'Nombre de la meta',
                textField: true,
                child: TextFormField(
                  key: const ValueKey('add-goal-name-field'),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ej. Fondo de emergencia',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.validationRequired : null,
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'Monto objetivo de la meta',
                textField: true,
                child: TextFormField(
                  key: const ValueKey('add-goal-target-field'),
                  controller: _targetController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Monto objetivo',
                    prefixText: '\$',
                    hintText: '0',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return l10n.validationRequired;
                    final parsed = int.tryParse(v);
                    if (parsed == null || parsed <= 0) {
                      return 'La meta debe ser mayor a \$0';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'Fecha limite (opcional)',
                button: true,
                child: InkWell(
                  key: const ValueKey('add-goal-deadline-picker'),
                  onTap: _pickDeadline,
                  borderRadius: BorderRadius.circular(4),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha limite (opcional)',
                      prefixIcon: Icon(Icons.event_outlined),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _deadline != null
                          ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                          : 'Sin fecha limite',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('add-goal-cancel-button'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const ValueKey('add-goal-save-button'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.finance),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // TODO: llamar a FinanceNotifier.addSavingsGoal cuando se conecte
              Navigator.of(context).pop();
            }
          },
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dialogo: contribuir a una meta
// ---------------------------------------------------------------------------

class _ContributeDialog extends StatefulWidget {
  const _ContributeDialog({required this.goal});

  final _MockGoal goal;

  @override
  State<_ContributeDialog> createState() => _ContributeDialogState();
}

class _ContributeDialogState extends State<_ContributeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      key: const ValueKey('contribute-goal-dialog'),
      title: Text('Contribuir a: ${widget.goal.name}'),
      content: Form(
        key: _formKey,
        child: Semantics(
          label: 'Monto de la contribucion',
          textField: true,
          child: TextFormField(
            key: const ValueKey('contribute-amount-field'),
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
            validator: (v) {
              if (v == null || v.isEmpty) return l10n.validationRequired;
              final parsed = int.tryParse(v);
              if (parsed == null || parsed <= 0) {
                return 'El monto debe ser mayor a \$0';
              }
              return null;
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('contribute-cancel-button'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const ValueKey('contribute-save-button'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.finance),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // TODO: llamar a FinanceNotifier.contributeToGoal cuando se conecte
              Navigator.of(context).pop();
            }
          },
          child: const Text('Contribuir'),
        ),
      ],
    );
  }
}
