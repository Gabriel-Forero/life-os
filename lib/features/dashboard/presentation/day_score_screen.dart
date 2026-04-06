import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/widgets/animated_list_item.dart';
import 'package:life_os/features/dashboard/providers/day_score_notifier.dart';

// ---------------------------------------------------------------------------
// DayScore Detail Screen
// ---------------------------------------------------------------------------

/// Pantalla de desglose del DayScore.
///
/// Muestra el anillo principal de puntuacion y una lista de componentes
/// por modulo con su peso y aporte individual.
///
/// A11Y-DASH-02: todos los graficos tienen Semantics con descripcion textual.
class DayScoreScreen extends ConsumerStatefulWidget {
  const DayScoreScreen({super.key});

  @override
  ConsumerState<DayScoreScreen> createState() => _DayScoreScreenState();
}

class _DayScoreScreenState extends ConsumerState<DayScoreScreen> {
  Future<void> _recalculate() async {
    await ref.read(dayScoreNotifierProvider).calculateDayScore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(dayScoreNotifierProvider);
    final state = notifier.state;
    final score = state.todayScore ?? 0;
    final components = state.components;

    return Scaffold(
      key: const ValueKey('day-score-screen'),
      appBar: AppBar(
        key: const ValueKey('day-score-app-bar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.dayScore,
        title: Semantics(
          header: true,
          child: const Text(
            'DayScore',
            key: ValueKey('day-score-screen-title'),
          ),
        ),
        actions: [
          Semantics(
            label: 'Recalcular puntuacion del dia',
            button: true,
            child: IconButton(
              key: const ValueKey('day-score-recalculate-button'),
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Recalcular',
              onPressed: _recalculate,
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                const SizedBox(height: 16),

                // --- Anillo central de puntuacion ---
                Semantics(
                  label: 'Puntuacion del dia: $score de 100',
                  child: Center(
                    child: Hero(
                      tag: 'day-score-ring',
                      child: _LargeScoreRing(
                        key: const ValueKey('day-score-large-ring'),
                        score: score,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Center(
                  child: Text(
                    _scoreLabel(score),
                    key: const ValueKey('day-score-label'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _scoreLabelColor(score),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(height: 32),

                // --- Desglose por modulo ---
                Semantics(
                  header: true,
                  child: Text(
                    'Desglose por modulo',
                    key: const ValueKey('day-score-breakdown-header'),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),

                if (components.isEmpty)
                  Semantics(
                    label: 'Sin componentes de puntuacion disponibles',
                    child: const _EmptyComponentsCard(),
                  )
                else
                  ...components.asMap().entries.map(
                    (entry) {
                      final i = entry.key;
                      final comp = entry.value;
                      return AnimatedListItem(
                        index: i,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Semantics(
                            label: '${_moduleLabel(comp.moduleKey)}: '
                                '${comp.rawValue.toStringAsFixed(1)} puntos, '
                                'peso ${comp.weight}, '
                                'aporte ${comp.weightedScore.toStringAsFixed(1)}',
                            child: _ComponentRow(
                              key: ValueKey(
                                  'score-component-${comp.moduleKey}'),
                              component: comp,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 24),

                // --- Formula ---
                _FormulaCard(
                  key: const ValueKey('day-score-formula-card'),
                  components: components,
                  totalScore: score,
                ),

                if (state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Semantics(
                    label: 'Error: ${state.errorMessage}',
                    child: Card(
                      color: AppColors.error.withAlpha(20),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  String _scoreLabel(int score) {
    if (score >= 90) return 'Excelente';
    if (score >= 75) return 'Muy bien';
    if (score >= 60) return 'Bien';
    if (score >= 40) return 'Regular';
    return 'Necesita mejora';
  }

  Color _scoreLabelColor(int score) {
    if (score >= 75) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  String _moduleLabel(String key) => switch (key) {
        'finance' => 'Finanzas',
        'gym' => 'Gimnasio',
        'nutrition' => 'Nutricion',
        'habits' => 'Habitos',
        _ => key,
      };
}

// ---------------------------------------------------------------------------
// Widget: Anillo de puntuacion grande
// ---------------------------------------------------------------------------

class _LargeScoreRing extends StatelessWidget {
  const _LargeScoreRing({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        fit: StackFit.expand,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: score / 100.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => CircularProgressIndicator(
              value: value,
              strokeWidth: 14,
              backgroundColor: AppColors.dayScore.withAlpha(30),
              valueColor: AlwaysStoppedAnimation<Color>(_ringColor(score)),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$score',
                  key: const ValueKey('large-ring-score-value'),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: _ringColor(score),
                      ),
                ),
                Text(
                  'de 100',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _ringColor(score).withAlpha(180),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _ringColor(int score) {
    if (score >= 75) return AppColors.success;
    if (score >= 50) return AppColors.dayScore;
    return AppColors.error;
  }
}

// ---------------------------------------------------------------------------
// Widget: Fila de componente de modulo
// ---------------------------------------------------------------------------

class _ComponentRow extends StatelessWidget {
  const _ComponentRow({super.key, required this.component});

  final ScoreComponentData component;

  Color _moduleColor(String key) => switch (key) {
        'finance' => AppColors.finance,
        'gym' => AppColors.gym,
        'nutrition' => AppColors.nutrition,
        'habits' => AppColors.habits,
        _ => AppColors.info,
      };

  IconData _moduleIcon(String key) => switch (key) {
        'finance' => Icons.account_balance_wallet_outlined,
        'gym' => Icons.fitness_center,
        'nutrition' => Icons.restaurant_menu,
        'habits' => Icons.check_circle_outline,
        _ => Icons.widgets_outlined,
      };

  String _moduleLabel(String key) => switch (key) {
        'finance' => 'Finanzas',
        'gym' => 'Gimnasio',
        'nutrition' => 'Nutricion',
        'habits' => 'Habitos',
        _ => key,
      };

  @override
  Widget build(BuildContext context) {
    final color = _moduleColor(component.moduleKey);
    final fraction = component.rawValue / 100.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _moduleIcon(component.moduleKey),
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _moduleLabel(component.moduleKey),
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${component.rawValue.toStringAsFixed(0)}/100',
                  key: ValueKey(
                      'component-score-${component.moduleKey}'),
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: fraction),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                key: ValueKey(
                    'component-progress-${component.moduleKey}'),
                value: value,
                backgroundColor: color.withAlpha(30),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Peso: ${component.weight}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(130),
                      ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Aporte: ${component.weightedScore.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(130),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Tarjeta de formula
// ---------------------------------------------------------------------------

class _FormulaCard extends StatelessWidget {
  const _FormulaCard({
    super.key,
    required this.components,
    required this.totalScore,
  });

  final List<ScoreComponentData> components;
  final int totalScore;

  @override
  Widget build(BuildContext context) {
    final totalWeight =
        components.fold<double>(0, (s, c) => s + c.weight);
    final weightedSum =
        components.fold<double>(0, (s, c) => s + c.weightedScore);

    return Card(
      elevation: 0,
      color: AppColors.dayScore.withAlpha(15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.dayScore.withAlpha(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Semantics(
          label: 'Formula: suma ponderada ${weightedSum.toStringAsFixed(1)} '
              'dividida entre peso total ${totalWeight.toStringAsFixed(1)} '
              'igual a $totalScore',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Formula de calculo',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Σ(puntuacion × peso) / Σ(pesos) = $totalScore',
                key: const ValueKey('formula-display'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${weightedSum.toStringAsFixed(1)} / '
                '${totalWeight.toStringAsFixed(1)} = $totalScore',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.dayScore,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Sin componentes
// ---------------------------------------------------------------------------

class _EmptyComponentsCard extends StatelessWidget {
  const _EmptyComponentsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.bar_chart_outlined, size: 36),
            const SizedBox(height: 10),
            Text(
              'Sin datos de modulos',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Habilita modulos en Ajustes para ver el desglose.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
