import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/widgets/animated_list_item.dart';
import 'package:life_os/core/widgets/pressable_card.dart';
import 'package:life_os/features/goals/domain/goals_input.dart';
import 'package:life_os/features/goals/presentation/add_edit_goal_screen.dart';
import 'package:life_os/features/goals/presentation/goal_detail_screen.dart';

// ---------------------------------------------------------------------------
// Sort options
// ---------------------------------------------------------------------------

enum _GoalSortOption {
  deadline,
  progress,
  category;

  String get label => switch (this) {
        _GoalSortOption.deadline => 'Urgentes primero',
        _GoalSortOption.progress => 'Casi completas',
        _GoalSortOption.category => 'Por categoria',
      };

  IconData get icon => switch (this) {
        _GoalSortOption.deadline => Icons.access_time,
        _GoalSortOption.progress => Icons.trending_up,
        _GoalSortOption.category => Icons.label_outline,
      };
}

// ---------------------------------------------------------------------------
// Goals Overview Screen
// ---------------------------------------------------------------------------

class GoalsOverviewScreen extends ConsumerStatefulWidget {
  const GoalsOverviewScreen({super.key});

  @override
  ConsumerState<GoalsOverviewScreen> createState() =>
      _GoalsOverviewScreenState();
}

class _GoalsOverviewScreenState extends ConsumerState<GoalsOverviewScreen> {
  String? _selectedCategory;
  _GoalSortOption _sortOption = _GoalSortOption.deadline;
  bool _completedExpanded = false;

  static const _goalsColor = AppColors.goals;

  List<LifeGoal> _activeGoals(List<LifeGoal> goals) {
    var active = goals.where((g) => g.status != 'completed').toList();
    if (_selectedCategory != null) {
      active = active.where((g) => g.category == _selectedCategory).toList();
    }
    _applySort(active);
    return active;
  }

  List<LifeGoal> _completedGoals(List<LifeGoal> goals) {
    final now = DateTime.now();
    final thisYear = now.year;
    return goals
        .where((g) =>
            g.status == 'completed' &&
            (g.updatedAt.year == thisYear || g.createdAt.year == thisYear))
        .toList();
  }

  void _applySort(List<LifeGoal> goals) {
    switch (_sortOption) {
      case _GoalSortOption.deadline:
        goals.sort((a, b) {
          if (a.targetDate == null && b.targetDate == null) {
            return a.name.compareTo(b.name);
          }
          if (a.targetDate == null) return 1;
          if (b.targetDate == null) return -1;
          final dateCmp = a.targetDate!.compareTo(b.targetDate!);
          return dateCmp != 0 ? dateCmp : a.name.compareTo(b.name);
        });
      case _GoalSortOption.progress:
        goals.sort((a, b) {
          final cmp = b.progress.compareTo(a.progress);
          return cmp != 0 ? cmp : a.name.compareTo(b.name);
        });
      case _GoalSortOption.category:
        goals.sort((a, b) {
          final catCmp = a.category.compareTo(b.category);
          return catCmp != 0 ? catCmp : a.name.compareTo(b.name);
        });
    }
  }

