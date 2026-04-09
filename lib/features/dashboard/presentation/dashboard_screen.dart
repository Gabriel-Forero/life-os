import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/constants/app_breakpoints.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/constants/app_decorations.dart';
import 'package:life_os/core/constants/app_typography.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/router/app_router.dart';
import 'package:life_os/core/widgets/animated_list_item.dart';
import 'package:life_os/core/widgets/pressable_card.dart';
import 'package:life_os/features/dashboard/providers/dashboard_notifier.dart';

// ---------------------------------------------------------------------------
// Main Dashboard Screen
// ---------------------------------------------------------------------------

/// Pantalla principal del dashboard de LifeOS.
///
/// Muestra: saludo, anillo DayScore, tarjetas de modulos habilitados
/// ordenados por prioridad, y acciones rapidas.
///
/// A11Y-DASH-01: todos los elementos interactivos tienen Semantics
/// con etiquetas en espanol.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _recurringSnackbarShown = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await ref.read(dashboardNotifierProvider).initialize();
      await ref.read(dayScoreNotifierProvider).initialize();
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowRecurringSnackbar());
    } catch (e) {
      debugPrint('Dashboard init error: $e');
    }
  }

  void _maybeShowRecurringSnackbar() {
    if (_recurringSnackbarShown || !mounted) return;
    final count = ref.read(recurringCreatedCountProvider);
    if (count > 0) {
      _recurringSnackbarShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Se crearon $count transaccione${count == 1 ? '' : 's'} recurrentes'),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Ver',
            onPressed: () => GoRouter.of(context).go(AppRoutes.finance),
          ),
        ),
      );
      ref.read(recurringCreatedCountProvider.notifier).state = 0;
    }
  }

  Future<void> _refresh() async {
    await ref.read(dayScoreNotifierProvider).calculateDayScore(DateTime.now());
    await ref.read(dashboardNotifierProvider).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardNotifier = ref.watch(dashboardNotifierProvider);
    final dayScoreNotifier = ref.watch(dayScoreNotifierProvider);
    final dashState = dashboardNotifier.state;
    final greeting = dashboardNotifier.greeting();
    final score = dayScoreNotifier.state.todayScore ?? dashState.dayScore;
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      key: const ValueKey('dashboard-screen'),
      body: RefreshIndicator(
        color: AppColors.dayScore,
        onRefresh: _refresh,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = AppBreakpoints.isMediumOrLarger(constraints);
            final maxWidth = isWide
                ? AppBreakpoints.maxContentWidth
                : double.infinity;
            final hPad = isWide ? 24.0 : 16.0;

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),

                              // ── Greeting ──
                              Semantics(
                                header: true,
                                label: '$greeting — Panel principal',
                                child: Text(
                                  greeting,
                                  key: const ValueKey('dashboard-greeting-text'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _todayLabel(),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary(brightness),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // ── DayScore Card ──
                              Semantics(
                                label: score != null
                                    ? 'Puntuacion del dia: $score de 100'
                                    : 'Calculando puntuacion del dia',
                                child: _DayScoreCard(
                                  key: const ValueKey('dashboard-day-score-card'),
                                  score: score,
                                  isLoading: dashState.isLoading,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ── Quick Actions ──
                              const _QuickActions(
                                key: ValueKey('dashboard-quick-actions'),
                              ),
                              const SizedBox(height: 24),

                              // ── Modules Section ──
                              Semantics(
                                header: true,
                                child: Text(
                                  'Mis modulos',
                                  key: const ValueKey('dashboard-modules-header'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(height: 12),

                              if (dashState.isLoading)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: const CircularProgressIndicator(
                                      color: AppColors.dayScore,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                )
                              else if (dashState.cards.isEmpty)
                                Semantics(
                                  label: 'No hay modulos habilitados',
                                  child: const _EmptyModulesCard(),
                                )
                              else
                                _ModuleCardGrid(
                                  key: const ValueKey('dashboard-module-grid'),
                                  cards: dashState.cards,
                                ),

                              if (dashState.errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Semantics(
                                  label: 'Error: ${dashState.errorMessage}',
                                  child: _ErrorBanner(
                                    key: const ValueKey('dashboard-error-banner'),
                                    message: dashState.errorMessage!,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const days = ['Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado', 'Domingo'];
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${days[now.weekday - 1]}, ${now.day} de ${months[now.month - 1]}';
  }
}

// ---------------------------------------------------------------------------
// Widget: DayScore Card — gradient ring with glass card
// ---------------------------------------------------------------------------

class _DayScoreCard extends StatelessWidget {
  const _DayScoreCard({
    super.key,
    required this.score,
    required this.isLoading,
  });

  final int? score;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground(brightness),
        borderRadius: BorderRadius.circular(AppDecorations.radiusLg),
        border: Border.all(
          color: isDark
              ? AppColors.dayScore.withAlpha(25)
              : AppColors.dayScore.withAlpha(15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.dayScore.withAlpha(isDark ? 12 : 6),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Score Ring — toca para ver desglose
            GestureDetector(
              onTap: () => GoRouter.of(context).push(AppRoutes.dayScore),
              child: Hero(
                tag: 'day-score-ring',
                child: _ScoreRing(
                  key: const ValueKey('day-score-ring'),
                  score: score,
                  isLoading: isLoading,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DayScore',
                    key: const ValueKey('day-score-title'),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tu puntuacion de bienestar de hoy',
                    key: const ValueKey('day-score-subtitle'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary(brightness),
                        ),
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    label: 'Ver desglose de puntuacion',
                    button: true,
                    child: OutlinedButton.icon(
                      key: const ValueKey('day-score-detail-button'),
                      onPressed: () {
                        GoRouter.of(context).push(AppRoutes.dayScore);
                      },
                      icon: const Icon(Icons.bar_chart_rounded, size: 16),
                      label: const Text('Ver desglose'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.dayScore,
                        side: BorderSide(
                          color: AppColors.dayScore.withAlpha(isDark ? 60 : 40),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
}

// ---------------------------------------------------------------------------
// Widget: Score Ring with gradient sweep
// ---------------------------------------------------------------------------

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({
    super.key,
    required this.score,
    required this.isLoading,
  });

  final int? score;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final displayScore = score ?? 0;
    final fraction = displayScore / 100.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle glow behind the ring
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                if (!isLoading && displayScore > 0)
                  BoxShadow(
                    color: AppColors.dayScore.withAlpha(isDark ? 30 : 15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
              ],
            ),
          ),
          if (isLoading)
            const CircularProgressIndicator(
              key: ValueKey('score-ring-progress'),
              strokeWidth: 8,
              backgroundColor: Color(0x1EFFD700),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.dayScore),
            )
          else
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: fraction),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CustomPaint(
                key: const ValueKey('score-ring-progress'),
                painter: _GradientRingPainter(
                  progress: value,
                  gradientColors: const [AppColors.dayScore, AppColors.dayScoreEnd],
                  backgroundColor: AppColors.dayScore.withAlpha(isDark ? 20 : 15),
                  strokeWidth: 8,
                ),
              ),
            ),
          Center(
            child: isLoading
                ? const SizedBox.shrink()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$displayScore',
                        key: const ValueKey('score-ring-value'),
                        style: AppTypography.numericDisplay(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dayScore,
                        ),
                      ),
                      Text(
                        '/100',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.dayScore.withAlpha(150),
                            ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Paints a ring arc with a sweep gradient.
class _GradientRingPainter extends CustomPainter {
  _GradientRingPainter({
    required this.progress,
    required this.gradientColors,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  final double progress;
  final List<Color> gradientColors;
  final Color backgroundColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -3.14159 / 2;

    // Background
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = backgroundColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    // Gradient arc
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + 6.28318 * progress,
        colors: gradientColors,
      ).createShader(rect);

    canvas.drawArc(rect, startAngle, 6.28318 * progress, false, paint);
  }

  @override
  bool shouldRepaint(_GradientRingPainter old) =>
      old.progress != progress;
}

// ---------------------------------------------------------------------------
// Widget: Module Card Grid
// ---------------------------------------------------------------------------

class _ModuleCardGrid extends StatelessWidget {
  const _ModuleCardGrid({super.key, required this.cards});

  final List<ModuleCardData> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = AppBreakpoints.gridColumns(constraints.maxWidth);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return AnimatedListItem(
              index: index,
              child: Semantics(
                label: '${card.title}: ${card.subtitle}. Toca para ver detalles.',
                button: true,
                child: _ModuleCard(
                  key: ValueKey('module-card-${card.moduleKey}'),
                  data: card,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({super.key, required this.data});

  final ModuleCardData data;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return PressableCard(
      onTap: () => GoRouter.of(context).go('/${data.moduleKey}'),
      child: Container(
        decoration: AppDecorations.moduleCard(brightness, accent: data.color),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon in a tinted circle
                  Hero(
                    tag: 'module-icon-${data.moduleKey}',
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: data.color.withAlpha(isDark ? 25 : 15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        data.icon,
                        color: data.color,
                        size: 18,
                        semanticLabel: data.title,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      data.title,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                data.subtitle,
                key: ValueKey('module-card-subtitle-${data.moduleKey}'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary(brightness),
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Empty Modules
// ---------------------------------------------------------------------------

class _EmptyModulesCard extends StatelessWidget {
  const _EmptyModulesCard();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      decoration: AppDecorations.card(brightness),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.textSecondary(brightness).withAlpha(12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.widgets_outlined,
              size: 28,
              color: AppColors.textSecondary(brightness),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No hay modulos habilitados',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Activa modulos en Ajustes para verlos aqui.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Quick Actions — horizontal row of action chips
// ---------------------------------------------------------------------------

class _QuickActions extends StatelessWidget {
  const _QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionItem(
        key: const ValueKey('quick-action-history'),
        icon: Icons.history_rounded,
        label: 'Historial',
        color: AppColors.dayScore,
        onTap: () => GoRouter.of(context).push(AppRoutes.scoreHistory),
      ),
      _QuickActionItem(
        key: const ValueKey('quick-action-monitoring'),
        icon: Icons.monitor_heart_outlined,
        label: 'Monitoreo',
        color: AppColors.gym,
        onTap: () => GoRouter.of(context).push(AppRoutes.monitoring),
      ),
      _QuickActionItem(
        key: const ValueKey('quick-action-evolution'),
        icon: Icons.timeline_outlined,
        label: 'Evolucion',
        color: AppColors.habits,
        onTap: () => GoRouter.of(context).push(AppRoutes.evolution),
      ),
    ];

    return Row(
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: actions[i]),
        ],
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Semantics(
      label: label,
      button: true,
      child: PressableCard(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground(brightness),
            borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
            border: Border.all(
              color: color.withAlpha(isDark ? 35 : 20),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(isDark ? 10 : 5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withAlpha(isDark ? 20 : 12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary(brightness),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Error Banner
// ---------------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(isDark ? 15 : 10),
        borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
        border: Border.all(color: AppColors.error.withAlpha(isDark ? 40 : 25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
