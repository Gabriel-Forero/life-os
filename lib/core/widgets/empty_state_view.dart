import 'package:flutter/material.dart';
import 'package:life_os/core/constants/app_colors.dart';

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionColor,
    this.testId,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? actionColor;
  final String? testId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final muted = AppColors.textSecondary(brightness);

    return Semantics(
      label: '$title. $message',
      child: Center(
        key: testId != null ? ValueKey(testId) : null,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon in a soft circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: muted.withAlpha(12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: muted),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onAction,
                  style: actionColor != null
                      ? FilledButton.styleFrom(backgroundColor: actionColor)
                      : null,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
