import 'package:flutter/material.dart';

class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.child,
    this.height = 200,
    this.testId,
  });

  final String title;
  final Widget child;
  final double height;
  final String? testId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Grafico: $title',
      child: Card(
        key: testId != null ? ValueKey(testId) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              SizedBox(
                height: height,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
