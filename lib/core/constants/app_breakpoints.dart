import 'package:flutter/widgets.dart';

abstract final class AppBreakpoints {
  /// Phone → Tablet transition
  static const double compact = 600;

  /// Tablet → Desktop transition
  static const double expanded = 1200;

  /// Maximum content width on desktop (prevents ultra-wide stretching)
  static const double maxContentWidth = 960;

  /// Maximum content width on tablet
  static const double maxContentWidthMedium = 720;

  /// Returns the number of grid columns based on available width.
  static int gridColumns(
    double width, {
    int compactCols = 2,
    int mediumCols = 3,
    int expandedCols = 4,
  }) {
    if (width >= expanded) return expandedCols;
    if (width >= compact) return mediumCols;
    return compactCols;
  }

  /// Whether the given [constraints] represent a desktop-class display.
  static bool isExpanded(BoxConstraints constraints) =>
      constraints.maxWidth >= expanded;

  /// Whether the given [constraints] represent at least a tablet display.
  static bool isMediumOrLarger(BoxConstraints constraints) =>
      constraints.maxWidth >= compact;
}
