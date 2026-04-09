import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/constants/app_decorations.dart';
import 'package:life_os/core/constants/app_typography.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/router/app_router.dart';
import 'package:life_os/features/finance/domain/finance_input.dart';

// ---------------------------------------------------------------------------
// Budget Wizard — guided budget creation in 3 modules
// ---------------------------------------------------------------------------

/// Multi-step budget wizard: Income → Expenses → Savings → Summary.
///
/// Each module collects entries, validates totals, and shows a per-module
/// summary before advancing. The final summary compares against the
/// 50/30/20 rule and flags warnings (debt > 30%, savings < 10%).
class BudgetWizardScreen extends ConsumerStatefulWidget {
  const BudgetWizardScreen({super.key});

  @override
  ConsumerState<BudgetWizardScreen> createState() => _BudgetWizardScreenState();
}

class _BudgetWizardScreenState extends ConsumerState<BudgetWizardScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // ── Income state ────────────────────────────────────────────────────────
  final _salaryController = TextEditingController();
  final List<_IncomeEntry> _extraIncomes = [];

  // ── Expense state ───────────────────────────────────────────────────────
  final List<_ExpenseEntry> _fixedExpenses = [
    _ExpenseEntry('Arriendo / vivienda', Icons.home_outlined),
    _ExpenseEntry('Servicios publicos', Icons.receipt_long_outlined),
    _ExpenseEntry('Transporte fijo', Icons.directions_car_outlined),
    _ExpenseEntry('Seguros', Icons.shield_outlined),
    _ExpenseEntry('Cuotas de credito / deudas', Icons.credit_card_outlined),
  ];
  final List<_ExpenseEntry> _variableExpenses = [
    _ExpenseEntry('Mercado / alimentacion', Icons.restaurant_outlined),
    _ExpenseEntry('Salidas y entretenimiento', Icons.movie_outlined),
    _ExpenseEntry('Ropa y cuidado personal', Icons.checkroom_outlined),
    _ExpenseEntry('Salud', Icons.local_hospital_outlined),
    _ExpenseEntry('Educacion / cursos', Icons.school_outlined),
    _ExpenseEntry('Otros', Icons.more_horiz_outlined),
  ];

  // ── Savings state ───────────────────────────────────────────────────────
  final _emergencyGoalController = TextEditingController();
  final _emergencyMonthlyController = TextEditingController();
  final List<_SavingsGoalEntry> _savingsGoals = [];
  final List<_InvestmentEntry> _investments = [];

  // ── Carry-over from previous month ───────────────────────────────────────
  final _ahorroAnteriorController = TextEditingController();
  bool _ahorroManuallyEdited = false;

  // ── Saving state ────────────────────────────────────────────────────────
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreviousMonthAhorro();
  }

  Future<void> _loadPreviousMonthAhorro() async {
    final now = DateTime.now();
    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    final prevYear = now.month == 1 ? now.year - 1 : now.year;
    final dao = ref.read(financeDaoProvider);

    // Calculate previous month: income - expenses - investments
    final from = DateTime(prevYear, prevMonth);
    final to = DateTime(prevYear, prevMonth + 1, 0, 23, 59, 59);
    final income = await dao.sumByType('income', from, to);
    final expenses = await dao.sumByType('expense', from, to);
    // Investments are tracked as expenses in savings-related categories
    // For now, use: ahorro = income - expenses (net leftover)
    final ahorro = income - expenses;
    if (mounted && !_ahorroManuallyEdited) {
      final value = ahorro > 0 ? ahorro : 0;
      _ahorroAnteriorController.text = value > 0 ? value.toString() : '';
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _salaryController.dispose();
    _ahorroAnteriorController.dispose();
    _emergencyGoalController.dispose();
    _emergencyMonthlyController.dispose();
    for (final e in _extraIncomes) {
      e.dispose();
    }
    for (final e in _fixedExpenses) {
      e.dispose();
    }
    for (final e in _variableExpenses) {
      e.dispose();
    }
    for (final g in _savingsGoals) {
      g.dispose();
    }
    for (final i in _investments) {
      i.dispose();
    }
    super.dispose();
  }

  // ── Computed totals ─────────────────────────────────────────────────────

  int get _salary => _parseCents(_salaryController.text);

  int get _totalExtraIncome =>
      _extraIncomes.fold(0, (sum, e) => sum + e.monthlyCents);

  int get _totalIncome => _salary + _totalExtraIncome;

  int get _totalFixedExpenses =>
      _fixedExpenses.fold(0, (sum, e) => sum + e.cents);

  int get _totalVariableExpenses =>
      _variableExpenses.fold(0, (sum, e) => sum + e.cents);

  int get _totalExpenses => _totalFixedExpenses + _totalVariableExpenses;

  int get _debtPayments {
    // The last fixed expense is "Cuotas de credito / deudas"
    return _fixedExpenses.last.cents;
  }

  int get _emergencyMonthly => _parseCents(_emergencyMonthlyController.text);

  int get _totalSavingsGoals =>
      _savingsGoals.fold(0, (sum, g) => sum + g.monthlyCents);

  int get _totalInvestments =>
      _investments.fold(0, (sum, i) => sum + i.monthlyCents);

  int get _totalSavings =>
      _emergencyMonthly + _totalSavingsGoals + _totalInvestments;

  /// Ahorro disponible = lo que sobra del mes (ingresos - gastos - inversiones)
  int get _ahorroDisponible =>
      _totalIncome - _totalExpenses - _totalSavings;

  int get _previousMonthAhorro => _parseCents(_ahorroAnteriorController.text);

  /// Total disponible este mes = ingresos + ahorro del mes anterior
  int get _totalDisponible => _totalIncome + _previousMonthAhorro;

  double get _expensePercent =>
      _totalDisponible > 0 ? _totalExpenses / _totalDisponible * 100 : 0;

  double get _savingsPercent =>
      _totalDisponible > 0 ? _totalSavings / _totalDisponible * 100 : 0;

  double get _debtPercent =>
      _totalDisponible > 0 ? _debtPayments / _totalDisponible * 100 : 0;

  // ── Navigation ──────────────────────────────────────────────────────────

  void _goToPage(int page) {
    setState(() => _currentPage = page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    if (_currentPage < 4) _goToPage(_currentPage + 1);
  }

  void _back() {
    if (_currentPage > 0) _goToPage(_currentPage - 1);
  }

  // ── Persistence ─────────────────────────────────────────────────────────

  Future<void> _saveBudget() async {
    setState(() => _isSaving = true);

    final now = DateTime.now();
    final month = now.month;
    final year = now.year;
    final notifier = ref.read(financeNotifierProvider);
    final dao = ref.read(financeDaoProvider);

    try {
      // Map expenses to categories and create budgets
      final expenseMappings = <String, int>{
        'Hogar': _fixedExpenses[0].cents, // Arriendo
        'Servicios': _fixedExpenses[1].cents, // Servicios publicos
        'Transporte': _fixedExpenses[2].cents, // Transporte fijo
        // Seguros and deudas go to Otros if no dedicated category
      };

      // Variable expense mappings
      final variableMappings = <String, int>{
        'Alimentacion': _variableExpenses[0].cents,
        'Entretenimiento': _variableExpenses[1].cents,
        'Ropa': _variableExpenses[2].cents,
        'Salud': _variableExpenses[3].cents,
        'Educacion': _variableExpenses[4].cents,
        'Otros': _variableExpenses[5].cents,
      };

      // Combine fixed leftovers into "Otros"
      final seguros = _fixedExpenses[3].cents;
      final deudas = _fixedExpenses[4].cents;
      variableMappings['Otros'] =
          (variableMappings['Otros'] ?? 0) + seguros + deudas;

      // Merge all
      final allMappings = {...expenseMappings, ...variableMappings};

      for (final entry in allMappings.entries) {
        if (entry.value <= 0) continue;
        final cat = await dao.getCategoryByName(entry.key);
        if (cat == null) continue;
        await notifier.setBudget(
          categoryId: cat.id,
          amountCents: entry.value,
          month: month,
          year: year,
        );
      }

      // Create savings goals
      for (final goal in _savingsGoals) {
        if (goal.name.isEmpty || goal.targetCents <= 0) continue;
        await notifier.addSavingsGoal(SavingsGoalInput(
          name: goal.name,
          targetCents: goal.targetCents,
          deadline: goal.deadline,
        ));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Presupuesto guardado exitosamente')),
      );
      GoRouter.of(context).go(AppRoutes.financeBudgets);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente de Presupuesto'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => GoRouter.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Step indicator
          _StepIndicator(
            currentStep: _currentPage,
            onStepTapped: _goToPage,
          ),
          // Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                _MenuPage(onSelected: _goToPage),
                _IncomePage(
                  salaryController: _salaryController,
                  extraIncomes: _extraIncomes,
                  totalIncome: _totalIncome,
                  onAddExtra: () => setState(() {
                    _extraIncomes.add(_IncomeEntry());
                  }),
                  onRemoveExtra: (i) => setState(() {
                    _extraIncomes[i].dispose();
                    _extraIncomes.removeAt(i);
                  }),
                  onChanged: () => setState(() {}),
                ),
                _ExpensesPage(
                  fixedExpenses: _fixedExpenses,
                  variableExpenses: _variableExpenses,
                  totalExpenses: _totalExpenses,
                  totalFixedExpenses: _totalFixedExpenses,
                  totalVariableExpenses: _totalVariableExpenses,
                  totalIncome: _totalIncome,
                  onChanged: () => setState(() {}),
                ),
                _SavingsPage(
                  emergencyGoalController: _emergencyGoalController,
                  emergencyMonthlyController: _emergencyMonthlyController,
                  savingsGoals: _savingsGoals,
                  investments: _investments,
                  totalSavings: _totalSavings,
                  totalIncome: _totalIncome,
                  onAddGoal: () => setState(() {
                    _savingsGoals.add(_SavingsGoalEntry());
                  }),
                  onRemoveGoal: (i) => setState(() {
                    _savingsGoals[i].dispose();
                    _savingsGoals.removeAt(i);
                  }),
                  onAddInvestment: () => setState(() {
                    _investments.add(_InvestmentEntry());
                  }),
                  onRemoveInvestment: (i) => setState(() {
                    _investments[i].dispose();
                    _investments.removeAt(i);
                  }),
                  onChanged: () => setState(() {}),
                ),
                _SummaryPage(
                  totalIncome: _totalIncome,
                  totalExpenses: _totalExpenses,
                  totalFixedExpenses: _totalFixedExpenses,
                  totalVariableExpenses: _totalVariableExpenses,
                  totalSavings: _totalSavings,
                  ahorroDisponible: _ahorroDisponible,
                  previousMonthAhorro: _previousMonthAhorro,
                  ahorroAnteriorController: _ahorroAnteriorController,
                  totalDisponible: _totalDisponible,
                  expensePercent: _expensePercent,
                  savingsPercent: _savingsPercent,
                  debtPercent: _debtPercent,
                  isSaving: _isSaving,
                  onSave: _saveBudget,
                  onAhorroChanged: () {
                    _ahorroManuallyEdited = true;
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          // Bottom nav bar
          if (_currentPage > 0)
            _BottomNav(
              currentPage: _currentPage,
              onBack: _back,
              onNext: _currentPage < 4 ? _next : null,
            ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Step Indicator
// ===========================================================================

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.onStepTapped});

  final int currentStep;
  final ValueChanged<int> onStepTapped;

  static const _labels = ['Menu', 'Ingresos', 'Gastos', 'Ahorro', 'Resumen'];
  static const _icons = [
    Icons.menu_rounded,
    Icons.trending_up_rounded,
    Icons.trending_down_rounded,
    Icons.savings_outlined,
    Icons.summarize_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderColor(brightness)),
        ),
      ),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final isActive = i == currentStep;
          final isDone = i < currentStep;
          final color = isActive
              ? AppColors.finance
              : isDone
                  ? AppColors.finance.withAlpha(120)
                  : AppColors.textSecondary(brightness);

          return Expanded(
            child: GestureDetector(
              onTap: () => onStepTapped(i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.finance.withAlpha(20)
                          : isDone
                              ? AppColors.finance.withAlpha(10)
                              : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withAlpha(isActive ? 100 : 40),
                        width: isActive ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      isDone ? Icons.check_rounded : _icons[i],
                      size: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _labels[i],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ===========================================================================
// Bottom Navigation
// ===========================================================================

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.currentPage,
    required this.onBack,
    this.onNext,
  });

  final int currentPage;
  final VoidCallback onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(brightness),
        border: Border(
          top: BorderSide(color: AppColors.borderColor(brightness)),
        ),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Atras'),
          ),
          const Spacer(),
          if (onNext != null)
            FilledButton.icon(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.finance,
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Siguiente'),
            ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Page 0: Menu
// ===========================================================================

class _MenuPage extends StatelessWidget {
  const _MenuPage({required this.onSelected});

  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final theme = Theme.of(context);

    final options = [
      _MenuOption(
        icon: Icons.add_chart_rounded,
        title: 'Crear nuevo presupuesto completo',
        subtitle: 'Ingresos, gastos y ahorro paso a paso',
        color: AppColors.finance,
        onTap: () => onSelected(1),
      ),
      _MenuOption(
        icon: Icons.trending_up_rounded,
        title: 'Presupuesto de Ingresos',
        subtitle: 'Salario, freelance, ingresos extra',
        color: const Color(0xFF10B981),
        onTap: () => onSelected(1),
      ),
      _MenuOption(
        icon: Icons.trending_down_rounded,
        title: 'Presupuesto de Gastos',
        subtitle: 'Gastos fijos y variables',
        color: const Color(0xFFEF4444),
        onTap: () => onSelected(2),
      ),
      _MenuOption(
        icon: Icons.savings_outlined,
        title: 'Ahorro e Inversion',
        subtitle: 'Fondo de emergencia, metas, inversiones',
        color: const Color(0xFF3B82F6),
        onTap: () => onSelected(3),
      ),
      _MenuOption(
        icon: Icons.summarize_outlined,
        title: 'Ver resumen general',
        subtitle: 'Balance, alertas y recomendaciones',
        color: const Color(0xFF8B5CF6),
        onTap: () => onSelected(4),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 8),
        Text(
          'Que quieres hacer?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Selecciona una opcion para comenzar',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary(brightness),
          ),
        ),
        const SizedBox(height: 20),
        ...options.map((o) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MenuOptionCard(option: o),
            )),
      ],
    );
  }
}

