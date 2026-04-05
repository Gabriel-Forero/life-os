import 'package:flutter/material.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/goals/domain/goals_input.dart';

// ---------------------------------------------------------------------------
// Goal Detail Screen
// ---------------------------------------------------------------------------

class GoalDetailScreen extends StatelessWidget {
  const GoalDetailScreen({
    super.key,
    required this.goalId,
    this.goal,
    this.subGoals = const [],
    this.milestones = const [],
    this.onSubGoalProgressChanged,
    this.onCompleteMilestone,
  });

  final int goalId;
  final LifeGoal? goal;
  final List<SubGoal> subGoals;
  final List<GoalMilestone> milestones;
  final void Function(int subGoalId, int progress)? onSubGoalProgressChanged;
  final void Function(int milestoneId)? onCompleteMilestone;

  static const _goalsColor = AppColors.goals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (goal == null) {
      return Scaffold(
        key: const ValueKey('goal_detail_screen'),
        appBar: AppBar(title: const Text('Objetivo')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final category = GoalCategory.fromString(goal!.category);
    final categoryLabel = category?.displayName ?? goal!.category;

    return Scaffold(
      key: const ValueKey('goal_detail_screen'),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App bar with hero color
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: Color(goal!.color),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                goal!.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Container(
                color: Color(goal!.color).withOpacity(0.8),
                child: Center(
                  child: Icon(
                    Icons.track_changes,
                    size: 64,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + status chips
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        key: const ValueKey('goal_category_chip'),
                        label: Text(categoryLabel),
                        backgroundColor: _goalsColor.withOpacity(0.1),
                        labelStyle: const TextStyle(color: _goalsColor),
                      ),
                      Chip(
                        key: const ValueKey('goal_status_chip'),
                        label: Text(_statusLabel(goal!.status)),
                        backgroundColor:
                            _statusColor(goal!.status).withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: _statusColor(goal!.status),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  if (goal!.description != null &&
                      goal!.description!.isNotEmpty) ...[
                    Text(
                      goal!.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Progress section
                  _GoalProgressSection(goal: goal!),
                  const SizedBox(height: 24),

                  // Milestones timeline
                  if (milestones.isNotEmpty) ...[
                    Text(
                      'Hitos',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _MilestonesTimeline(
                      milestones: milestones,
                      goalProgress: goal!.progress,
                      onComplete: onCompleteMilestone,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Sub-goals section
                  Text(
                    'Sub-objetivos',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Sub-goals list
          subGoals.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Aun no hay sub-objetivos para este objetivo.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final sub = subGoals[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: _SubGoalItem(
                          key: ValueKey('sub_goal_${sub.id}'),
                          subGoal: sub,
                          onProgressChanged: onSubGoalProgressChanged != null
                              ? (p) =>
                                  onSubGoalProgressChanged!(sub.id, p)
                              : null,
                        ),
                      );
                    },
                    childCount: subGoals.length,
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'completed' => AppColors.success,
        'paused' => AppColors.warning,
        'abandoned' => AppColors.error,
        _ => AppColors.goals,
      };

  String _statusLabel(String status) => switch (status) {
        'completed' => 'Completado',
        'paused' => 'Pausado',
        'abandoned' => 'Abandonado',
        _ => 'Activo',
      };
}

// ---------------------------------------------------------------------------
// Goal Progress Section
// ---------------------------------------------------------------------------

class _GoalProgressSection extends StatelessWidget {
  const _GoalProgressSection({required this.goal});

  final LifeGoal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Progreso del objetivo: ${goal.progress}%',
      child: Container(
        key: const ValueKey('goal_progress_section'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.goals.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.goals.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progreso General',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${goal.progress}%',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.goals,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                key: const ValueKey('goal_detail_progress_bar'),
                value: goal.progress / 100.0,
                backgroundColor: AppColors.goals.withOpacity(0.15),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.goals),
                minHeight: 10,
              ),
            ),
            if (goal.targetDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Fecha limite: ${_formatDate(goal.targetDate!)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

// ---------------------------------------------------------------------------
// Milestones Timeline (horizontal)
// ---------------------------------------------------------------------------

class _MilestonesTimeline extends StatelessWidget {
  const _MilestonesTimeline({
    required this.milestones,
    required this.goalProgress,
    this.onComplete,
  });

  final List<GoalMilestone> milestones;
  final int goalProgress;
  final void Function(int milestoneId)? onComplete;

  @override
  Widget build(BuildContext context) {
    final sorted = [...milestones]
      ..sort((a, b) => a.targetProgress.compareTo(b.targetProgress));

    return SizedBox(
      key: const ValueKey('milestones_timeline'),
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: sorted.length,
        separatorBuilder: (context, idx) => _TimelineConnector(
          isReached: goalProgress >= sorted[idx < sorted.length - 1
              ? idx + 1
              : idx].targetProgress,
        ),
        itemBuilder: (context, index) {
          final milestone = sorted[index];
          final isReached = goalProgress >= milestone.targetProgress;
          return _MilestoneDot(
            key: ValueKey('milestone_${milestone.id}'),
            milestone: milestone,
            isReached: isReached,
            onComplete: (!milestone.isCompleted && isReached && onComplete != null)
                ? () => onComplete!(milestone.id)
                : null,
          );
        },
      ),
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector({required this.isReached});

  final bool isReached;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Container(
          width: 32,
          height: 2,
          color: isReached
              ? AppColors.goals
              : AppColors.goals.withOpacity(0.3),
        ),
      ),
    );
  }
}

class _MilestoneDot extends StatelessWidget {
  const _MilestoneDot({
    super.key,
    required this.milestone,
    required this.isReached,
    this.onComplete,
  });

  final GoalMilestone milestone;
  final bool isReached;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = milestone.isCompleted
        ? AppColors.success
        : isReached
            ? AppColors.goals
            : AppColors.goals.withOpacity(0.3);

    return Semantics(
      label: 'Hito: ${milestone.name}, ${milestone.targetProgress}%'
          '${milestone.isCompleted ? ", completado" : ""}',
      button: onComplete != null,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onComplete,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.15),
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(
                  milestone.isCompleted
                      ? Icons.check
                      : Icons.flag_outlined,
                  size: 18,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${milestone.targetProgress}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              milestone.name,
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (milestone.isCompleted && milestone.completedAt != null) ...[
              Text(
                _formatDate(milestone.completedAt!),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.success,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
              ),
            ] else if (milestone.targetDate != null) ...[
              Text(
                _formatDate(milestone.targetDate!),
                style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// Sub-goal Item
// ---------------------------------------------------------------------------

class _SubGoalItem extends StatefulWidget {
  const _SubGoalItem({
    super.key,
    required this.subGoal,
    this.onProgressChanged,
  });

  final SubGoal subGoal;
  final void Function(int progress)? onProgressChanged;

  @override
  State<_SubGoalItem> createState() => _SubGoalItemState();
}

class _SubGoalItemState extends State<_SubGoalItem> {
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.subGoal.progress.toDouble();
  }

  @override
  void didUpdateWidget(_SubGoalItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subGoal.progress != widget.subGoal.progress) {
      _sliderValue = widget.subGoal.progress.toDouble();
    }
  }

  bool get _isManual =>
      widget.subGoal.linkedModule == null || widget.subGoal.isOverridden;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sub = widget.subGoal;

    return Semantics(
      label: 'Sub-objetivo: ${sub.name}, progreso ${sub.progress}%',
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sub.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${(sub.weight * 100).round()}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.goals.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${sub.progress}%',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.goals,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (sub.description != null && sub.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  sub.description!,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 8),
              if (_isManual && widget.onProgressChanged != null)
                Semantics(
                  label: 'Ajustar progreso de ${sub.name}',
                  slider: true,
                  child: Slider(
                    key: ValueKey('sub_goal_slider_${sub.id}'),
                    value: _sliderValue,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${_sliderValue.round()}%',
                    activeColor: AppColors.goals,
                    onChanged: (v) => setState(() => _sliderValue = v),
                    onChangeEnd: (v) =>
                        widget.onProgressChanged!(v.round()),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: sub.progress / 100.0,
                    backgroundColor: AppColors.goals.withOpacity(0.1),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.goals),
                    minHeight: 6,
                  ),
                ),
              if (sub.linkedModule != null && !sub.isOverridden) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.link, size: 12,
                        color: theme.textTheme.bodySmall?.color),
                    const SizedBox(width: 4),
                    Text(
                      'Auto: ${sub.linkedModule}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