  void _navigateToAddGoal() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AddEditGoalScreen(
          onSaveGoal: (input) {
            ref.read(goalsNotifierProvider).addGoal(input);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _navigateToGoal(LifeGoal goal) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => GoalDetailScreen(goalId: goal.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goalsDao = ref.watch(goalsDaoProvider);

    return Scaffold(
      key: const ValueKey('goals_overview_screen'),
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: const Text(
          'Mis Objetivos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Sort picker
          PopupMenuButton<_GoalSortOption>(
            key: const ValueKey('sort_goals_button'),
            icon: const Icon(Icons.sort),
            tooltip: 'Ordenar',
            onSelected: (opt) => setState(() => _sortOption = opt),
            itemBuilder: (_) => _GoalSortOption.values
                .map(
                  (opt) => PopupMenuItem<_GoalSortOption>(
                    value: opt,
                    child: Row(
                      children: [
                        Icon(opt.icon,
                            size: 18,
                            color: _sortOption == opt
                                ? _goalsColor
                                : null),
                        const SizedBox(width: 8),
                        Text(
                          opt.label,
                          style: TextStyle(
                            color: _sortOption == opt
                                ? _goalsColor
                                : null,
                            fontWeight: _sortOption == opt
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          Semantics(
            label: 'Agregar objetivo',
            button: true,
            child: IconButton(
              key: const ValueKey('add_goal_button'),
              icon: const Icon(Icons.add),
              color: _goalsColor,
              onPressed: _navigateToAddGoal,
              tooltip: 'Agregar objetivo',
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<LifeGoal>>(
        stream: goalsDao.watchAllGoals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final goals = snapshot.data ?? [];
          final active = _activeGoals(goals);
          final completed = _completedGoals(goals);
          final totalActive =
              goals.where((g) => g.status == 'active').length;

          return Column(
            children: [
              // Top summary banner
              _SummaryBanner(
                activeCount: totalActive,
                completedThisYearCount: completed.length,
              ),
              // Category filter
              _CategoryFilterBar(
                selectedCategory: _selectedCategory,
                onCategorySelected: (cat) {
                  setState(() {
                    _selectedCategory =
                        _selectedCategory == cat ? null : cat;
                  });
                },
              ),
              // Sort indicator
              if (active.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Icon(_sortOption.icon,
                          size: 14,
                          color: theme.textTheme.bodySmall?.color),
                      const SizedBox(width: 4),
                      Text(
                        _sortOption.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: active.isEmpty && completed.isEmpty
                    ? _EmptyGoalsPlaceholder(onAddGoal: _navigateToAddGoal)
                    : ListView(
                        key: const ValueKey('goals_list'),
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Active goals
                          ...active.asMap().entries.map((entry) {
                            final index = entry.key;
                            final goal = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AnimatedListItem(
                                index: index,
                                child: _EnhancedGoalCard(
                                  key: ValueKey('goal_card_${goal.id}'),
                                  goal: goal,
                                  onTap: () => _navigateToGoal(goal),
                                ),
                              ),
                            );
                          }),
                          // Completed section
                          if (completed.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _CompletedSection(
                              goals: completed,
                              expanded: _completedExpanded,
                              onToggle: () => setState(
                                  () => _completedExpanded =
                                      !_completedExpanded),
                              onGoalTap: _navigateToGoal,
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Semantics(
        label: 'Nuevo objetivo',
        button: true,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (context, value, child) =>
              Transform.scale(scale: value, child: child),
          child: FloatingActionButton(
            key: const ValueKey('fab_add_goal'),
            backgroundColor: _goalsColor,
            foregroundColor: Colors.white,
            onPressed: _navigateToAddGoal,
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary Banner
// ---------------------------------------------------------------------------

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({
    required this.activeCount,
    required this.completedThisYearCount,
  });

  final int activeCount;
  final int completedThisYearCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label:
          '$activeCount metas activas, $completedThisYearCount completadas este año',
      child: Container(
        key: const ValueKey('goals_summary_banner'),
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: AppColors.goals.withOpacity(0.07),
        child: Row(
          children: [
            _SummaryItem(
              value: '$activeCount',
              label: 'metas activas',
              color: AppColors.goals,
            ),
            Container(
              width: 1,
              height: 28,
              color: AppColors.goals.withOpacity(0.2),
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            _SummaryItem(
              value: '$completedThisYearCount',
              label: 'completadas este año',
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Category Filter Bar
// ---------------------------------------------------------------------------

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final String? selectedCategory;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        key: const ValueKey('category_filter_bar'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: GoalCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = GoalCategory.values[i];
          final isSelected = selectedCategory == cat.name;
          return Semantics(
            label: 'Filtrar por ${cat.displayName}',
            selected: isSelected,
            button: true,
            child: FilterChip(
              key: ValueKey('filter_chip_${cat.name}'),
              label: Text(cat.displayName),
              selected: isSelected,
              onSelected: (_) => onCategorySelected(cat.name),
              selectedColor: AppColors.goals.withOpacity(0.2),
              checkmarkColor: AppColors.goals,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.goals : null,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Enhanced Goal Card (Feature 3)
// ---------------------------------------------------------------------------

class _EnhancedGoalCard extends ConsumerWidget {
  const _EnhancedGoalCard({
    super.key,
    required this.goal,
    required this.onTap,
  });

  final LifeGoal goal;
  final VoidCallback onTap;

  Color get _statusColor => switch (goal.status) {
        'completed' => AppColors.success,
        'paused' => AppColors.warning,
        'abandoned' => AppColors.error,
        _ => AppColors.goals,
      };

  String get _statusLabel => switch (goal.status) {
        'completed' => 'Completado',
        'paused' => 'Pausado',
        'abandoned' => 'Abandonado',
        _ => 'Activo',
      };

  /// Deadline status: 'on_track', 'behind', 'overdue', or null when no deadline
  String? _deadlineStatus() {
    if (goal.targetDate == null || goal.progress == 0) return null;
    final now = DateTime.now();
    if (goal.targetDate!.isBefore(now)) return 'overdue';

    final daysSinceCreation =
        now.difference(goal.createdAt).inDays.clamp(1, 36500);
    final progressPerDay = goal.progress / daysSinceCreation;
    final remaining = 100 - goal.progress;
    final estimatedDays = progressPerDay > 0
        ? (remaining / progressPerDay).ceil()
        : null;
    if (estimatedDays == null) return null;

    final daysToDeadline = goal.targetDate!.difference(now).inDays;
    return estimatedDays <= daysToDeadline ? 'on_track' : 'behind';
  }

  Color _deadlineStatusColor(String status) => switch (status) {
        'on_track' => AppColors.success,
        'behind' => AppColors.warning,
        'overdue' => AppColors.error,
        _ => AppColors.goals,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final goalsDao = ref.watch(goalsDaoProvider);
    final category = GoalCategory.fromString(goal.category);
    final categoryLabel = category?.displayName ?? goal.category;
    final now = DateTime.now();
    final deadlineStatus = _deadlineStatus();

    // Days remaining
    String? daysRemainingLabel;
    if (goal.targetDate != null) {
      final daysLeft = goal.targetDate!.difference(now).inDays;
      if (daysLeft < 0) {
        daysRemainingLabel = '${daysLeft.abs()} dias vencida';
      } else if (daysLeft == 0) {
        daysRemainingLabel = 'Vence hoy';
      } else {
        daysRemainingLabel = '$daysLeft dias restantes';
      }
    } else {
      daysRemainingLabel = 'Sin fecha limite';
    }

    return Semantics(
      label: 'Objetivo: ${goal.name}, progreso ${goal.progress}%',
      button: true,
      child: PressableCard(
        onTap: onTap,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.dividerColor.withOpacity(0.3),
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(goal.color).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.track_changes,
                          color: Color(goal.color),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.goals.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    categoryLabel,
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(color: AppColors.goals),
                                  ),
                                ),
                                if (goal.status != 'active') ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _statusLabel,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(color: _statusColor),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Deadline status dot + progress %
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${goal.progress}%',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: _statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (deadlineStatus != null)
                            Semantics(
                              label:
                                  'Estado deadline: $deadlineStatus',
                              child: Container(
                                key: ValueKey(
                                    'deadline_dot_${goal.id}'),
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _deadlineStatusColor(
                                      deadlineStatus),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Animated progress bar
                  Semantics(
                    label: 'Progreso ${goal.progress}%',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                            begin: 0.0, end: goal.progress / 100.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) =>
                            LinearProgressIndicator(
                          key: ValueKey('progress_bar_${goal.id}'),
                          value: value,
                          backgroundColor:
                              _statusColor.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              _statusColor),
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Bottom row: days remaining + sub-goal count
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        daysRemainingLabel,
                        style: theme.textTheme.bodySmall,
                      ),
                      const Spacer(),
                      // Sub-goals count (streamed)
                      StreamBuilder<List<SubGoal>>(
                        stream: goalsDao.watchSubGoals(goal.id),
                        builder: (context, subSnap) {
                          final subs = subSnap.data ?? [];
                          if (subs.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final completed = subs
                              .where((s) => s.progress >= 100)
                              .length;
                          return Row(
                            children: [
                              Icon(
                                Icons.check_box_outline_blank,
                                size: 12,
                                color:
                                    theme.textTheme.bodySmall?.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$completed/${subs.length} sub-metas',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Completed Goals Section (collapsed by default)
// ---------------------------------------------------------------------------

class _CompletedSection extends StatelessWidget {
  const _CompletedSection({
    required this.goals,
    required this.expanded,
    required this.onToggle,
    required this.onGoalTap,
  });

  final List<LifeGoal> goals;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<LifeGoal> onGoalTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label:
              '${goals.length} objetivos completados. ${expanded ? "Contraer" : "Expandir"}',
          button: true,
          child: InkWell(
            key: const ValueKey('completed_section_toggle'),
            onTap: onToggle,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Completadas (${goals.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: 8),
          ...goals.map(
            (goal) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _CompletedGoalRow(
                key: ValueKey('completed_goal_${goal.id}'),
                goal: goal,
                onTap: () => onGoalTap(goal),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CompletedGoalRow extends StatelessWidget {
  const _CompletedGoalRow({
    super.key,
    required this.goal,
    required this.onTap,
  });

  final LifeGoal goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Objetivo completado: ${goal.name}',
      button: true,
      child: PressableCard(
        onTap: onTap,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppColors.success.withOpacity(0.2),
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      goal.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '100%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State Placeholder
// ---------------------------------------------------------------------------

class _EmptyGoalsPlaceholder extends StatelessWidget {
  const _EmptyGoalsPlaceholder({required this.onAddGoal});

  final VoidCallback onAddGoal;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('goals_empty_state'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.track_changes,
              size: 64,
              color: AppColors.goals.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Aun no tienes objetivos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primer objetivo y empieza a avanzar',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
            ),
            const SizedBox(height: 24),
            Semantics(
              label: 'Crear primer objetivo',
              button: true,
              child: ElevatedButton.icon(
                key: const ValueKey('empty_add_goal_button'),
                onPressed: onAddGoal,
                icon: const Icon(Icons.add),
                label: const Text('Crear objetivo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goals,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
