import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/widgets/chart_card.dart';
import 'package:life_os/features/goals/domain/goals_input.dart';

// ---------------------------------------------------------------------------
// Goal Detail Screen
// ---------------------------------------------------------------------------

class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({
    super.key,
    required this.goalId,
  });

  final int goalId;

  static const _goalsColor = AppColors.goals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final goalsDao = ref.watch(goalsDaoProvider);

    return StreamBuilder<LifeGoal?>(
      stream: goalsDao.watchGoal(goalId),
      builder: (context, goalSnapshot) {
        final goal = goalSnapshot.data;

        if (goal == null) {
          return Scaffold(
            key: const ValueKey('goal_detail_screen'),
            appBar: AppBar(title: const Text('Objetivo'), centerTitle: true, foregroundColor: AppColors.goals),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final category = GoalCategory.fromString(goal.category);
        final categoryLabel = category?.displayName ?? goal.category;

        return Scaffold(
          key: const ValueKey('goal_detail_screen'),
          backgroundColor: theme.scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              // App bar with hero color
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                backgroundColor: Color(goal.color),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    goal.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  background: Container(
                    color: Color(goal.color).withOpacity(0.8),
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
                            label: Text(_statusLabel(goal.status)),
                            backgroundColor:
                                _statusColor(goal.status).withOpacity(0.1),
                            labelStyle: TextStyle(
                              color: _statusColor(goal.status),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      if (goal.description != null &&
                          goal.description!.isNotEmpty) ...[
                        Text(
                          goal.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Progress section
                      _GoalProgressSection(goal: goal),
                      const SizedBox(height: 12),

                      // Sub-goals progress chart
                      _SubGoalProgressChart(
                        goalId: goalId,
                        goalColor: Color(goal.color),
                      ),
                      const SizedBox(height: 12),

                      // AI deadline prediction card
                      _DeadlinePredictionCard(goal: goal),
                      const SizedBox(height: 24),

                      // Milestones timeline section
                      Text(
                        'Hoja de ruta',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MilestonesTimeline(
                        goalId: goalId,
                        goalProgress: goal.progress,
                        goalColor: Color(goal.color),
                      ),
                      const SizedBox(height: 24),

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

              // Sub-goals list from DB
              StreamBuilder<List<SubGoal>>(
                stream: goalsDao.watchSubGoals(goalId),
                builder: (context, subSnapshot) {
                  final subGoals = subSnapshot.data ?? [];
                  if (subGoals.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Aun no hay sub-objetivos para este objetivo.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    );
                  }
                  return SliverList(
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
                            onProgressChanged: (p) {
                              goalsDao.updateSubGoalProgress(sub.id, p);
                            },
                          ),
                        );
                      },
                      childCount: subGoals.length,
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
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
// Deadline Prediction Card (Feature 2)
// ---------------------------------------------------------------------------

class _DeadlinePredictionCard extends StatelessWidget {
  const _DeadlinePredictionCard({required this.goal});

  final LifeGoal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prediction = _computePrediction();

    return Semantics(
      label: 'Prediccion de deadline: ${prediction.message}',
      child: Container(
        key: const ValueKey('deadline_prediction_card'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: prediction.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: prediction.color.withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(prediction.icon, color: prediction.color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prediccion inteligente',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: prediction.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    prediction.message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _DeadlinePrediction _computePrediction() {
    final now = DateTime.now();
    final daysSinceCreation =
        now.difference(goal.createdAt).inDays.clamp(1, 36500);
    final progress = goal.progress;

    // No progress at all
    if (progress == 0) {
      return const _DeadlinePrediction(
        color: AppColors.error,
        icon: Icons.warning_amber_rounded,
        message:
            'Sin progreso registrado. Comienza hoy para alcanzar tu meta.',
      );
    }

    final progressPerDay = progress / daysSinceCreation;
    final remaining = 100 - progress;
    final estimatedDaysToComplete =
        (progressPerDay > 0) ? (remaining / progressPerDay).ceil() : null;

    // No target date — just show estimated completion
    if (goal.targetDate == null) {
      if (estimatedDaysToComplete == null) {
        return const _DeadlinePrediction(
          color: AppColors.error,
          icon: Icons.warning_amber_rounded,
          message: 'Sin progreso registrado. Comienza hoy para alcanzar tu meta.',
        );
      }
      final estimatedDate =
          now.add(Duration(days: estimatedDaysToComplete));
      return _DeadlinePrediction(
        color: AppColors.goals,
        icon: Icons.lightbulb_outline,
        message:
            'Al ritmo actual, completaras esta meta el ${_fmt(estimatedDate)}.',
      );
    }

    final deadline = goal.targetDate!;
    final daysToDeadline = deadline.difference(now).inDays;

    if (estimatedDaysToComplete == null) {
      return _DeadlinePrediction(
        color: AppColors.error,
        icon: Icons.warning_amber_rounded,
        message: 'Sin progreso registrado. Comienza hoy para alcanzar tu meta.',
      );
    }

    final estimatedDate = now.add(Duration(days: estimatedDaysToComplete));
    final delta = estimatedDaysToComplete - daysToDeadline;

    if (delta <= 0) {
      // On track
      return _DeadlinePrediction(
        color: AppColors.success,
        icon: Icons.check_circle_outline,
        message:
            'Al ritmo actual, completaras esta meta el ${_fmt(estimatedDate)} \u2713',
      );
    } else {
      // Behind
      return _DeadlinePrediction(
        color: AppColors.warning,
        icon: Icons.schedule,
        message:
            'Necesitas aumentar tu ritmo. Al paso actual, completaras el '
            '${_fmt(estimatedDate)}, $delta dias despues de tu deadline.',
      );
    }
  }

  String _fmt(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

class _DeadlinePrediction {
  const _DeadlinePrediction({
    required this.color,
    required this.icon,
    required this.message,
  });

  final Color color;
  final IconData icon;
  final String message;
}

// ---------------------------------------------------------------------------
// Milestones Timeline (Feature 1)
// ---------------------------------------------------------------------------

class _MilestonesTimeline extends ConsumerWidget {
  const _MilestonesTimeline({
    required this.goalId,
    required this.goalProgress,
    required this.goalColor,
  });

  final int goalId;
  final int goalProgress;
  final Color goalColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsDao = ref.watch(goalsDaoProvider);

    return StreamBuilder<List<GoalMilestone>>(
      stream: goalsDao.watchMilestones(goalId),
      builder: (context, snapshot) {
        final milestones = snapshot.data ?? [];
        return _MilestonesTimelineContent(
          milestones: milestones,
          goalId: goalId,
          goalProgress: goalProgress,
          goalColor: goalColor,
        );
      },
    );
  }
}

class _MilestonesTimelineContent extends ConsumerWidget {
  const _MilestonesTimelineContent({
    required this.milestones,
    required this.goalId,
    required this.goalProgress,
    required this.goalColor,
  });

  final List<GoalMilestone> milestones;
  final int goalId;
  final int goalProgress;
  final Color goalColor;

  static const _nodeSize = 32.0;
  static const _lineHeight = 3.0;
  static const _nodeSpacing = 100.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (milestones.isEmpty) {
      return _buildEmptyState(context, ref, theme);
    }

    // Total width: padding + nodes + lines between them + add button
    final totalNodes = milestones.length;
    final totalWidth =
        16 + totalNodes * _nodeSpacing + _nodeSize + 80;

    return SizedBox(
      height: 100,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Horizontal connector line
              Positioned(
                left: 16 + _nodeSize / 2,
                top: 24,
                width: totalNodes * _nodeSpacing + 40,
                height: _lineHeight,
                child: _buildConnectorLine(),
              ),
              // Progress marker on the line
              _buildProgressMarker(totalNodes),
              // Milestone nodes
              ...List.generate(milestones.length, (i) {
                final ms = milestones[i];
                final left = 16.0 + i * _nodeSpacing;
                return Positioned(
                  left: left,
                  top: 0,
                  child: _MilestoneNode(
                    milestone: ms,
                    goalProgress: goalProgress,
                    nodeSize: _nodeSize,
                    onTap: () => _showMilestoneDialog(context, ref, ms),
                  ),
                );
              }),
              // "Agregar milestone" button at the end
              Positioned(
                left: 16.0 + totalNodes * _nodeSpacing,
                top: 8,
                child: _AddMilestoneButton(
                  goalId: goalId,
                  milestoneCount: milestones.length,
                  nodeSize: _nodeSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectorLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, _lineHeight),
          painter: _TimelineLinePainter(goalColor: goalColor),
        );
      },
    );
  }

  Widget _buildProgressMarker(int totalNodes) {
    if (totalNodes == 0) return const SizedBox.shrink();
    // Position the marker based on current progress across the full line
    final lineWidth = totalNodes * _nodeSpacing + 40.0;
    final markerX = 16 + _nodeSize / 2 + (goalProgress / 100.0) * lineWidth;

    return Positioned(
      left: markerX - 6,
      top: 18,
      child: Semantics(
        label: 'Progreso actual: $goalProgress%',
        child: Container(
          key: const ValueKey('milestone_progress_marker'),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: goalColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: goalColor.withOpacity(0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, WidgetRef ref, ThemeData theme) {
    return Container(
      key: const ValueKey('milestones_empty'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.dividerColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.flag_outlined,
            color: theme.textTheme.bodySmall?.color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sin hitos definidos.',
              style: theme.textTheme.bodySmall,
            ),
          ),
          _AddMilestoneButton(
            goalId: goalId,
            milestoneCount: 0,
            nodeSize: _nodeSize,
          ),
        ],
      ),
    );
  }

  void _showMilestoneDialog(
    BuildContext context,
    WidgetRef ref,
    GoalMilestone milestone,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _MilestoneActionDialog(
        milestone: milestone,
        ref: ref,
      ),
    );
  }
}

class _TimelineLinePainter extends CustomPainter {
  _TimelineLinePainter({required this.goalColor});
  final Color goalColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = goalColor.withOpacity(0.25)
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TimelineLinePainter old) =>
      old.goalColor != goalColor;
}

// ---------------------------------------------------------------------------
// Milestone Node
// ---------------------------------------------------------------------------

class _MilestoneNode extends StatelessWidget {
  const _MilestoneNode({
    required this.milestone,
    required this.goalProgress,
    required this.nodeSize,
    required this.onTap,
  });

  final GoalMilestone milestone;
  final int goalProgress;
  final double nodeSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = milestone.isCompleted;
    final isCurrent =
        !isCompleted && goalProgress >= milestone.targetProgress - 10;

    final Color nodeColor;
    final Color borderColor;
    final Widget nodeIcon;

    if (isCompleted) {
      nodeColor = AppColors.success;
      borderColor = AppColors.success;
      nodeIcon = const Icon(Icons.check, color: Colors.white, size: 16);
    } else if (isCurrent) {
      nodeColor = AppColors.warning;
      borderColor = AppColors.warning;
      nodeIcon = Icon(
        Icons.circle,
        color: Colors.white.withOpacity(0.9),
        size: 10,
      );
    } else {
      nodeColor = Colors.transparent;
      borderColor = Colors.grey.withOpacity(0.5);
      nodeIcon = Icon(
        Icons.circle_outlined,
        color: Colors.grey.withOpacity(0.5),
        size: 10,
      );
    }

    return Semantics(
      label:
          'Hito: ${milestone.name}, ${isCompleted ? "completado" : "pendiente"}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: nodeSize,
          child: Column(
            children: [
              // Target date above node
              SizedBox(
                height: 16,
                child: milestone.targetDate != null
                    ? Text(
                        _fmtShort(milestone.targetDate!),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      )
                    : const SizedBox.shrink(),
              ),
              // Circle node
              Container(
                width: nodeSize,
                height: nodeSize,
                decoration: BoxDecoration(
                  color: isCompleted || isCurrent
                      ? nodeColor
                      : theme.scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: Center(child: nodeIcon),
              ),
              const SizedBox(height: 4),
              // Milestone name below node
              SizedBox(
                width: nodeSize + 20,
                child: Text(
                  milestone.name,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    fontWeight: isCompleted || isCurrent
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtShort(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// Add Milestone Button
// ---------------------------------------------------------------------------

class _AddMilestoneButton extends ConsumerWidget {
  const _AddMilestoneButton({
    required this.goalId,
    required this.milestoneCount,
    required this.nodeSize,
  });

  final int goalId;
  final int milestoneCount;
  final double nodeSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      label: 'Agregar milestone',
      button: true,
      child: GestureDetector(
        key: const ValueKey('add_milestone_button'),
        onTap: () => _showAddMilestoneDialog(context, ref),
        child: Container(
          width: nodeSize,
          height: nodeSize,
          decoration: BoxDecoration(
            color: AppColors.goals.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.goals.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: const Icon(Icons.add, color: AppColors.goals, size: 18),
        ),
      ),
    );
  }

  void _showAddMilestoneDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => _AddMilestoneDialog(
        goalId: goalId,
        sortOrder: milestoneCount,
        ref: ref,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Milestone Action Dialog (tap existing milestone)
// ---------------------------------------------------------------------------

class _MilestoneActionDialog extends StatelessWidget {
  const _MilestoneActionDialog({
    required this.milestone,
    required this.ref,
  });

  final GoalMilestone milestone;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      key: const ValueKey('milestone_action_dialog'),
      title: Text(milestone.name),
      content: Text(
        milestone.isCompleted
            ? 'Este hito ya esta completado.'
            : 'Que deseas hacer con este hito?',
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        if (!milestone.isCompleted)
          ElevatedButton.icon(
            key: const ValueKey('complete_milestone_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Marcar completado'),
            onPressed: () async {
              final goalsNotifier = ref.read(goalsNotifierProvider);
              await goalsNotifier.completeMilestone(milestone.id);
              if (context.mounted) Navigator.pop(context);
            },
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Add Milestone Dialog
// ---------------------------------------------------------------------------

class _AddMilestoneDialog extends StatefulWidget {
  const _AddMilestoneDialog({
    required this.goalId,
    required this.sortOrder,
    required this.ref,
  });

  final int goalId;
  final int sortOrder;
  final WidgetRef ref;

  @override
  State<_AddMilestoneDialog> createState() => _AddMilestoneDialogState();
}

class _AddMilestoneDialogState extends State<_AddMilestoneDialog> {
  final _nameController = TextEditingController();
  int _targetProgress = 50;
  DateTime? _targetDate;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    final goalsNotifier = widget.ref.read(goalsNotifierProvider);
    await goalsNotifier.addMilestone(
      MilestoneInput(
        goalId: widget.goalId,
        name: name,
        targetProgress: _targetProgress,
        targetDate: _targetDate,
        sortOrder: widget.sortOrder,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      key: const ValueKey('add_milestone_dialog'),
      title: const Text('Agregar milestone'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const ValueKey('milestone_name_field'),
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del hito',
                hintText: 'Ej: Primera revision',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            Text(
              'Progreso objetivo: $_targetProgress%',
              style: theme.textTheme.bodySmall,
            ),
            Slider(
              key: const ValueKey('milestone_progress_slider'),
              value: _targetProgress.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              label: '$_targetProgress%',
              activeColor: AppColors.goals,
              onChanged: (v) =>
                  setState(() => _targetProgress = v.round()),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _targetDate != null
                        ? '${_targetDate!.day.toString().padLeft(2, '0')}/'
                            '${_targetDate!.month.toString().padLeft(2, '0')}/'
                            '${_targetDate!.year}'
                        : 'Sin fecha limite',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  key: const ValueKey('milestone_pick_date_button'),
                  onPressed: _pickDate,
                  child: const Text('Elegir fecha'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          key: const ValueKey('save_milestone_button'),
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.goals,
            foregroundColor: Colors.white,
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
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

// ---------------------------------------------------------------------------
// Sub-Goal Progress Chart — bar chart showing each sub-goal's progress
// ---------------------------------------------------------------------------

class _SubGoalProgressChart extends ConsumerWidget {
  const _SubGoalProgressChart({
    required this.goalId,
    required this.goalColor,
  });

  final int goalId;
  final Color goalColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(goalsDaoProvider);

    return StreamBuilder<List<SubGoal>>(
      stream: dao.watchSubGoals(goalId),
      builder: (context, snapshot) {
        final subGoals = snapshot.data ?? [];

        if (subGoals.length < 1) {
          return ChartCard(
            title: 'Progreso de sub-objetivos',
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Sin sub-objetivos aun'),
              ),
            ),
          );
        }

        final spots = subGoals.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), e.value.progress.toDouble());
        }).toList();

        return ChartCard(
          key: const ValueKey('goal_subgoal_progress_chart'),
          title: 'Progreso de sub-objetivos',
          child: subGoals.length < 2
              ? _buildSingleSubGoalBar(subGoals.first, goalColor)
              : _buildBarChart(subGoals, goalColor),
        );
      },
    );
  }

  Widget _buildSingleSubGoalBar(SubGoal sub, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sub.name, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: sub.progress / 100.0,
              minHeight: 10,
              backgroundColor: color.withAlpha(30),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text('${sub.progress}%', style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<SubGoal> subGoals, Color color) {
    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: 100,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= subGoals.length) {
                    return const SizedBox.shrink();
                  }
                  final name = subGoals[idx].name;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      name.length > 6 ? '${name.substring(0, 6)}…' : name,
                      style: const TextStyle(fontSize: 9),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: Color(0x1A9E9E9E),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: subGoals.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.progress.toDouble(),
                  color: color,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
