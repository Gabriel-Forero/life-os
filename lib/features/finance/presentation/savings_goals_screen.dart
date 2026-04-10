import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/widgets/empty_state_view.dart';
import 'package:life_os/features/finance/domain/amount_formatting.dart';
import 'package:life_os/features/finance/domain/finance_input.dart';
import 'package:life_os/features/finance/domain/models/savings_goal_model.dart';
import 'package:life_os/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Pantalla de metas de ahorro
// ---------------------------------------------------------------------------

/// Muestra la lista de metas de ahorro como tarjetas con barras de progreso.
/// Permite agregar nuevas metas (FAB) y contribuir a las existentes.
///
/// Accesibilidad: A11Y-FIN-01 — cada tarjeta de meta tiene Semantics con el
/// estado de progreso, monto acumulado y fecha limite.
class SavingsGoalsScreen extends ConsumerWidget {
  const SavingsGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(financeRepositoryProvider);

    return Scaffold(
      key: const ValueKey('savings-goals-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.finance,
        title: Semantics(
          header: true,
          child: const Text('Metas de ahorro'),
        ),
      ),
      floatingActionButton: Semantics(
        label: 'Agregar nueva meta de ahorro',
        button: true,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (context, value, child) =>
              Transform.scale(scale: value, child: child),
          child: FloatingActionButton(
            key: const ValueKey('savings-add-goal-fab'),
            onPressed: () => _showAddGoalDialog(context, ref),
            backgroundColor: AppColors.finance,
            foregroundColor: Colors.white,
            tooltip: 'Nueva meta',
            child: const Icon(Icons.add),
          ),
        ),
      ),
      body: StreamBuilder<List<SavingsGoalModel>>(
        stream: repo.watchSavingsGoals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final goals = snapshot.data ?? [];
          final completedCount = goals.where((g) => g.isCompleted).length;

          if (goals.isEmpty) {
            return EmptyStateView(
              key: const ValueKey('savings-empty-state'),
              icon: Icons.savings_outlined,
              title: 'Sin metas de ahorro',
              message:
                  'Crea tu primera meta de ahorro para empezar a progresar',
              actionLabel: 'Crear meta',
              actionColor: AppColors.finance,
              onAction: () => _showAddGoalDialog(context, ref),
            );
          }

          final activeGoals = goals.where((g) => !g.isCompleted).toList();
          final completedGoals = goals.where((g) => g.isCompleted).toList();

          return Column(
            children: [
              // Completed chip in a row at top
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Semantics(
                      label: 'Metas completadas: $completedCount de ${goals.length}',
                      child: Chip(
                        key: const ValueKey('savings-completed-chip'),
                        label: Text('$completedCount / ${goals.length}'),
                        avatar: const Icon(Icons.check_circle_outline, size: 16),
                        backgroundColor: AppColors.finance.withAlpha(25),
                        labelStyle: const TextStyle(
                          color: AppColors.finance,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  key: const ValueKey('savings-goals-list'),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  children: [
                    ...activeGoals.map(
                      (goal) => _GoalCard(
                        key: ValueKey('savings-goal-${goal.id}'),
                        goal: goal,
                        onContribute: () =>
                            _showContributeDialog(context, ref, goal),
                      ),
                    ),
                    if (completedGoals.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Semantics(
                          header: true,
                          child: Text(
                            'Completadas',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ),
                      ),
                      ...completedGoals.map(
                        (goal) => _GoalCard(
                          key: ValueKey('savings-goal-${goal.id}'),
                          goal: goal,
                          onContribute: () {},
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _AddGoalDialog(ref: ref),
    );
  }

  void _showContributeDialog(
      BuildContext context, WidgetRef ref, SavingsGoalModel goal) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _ContributeDialog(goal: goal, ref: ref),
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

  final SavingsGoalModel goal;
  final VoidCallback onContribute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = goal.targetCents > 0
        ? (goal.currentCents / goal.targetCents).clamp(0.0, 1.0)
        : 0.0;
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
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: progress),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => LinearProgressIndicator(
                    key: ValueKey('savings-goal-progress-${goal.id}'),
                    value: value,
                    backgroundColor: theme.dividerColor,
                    color: AppColors.finance,
                    minHeight: 8,
                  ),
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
  const _AddGoalDialog({required this.ref});

  final WidgetRef ref;

  @override
  State<_AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<_AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  DateTime? _deadline;
  bool _isSaving = false;

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final notifier = widget.ref.read(financeNotifierProvider);
    await notifier.addSavingsGoal(SavingsGoalInput(
      name: _nameController.text.trim(),
      targetCents: int.parse(_targetController.text),
      deadline: _deadline,
    ));

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Guardado!')));
      Navigator.of(context).pop();
    }
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
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.validationRequired
                      : null,
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
          onPressed: _isSaving ? null : _save,
          child: Text(_isSaving ? 'Guardando...' : l10n.commonSave),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dialogo: contribuir a una meta
// ---------------------------------------------------------------------------

class _ContributeDialog extends StatefulWidget {
  const _ContributeDialog({required this.goal, required this.ref});

  final SavingsGoalModel goal;
  final WidgetRef ref;

  @override
  State<_ContributeDialog> createState() => _ContributeDialogState();
}

class _ContributeDialogState extends State<_ContributeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final notifier = widget.ref.read(financeNotifierProvider);
    await notifier.contributeToGoal(
      widget.goal.id,
      int.parse(_amountController.text),
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
          onPressed: _isSaving ? null : _save,
          child: Text(_isSaving ? 'Contribuyendo...' : 'Contribuir'),
        ),
      ],
    );
  }
}
