import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:life_os/core/constants/app_breakpoints.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/features/finance/database/finance_dao.dart';
import 'package:life_os/core/widgets/empty_state_view.dart';
import 'package:life_os/features/finance/domain/amount_formatting.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Budget data with resolved category info
// ---------------------------------------------------------------------------

class _BudgetWithCategory {
  _BudgetWithCategory({
    required this.budget,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.spentCents,
  });

  final Budget budget;
  final String categoryName;
  final String categoryIcon;
  final int categoryColor;
  final int spentCents;

  double get utilization =>
      budget.amountCents > 0 ? spentCents / budget.amountCents : 0.0;

  bool get isOverBudget => spentCents > budget.amountCents;

  /// Traffic light color based on utilization.
  Color get trafficLightColor {
    if (isOverBudget) return Colors.grey.shade700;
    if (utilization >= 0.85) return AppColors.error;
    if (utilization >= 0.60) return AppColors.warning;
    return AppColors.finance;
  }
}

class _GroupData {
  _GroupData({
    required this.group,
    required this.budgetCents,
    required this.spentCents,
    required this.items,
  });

  final CategoryGroup group;
  final int budgetCents;
  final int spentCents;
  final List<_BudgetWithCategory> items;

  double get utilization =>
      budgetCents > 0 ? spentCents / budgetCents : 0.0;

  bool get isOverBudget => spentCents > budgetCents;

  Color get trafficLightColor {
    if (isOverBudget) return Colors.grey.shade700;
    if (utilization >= 0.85) return AppColors.error;
    if (utilization >= 0.60) return AppColors.warning;
    return AppColors.finance;
  }
}

// ---------------------------------------------------------------------------
// Main screen
// ---------------------------------------------------------------------------

class BudgetOverviewScreen extends ConsumerStatefulWidget {
  const BudgetOverviewScreen({super.key});

  @override
  ConsumerState<BudgetOverviewScreen> createState() =>
      _BudgetOverviewScreenState();
}

class _BudgetOverviewScreenState extends ConsumerState<BudgetOverviewScreen> {
  late int _month;
  late int _year;
  int? _selectedBudgetId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;

