import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/router/app_router.dart';
import 'package:life_os/core/widgets/animated_list_item.dart';
import 'package:life_os/core/widgets/empty_state_view.dart';
import 'package:life_os/features/finance/presentation/sms_import_screen.dart';
import 'package:intl/intl.dart';

/// Transactions list screen wired to the Drift FinanceDao.
///
/// Accessibility: A11Y-FIN-01 — every interactive element has a Semantics label.
class TransactionsListScreen extends ConsumerStatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  ConsumerState<TransactionsListScreen> createState() =>
      _TransactionsListScreenState();
}

class _TransactionsListScreenState
    extends ConsumerState<TransactionsListScreen> {
  // Default: show this month
  DateTime get _from {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  DateTime get _to {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  Map<String, List<Transaction>> _groupByDate(List<Transaction> transactions) {
    final grouped = <String, List<Transaction>>{};
    for (final tx in transactions) {
      final key = DateFormat('yyyy-MM-dd').format(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    return grouped;
  }

  String _formatDateHeader(String dateKey) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Hoy';
    if (d == yesterday) return 'Ayer';
    return DateFormat('EEEE, d MMM', 'es').format(date);
  }

  String _formatAmount(Transaction tx) {
    final symbol = '\$';
    final formatter = NumberFormat('#,##0', 'es_CO');
    return '${tx.type == 'expense' ? '-' : '+'}$symbol${formatter.format(tx.amountCents)}';
  }

  Future<void> _deleteTransaction(BuildContext context, Transaction tx) async {
    // Use deferred (undo) delete — no confirmation dialog needed.
    final notifier = ref.read(financeNotifierProvider);
    await notifier.removeTransactionWithUndo(tx.id);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const ValueKey('delete-undo-snackbar'),
        content: const Text('Transaccion eliminada'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () {
            ref.read(financeNotifierProvider).undoDelete();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dao = ref.watch(financeDaoProvider);

    return Scaffold(
      key: const ValueKey('transactions-list-screen'),
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: const Text('Transacciones'),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Semantics(
            label: 'Importar transacciones desde SMS o portapapeles',
            button: true,
            child: IconButton(
              key: const ValueKey('transactions-sms-import-button'),
              icon: const Icon(Icons.sms_outlined),
              onPressed: () =>
                  GoRouter.of(context).push(AppRoutes.financeSmsImport),
              tooltip: 'Importar SMS',
            ),
          ),
          IconButton(
            key: const ValueKey('transactions-budget-button'),
            icon: const Icon(Icons.pie_chart_outline),
            onPressed: () => GoRouter.of(context).push('/finance/budgets'),
            tooltip: 'Presupuestos',
          ),
          IconButton(
            key: const ValueKey('transactions-dashboard-button'),
            icon: const Icon(Icons.bar_chart),
            onPressed: () => GoRouter.of(context).push('/finance/dashboard'),
            tooltip: 'Dashboard',
          ),
          IconButton(
            key: const ValueKey('transactions-savings-button'),
            icon: const Icon(Icons.savings_outlined),
            onPressed: () => GoRouter.of(context).push('/finance/savings'),
            tooltip: 'Metas de ahorro',
          ),
          Semantics(
            label: 'Ver valoracion de finanzas',
            button: true,
            child: IconButton(
              key: const ValueKey('transactions-valuation-button'),
              icon: const Icon(Icons.assessment_outlined),
              onPressed: () =>
                  GoRouter.of(context).push(AppRoutes.financeValuation),
              tooltip: 'Valoracion',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Clipboard detection banner (dismisses itself when not applicable)
          const ClipboardTransactionBanner(
            key: ValueKey('clipboard-transaction-banner'),
          ),
          Expanded(
            child: StreamBuilder<List<Transaction>>(
              stream: dao.watchTransactions(_from, _to),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final transactions = snapshot.data ?? [];
                if (transactions.isEmpty) {
                  return EmptyStateView(
                    key: const ValueKey('transactions-empty-state'),
                    icon: Icons.receipt_long_outlined,
                    title: 'Sin transacciones',
                    message: 'Agrega tu primera transaccion tocando el boton +',
                    actionLabel: 'Agregar transaccion',
                    onAction: () => GoRouter.of(context).push('/finance/add'),
                  );
                }

                final grouped = _groupByDate(transactions);
                final dateKeys = grouped.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                // Build a cumulative index so stagger spans across groups
                var cumulativeIndex = 0;
                final groupWidgets = <Widget>[];
                for (final dateKey in dateKeys) {
                  final txs = grouped[dateKey]!;
                  groupWidgets.add(_DateGroup(
                    dateHeader: _formatDateHeader(dateKey),
                    transactions: txs,
                    formatAmount: _formatAmount,
                    onDelete: (tx) => _deleteTransaction(context, tx),
                    onEdit: (tx) =>
                        GoRouter.of(context).push('/finance/add?id=${tx.id}'),
                    indexOffset: cumulativeIndex,
                  ));
                  cumulativeIndex += txs.length;
                }

                return ListView(
                  key: const ValueKey('transactions-list'),
                  padding: const EdgeInsets.only(bottom: 88),
                  children: groupWidgets,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Semantics(
        label: 'Agregar transaccion',
        button: true,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (context, value, child) =>
              Transform.scale(scale: value, child: child),
          child: FloatingActionButton(
            key: const ValueKey('transactions-fab-add'),
            backgroundColor: AppColors.finance,
            foregroundColor: Colors.white,
            onPressed: () => GoRouter.of(context).push('/finance/add'),
            tooltip: 'Agregar transaccion',
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _DateGroup extends StatelessWidget {
  const _DateGroup({
    required this.dateHeader,
    required this.transactions,
    required this.formatAmount,
    required this.onDelete,
    required this.onEdit,
    this.indexOffset = 0,
  });

  final String dateHeader;
  final List<Transaction> transactions;
  final String Function(Transaction) formatAmount;
  final void Function(Transaction) onDelete;
  final void Function(Transaction) onEdit;
  final int indexOffset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Semantics(
            header: true,
            child: Text(
              dateHeader,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.finance,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        ...transactions.asMap().entries.map(
          (entry) => AnimatedListItem(
            index: indexOffset + entry.key,
            child: _TransactionTile(
              transaction: entry.value,
              formattedAmount: formatAmount(entry.value),
              onDelete: () => onDelete(entry.value),
              onEdit: () => onEdit(entry.value),
            ),
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.formattedAmount,
    required this.onDelete,
    required this.onEdit,
  });

  final Transaction transaction;
  final String formattedAmount;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = transaction.type == 'expense';
    final amountColor =
        isExpense ? const Color(0xFFEF4444) : AppColors.finance;

    return Semantics(
      label: 'Transaccion: $formattedAmount',
      child: Dismissible(
        key: ValueKey('transaction-tile-${transaction.id}'),
        background: _SwipeBackground(
          color: AppColors.finance,
          icon: Icons.edit_outlined,
          alignment: Alignment.centerLeft,
          label: 'Editar',
        ),
        secondaryBackground: _SwipeBackground(
          color: const Color(0xFFEF4444),
          icon: Icons.delete_outline,
          alignment: Alignment.centerRight,
          label: 'Eliminar',
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onEdit();
            return false;
          }
          // Swipe-left confirm immediately — undo snackbar handles recovery.
          return true;
        },
        onDismissed: (_) => onDelete(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 3, 16, 3),
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: amountColor.withAlpha(30),
              ),
            ),
            child: ListTile(
              key: ValueKey('transaction-item-${transaction.id}'),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: amountColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isExpense
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  size: 20,
                  color: amountColor,
                ),
              ),
              title: Text(
                transaction.note ?? (isExpense ? 'Gasto' : 'Ingreso'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              trailing: Text(
                formattedAmount,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.alignment,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final AlignmentGeometry alignment;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withAlpha(25),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
