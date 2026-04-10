import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  bool _isLoading = false;
  String? _cachedInsight;
  String? _errorMessage;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_cachedInsight == null) _runAnalysis();
    });
  }

  Future<String> _buildContextString() async {
    final now = DateTime.now();
    final from30 = now.subtract(const Duration(days: 30));

    final mentalRepo = ref.read(mentalRepositoryProvider);
    final sleepDao = ref.read(sleepRepositoryProvider);
    final habitsDao = ref.read(habitsRepositoryProvider);
    final financeRepo = ref.read(financeRepositoryProvider);
    final gymRepo = ref.read(gymRepositoryProvider);

    // --- Mood ---
    final moodLogs = await mentalRepo.getMoodLogs(from30, now);
    double avgMood = 0;
    if (moodLogs.isNotEmpty) {
      double total = 0;
      for (final m in moodLogs) {
        final v = (m.valence - 1) / 4.0 * 50.0;
        final e = (m.energy - 1) / 4.0 * 50.0;
        total += v + e;
      }
      avgMood = total / moodLogs.length;
    }

    // --- Sleep ---
    double avgSleepHours = 0;
    int sleepCount = 0;
    try {
      final sleepLogs = await sleepDao.watchSleepLogs(from30, now).first;
      sleepCount = sleepLogs.length;
      if (sleepLogs.isNotEmpty) {
        double totalH = 0;
        for (final s in sleepLogs) {
          totalH += s.wakeTime.difference(s.bedTime).inMinutes.abs() / 60.0;
        }
        avgSleepHours = totalH / sleepLogs.length;
      }
    } on Object {
      // sleep data unavailable
    }

    // --- Habits ---
    double habitsRate = 0;
    int habitCount = 0;
    try {
      final activeHabits = await habitsDao.watchActiveHabits().first;
      habitCount = activeHabits.length;
      if (habitCount > 0) {
        int done = 0;
        for (final h in activeHabits) {
          try {
            final logs = await habitsDao.watchHabitLogs(h.id, from30, now).first;
            done += logs.length;
          } on Object {
            // skip
          }
        }
        habitsRate = done / (habitCount * 30) * 100;
      }
    } on Object {
      // habits data unavailable
    }

    // --- Finance ---
    double dailySpend = 0;
    try {
      final transactions = await financeRepo.watchTransactions(from30, now).first;
      double total = 0;
      for (final t in transactions) {
        if (t.type == 'expense') {
          total += t.amountCents / 100.0;
        }
      }
      dailySpend = total / 30.0;
    } on Object {
      // finance data unavailable
    }

    // --- Workouts ---
    int recentWorkouts = 0;
    try {
      final allWorkouts = await gymRepo.watchWorkouts().first;
      recentWorkouts = allWorkouts.where((w) => w.startedAt.isAfter(from30)).length;
    } on Object {
      // gym data unavailable
    }
    final double weeklyWorkouts = recentWorkouts / 4.0;

    final lines = <String>[
      'Datos de los ultimos 30 dias:',
      if (moodLogs.isNotEmpty)
        'Humor promedio: ${avgMood.round()}/100 (${moodLogs.length} registros)',
      if (sleepCount > 0)
        'Sueno promedio: ${avgSleepHours.toStringAsFixed(1)}h/noche ($sleepCount registros)',
      if (habitCount > 0)
        'Habitos completados: ${habitsRate.round()}% ($habitCount habitos activos)',
      if (dailySpend > 0)
        'Gasto promedio: \$${dailySpend.toStringAsFixed(0)}/dia',
      if (recentWorkouts > 0)
        'Entrenamientos: ${weeklyWorkouts.toStringAsFixed(1)}/semana ($recentWorkouts en 30 dias)',
    ];

    return lines.join('\n');
  }

  Future<void> _runAnalysis() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _cachedInsight = null;
    });

    try {
      final contextStr = await _buildContextString();
      final aiNotifier = ref.read(aiNotifierProvider);

      await aiNotifier.initialize();

      final conversations = await aiNotifier.listConversations();
      final existing = conversations
          .where((c) => c.title == 'Patrones LifeOS')
          .firstOrNull;

      String conversationId;
      if (existing != null) {
        conversationId = existing.id;
        await aiNotifier.openConversation(conversationId);
      } else {
        final result = await aiNotifier.createConversation(
          title: 'Patrones LifeOS',
        );
        if (result.isSuccess && result.valueOrNull != null) {
          conversationId = result.valueOrNull!;
        } else {
          throw Exception('No se pudo crear la conversacion');
        }
      }

      final prompt = '$contextStr\n\n'
          'Basandote en estos datos, identifica 3 patrones o correlaciones '
          'entre mi sueno, ejercicio, gastos y estado de animo. '
          'Responde en espanol, de forma concisa.';

      final buffer = StringBuffer();
      final stream = aiNotifier.sendMessage(conversationId, prompt);
      await for (final chunk in stream) {
        buffer.write(chunk);
        if (mounted) {
          setState(() => _cachedInsight = buffer.toString());
        }
      }

      if (mounted) {
        setState(() {
          _lastUpdated = DateTime.now();
          _isLoading = false;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al obtener patrones: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mentalColor = AppColors.mental;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Patrones de IA'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: mentalColor,
        actions: [
          Semantics(
            button: true,
            label: 'Actualizar analisis',
            child: IconButton(
              key: const ValueKey('refresh-insights-button'),
              icon: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: mentalColor),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _runAnalysis,
              tooltip: 'Actualizar analisis',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            Card(
              key: const ValueKey('insights-header-card'),
              color: mentalColor.withAlpha(20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.auto_awesome, color: mentalColor, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'Patrones detectados',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: mentalColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Analisis de tus ultimos 30 dias de datos',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: mentalColor.withAlpha(180),
                      ),
                    ),
                    if (_lastUpdated != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Actualizado: ${_lastUpdated!.day}/${_lastUpdated!.month}/${_lastUpdated!.year}',
                        style: TextStyle(
                            fontSize: 10, color: mentalColor.withAlpha(140)),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Insight content
            Card(
              key: const ValueKey('insights-content-card'),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildContent(theme, mentalColor),
              ),
            ),

            const SizedBox(height: 16),

            // Refresh button
            Semantics(
              button: true,
              label: 'Actualizar analisis de patrones',
              child: OutlinedButton.icon(
                key: const ValueKey('refresh-insights-bottom-button'),
                onPressed: _isLoading ? null : _runAnalysis,
                style: OutlinedButton.styleFrom(
                  foregroundColor: mentalColor,
                  side: BorderSide(color: mentalColor),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Actualizar analisis'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, Color mentalColor) {
    if (_isLoading && (_cachedInsight == null || _cachedInsight!.isEmpty)) {
      return Column(
        children: [
          CircularProgressIndicator(color: mentalColor),
          const SizedBox(height: 12),
          Text(
            'Analizando tus datos...',
            style: TextStyle(color: mentalColor),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 32),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (_cachedInsight == null || _cachedInsight!.isEmpty) {
      return Column(
        children: [
          Icon(Icons.psychology_outlined, color: mentalColor, size: 32),
          const SizedBox(height: 8),
          Text(
            'Toca "Actualizar analisis" para detectar patrones',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(color: mentalColor),
          ),
        Semantics(
          label: 'Analisis de patrones de IA',
          child: Text(
            _cachedInsight!,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
      ],
    );
  }
}
