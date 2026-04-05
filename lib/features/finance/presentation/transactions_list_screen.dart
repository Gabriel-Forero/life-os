import 'package:flutter/material.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/widgets/empty_state_view.dart';
import 'package:life_os/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// A mock transaction item used as a presentation shell until Riverpod is wired.
class _MockTransaction {
  const _MockTransaction({
    required this.id,
    required this.type,
    required this.amountCents,
    required this.categoryName,
    required this.categoryIcon,
    required this.note,
    required this.date,
  });

  final int id;
  final String type;
  final int amountCents;
  final String categoryName;
  final String categoryIcon;
  final String? note;
  final DateTime date;
}

/// Presentation shell for the transactions list.
///
/// Groups transactions by date and provides swipe-to-delete / swipe-to-edit
/// affordances. Full Riverpod integration (provider subscription, actual
/// delete / edit calls via FinanceNotifier) is wired up in a subsequent pass.
///
/// Accessibility: A11Y-FIN-01 — every interactive element has a Semantics label.
class TransactionsListScreen extends StatelessWidget {
  const TransactionsListScreen({super.key});

  // ---------------------------------------------------------------------------
  // Mock data — replaced by real provider data when wired.
  // ---------------------------------------------------------------------------
  static final List<_MockTransaction> _mockTransactions = [
    _MockTransaction(
      id: 1,
      type: 'expense',
      amountCents: 1250000,
      categoryName: 'Alimentacion',
      categoryIcon: 'restaurant',
      note: 'Almuerzo con el equipo',
      date: DateTime.now(),
    ),
    _MockTransaction(
      id: 2,
      type: 'income',
      amountCents: 300000000,
      categoryName: 'Salario',
      categoryIcon: 'payments',
      note: null,
      date: DateTime.now(),
    ),
    _MockTransaction(
      id: 3,
      type: 'expense',
      amountCents: 8000000,
      categoryName: 'Transporte',
      categoryIcon: 'directions_car',
      note: 'Uber al aeropuerto',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    _MockTransaction(
      id: 4,
      type: 'expense',
      amountCents: 5500000,
      categoryName: 'Entretenimiento',
      categoryIcon: 'movie',
      note: 'Netflix',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Map<String, List<_MockTransaction>> _groupByDate(
    List<_MockTransaction> transactions,
  ) {
    final grouped = <String, List<_MockTransaction>>{};
    for (final tx in transactions) {
      final key = DateFormat('yyyy-MM-dd').format(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    return grouped;
  }

  String _formatDateHeader(String dateKey, BuildContext context) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Hoy';
    if (d == yesterday) return 'Ayer';
    return DateFormat('EEEE, d MMM', 'es').format(date);
  }

  String _formatAmount(_MockTransaction tx) {
    // COP has no decimals — amount stored in cents equals the full integer.
    final symbol = '\$';
    final formatter = NumberFormat('#,##0', 'es_CO');
    return '${tx.type == 'expense' ? '-' : '+'}$symbol${formatter.format(tx.amountCents)}';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final grouped = _groupByDate(_mockTransactions);
    final dateKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

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
            label: 'Filtrar transacciones',
            button: true,
            child: IconButton(
              key: const ValueKey('transactions-filter-button'),
              icon: const Icon(Icons.filter_list_outlined),
              onPressed: () {
                // TODO: open filter bottom sheet when wired
              },
              tooltip: 'Filtrar',
            ),
          ),
          Semantics(
            label: 'Buscar transacciones',
            button: true,
            child: IconButton(
              key: const ValueKey('transactions-search-button'),
              icon: const Icon(Icons.search_outlined),
              onPressed: () {
                // TODO: open search delegate when wired
              },
              tooltip: 'Buscar',
            ),
          ),
        ],
      ),
      body: _mockTransactions.isEmpty
          ? EmptyStateView(
              key: const ValueKey('transactions-empty-state'),
              icon: Icons.receipt_long_outlined,
              title: 'Sin transacciones',
              message: 'Agrega tu primera transaccion tocando el boton +',
              actionLabel: 'Agregar transaccion',
              onAction: () {
                // TODO: navigate to add screen when wired
              },
            )
          : ListView.builder(
              key: const ValueKey('transactions-list'),
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: dateKeys.length,
              itemBuilder: (context, index) {
                final dateKey = dateKeys[index];
                final txs = grouped[dateKey]!;
                return _DateGroup(
                  dateHeader: _formatDateHeader(dateKey, context),
                  transactions: txs,
                  formatAmount: _formatAmount,
                  onDelete: (tx) {
                    // TODO: call notifier.removeTransaction(tx.id) when wired
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.commonDelete),
                        action: SnackBarAction(
                          label: 'Deshacer',
                          onPressed: () {},
                        ),
                      ),
                    );
                  },
                  onEdit: (tx) {
                    // TODO: navigate to add/edit screen when wired
                  },
                );
              },
            ),
      floatingActionButton: Semantics(
        label: 'Agregar transaccion',
        button: true,
        child: FloatingActionButton(
          key: const ValueKey('transactions-fab-add'),
          backgroundColor: AppColors.finance,
          foregroundColor: Colors.white,
          onPressed: () {
            // TODO: navigate to add/edit screen when wired
          },
          tooltip: 'Agregar transaccion',
          child: const Icon(Icons.add),
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
  });

  final String dateHeader;
  final List<_MockTransaction> transactions;
  final String Function(_MockTransaction) formatAmount;
  final void Function(_MockTransaction) onDelete;
  final void Function(_MockTransaction) onEdit;

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
                color: theme.textTheme.bodySmall?.color,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        ...transactions.map(
          (tx) => _TransactionTile(
            transaction: tx,
            formattedAmount: formatAmount(tx),
            onDelete: () => onDelete(tx),
            onEdit: () => onEdit(tx),
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

  final _MockTransaction transaction;
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
      label:
          '${transaction.categoryName}, $formattedAmount, ${transaction.note ?? ''}',
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
          // Delete direction — show confirmation
          return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Eliminar transaccion'),
                  content: const Text(
                    'Esta accion no se puede deshacer.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              ) ??
              false;
        },
        onDismissed: (_) => onDelete(),
        child: ListTile(
          key: ValueKey('transaction-item-${transaction.id}'),
          leading: Semantics(
            label: 'Categoria: ${transaction.categoryName}',
            child: CircleAvatar(
              backgroundColor: (isExpense
                      ? const Color(0xFFEF4444)
                      : AppColors.finance)
                  .withAlpha(25),
              child: Icon(
                _iconData(transaction.categoryIcon),
                size: 20,
                color: isExpense ? const Color(0xFFEF4444) : AppColors.finance,
              ),
            ),
          ),
          title: Text(
            transaction.categoryName,
            style: theme.textTheme.bodyMedium,
          ),
          subtitle: transaction.note != null
              ? Text(
                  transaction.note!,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: Text(
            formattedAmount,
            style: theme.textTheme.titleSmall?.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconData(String name) {
    return switch (name) {
      'restaurant' => Icons.restaurant,
      'payments' => Icons.payments_outlined,
      'directions_car' => Icons.directions_car_outlined,
      'movie' => Icons.movie_outlined,
      'local_hospital' => Icons.local_hospital_outlined,
      'home' => Icons.home_outlined,
      'school' => Icons.school_outlined,
      'checkroom' => Icons.checkroom_outlined,
      'receipt_long' => Icons.receipt_long_outlined,
      'account_balance' => Icons.account_balance_outlined,
      'work' => Icons.work_outline,
      _ => Icons.category_outlined,
    };
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
