import 'package:flutter/material.dart';
import 'package:life_os/core/constants/app_colors.dart';

class ErrorCard extends StatelessWidget {
  const ErrorCard({
    super.key,
    required this.message,
    this.onRetry,
    this.testId,
  });

  final String message;
  final VoidCallback? onRetry;
  final String? testId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Error: $message',
      child: Card(
        key: testId != null ? ValueKey(testId) : null,
        color: AppColors.error.withAlpha(25),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (onRetry != null)
                IconButton(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reintentar',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
