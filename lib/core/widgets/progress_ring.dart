import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:life_os/core/constants/app_typography.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 80,
    this.strokeWidth = 6,
    this.color,
    this.gradientColors,
    this.backgroundColor,
    this.label,
    this.testId,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Color? color;
  /// If provided, paints the arc with a sweep gradient instead of a flat color.
  final List<Color>? gradientColors;
  final Color? backgroundColor;
  final String? label;
  final String? testId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;
    final bgColor = backgroundColor ??
        (theme.brightness == Brightness.dark
            ? theme.dividerColor
            : effectiveColor.withAlpha(20));
    final clampedProgress = progress.clamp(0.0, 1.0);
    final percentage = (clampedProgress * 100).round();

    return Semantics(
      label: label != null
          ? '$label: $percentage%'
          : '$percentage% completado',
      child: SizedBox(
        key: testId != null ? ValueKey(testId) : null,
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(
            progress: clampedProgress,
            color: effectiveColor,
            gradientColors: gradientColors,
            backgroundColor: bgColor,
            strokeWidth: strokeWidth,
          ),
          child: Center(
            child: Text(
              '$percentage%',
              style: AppTypography.numericDisplay(
                fontSize: size * 0.2,
                color: effectiveColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    this.gradientColors,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final List<Color>? gradientColors;
  final Color backgroundColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Foreground arc
    final fgPaint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (gradientColors != null && gradientColors!.length >= 2) {
      fgPaint.shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + 2 * math.pi * progress,
        colors: gradientColors!,
      ).createShader(rect);
    } else {
      fgPaint.color = color;
    }

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.gradientColors != gradientColors;
}
