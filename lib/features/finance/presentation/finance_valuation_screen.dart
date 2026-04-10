import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/features/dashboard/domain/models/life_snapshot_model.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Modelos internos
// ---------------------------------------------------------------------------

class _FinanceMetrics {
  const _FinanceMetrics({
    required this.incomeThisMonth,
    required this.expensesThisMonth,
    required this.balance,
    required this.savingsRate,
    required this.budgetUsedPercent,
    required this.topCategories,
    required this.activeRecurrings,
    required this.prevMonthIncome,
    required this.prevMonthExpenses,
    required this.prevMonthBalance,
    required this.avgDailySpend,
    required this.projectedMonthEnd,
  });

  final int incomeThisMonth; // cents
  final int expensesThisMonth; // cents
  final int balance; // cents
  final double savingsRate; // 0..100
  final double budgetUsedPercent; // 0..100
  final List<_CategorySpend> topCategories;
  final int activeRecurrings;
  final int prevMonthIncome;
  final int prevMonthExpenses;
  final int prevMonthBalance;
  final double avgDailySpend; // cents
  final double projectedMonthEnd; // cents
}

class _CategorySpend {
  const _CategorySpend({required this.name, required this.amountCents});

  final String name;
  final int amountCents;
}

// ---------------------------------------------------------------------------
// Pantalla: Valoracion Finanzas
// ---------------------------------------------------------------------------

/// Valoracion integral del modulo Finanzas. Muestra balance, control
/// presupuestario y tendencias comparados con la ultima valoracion.
class FinanceValuationScreen extends ConsumerStatefulWidget {
  const FinanceValuationScreen({super.key});

  @override
  ConsumerState<FinanceValuationScreen> createState() =>
      _FinanceValuationScreenState();
}

