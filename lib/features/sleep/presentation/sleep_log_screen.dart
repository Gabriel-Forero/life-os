import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/features/sleep/domain/sleep_input.dart';

// ---------------------------------------------------------------------------
// Mock models (kept as fallback for local UI state)
// ---------------------------------------------------------------------------

enum _QualityLabel { muy_malo, malo, regular, bueno, excelente }

extension _QualityLabelExt on _QualityLabel {
  String get displayName => switch (this) {
        _QualityLabel.muy_malo => 'Muy malo',
        _QualityLabel.malo => 'Malo',
        _QualityLabel.regular => 'Regular',
        _QualityLabel.bueno => 'Bueno',
        _QualityLabel.excelente => 'Excelente',
      };

  IconData get icon => switch (this) {
        _QualityLabel.muy_malo => Icons.sentiment_very_dissatisfied,
        _QualityLabel.malo => Icons.sentiment_dissatisfied,
        _QualityLabel.regular => Icons.sentiment_neutral,
        _QualityLabel.bueno => Icons.sentiment_satisfied,
        _QualityLabel.excelente => Icons.sentiment_very_satisfied,
      };
}

class _MockSleepLog {
  DateTime? bedTime;
  DateTime? wakeTime;
  int qualityRating = 3; // 1–5
  String note = '';
  bool saved = false;
  int? sleepScore;

  double? get hoursSlept {
    if (bedTime == null || wakeTime == null) return null;
    return wakeTime!.difference(bedTime!).inMinutes / 60.0;
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class SleepLogScreen extends ConsumerStatefulWidget {
  const SleepLogScreen({super.key});

  @override
  ConsumerState<SleepLogScreen> createState() => _SleepLogScreenState();
}

class _SleepLogScreenState extends ConsumerState<SleepLogScreen> {
  final _mockLog = _MockSleepLog();
  final _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickBedTime() async {
    final now = DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 22, minute: 0),
      helpText: 'Hora de dormir',
    );
    if (picked != null) {
      setState(() {
        // Assume bedtime might be yesterday
        var bed = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
        if (picked.hour >= 18) {
          // evening — keep as yesterday if it would be before today morning
          bed = DateTime(now.year, now.month, now.day - 1, picked.hour, picked.minute);
        }
        _mockLog.bedTime = bed;
      });
    }
  }

  Future<void> _pickWakeTime() async {
    final now = DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 6, minute: 30),
      helpText: 'Hora de despertar',
    );
    if (picked != null) {
      setState(() {
        _mockLog.wakeTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      });
    }
  }

  Future<void> _saveSleep() async {
    if (_mockLog.bedTime == null || _mockLog.wakeTime == null) return;
    setState(() => _isSaving = true);

    final notifier = ref.read(sleepNotifierProvider);
    final hours = _mockLog.hoursSlept ?? 0;
    final durationScore = (hours / 8.0 * 100.0).clamp(0.0, 100.0);
    final qualityScore = (_mockLog.qualityRating / 5.0) * 100.0;
    final score = ((durationScore * 0.4) + (qualityScore * 0.4) + (100.0 * 0.2)).round();

    await notifier.logSleep(SleepInput(
      date: DateTime.now(),
      bedTime: _mockLog.bedTime!,
      wakeTime: _mockLog.wakeTime!,
      qualityRating: _mockLog.qualityRating,
      note: _mockLog.note.isEmpty ? null : _mockLog.note,
    ));

    if (mounted) {
      setState(() {
        _mockLog.sleepScore = score.clamp(0, 100);
        _mockLog.saved = true;
        _isSaving = false;
      });
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sleepColor = AppColors.sleep;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Registrar Sueno'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: sleepColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Sleep Score Card (shown after save) ---
            if (_mockLog.saved && _mockLog.sleepScore != null) ...[
              Semantics(
                label: 'Puntuacion de sueno: ${_mockLog.sleepScore}',
                child: Card(
                  key: const ValueKey('sleep-score-card'),
                  color: sleepColor.withAlpha(30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: sleepColor, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          '${_mockLog.sleepScore}',
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: sleepColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Puntuacion de Sueno',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: sleepColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_mockLog.hoursSlept?.toStringAsFixed(1) ?? '--'} horas dormidas',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // --- Bedtime & Wake Time ---
            Card(
              key: const ValueKey('sleep-times-card'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Horario de Sueno',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            button: true,
                            label: 'Hora de dormir: ${_formatTime(_mockLog.bedTime)}',
                            child: _TimeButton(
                              key: const ValueKey('bed-time-button'),
                              icon: Icons.bedtime_outlined,
                              label: 'Me dormi',
                              time: _formatTime(_mockLog.bedTime),
                              color: sleepColor,
                              onTap: _pickBedTime,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Semantics(
                            button: true,
                            label: 'Hora de despertar: ${_formatTime(_mockLog.wakeTime)}',
                            child: _TimeButton(
                              key: const ValueKey('wake-time-button'),
                              icon: Icons.wb_sunny_outlined,
                              label: 'Me desperte',
                              time: _formatTime(_mockLog.wakeTime),
                              color: AppColors.gym,
                              onTap: _pickWakeTime,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_mockLog.hoursSlept != null) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          '${_mockLog.hoursSlept!.toStringAsFixed(1)} horas',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: sleepColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --- Quality Rating ---
            Card(
              key: const ValueKey('quality-rating-card'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calidad del Sueno',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      label: 'Calidad: ${_QualityLabel.values[_mockLog.qualityRating - 1].displayName}',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(5, (index) {
                          final rating = index + 1;
                          final label = _QualityLabel.values[index];
                          final isSelected = _mockLog.qualityRating == rating;
                          return Semantics(
                            button: true,
                            label: label.displayName,
                            selected: isSelected,
                            child: GestureDetector(
                              key: ValueKey('quality-$rating'),
                              onTap: () => setState(() => _mockLog.qualityRating = rating),
                              child: Column(
                                children: [
                                  Icon(
                                    label.icon,
                                    size: 32,
                                    color: isSelected ? sleepColor : Colors.grey,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$rating',
                                    style: TextStyle(
                                      color: isSelected ? sleepColor : Colors.grey,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --- Note ---
            Card(
              key: const ValueKey('sleep-note-card'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nota (opcional)',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Campo de nota de sueno',
                      child: TextField(
                        key: const ValueKey('sleep-note-field'),
                        controller: _noteController,
                        maxLength: 200,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Como fue tu sueno...',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => _mockLog.note = v,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- Save Button ---
            Semantics(
              button: true,
              label: 'Guardar registro de sueno',
              child: FilledButton.icon(
                key: const ValueKey('save-sleep-button'),
                onPressed: (_mockLog.bedTime != null && _mockLog.wakeTime != null && !_isSaving)
                    ? _saveSleep
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: sleepColor,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Guardando...' : 'Guardar Sueno'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _TimeButton widget
// ---------------------------------------------------------------------------

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    super.key,
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String time;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