    // Auto-repeat budgets for current month on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(financeNotifierProvider).ensureBudgetsForMonth(_month, _year);
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      var m = _month + delta;
      var y = _year;
      if (m < 1) {
        m = 12;
        y--;
      } else if (m > 12) {
        m = 1;
        y++;
      }
      _month = m;
      _year = y;
      _selectedBudgetId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      body: StreamBuilder<List<Budget>>(
        stream: dao.watchBudgets(_month, _year),
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

          return _BudgetDataLoader(
            dao: dao,
            budgets: budgets,
            month: _month,
            year: _year,
            selectedBudgetId: _selectedBudgetId,
            onMonthChange: _changeMonth,
            onSelectBudget: (id) => setState(() => _selectedBudgetId = id),
            onEditBudget: (budget) =>
                _showSetBudgetDialog(context, ref, budget),
            onAddBudget: () => _showSetBudgetDialog(context, ref, null),
          );
        },
      ),
      floatingActionButton: _BudgetFab(
        onAddBudget: () => _showSetBudgetDialog(context, ref, null),
        onSaveTemplate: () => _showSaveTemplateDialog(context, ref),
        onApplyTemplate: () => _showApplyTemplateDialog(context, ref),
        onSetGlobalBudget: () => _showSetGlobalBudgetDialog(context, ref),
        onAnalytics: () => GoRouter.of(context)
            .go('/finance/budget-analytics'),
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

  void _showSaveTemplateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Guardar como plantilla'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre de la plantilla',
            hintText: 'Ej: Mes normal',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.finance),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              final notifier = ref.read(financeNotifierProvider);
              final result = await notifier.saveAsTemplate(
                name: name,
                month: _month,
                year: _year,
              );
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result.isSuccess
                      ? 'Plantilla "$name" guardada'
                      : 'Error al guardar plantilla'),
                ));
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showApplyTemplateDialog(BuildContext context, WidgetRef ref) {
    final dao = ref.read(financeDaoProvider);
    showDialog<void>(
      context: context,
      builder: (ctx) => StreamBuilder<List<BudgetTemplate>>(
        stream: dao.watchTemplates(),
        builder: (context, snapshot) {
          final templates = snapshot.data ?? [];
          return AlertDialog(
            title: const Text('Aplicar plantilla'),
            content: templates.isEmpty
                ? const Text('No hay plantillas guardadas')
                : SizedBox(
                    width: 300,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        final t = templates[index];
                        return ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: Text(t.name),
                          subtitle: Text(DateFormat('dd/MM/yyyy')
                              .format(t.updatedAt)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () async {
                              await ref
                                  .read(financeNotifierProvider)
                                  .deleteTemplate(t.id);
                            },
                          ),
                          onTap: () async {
                            final notifier =
                                ref.read(financeNotifierProvider);
                            await notifier.applyTemplate(
                              templateId: t.id,
                              month: _month,
                              year: _year,
                            );
                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content:
                                    Text('Plantilla "${t.name}" aplicada'),
                              ));
                            }
                          },
                        );
                      },
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSetGlobalBudgetDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final dao = ref.read(financeDaoProvider);

    // Pre-fill with existing global budget
    dao.getMonthlyConfig(_month, _year).then((config) {
      if (config?.globalBudgetCents != null) {
        controller.text = config!.globalBudgetCents.toString();
      }
    });

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Presupuesto global del mes'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Monto total del mes',
            prefixText: '\$',
            hintText: '0',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.finance),
            onPressed: () async {
              final amount = int.tryParse(controller.text);
              if (amount == null || amount <= 0) return;
              final notifier = ref.read(financeNotifierProvider);
              await notifier.setGlobalBudget(
                amountCents: amount,
                month: _month,
                year: _year,
              );
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                setState(() {}); // Refresh
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Presupuesto global actualizado')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loads spent amounts + category info, then builds responsive layout
// ---------------------------------------------------------------------------

class _BudgetDataLoader extends StatelessWidget {
  const _BudgetDataLoader({
    required this.dao,
    required this.budgets,
    required this.month,
    required this.year,
    required this.selectedBudgetId,
    required this.onMonthChange,
    required this.onSelectBudget,
    required this.onEditBudget,
    required this.onAddBudget,
  });

  final FinanceDao dao;
  final List<Budget> budgets;
  final int month;
  final int year;
  final int? selectedBudgetId;
  final ValueChanged<int> onMonthChange;
  final ValueChanged<int> onSelectBudget;
  final ValueChanged<Budget> onEditBudget;
  final VoidCallback onAddBudget;

  @override
  Widget build(BuildContext context) {
    // Load spent amounts
    return FutureBuilder<List<int>>(
      future: Future.wait(
        budgets.map((b) => dao.spentInBudget(b.categoryId, month, year)),
      ),
      builder: (context, spentSnap) {
        final spentList =
            spentSnap.data ?? List.filled(budgets.length, 0);

        // Load category details
        return StreamBuilder<List<Category>>(
          stream: dao.watchCategories(),
          builder: (context, catSnap) {
            final categories = catSnap.data ?? [];
            final catMap = {for (final c in categories) c.id: c};

            // Load groups + group members + global config
            return StreamBuilder<List<CategoryGroup>>(
              stream: dao.watchGroups(),
              builder: (context, groupSnap) {
                final groups = groupSnap.data ?? [];

                return FutureBuilder<_ResolvedBudgetData>(
                  future: _resolveBudgetData(
                    dao: dao,
                    budgets: budgets,
                    spentList: spentList,
                    catMap: catMap,
                    groups: groups,
                    month: month,
                    year: year,
                  ),
                  builder: (context, resolvedSnap) {
                    final resolved = resolvedSnap.data;
                    if (resolved == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        if (AppBreakpoints.isMediumOrLarger(constraints)) {
                          return _DesktopLayout(
                            groupedData: resolved.groups,
                            ungroupedItems: resolved.ungrouped,
                            totalBudgetCents: resolved.totalBudgetCents,
                            totalSpentCents: resolved.totalSpentCents,
                            globalBudgetCents: resolved.globalBudgetCents,
                            month: month,
                            year: year,
                            selectedBudgetId: selectedBudgetId,
                            onMonthChange: onMonthChange,
                            onSelectBudget: onSelectBudget,
                            onEditBudget: onEditBudget,
                            sidebarWidth: constraints.maxWidth >= AppBreakpoints.expanded ? 340 : 280,
                          );
                        }
                        return _PhoneLayout(
                          groupedData: resolved.groups,
                          ungroupedItems: resolved.ungrouped,
                          totalBudgetCents: resolved.totalBudgetCents,
                          totalSpentCents: resolved.totalSpentCents,
                          globalBudgetCents: resolved.globalBudgetCents,
                          month: month,
                          year: year,
                          onMonthChange: onMonthChange,
                          onEditBudget: onEditBudget,
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Resolved budget data with groups
// ---------------------------------------------------------------------------

class _ResolvedBudgetData {
  _ResolvedBudgetData({
    required this.groups,
    required this.ungrouped,
    required this.totalBudgetCents,
    required this.totalSpentCents,
    required this.globalBudgetCents,
  });

  final List<_GroupData> groups;
  final List<_BudgetWithCategory> ungrouped;
  final int totalBudgetCents;
  final int totalSpentCents;
  final int? globalBudgetCents;
}

Future<_ResolvedBudgetData> _resolveBudgetData({
  required FinanceDao dao,
  required List<Budget> budgets,
  required List<int> spentList,
  required Map<int, Category> catMap,
  required List<CategoryGroup> groups,
  required int month,
  required int year,
}) async {
  // Build all budget items
  final allItems = List.generate(budgets.length, (i) {
    final b = budgets[i];
    final cat = catMap[b.categoryId];
    return _BudgetWithCategory(
      budget: b,
      categoryName: cat?.name ?? 'Categoria #${b.categoryId}',
      categoryIcon: cat?.icon ?? 'category',
      categoryColor: cat?.color ?? 0xFF9CA3AF,
      spentCents: i < spentList.length ? spentList[i] : 0,
    );
  });

  // Get group membership for each category
  final catToGroup = <int, int>{};
  for (final group in groups) {
    final members = await dao.getGroupMembers(group.id);
    for (final m in members) {
      catToGroup[m.categoryId] = group.id;
    }
  }

  // Build group data
  final groupDataList = <_GroupData>[];
  for (final group in groups) {
    final groupItems = allItems
        .where((item) => catToGroup[item.budget.categoryId] == group.id)
        .toList();
    if (groupItems.isEmpty) continue;

    final gb = await dao.getGroupBudget(group.id, month, year);
    final groupSpent =
        groupItems.fold<int>(0, (s, item) => s + item.spentCents);

    groupDataList.add(_GroupData(
      group: group,
      budgetCents: gb?.amountCents ??
          groupItems.fold<int>(0, (s, item) => s + item.budget.amountCents),
      spentCents: groupSpent,
      items: groupItems,
    ));
  }

  // Ungrouped items
  final ungrouped = allItems
      .where((item) => !catToGroup.containsKey(item.budget.categoryId))
      .toList();

  final totalBudget = budgets.fold<int>(0, (s, b) => s + b.amountCents);
  final totalSpent = spentList.fold<int>(0, (s, v) => s + v);

  final config = await dao.getMonthlyConfig(month, year);

  return _ResolvedBudgetData(
    groups: groupDataList,
    ungrouped: ungrouped,
    totalBudgetCents: totalBudget,
    totalSpentCents: totalSpent,
    globalBudgetCents: config?.globalBudgetCents,
  );
}

// ---------------------------------------------------------------------------
// DESKTOP / TABLET — Sidebar + Detail Panel
// ---------------------------------------------------------------------------

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.groupedData,
    required this.ungroupedItems,
    required this.totalBudgetCents,
    required this.totalSpentCents,
    required this.globalBudgetCents,
    required this.month,
    required this.year,
    required this.selectedBudgetId,
    required this.onMonthChange,
    required this.onSelectBudget,
    required this.onEditBudget,
    required this.sidebarWidth,
  });

  final List<_GroupData> groupedData;
  final List<_BudgetWithCategory> ungroupedItems;
  final int totalBudgetCents;
  final int totalSpentCents;
  final int? globalBudgetCents;
  final int month;
  final int year;
  final int? selectedBudgetId;
  final ValueChanged<int> onMonthChange;
  final ValueChanged<int> onSelectBudget;
  final ValueChanged<Budget> onEditBudget;
  final double sidebarWidth;

  List<_BudgetWithCategory> get _allItems => [
        ...groupedData.expand((g) => g.items),
        ...ungroupedItems,
      ];

  @override
  Widget build(BuildContext context) {
    final selected = selectedBudgetId != null
        ? _allItems.where((i) => i.budget.id == selectedBudgetId).firstOrNull
        : null;

    return Row(
      children: [
        // --- Sidebar ---
        SizedBox(
          width: sidebarWidth,
          child: _SidebarContent(
            groupedData: groupedData,
            ungroupedItems: ungroupedItems,
            totalBudgetCents: totalBudgetCents,
            totalSpentCents: totalSpentCents,
            globalBudgetCents: globalBudgetCents,
            month: month,
            year: year,
            selectedBudgetId: selectedBudgetId,
            onMonthChange: onMonthChange,
            onSelectBudget: onSelectBudget,
          ),
        ),
        const VerticalDivider(width: 1),
        // --- Detail Panel ---
        Expanded(
          child: selected != null
              ? _BudgetDetailPanel(
                  item: selected,
                  month: month,
                  year: year,
                  onEdit: () => onEditBudget(selected.budget),
                )
              : const Center(
                  child: Text('Selecciona una categoria para ver el detalle'),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// PHONE — Vertical stack
// ---------------------------------------------------------------------------

class _PhoneLayout extends StatelessWidget {
  const _PhoneLayout({
    required this.groupedData,
    required this.ungroupedItems,
    required this.totalBudgetCents,
    required this.totalSpentCents,
    required this.globalBudgetCents,
    required this.month,
    required this.year,
    required this.onMonthChange,
    required this.onEditBudget,
  });

  final List<_GroupData> groupedData;
  final List<_BudgetWithCategory> ungroupedItems;
  final int totalBudgetCents;
  final int totalSpentCents;
  final int? globalBudgetCents;
  final int month;
  final int year;
  final ValueChanged<int> onMonthChange;
  final ValueChanged<Budget> onEditBudget;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Adaptive padding: tighter on small phones, roomier on large
        final horizontalPadding = width < 360 ? 10.0 : 16.0;
        // On wider phones (>480), constrain content width
        final maxContentWidth = width > 480 ? 480.0 : double.infinity;

        return ListView(
          key: const ValueKey('budget-list'),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 12,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MonthSelector(
                      month: month,
                      year: year,
                      onMonthChange: onMonthChange,
                    ),
                    const SizedBox(height: 12),
                    _BudgetSummaryCard(
                      key: const ValueKey('budget-summary-card'),
                      totalBudgetCents: totalBudgetCents,
                      totalSpentCents: totalSpentCents,
                      globalBudgetCents: globalBudgetCents,
                      month: month,
                      year: year,
                    ),
                    const SizedBox(height: 16),
                    ...groupedData.map((gd) => _GroupSection(
                          key: ValueKey('group-${gd.group.id}'),
                          groupData: gd,
                          onEditBudget: onEditBudget,
                        )),
                    if (ungroupedItems.isNotEmpty &&
                        groupedData.isNotEmpty) ...[
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 8, bottom: 4, left: 4),
                        child: Text(
                          'Sin agrupar',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                        ),
                      ),
                    ],
                    ...ungroupedItems.map((item) => _BudgetCategoryRow(
                          key: ValueKey('budget-row-${item.budget.id}'),
                          item: item,
                          onTap: () => onEditBudget(item.budget),
                        )),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar content (used by desktop layout)
// ---------------------------------------------------------------------------

class _SidebarContent extends StatelessWidget {
  const _SidebarContent({
    required this.groupedData,
    required this.ungroupedItems,
    required this.totalBudgetCents,
    required this.totalSpentCents,
    required this.globalBudgetCents,
    required this.month,
    required this.year,
    required this.selectedBudgetId,
    required this.onMonthChange,
    required this.onSelectBudget,
  });

  final List<_GroupData> groupedData;
  final List<_BudgetWithCategory> ungroupedItems;
  final int totalBudgetCents;
  final int totalSpentCents;
  final int? globalBudgetCents;
  final int month;
  final int year;
  final int? selectedBudgetId;
  final ValueChanged<int> onMonthChange;
  final ValueChanged<int> onSelectBudget;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _MonthSelector(
          month: month,
          year: year,
          onMonthChange: onMonthChange,
        ),
        const SizedBox(height: 12),
        _BudgetSummaryCard(
          totalBudgetCents: totalBudgetCents,
          totalSpentCents: totalSpentCents,
          globalBudgetCents: globalBudgetCents,
          month: month,
          year: year,
        ),
        const SizedBox(height: 12),
        ...groupedData.map((gd) => _GroupSection(
              key: ValueKey('group-${gd.group.id}'),
              groupData: gd,
              selectedBudgetId: selectedBudgetId,
              onSelectBudget: onSelectBudget,
            )),
        if (ungroupedItems.isNotEmpty && groupedData.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4, left: 4),
            child: Text(
              'Sin agrupar',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
            ),
          ),
        ],
        ...ungroupedItems.map((item) {
          final isSelected = item.budget.id == selectedBudgetId;
          return _BudgetCategoryRow(
            key: ValueKey('budget-row-${item.budget.id}'),
            item: item,
            isSelected: isSelected,
            onTap: () => onSelectBudget(item.budget.id),
          );
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Collapsible group section
// ---------------------------------------------------------------------------

class _GroupSection extends StatefulWidget {
  const _GroupSection({
    super.key,
    required this.groupData,
    this.selectedBudgetId,
    this.onSelectBudget,
    this.onEditBudget,
  });

  final _GroupData groupData;
  final int? selectedBudgetId;
  final ValueChanged<int>? onSelectBudget;
  final ValueChanged<Budget>? onEditBudget;

  @override
  State<_GroupSection> createState() => _GroupSectionState();
}

class _GroupSectionState extends State<_GroupSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gd = widget.groupData;
    final pct = (gd.utilization * 100).round();
    final color = gd.trafficLightColor;
    final groupColor = Color(gd.group.color);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: groupColor.withAlpha(30),
                  child: Icon(Icons.folder_outlined, size: 14, color: groupColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gd.group.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${gd.spentCents.toCurrency('COP')} / ${gd.budgetCents.toCurrency('COP')}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '$pct%',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ],
            ),
          ),
        ),
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: gd.utilization.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: theme.dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        // Expanded items
        if (_expanded) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              children: gd.items.map((item) {
                final isSelected = item.budget.id == widget.selectedBudgetId;
                return _BudgetCategoryRow(
                  key: ValueKey('budget-row-${item.budget.id}'),
                  item: item,
                  isSelected: isSelected,
                  onTap: () {
                    widget.onSelectBudget?.call(item.budget.id);
                    widget.onEditBudget?.call(item.budget);
                  },
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Month selector
// ---------------------------------------------------------------------------

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.year,
    required this.onMonthChange,
  });

  final int month;
  final int year;
  final ValueChanged<int> onMonthChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = DateFormat('MMMM yyyy', 'es').format(DateTime(year, month));

    return Semantics(
      label: 'Mes actual: $label. Usa las flechas para cambiar de mes.',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            key: const ValueKey('month-prev'),
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onMonthChange(-1),
            tooltip: 'Mes anterior',
          ),
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            key: const ValueKey('month-next'),
            icon: const Icon(Icons.chevron_right),
            onPressed: () => onMonthChange(1),
            tooltip: 'Mes siguiente',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary card
// ---------------------------------------------------------------------------

class _BudgetSummaryCard extends StatelessWidget {
  const _BudgetSummaryCard({
    super.key,
    required this.totalBudgetCents,
    required this.totalSpentCents,
    required this.globalBudgetCents,
    required this.month,
    required this.year,
  });

  final int totalBudgetCents;
  final int totalSpentCents;
  final int? globalBudgetCents;
  final int month;
  final int year;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBudget = globalBudgetCents ?? totalBudgetCents;
    final remaining = effectiveBudget - totalSpentCents;
    final utilization = effectiveBudget > 0
        ? (totalSpentCents / effectiveBudget).clamp(0.0, 1.0)
        : 0.0;
    final overBudget = totalSpentCents > effectiveBudget;

    // Days remaining calculation
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final now = DateTime.now();
    final isCurrentMonth = now.month == month && now.year == year;
    final daysRemaining = isCurrentMonth ? daysInMonth - now.day : 0;
    final perDayAvailable =
        daysRemaining > 0 ? (remaining / daysRemaining).round() : 0;

    // Traffic light color
    final barColor = overBudget
        ? AppColors.error
        : utilization >= 0.85
            ? AppColors.error
            : utilization >= 0.60
                ? AppColors.warning
                : AppColors.finance;

    // Responsive: smaller headline on narrow screens
    final screenWidth = MediaQuery.of(context).size.width;
    final amountStyle = screenWidth < 360
        ? theme.textTheme.titleLarge
        : theme.textTheme.headlineMedium;

    return Semantics(
      label:
          'Resumen: gastado ${totalSpentCents.toCurrency('COP')} de ${effectiveBudget.toCurrency('COP')}. '
          '${overBudget ? 'Excedido' : '${remaining.toCurrency('COP')} restante'}',
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(screenWidth < 360 ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (globalBudgetCents != null) ...[
                Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: barColor),
                    const SizedBox(width: 4),
                    Text(
                      'Presupuesto global',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: barColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          totalSpentCents.toCurrency('COP'),
                          style: amountStyle?.copyWith(
                            color: overBudget ? AppColors.error : null,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'de ${effectiveBudget.toCurrency('COP')}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        overBudget
                            ? 'Excedido'
                            : remaining.toCurrency('COP'),
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
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: utilization),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => LinearProgressIndicator(
                    key: const ValueKey('budget-total-bar'),
                    value: value,
                    minHeight: 8,
                    backgroundColor: theme.dividerColor,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ),
              if (isCurrentMonth && !overBudget && daysRemaining > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '$daysRemaining dias restantes · ${perDayAvailable.toCurrency('COP')}/dia',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Budget category row with traffic light
// ---------------------------------------------------------------------------

class _BudgetCategoryRow extends StatelessWidget {
  const _BudgetCategoryRow({
    super.key,
    required this.item,
    required this.onTap,
    this.isSelected = false,
  });

  final _BudgetWithCategory item;
  final VoidCallback onTap;
  final bool isSelected;

  static const _iconMap = <String, IconData>{
    'restaurant': Icons.restaurant,
    'car': Icons.directions_car,
    'movie': Icons.movie,
    'hospital': Icons.local_hospital,
    'home': Icons.home,
    'school': Icons.school,
    'checkroom': Icons.checkroom,
    'receipt': Icons.receipt_long,
    'category': Icons.category,
    'account_balance': Icons.account_balance,
    'payments': Icons.payments,
    'work': Icons.work,
    'pets': Icons.pets,
    'star': Icons.star,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final util = item.utilization;
    final pct = (util * 100).round();
    final color = item.trafficLightColor;
    final catColor = Color(item.categoryColor);
    final icon = _iconMap[item.categoryIcon] ?? Icons.category;
    final isNarrow = MediaQuery.of(context).size.width < 360;

    return Semantics(
      label:
          '${item.categoryName}: $pct% del presupuesto utilizado. '
          'Gastado ${item.spentCents.toCurrency('COP')} '
          'de ${item.budget.amountCents.toCurrency('COP')}.',
      button: true,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: isSelected ? theme.colorScheme.surfaceContainerHighest : null,
        child: InkWell(
          key: ValueKey('budget-row-tap-${item.budget.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(isNarrow ? 8 : 12),
            child: Row(
              children: [
                // Traffic light dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
                SizedBox(width: isNarrow ? 6 : 10),
                // Category icon
                CircleAvatar(
                  radius: isNarrow ? 14 : 18,
                  backgroundColor: catColor.withAlpha(30),
                  child: Icon(icon, size: isNarrow ? 14 : 18, color: catColor),
                ),
                SizedBox(width: isNarrow ? 6 : 10),
                // Name + amount
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.categoryName,
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${item.spentCents.toCurrency('COP')} / ${item.budget.amountCents.toCurrency('COP')}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Percentage
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$pct%',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.isOverBudget)
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
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail panel (desktop only)
// ---------------------------------------------------------------------------

class _BudgetDetailPanel extends StatelessWidget {
  const _BudgetDetailPanel({
    required this.item,
    required this.month,
    required this.year,
    required this.onEdit,
  });

  final _BudgetWithCategory item;
  final int month;
  final int year;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final util = item.utilization;
    final pct = (util * 100).round();
    final color = item.trafficLightColor;
    final remaining = item.budget.amountCents - item.spentCents;

    final daysInMonth = DateTime(year, month + 1, 0).day;
    final now = DateTime.now();
    final isCurrentMonth = now.month == month && now.year == year;
    final daysRemaining = isCurrentMonth ? daysInMonth - now.day : 0;
    final perDayAvailable = daysRemaining > 0
        ? (remaining.clamp(0, remaining) / daysRemaining).round()
        : 0;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContentWidth),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(item.categoryColor).withAlpha(30),
                  child: Icon(
                    _BudgetCategoryRow._iconMap[item.categoryIcon] ??
                        Icons.category,
                    size: 24,
                    color: Color(item.categoryColor),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.categoryName,
                        style: theme.textTheme.headlineSmall,
                      ),
                      Text(
                        'Presupuesto mensual',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Editar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.finance,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Progress
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: util.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 12,
                  backgroundColor: theme.dividerColor,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$pct% utilizado',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  item.isOverBudget
                      ? 'Excedido por ${(item.spentCents - item.budget.amountCents).toCurrency('COP')}'
                      : '${remaining.toCurrency('COP')} restante',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats grid
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Presupuesto',
                    value: item.budget.amountCents.toCurrency('COP'),
                    icon: Icons.account_balance_wallet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'Gastado',
                    value: item.spentCents.toCurrency('COP'),
                    icon: Icons.shopping_cart,
                    valueColor: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isCurrentMonth && !item.isOverBudget && daysRemaining > 0)
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Dias restantes',
                      value: '$daysRemaining',
                      icon: Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      label: 'Disponible/dia',
                      value: perDayAvailable.toCurrency('COP'),
                      icon: Icons.trending_flat,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Auto-repeat status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      item.budget.autoRepeat
                          ? Icons.repeat
                          : Icons.repeat_one,
                      color: item.budget.autoRepeat
                          ? AppColors.finance
                          : theme.textTheme.bodySmall?.color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.budget.autoRepeat
                            ? 'Se repite automaticamente cada mes'
                            : 'No se repite automaticamente',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small stat tile
// ---------------------------------------------------------------------------

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: theme.textTheme.bodySmall?.color),
                const SizedBox(width: 4),
                Text(label, style: theme.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FAB with menu options
// ---------------------------------------------------------------------------

class _BudgetFab extends StatelessWidget {
  const _BudgetFab({
    required this.onAddBudget,
    required this.onSaveTemplate,
    required this.onApplyTemplate,
    required this.onSetGlobalBudget,
    required this.onAnalytics,
  });

  final VoidCallback onAddBudget;
  final VoidCallback onSaveTemplate;
  final VoidCallback onApplyTemplate;
  final VoidCallback onSetGlobalBudget;
  final VoidCallback onAnalytics;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      key: const ValueKey('budget-fab'),
      backgroundColor: AppColors.finance,
      onPressed: () => _showMenu(context),
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _showMenu(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy - 220,
        offset.dx + size.width,
        offset.dy,
      ),
      items: [
        const PopupMenuItem(
          value: 'add',
          child: ListTile(
            leading: Icon(Icons.add_circle_outline),
            title: Text('Nuevo presupuesto'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'global',
          child: ListTile(
            leading: Icon(Icons.shield_outlined),
            title: Text('Presupuesto global'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'save',
          child: ListTile(
            leading: Icon(Icons.save_outlined),
            title: Text('Guardar como plantilla'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'apply',
          child: ListTile(
            leading: Icon(Icons.file_copy_outlined),
            title: Text('Aplicar plantilla'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'analytics',
          child: ListTile(
            leading: Icon(Icons.analytics_outlined),
            title: Text('Analisis'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'add':
          onAddBudget();
        case 'global':
          onSetGlobalBudget();
        case 'save':
          onSaveTemplate();
        case 'apply':
          onApplyTemplate();
        case 'analytics':
          onAnalytics();
      }
    });
  }
}

// ---------------------------------------------------------------------------
// Dialog to set / edit budget
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