class _FinanceValuationScreenState
    extends ConsumerState<FinanceValuationScreen> {
  _FinanceMetrics? _current;
  Map<String, dynamic>? _previousData;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final financeRepo = ref.read(financeRepositoryProvider);
      final dashRepo = ref.read(dashboardRepositoryProvider);
      final now = DateTime.now();

      // --- Mes actual ---
      final fromThisMonth = DateTime(now.year, now.month, 1);
      final toThisMonth =
          DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final incomeThisMonth =
          await financeRepo.sumByType('income', fromThisMonth, toThisMonth);
      final expensesThisMonth =
          await financeRepo.sumByType('expense', fromThisMonth, toThisMonth);
      final balance = incomeThisMonth - expensesThisMonth;
      final savingsRate = incomeThisMonth > 0
          ? (balance / incomeThisMonth * 100).clamp(0.0, 100.0)
          : 0.0;

      // --- Mes anterior ---
      final prevMonth = now.month == 1 ? 12 : now.month - 1;
      final prevYear = now.month == 1 ? now.year - 1 : now.year;
      final fromPrevMonth = DateTime(prevYear, prevMonth, 1);
      final toPrevMonth = DateTime(prevYear, prevMonth + 1, 0, 23, 59, 59);

      final prevIncome =
          await financeRepo.sumByType('income', fromPrevMonth, toPrevMonth);
      final prevExpenses =
          await financeRepo.sumByType('expense', fromPrevMonth, toPrevMonth);
      final prevBalance = prevIncome - prevExpenses;

      // --- Presupuesto ---
      final budgets =
          await financeRepo.watchBudgets(now.month, now.year).first;
      int totalBudgetCents = 0;
      int totalSpentCents = 0;
      for (final b in budgets) {
        totalBudgetCents += b.amountCents;
        totalSpentCents +=
            await financeRepo.spentInBudget(b.categoryId, now.month, now.year);
      }
      final budgetUsedPercent = totalBudgetCents > 0
          ? (totalSpentCents / totalBudgetCents * 100).clamp(0.0, 150.0)
          : 0.0;

      // --- Top 3 categorias ---
      final categories = await financeRepo.watchCategories().first;
      final categorySpends = <_CategorySpend>[];
      for (final cat in categories) {
        if (cat.type == 'income') continue;
        final spent = await financeRepo.spentInBudget(
            cat.id, now.month, now.year);
        if (spent > 0) {
          categorySpends.add(_CategorySpend(name: cat.name, amountCents: spent));
        }
      }
      categorySpends.sort((a, b) => b.amountCents.compareTo(a.amountCents));
      final topCategories = categorySpends.take(3).toList();

      // --- Promedio y proyeccion ---
      final daysInMonth =
          DateTime(now.year, now.month + 1, 0).day;
      final daysPassed = now.day;
      final avgDailySpend =
          daysPassed > 0 ? expensesThisMonth / daysPassed : 0.0;
      final projected = avgDailySpend * daysInMonth;

      // --- Recurrentes activos ---
      final allTx = await financeRepo.watchTransactions(
          fromThisMonth, toThisMonth).first;
      final activeRecurrings =
          allTx.where((t) => t.recurringId != null).map((t) => t.recurringId).toSet().length;

      final metrics = _FinanceMetrics(
        incomeThisMonth: incomeThisMonth,
        expensesThisMonth: expensesThisMonth,
        balance: balance,
        savingsRate: savingsRate,
        budgetUsedPercent: budgetUsedPercent,
        topCategories: topCategories,
        activeRecurrings: activeRecurrings,
        prevMonthIncome: prevIncome,
        prevMonthExpenses: prevExpenses,
        prevMonthBalance: prevBalance,
        avgDailySpend: avgDailySpend,
        projectedMonthEnd: projected,
      );

      // --- Ultima valoracion previa ---
      final snapshots = await dashRepo.getAllSnapshots();
      Map<String, dynamic>? prevData;
      for (final snap in snapshots) {
        try {
          final decoded =
              jsonDecode(snap.metricsJson) as Map<String, dynamic>;
          if (decoded['moduleKey'] == 'finance') {
            prevData = decoded['data'] as Map<String, dynamic>?;
            break;
          }
        } on Exception {
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _current = metrics;
          _previousData = prevData;
          _loading = false;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando datos: $e')),
        );
      }
    }
  }

  Map<String, dynamic> _serializeMetrics() {
    final m = _current!;
    return {
      'incomeThisMonth': m.incomeThisMonth,
      'expensesThisMonth': m.expensesThisMonth,
      'balance': m.balance,
      'savingsRate': m.savingsRate,
      'budgetUsedPercent': m.budgetUsedPercent,
      'activeRecurrings': m.activeRecurrings,
      'avgDailySpend': m.avgDailySpend,
      'projectedMonthEnd': m.projectedMonthEnd,
      'prevMonthIncome': m.prevMonthIncome,
      'prevMonthExpenses': m.prevMonthExpenses,
      'prevMonthBalance': m.prevMonthBalance,
      'topCategories': m.topCategories
          .map((c) => {'name': c.name, 'amountCents': c.amountCents})
          .toList(),
    };
  }

  Future<void> _saveValuation() async {
    if (_current == null || _saving) return;
    setState(() => _saving = true);
    try {
      final dashRepo = ref.read(dashboardRepositoryProvider);
      final data = _serializeMetrics();
      await dashRepo.insertValuationSnapshot(
        moduleKey: 'finance',
        data: data,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            key: ValueKey('finance-valuation-saved-snackbar'),
            content: Text('Valoracion guardada!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _load();
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error guardando: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _FinanceValuationHistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('finance-valuation-screen'),
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: const Text('Valoracion Finanzas'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.finance,
        actions: [
          Semantics(
            label: 'Ver historial de valoraciones',
            button: true,
            child: IconButton(
              key: const ValueKey('finance-valuation-history-button'),
              icon: const Icon(Icons.history_outlined),
              onPressed: () => _showHistory(context),
              tooltip: 'Historial',
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _current == null
              ? const Center(child: Text('No se pudieron cargar los datos.'))
              : _buildBody(context),
      bottomNavigationBar: _loading || _current == null
          ? null
          : _BottomActions(
              onSave: _saving ? null : _saveValuation,
              onHistory: () => _showHistory(context),
              saving: _saving,
              color: AppColors.finance,
              saveKey: 'finance-valuation-save-button',
              historyKey: 'finance-valuation-history-bottom-button',
            ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final m = _current!;
    final prev = _previousData;

    return ListView(
      key: const ValueKey('finance-valuation-list'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        if (prev != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Comparando con ultima valoracion guardada',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.finance,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        // --- Seccion Balance ---
        _SectionHeader(
          key: const ValueKey('finance-val-balance-header'),
          icon: Icons.account_balance_wallet_outlined,
          title: 'Balance',
          color: AppColors.finance,
        ),
        _MoneyRow(
          key: const ValueKey('finance-val-income'),
          label: 'Ingresos del mes',
          cents: m.incomeThisMonth,
          prevCents: prev != null
              ? (prev['incomeThisMonth'] as num?)?.toInt()
              : null,
          higherIsBetter: true,
          color: AppColors.finance,
        ),
        _MoneyRow(
          key: const ValueKey('finance-val-expenses'),
          label: 'Gastos del mes',
          cents: m.expensesThisMonth,
          prevCents: prev != null
              ? (prev['expensesThisMonth'] as num?)?.toInt()
              : null,
          higherIsBetter: false,
          color: AppColors.finance,
        ),
        _MoneyRow(
          key: const ValueKey('finance-val-balance-net'),
          label: 'Balance neto',
          cents: m.balance,
          prevCents:
              prev != null ? (prev['balance'] as num?)?.toInt() : null,
          higherIsBetter: true,
          color: AppColors.finance,
          bold: true,
        ),
        _MetricRow(
          key: const ValueKey('finance-val-savings-rate'),
          label: 'Tasa de ahorro',
          value: '${m.savingsRate.toStringAsFixed(1)}%',
          previousValue: prev?['savingsRate'] != null
              ? '${(prev!['savingsRate'] as num).toStringAsFixed(1)}%'
              : null,
          higherIsBetter: true,
          numericCurrent: m.savingsRate,
          numericPrevious: (prev?['savingsRate'] as num?)?.toDouble(),
          unit: '%',
          color: AppColors.finance,
        ),

        const SizedBox(height: 20),

        // --- Seccion Control ---
        _SectionHeader(
          key: const ValueKey('finance-val-control-header'),
          icon: Icons.pie_chart_outline,
          title: 'Control',
          color: AppColors.finance,
        ),
        _MetricRow(
          key: const ValueKey('finance-val-budget-used'),
          label: 'Presupuesto utilizado',
          value: '${m.budgetUsedPercent.toStringAsFixed(1)}%',
          previousValue: prev?['budgetUsedPercent'] != null
              ? '${(prev!['budgetUsedPercent'] as num).toStringAsFixed(1)}%'
              : null,
          higherIsBetter: false,
          numericCurrent: m.budgetUsedPercent,
          numericPrevious: (prev?['budgetUsedPercent'] as num?)?.toDouble(),
          unit: '%',
          color: AppColors.finance,
        ),
        _MetricRow(
          key: const ValueKey('finance-val-recurrings'),
          label: 'Transacciones recurrentes activas',
          value: '${m.activeRecurrings}',
          previousValue: prev != null
              ? '${(prev['activeRecurrings'] as num?)?.toInt() ?? 0}'
              : null,
          higherIsBetter: false,
          color: AppColors.finance,
        ),
        if (m.topCategories.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'Top 3 categorias de gasto:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...m.topCategories.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            return Semantics(
              label: '${i + 1}. ${c.name}: ${_fmtCents(c.amountCents)}',
              child: Card(
                key: ValueKey('finance-val-cat-$i'),
                margin: const EdgeInsets.only(bottom: 4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        '${i + 1}.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.finance),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c.name)),
                      Text(
                        _fmtCents(c.amountCents),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],

        const SizedBox(height: 20),

        // --- Seccion Tendencia ---
        _SectionHeader(
          key: const ValueKey('finance-val-tendencia-header'),
          icon: Icons.trending_up_outlined,
          title: 'Tendencia',
          color: AppColors.finance,
        ),
        _MoneyRow(
          key: const ValueKey('finance-val-prev-income'),
          label: 'Ingresos mes anterior',
          cents: m.prevMonthIncome,
          prevCents: null,
          higherIsBetter: true,
          color: AppColors.finance,
        ),
        _MoneyRow(
          key: const ValueKey('finance-val-prev-expenses'),
          label: 'Gastos mes anterior',
          cents: m.prevMonthExpenses,
          prevCents: null,
          higherIsBetter: false,
          color: AppColors.finance,
        ),
        _MoneyRow(
          key: const ValueKey('finance-val-prev-balance'),
          label: 'Balance mes anterior',
          cents: m.prevMonthBalance,
          prevCents: null,
          higherIsBetter: true,
          color: AppColors.finance,
        ),
        _MoneyRow(
          key: const ValueKey('finance-val-avg-daily'),
          label: 'Gasto promedio diario',
          cents: m.avgDailySpend.round(),
          prevCents: prev != null
              ? (prev['avgDailySpend'] as num?)?.toInt()
              : null,
          higherIsBetter: false,
          color: AppColors.finance,
        ),
        _MoneyRow(
          key: const ValueKey('finance-val-projected'),
          label: 'Proyeccion fin de mes',
          cents: m.projectedMonthEnd.round(),
          prevCents: prev != null
              ? (prev['projectedMonthEnd'] as num?)?.toInt()
              : null,
          higherIsBetter: false,
          color: AppColors.finance,
        ),
      ],
    );
  }

  String _fmtCents(int cents) {
    final formatter = NumberFormat('#,##0', 'es_CO');
    return '\$${formatter.format(cents)}';
  }
}

// ---------------------------------------------------------------------------
// Historial de valoraciones Finance
// ---------------------------------------------------------------------------

class _FinanceValuationHistoryScreen extends ConsumerWidget {
  const _FinanceValuationHistoryScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ValuationHistoryScreen(
      moduleKey: 'finance',
      title: 'Historial Valoracion Finanzas',
      color: AppColors.finance,
      summaryBuilder: (data) {
        final income = (data['incomeThisMonth'] as num?)?.toInt() ?? 0;
        final expenses = (data['expensesThisMonth'] as num?)?.toInt() ?? 0;
        final savings = (data['savingsRate'] as num?)?.toDouble() ?? 0.0;
        final fmt = NumberFormat('#,##0', 'es_CO');
        return 'Ing: \$${fmt.format(income)} · Gto: \$${fmt.format(expenses)} · Ahorro: ${savings.toStringAsFixed(1)}%';
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets especificos de Finance
// ---------------------------------------------------------------------------

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    super.key,
    required this.label,
    required this.cents,
    required this.prevCents,
    required this.higherIsBetter,
    required this.color,
    this.bold = false,
  });

  final String label;
  final int cents;
  final int? prevCents;
  final bool higherIsBetter;
  final Color color;
  final bool bold;

  String _fmt(int c) {
    final formatter = NumberFormat('#,##0', 'es_CO');
    return '\$${formatter.format(c)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showDelta = prevCents != null;

    return Semantics(
      label: '$label: ${_fmt(cents)}${prevCents != null ? ", anterior: ${_fmt(prevCents!)}" : ""}',
      child: Card(
        key: key,
        margin: const EdgeInsets.only(bottom: 6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.bodyMedium),
                    if (prevCents != null)
                      Text(
                        'Anterior: ${_fmt(prevCents!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(120),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                _fmt(cents),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              if (showDelta) ...[
                const SizedBox(width: 8),
                _DeltaWidget(
                  current: cents.toDouble(),
                  previous: prevCents!.toDouble(),
                  higherIsBetter: higherIsBetter,
                  unit: '',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Semantics(
            header: true,
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    super.key,
    required this.label,
    required this.value,
    required this.previousValue,
    required this.higherIsBetter,
    required this.color,
    this.numericCurrent,
    this.numericPrevious,
    this.unit = '',
  });

  final String label;
  final String value;
  final String? previousValue;
  final bool higherIsBetter;
  final Color color;
  final double? numericCurrent;
  final double? numericPrevious;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showDelta = numericCurrent != null && numericPrevious != null;

    return Semantics(
      label: '$label: $value${previousValue != null ? ", anterior: $previousValue" : ""}',
      child: Card(
        key: key,
        margin: const EdgeInsets.only(bottom: 6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.bodyMedium),
                    if (previousValue != null)
                      Text(
                        'Anterior: $previousValue',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(120),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (showDelta) ...[
                const SizedBox(width: 8),
                _DeltaWidget(
                  current: numericCurrent!,
                  previous: numericPrevious!,
                  higherIsBetter: higherIsBetter,
                  unit: unit,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DeltaWidget extends StatelessWidget {
  const _DeltaWidget({
    required this.current,
    required this.previous,
    required this.higherIsBetter,
    required this.unit,
  });

  final double current;
  final double previous;
  final bool higherIsBetter;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final delta = current - previous;
    final isGood = higherIsBetter ? delta > 0 : delta < 0;
    final isNeutral = delta.abs() < 0.01;

    Color color;
    IconData icon;
    if (isNeutral) {
      color = Colors.grey;
      icon = Icons.remove;
    } else if (isGood) {
      color = AppColors.success;
      icon = Icons.arrow_upward;
    } else {
      color = AppColors.error;
      icon = Icons.arrow_downward;
    }

    final absStr = unit.isNotEmpty
        ? '${delta.abs().toStringAsFixed(1)}$unit'
        : delta.abs().toStringAsFixed(1);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        Text(
          isNeutral ? 'igual' : absStr,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.onSave,
    required this.onHistory,
    required this.saving,
    required this.color,
    required this.saveKey,
    required this.historyKey,
  });

  final VoidCallback? onSave;
  final VoidCallback onHistory;
  final bool saving;
  final Color color;
  final String saveKey;
  final String historyKey;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                label: 'Guardar valoracion actual',
                button: true,
                child: FilledButton.icon(
                  key: ValueKey(saveKey),
                  onPressed: onSave,
                  style: FilledButton.styleFrom(backgroundColor: color),
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(saving ? 'Guardando...' : 'Guardar Valoracion'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: 'Ver historial de valoraciones',
              button: true,
              child: OutlinedButton.icon(
                key: ValueKey(historyKey),
                onPressed: onHistory,
                icon: const Icon(Icons.history_outlined),
                label: const Text('Historial'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pantalla generica de historial
// ---------------------------------------------------------------------------

class _ValuationHistoryScreen extends ConsumerStatefulWidget {
  const _ValuationHistoryScreen({
    required this.moduleKey,
    required this.title,
    required this.color,
    required this.summaryBuilder,
  });

  final String moduleKey;
  final String title;
  final Color color;
  final String Function(Map<String, dynamic> data) summaryBuilder;

  @override
  ConsumerState<_ValuationHistoryScreen> createState() =>
      _ValuationHistoryScreenState();
}

class _ValuationHistoryScreenState
    extends ConsumerState<_ValuationHistoryScreen> {
  List<LifeSnapshotModel> _snapshots = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dashRepo = ref.read(dashboardRepositoryProvider);
    final all = await dashRepo.getAllSnapshots();
    final filtered = all.where((s) {
      try {
        final decoded = jsonDecode(s.metricsJson) as Map<String, dynamic>;
        return decoded['moduleKey'] == widget.moduleKey;
      } on Exception {
        return false;
      }
    }).toList();

    if (mounted) {
      setState(() {
        _snapshots = filtered;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: ValueKey('${widget.moduleKey}-valuation-history-screen'),
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(widget.title),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.finance,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _snapshots.isEmpty
              ? Center(
                  child: Text(
                    'Sin valoraciones guardadas todavia.',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : ListView.separated(
                  key: ValueKey(
                      '${widget.moduleKey}-valuation-history-list'),
                  padding: const EdgeInsets.all(16),
                  itemCount: _snapshots.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final snap = _snapshots[index];
                    Map<String, dynamic>? data;
                    try {
                      final decoded = jsonDecode(snap.metricsJson)
                          as Map<String, dynamic>;
                      data = decoded['data'] as Map<String, dynamic>?;
                    } on Exception {
                      data = null;
                    }
                    final summary =
                        data != null ? widget.summaryBuilder(data) : '';
                    final dateStr =
                        DateFormat('d MMM yyyy · HH:mm', 'es')
                            .format(snap.date.toLocal());

                    return Semantics(
                      label: 'Valoracion del $dateStr: $summary',
                      child: Card(
                        key: ValueKey(
                            '${widget.moduleKey}-history-snap-${snap.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateStr,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: widget.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                summary,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
