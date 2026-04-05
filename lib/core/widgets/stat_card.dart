import 'package:flutter/material.dart';
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
    final effectiveColor = color ?? theme.colorScheme.primary;

    return Semantics(
      label: '$label: $value',
      child: Card(
        key: testId != null ? ValueKey(testId) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: effectiveColor, size: 28),
              const SizedBox(height: 8),
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
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
