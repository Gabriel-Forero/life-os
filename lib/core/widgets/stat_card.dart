import 'package:flutter/material.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/constants/app_decorations.dart';
import 'package:life_os/core/constants/app_typography.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color,
    this.testId,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? color;
  final String? testId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final effectiveColor = color ?? theme.colorScheme.primary;

    return Semantics(
      label: '$label: $value',
      child: Container(
        key: testId != null ? ValueKey(testId) : null,
        decoration: AppDecorations.moduleCard(brightness, accent: effectiveColor),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with subtle color background circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: effectiveColor.withAlpha(
                  brightness == Brightness.dark ? 20 : 12,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: effectiveColor, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: AppTypography.numericDisplay(
                fontSize: 20,
                color: effectiveColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary(brightness),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
