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
// Goals Overview Screen
// ---------------------------------------------------------------------------

class GoalsOverviewScreen extends ConsumerStatefulWidget {
  const GoalsOverviewScreen({super.key});

  @override
  ConsumerState<GoalsOverviewScreen> createState() => _GoalsOverviewScreenState();
}

class _GoalsOverviewScreenState extends ConsumerState<GoalsOverviewScreen> {
  String? _selectedCategory;

  static const _goalsColor = AppColors.goals;

  List<LifeGoal> _filteredGoals(List<LifeGoal> goals) {
    var filtered = goals;
    if (_selectedCategory != null) {
      filtered =
          filtered.where((g) => g.category == _selectedCategory).toList();
    }
    // Active goals first, then by targetDate ASC (nulls last), then by name
    filtered.sort((a, b) {
      if (a.status == 'active' && b.status != 'active') return -1;
      if (a.status != 'active' && b.status == 'active') return 1;
      if (a.targetDate == null && b.targetDate == null) {
        return a.name.compareTo(b.name);
      }
      if (a.targetDate == null) return 1;
      if (b.targetDate == null) return -1;
      final dateCmp = a.targetDate!.compareTo(b.targetDate!);
      if (dateCmp != 0) return dateCmp;
      return a.name.compareTo(b.name);
    });
    return filtered;
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
          final filtered = _filteredGoals(goals);

          return Column(
            children: [
              _CategoryFilterBar(
                selectedCategory: _selectedCategory,
                onCategorySelected: (cat) {
                  setState(() {
                    _selectedCategory = _selectedCategory == cat ? null : cat;
                  });
                },
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyGoalsPlaceholder(onAddGoal: _navigateToAddGoal)
                    : ListView.separated(
                        key: const ValueKey('goals_list'),
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final goal = filtered[index];
                          return AnimatedListItem(
                            index: index,
                            child: _GoalCard(
                              key: ValueKey('goal_card_${goal.id}'),
                              goal: goal,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        GoalDetailScreen(goalId: goal.id),
                                  ),
                                );
                              },
                            ),
                          );
                        },
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
// Goal Card
// ---------------------------------------------------------------------------

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    super.key,
    required this.goal,
    required this.onTap,
  });

  final LifeGoal goal;
  final VoidCallback onTap;

  Color get _statusColor {
    return switch (goal.status) {
      'completed' => AppColors.success,
      'paused' => AppColors.warning,
      'abandoned' => AppColors.error,
      _ => AppColors.goals,
    };
  }

  String get _statusLabel => switch (goal.status) {
        'completed' => 'Completado',
        'paused' => 'Pausado',
        'abandoned' => 'Abandonado',
        _ => 'Activo',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = GoalCategory.fromString(goal.category);
    final categoryLabel = category?.displayName ?? goal.category;

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
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.goals,
                                  ),
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
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: _statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${goal.progress}%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Semantics(
                  label: 'Progreso ${goal.progress}%',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: goal.progress / 100.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => LinearProgressIndicator(
                        key: ValueKey('progress_bar_${goal.id}'),
                        value: value,
                        backgroundColor: _statusColor.withOpacity(0.15),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_statusColor),
                        minHeight: 6,
                      ),
                    ),
                  ),
                ),
                if (goal.targetDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(goal.targetDate!),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
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
