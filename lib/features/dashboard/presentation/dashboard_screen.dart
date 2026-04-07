import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/constants/app_breakpoints.dart';
import 'package:life_os/core/constants/app_colors.dart';
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
      // Ensure dashboard shows content even if init partially fails
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
      // Reset the count so the snackbar does not appear again.
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

    return Scaffold(
      key: const ValueKey('dashboard-screen'),
      body: RefreshIndicator(
        color: AppColors.dayScore,
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),
                  // --- Saludo ---
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
                  const SizedBox(height: 8),

                  // --- Tarjeta DayScore ---
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
                  const SizedBox(height: 20),

                  // --- Seccion: Modulos ---
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

                  // --- Grid de tarjetas de modulo ---
                  if (dashState.isLoading)
                    const Center(child: CircularProgressIndicator())
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

                  const SizedBox(height: 20),

                  // --- Acciones rapidas ---
                  Semantics(
                    header: true,
                    child: Text(
                      'Acciones rapidas',
                      key: const ValueKey('dashboard-quick-actions-header'),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _QuickActions(
                    key: ValueKey('dashboard-quick-actions'),
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
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Tarjeta DayScore con anillo
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          left: BorderSide(
            color: AppColors.dayScore,
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Anillo de puntuacion — toca para ver desglose
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
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tu puntuacion de bienestar de hoy',
                    key: const ValueKey('day-score-subtitle'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(160),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    label: 'Ver desglose de puntuacion',
                    button: true,
                    child: OutlinedButton(
                      key: const ValueKey('day-score-detail-button'),
                      onPressed: () {
                        GoRouter.of(context).push(AppRoutes.dayScore);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.dayScore,
                        side: const BorderSide(color: AppColors.dayScore),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Ver desglose',
                        style: TextStyle(fontSize: 12),
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
// Widget: Anillo de puntuacion circular
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

    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        fit: StackFit.expand,
        children: [
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
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CircularProgressIndicator(
                key: const ValueKey('score-ring-progress'),
                value: value,
                strokeWidth: 8,
                backgroundColor: AppColors.dayScore.withAlpha(30),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.dayScore),
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
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.dayScore,
                            ),
                      ),
                      Text(
                        '/100',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.dayScore.withAlpha(180),
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

// ---------------------------------------------------------------------------
// Widget: Grid de tarjetas de modulo
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
    return PressableCard(
      onTap: () => GoRouter.of(context).go('/${data.moduleKey}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border(
            left: BorderSide(color: data.color, width: 3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Hero(
                    tag: 'module-icon-${data.moduleKey}',
                    child: Icon(
                      data.icon,
                      color: data.color,
                      size: 20,
                      semanticLabel: data.title,
                    ),
                  ),
                  const SizedBox(width: 8),
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
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(140),
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
// Widget: Sin modulos habilitados
// ---------------------------------------------------------------------------

class _EmptyModulesCard extends StatelessWidget {
  const _EmptyModulesCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.widgets_outlined, size: 40),
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Acciones rapidas
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
        onTap: () {
          GoRouter.of(context).push(AppRoutes.scoreHistory);
        },
      ),
      _QuickActionItem(
        key: const ValueKey('quick-action-monitoring'),
        icon: Icons.monitor_heart_outlined,
        label: 'Monitoreo',
        color: AppColors.gym,
        onTap: () {
          GoRouter.of(context).push(AppRoutes.monitoring);
        },
      ),
      _QuickActionItem(
        key: const ValueKey('quick-action-evolution'),
        icon: Icons.timeline_outlined,
        label: 'Evolucion',
        color: AppColors.habits,
        onTap: () {
          GoRouter.of(context).push(AppRoutes.evolution);
        },
      ),
    ];

    return Row(
      children: actions
          .map(
            (a) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: a,
              ),
            ),
          )
          .toList(),
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
    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
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
// Widget: Banner de error
// ---------------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
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