class _MenuOption {
  const _MenuOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
}

class _MenuOptionCard extends StatelessWidget {
  const _MenuOptionCard({required this.option});

  final _MenuOption option;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Semantics(
      label: option.title,
      button: true,
      child: InkWell(
        onTap: option.onTap,
        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
        child: Container(
          decoration: AppDecorations.moduleCard(brightness, accent: option.color),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: option.color.withAlpha(isDark ? 25 : 15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(option.icon, color: option.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary(brightness),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary(brightness),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Page 1: Ingresos (Income)
// ===========================================================================

class _IncomePage extends StatelessWidget {
  const _IncomePage({
    required this.salaryController,
    required this.extraIncomes,
    required this.totalIncome,
    required this.onAddExtra,
    required this.onRemoveExtra,
    required this.onChanged,
  });

  final TextEditingController salaryController;
  final List<_IncomeEntry> extraIncomes;
  final int totalIncome;
  final VoidCallback onAddExtra;
  final ValueChanged<int> onRemoveExtra;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionHeader(
          icon: Icons.trending_up_rounded,
          title: 'Ingresos',
          color: const Color(0xFF10B981),
        ),
        const SizedBox(height: 16),

        // Salary
        Text('Salario neto mensual',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _AmountField(
          controller: salaryController,
          hint: '0',
          prefix: '\$',
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 24),

        // Extra incomes
        Row(
          children: [
            Expanded(
              child: Text('Ingresos variables o extra',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            TextButton.icon(
              onPressed: onAddExtra,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Agregar'),
              style: TextButton.styleFrom(foregroundColor: AppColors.finance),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (extraIncomes.isEmpty)
          Text(
            'Sin ingresos extra. Toca "Agregar" para incluir freelance, arriendos, bonos, etc.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary(brightness),
            ),
          ),

        ...List.generate(extraIncomes.length, (i) {
          final entry = extraIncomes[i];
          return _ExtraIncomeRow(
            key: ValueKey('extra-income-$i'),
            entry: entry,
            onRemove: () => onRemoveExtra(i),
            onChanged: onChanged,
          );
        }),

        const SizedBox(height: 24),

        // Module summary
        _ModuleSummary(
          label: 'INGRESO TOTAL MENSUAL',
          amountCents: totalIncome,
          color: const Color(0xFF10B981),
        ),
      ],
    );
  }
}

class _ExtraIncomeRow extends StatelessWidget {
  const _ExtraIncomeRow({
    super.key,
    required this.entry,
    required this.onRemove,
    required this.onChanged,
  });

  final _IncomeEntry entry;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.card(brightness),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: entry.nameController,
                  decoration: const InputDecoration(
                    hintText: 'Descripcion (ej. Freelance)',
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textSecondary(brightness)),
                onPressed: onRemove,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _AmountField(
                  controller: entry.amountController,
                  hint: '0',
                  prefix: '\$',
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: entry.frequency,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
                    DropdownMenuItem(
                        value: 'biweekly', child: Text('Quincenal')),
                    DropdownMenuItem(
                        value: 'occasional', child: Text('Ocasional')),
                  ],
                  onChanged: (v) {
                    entry.frequency = v ?? 'monthly';
                    onChanged();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Page 2: Gastos (Expenses)
// ===========================================================================

class _ExpensesPage extends StatelessWidget {
  const _ExpensesPage({
    required this.fixedExpenses,
    required this.variableExpenses,
    required this.totalExpenses,
    required this.totalFixedExpenses,
    required this.totalVariableExpenses,
    required this.totalIncome,
    required this.onChanged,
  });

  final List<_ExpenseEntry> fixedExpenses;
  final List<_ExpenseEntry> variableExpenses;
  final int totalExpenses;
  final int totalFixedExpenses;
  final int totalVariableExpenses;
  final int totalIncome;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = Theme.of(context).brightness;
    final pct = totalIncome > 0
        ? (totalExpenses / totalIncome * 100).toStringAsFixed(1)
        : '0';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionHeader(
          icon: Icons.trending_down_rounded,
          title: 'Gastos',
          color: const Color(0xFFEF4444),
        ),
        const SizedBox(height: 16),

        // Fixed expenses
        Text('Gastos fijos',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          'No cambian mes a mes',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: AppColors.textSecondary(brightness)),
        ),
        const SizedBox(height: 12),
        ...fixedExpenses.map((e) => _ExpenseRow(
              key: ValueKey('fixed-${e.label}'),
              entry: e,
              onChanged: onChanged,
            )),

        const SizedBox(height: 8),
        _SubTotal(label: 'Total fijos', amountCents: totalFixedExpenses),
        const SizedBox(height: 24),

        // Variable expenses
        Text('Gastos variables',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          'Fluctuan cada mes',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: AppColors.textSecondary(brightness)),
        ),
        const SizedBox(height: 12),
        ...variableExpenses.map((e) => _ExpenseRow(
              key: ValueKey('variable-${e.label}'),
              entry: e,
              onChanged: onChanged,
            )),

        const SizedBox(height: 8),
        _SubTotal(
            label: 'Total variables', amountCents: totalVariableExpenses),
        const SizedBox(height: 24),

        // Module summary
        _ModuleSummary(
          label: 'GASTO TOTAL',
          amountCents: totalExpenses,
          color: const Color(0xFFEF4444),
          extra: '$pct% de los ingresos',
        ),
      ],
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    super.key,
    required this.entry,
    required this.onChanged,
  });

  final _ExpenseEntry entry;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(entry.icon, size: 20, color: AppColors.textSecondary(
            Theme.of(context).brightness,
          )),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(entry.label,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 140,
            child: _AmountField(
              controller: entry.controller,
              hint: '0',
              prefix: '\$',
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Page 3: Ahorro e Inversion (Savings)
// ===========================================================================

class _SavingsPage extends StatelessWidget {
  const _SavingsPage({
    required this.emergencyGoalController,
    required this.emergencyMonthlyController,
    required this.savingsGoals,
    required this.investments,
    required this.totalSavings,
    required this.totalIncome,
    required this.onAddGoal,
    required this.onRemoveGoal,
    required this.onAddInvestment,
    required this.onRemoveInvestment,
    required this.onChanged,
  });

  final TextEditingController emergencyGoalController;
  final TextEditingController emergencyMonthlyController;
  final List<_SavingsGoalEntry> savingsGoals;
  final List<_InvestmentEntry> investments;
  final int totalSavings;
  final int totalIncome;
  final VoidCallback onAddGoal;
  final ValueChanged<int> onRemoveGoal;
  final VoidCallback onAddInvestment;
  final ValueChanged<int> onRemoveInvestment;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final pct = totalIncome > 0
        ? (totalSavings / totalIncome * 100).toStringAsFixed(1)
        : '0';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionHeader(
          icon: Icons.savings_outlined,
          title: 'Ahorro e Inversion',
          color: const Color(0xFF3B82F6),
        ),
        const SizedBox(height: 16),

        // Emergency fund
        Text('Fondo de emergencia',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Meta total',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary(brightness))),
                  const SizedBox(height: 4),
                  _AmountField(
                    controller: emergencyGoalController,
                    hint: '0',
                    prefix: '\$',
                    onChanged: (_) => onChanged(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aporte mensual',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary(brightness))),
                  const SizedBox(height: 4),
                  _AmountField(
                    controller: emergencyMonthlyController,
                    hint: '0',
                    prefix: '\$',
                    onChanged: (_) => onChanged(),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Savings goals
        Row(
          children: [
            Expanded(
              child: Text('Metas de ahorro',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            TextButton.icon(
              onPressed: onAddGoal,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Agregar'),
              style: TextButton.styleFrom(foregroundColor: AppColors.finance),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (savingsGoals.isEmpty)
          Text(
            'Sin metas aun. Agrega metas como viaje, carro, casa, etc.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary(brightness)),
          ),

        ...List.generate(savingsGoals.length, (i) => _SavingsGoalRow(
              key: ValueKey('savings-goal-$i'),
              entry: savingsGoals[i],
              onRemove: () => onRemoveGoal(i),
              onChanged: onChanged,
            )),

        const SizedBox(height: 24),

        // Investments
        Row(
          children: [
            Expanded(
              child: Text('Inversiones',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            TextButton.icon(
              onPressed: onAddInvestment,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Agregar'),
              style: TextButton.styleFrom(foregroundColor: AppColors.finance),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (investments.isEmpty)
          Text(
            'CDTs, fondos de inversion, cripto, acciones, etc.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary(brightness)),
          ),

        ...List.generate(investments.length, (i) => _InvestmentRow(
              key: ValueKey('investment-$i'),
              entry: investments[i],
              onRemove: () => onRemoveInvestment(i),
              onChanged: onChanged,
            )),

        const SizedBox(height: 24),

        // Module summary
        _ModuleSummary(
          label: 'AHORRO TOTAL MENSUAL',
          amountCents: totalSavings,
          color: const Color(0xFF3B82F6),
          extra: 'Tasa de ahorro: $pct%',
        ),
      ],
    );
  }
}

class _SavingsGoalRow extends StatelessWidget {
  const _SavingsGoalRow({
    super.key,
    required this.entry,
    required this.onRemove,
    required this.onChanged,
  });

  final _SavingsGoalEntry entry;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.card(brightness),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: entry.nameController,
                  decoration: const InputDecoration(
                    hintText: 'Nombre de la meta',
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textSecondary(brightness)),
                onPressed: onRemove,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _AmountField(
                  controller: entry.targetController,
                  hint: 'Meta total',
                  prefix: '\$',
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AmountField(
                  controller: entry.monthlyController,
                  hint: 'Aporte/mes',
                  prefix: '\$',
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvestmentRow extends StatelessWidget {
  const _InvestmentRow({
    super.key,
    required this.entry,
    required this.onRemove,
    required this.onChanged,
  });

  final _InvestmentEntry entry;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.card(brightness),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: entry.nameController,
              decoration: const InputDecoration(
                hintText: 'Tipo (CDT, fondo, cripto...)',
                isDense: true,
                border: InputBorder.none,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
            child: _AmountField(
              controller: entry.amountController,
              hint: '0/mes',
              prefix: '\$',
              onChanged: (_) => onChanged(),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded,
                size: 18, color: AppColors.textSecondary(brightness)),
            onPressed: onRemove,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Page 4: Summary
// ===========================================================================

class _SummaryPage extends StatelessWidget {
  const _SummaryPage({
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalFixedExpenses,
    required this.totalVariableExpenses,
    required this.totalSavings,
    required this.ahorroDisponible,
    required this.previousMonthAhorro,
    required this.ahorroAnteriorController,
    required this.totalDisponible,
    required this.expensePercent,
    required this.savingsPercent,
    required this.debtPercent,
    required this.isSaving,
    required this.onSave,
    required this.onAhorroChanged,
  });

  final int totalIncome;
  final int totalExpenses;
  final int totalFixedExpenses;
  final int totalVariableExpenses;
  final int totalSavings;
  final int ahorroDisponible;
  final int previousMonthAhorro;
  final TextEditingController ahorroAnteriorController;
  final int totalDisponible;
  final double expensePercent;
  final double savingsPercent;
  final double debtPercent;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onAhorroChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;

    // 50/30/20 analysis
    final fixedPct =
        totalDisponible > 0 ? totalFixedExpenses / totalDisponible * 100 : 0.0;
    final variablePct =
        totalDisponible > 0 ? totalVariableExpenses / totalDisponible * 100 : 0.0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionHeader(
          icon: Icons.summarize_outlined,
          title: 'Resumen General',
          color: const Color(0xFF8B5CF6),
        ),
        const SizedBox(height: 16),

        // Ahorro disponible card (main hero)
        Container(
          decoration: AppDecorations.elevatedCard(brightness),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('Ahorro disponible este mes',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary(brightness))),
              const SizedBox(height: 8),
              Text(
                _formatCurrency(ahorroDisponible),
                style: AppTypography.numericDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: ahorroDisponible >= 0 ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ahorroDisponible >= 0
                    ? 'Dinero que sobra despues de gastos e inversiones'
                    : 'Deficit — gastas mas de lo que ganas',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary(brightness)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Ahorro del mes anterior — auto-calculated, manually editable
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.finance.withAlpha(isDark ? 15 : 8),
            borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
            border: Border.all(color: AppColors.finance.withAlpha(isDark ? 40 : 25)),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.savings_outlined, color: AppColors.finance, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ahorro del mes anterior',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.finance,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Auto-calculado. Editalo si difiere.',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary(brightness),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 120,
                child: _AmountField(
                  controller: ahorroAnteriorController,
                  hint: '0',
                  prefix: '\$',
                  onChanged: (_) => onAhorroChanged(),
                ),
              ),
            ],
          ),
        ),

        // Breakdown rows
        _SummaryRow('Ingresos del mes', totalIncome, const Color(0xFF10B981)),
        if (previousMonthAhorro > 0)
          _SummaryRow('+ Ahorro mes anterior', previousMonthAhorro, AppColors.finance),
        _SummaryRow('Total disponible', totalDisponible, const Color(0xFF10B981),
            subtitle: 'Ingresos + ahorro anterior'),
        const SizedBox(height: 4),
        _SummaryRow('Gastos fijos', totalFixedExpenses, const Color(0xFFEF4444),
            subtitle: '${fixedPct.toStringAsFixed(1)}%'),
        _SummaryRow(
            'Gastos variables', totalVariableExpenses, const Color(0xFFF59E0B),
            subtitle: '${variablePct.toStringAsFixed(1)}%'),
        _SummaryRow(
            'Ahorro e inversion', totalSavings, const Color(0xFF3B82F6),
            subtitle: '${savingsPercent.toStringAsFixed(1)}%'),

        const SizedBox(height: 16),

        // Validation: Ingresos + Ahorro anterior = Gastos + Inversiones + Ahorro disponible
        Container(
          decoration: AppDecorations.card(brightness),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                ahorroDisponible >= 0 ? Icons.check_circle_rounded : Icons.warning_rounded,
                color: ahorroDisponible >= 0 ? AppColors.success : AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Disponible = Gastos + Inversiones + Ahorro\n'
                  '${_formatCurrency(totalDisponible)} = ${_formatCurrency(totalExpenses)} + ${_formatCurrency(totalSavings)} + ${_formatCurrency(ahorroDisponible)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Alerts
        if (debtPercent > 30)
          _AlertCard(
            icon: Icons.warning_rounded,
            color: AppColors.error,
            title: 'Deuda alta: ${debtPercent.toStringAsFixed(1)}%',
            message:
                'Tus cuotas de credito superan el 30% de tus ingresos. Se recomienda no superar ese umbral.',
          ),
        if (savingsPercent < 10 && totalIncome > 0)
          _AlertCard(
            icon: Icons.savings_outlined,
            color: AppColors.warning,
            title: 'Ahorro bajo: ${savingsPercent.toStringAsFixed(1)}%',
            message:
                'Tu tasa de ahorro es menor al 10% recomendado. Intenta destinar al menos el 20% de tus ingresos a ahorro.',
          ),
        if (ahorroDisponible < 0)
          _AlertCard(
            icon: Icons.error_outline_rounded,
            color: AppColors.error,
            title: 'Deficit de ${_formatCurrency(ahorroDisponible.abs())}',
            message:
                'Tus gastos e inversiones superan tus ingresos. Revisa las categorias de gasto para ajustar.',
          ),

        const SizedBox(height: 16),

        // 50/30/20 recommendation
        Container(
          decoration: AppDecorations.card(brightness),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Regla 50/30/20',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _Rule5030Row(
                  'Necesidades (50%)', fixedPct, 50, const Color(0xFFEF4444)),
              const SizedBox(height: 8),
              _Rule5030Row('Deseos (30%)', variablePct, 30,
                  const Color(0xFFF59E0B)),
              const SizedBox(height: 8),
              _Rule5030Row('Ahorro (20%)', savingsPercent, 20,
                  const Color(0xFF3B82F6)),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Save button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isSaving ? null : onSave,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.finance,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(isSaving ? 'Guardando...' : 'Guardar presupuesto'),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}

// ===========================================================================
// Shared helper widgets
// ===========================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(isDark ? 25 : 15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    this.hint,
    this.prefix,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? hint;
  final String? prefix;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefix,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: AppTypography.numericDisplay(
        fontSize: 16,
        color: Theme.of(context).textTheme.bodyMedium?.color,
      ),
      onChanged: onChanged,
    );
  }
}

class _ModuleSummary extends StatelessWidget {
  const _ModuleSummary({
    required this.label,
    required this.amountCents,
    required this.color,
    this.extra,
  });

  final String label;
  final int amountCents;
  final Color color;
  final String? extra;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 15 : 8),
        borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
        border: Border.all(color: color.withAlpha(isDark ? 40 : 25)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                ),
                if (extra != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    extra!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary(brightness),
                        ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            _formatCurrency(amountCents),
            style: AppTypography.numericDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubTotal extends StatelessWidget {
  const _SubTotal({required this.label, required this.amountCents});

  final String label;
  final int amountCents;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderColor(brightness)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
          Text(
            _formatCurrency(amountCents),
            style: AppTypography.numericDisplay(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(brightness),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.amountCents, this.color, {this.subtitle});

  final String label;
  final int amountCents;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: AppDecorations.card(brightness),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context).textTheme.bodyMedium),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary(brightness),
                            )),
                ],
              ),
            ),
            Text(
              _formatCurrency(amountCents),
              style: AppTypography.numericDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 12 : 8),
          borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
          border: Border.all(color: color.withAlpha(isDark ? 35 : 20)),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          )),
                  const SizedBox(height: 4),
                  Text(message,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rule5030Row extends StatelessWidget {
  const _Rule5030Row(this.label, this.actual, this.target, this.color);

  final String label;
  final double actual;
  final double target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final isOver = actual > target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(
              '${actual.toStringAsFixed(1)}% / ${target.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isOver ? AppColors.error : color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (actual / 100).clamp(0, 1),
            backgroundColor: color.withAlpha(isDark ? 20 : 12),
            valueColor: AlwaysStoppedAnimation(
              isOver ? AppColors.error : color,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Data models (local to wizard, not persisted directly)
// ===========================================================================

class _IncomeEntry {
  final nameController = TextEditingController();
  final amountController = TextEditingController();
  String frequency = 'monthly';

  int get monthlyCents {
    final raw = _parseCents(amountController.text);
    return switch (frequency) {
      'biweekly' => (raw * 2),
      'occasional' => (raw ~/ 12),
      _ => raw,
    };
  }

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }
}

class _ExpenseEntry {
  _ExpenseEntry(this.label, this.icon);

  final String label;
  final IconData icon;
  final controller = TextEditingController();

  int get cents => _parseCents(controller.text);

  void dispose() {
    controller.dispose();
  }
}

class _SavingsGoalEntry {
  final nameController = TextEditingController();
  final targetController = TextEditingController();
  final monthlyController = TextEditingController();

  String get name => nameController.text.trim();
  int get targetCents => _parseCents(targetController.text);
  int get monthlyCents => _parseCents(monthlyController.text);
  DateTime? get deadline => null; // Could add date picker

  void dispose() {
    nameController.dispose();
    targetController.dispose();
    monthlyController.dispose();
  }
}

class _InvestmentEntry {
  final nameController = TextEditingController();
  final amountController = TextEditingController();

  int get monthlyCents => _parseCents(amountController.text);

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }
}

// ===========================================================================
// Helpers
// ===========================================================================

/// Parses a text field into cents (integer, no decimals).
int _parseCents(String text) {
  final cleaned = text.replaceAll(RegExp(r'[^\d]'), '');
  return int.tryParse(cleaned) ?? 0;
}

/// Formats cents into a readable currency string.
String _formatCurrency(int cents) {
  final negative = cents < 0;
  final abs = cents.abs();
  final formatted = abs.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );
  return '${negative ? '-' : ''}\$$formatted';
}
