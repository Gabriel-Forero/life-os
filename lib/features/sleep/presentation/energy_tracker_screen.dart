import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/features/sleep/domain/sleep_input.dart';

// ---------------------------------------------------------------------------
// Mock models
// ---------------------------------------------------------------------------

class _EnergySlot {
  _EnergySlot({
    required this.timeOfDay,
    required this.label,
    required this.icon,
    required this.timeRange,
  });

  final String timeOfDay; // morning / afternoon / evening
  final String label;
  final IconData icon;
  final String timeRange;
  int? level; // 1–10, null = not logged
  String note = '';
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class EnergyTrackerScreen extends ConsumerStatefulWidget {
  const EnergyTrackerScreen({super.key});

  @override
  ConsumerState<EnergyTrackerScreen> createState() =>
      _EnergyTrackerScreenState();
}

class _EnergyTrackerScreenState extends ConsumerState<EnergyTrackerScreen> {
  final _slots = [
    _EnergySlot(
      timeOfDay: 'morning',
      label: 'Manana',
      icon: Icons.wb_sunny_outlined,
      timeRange: '6:00 — 12:00',
    ),
    _EnergySlot(
      timeOfDay: 'afternoon',
      label: 'Tarde',
      icon: Icons.wb_cloudy_outlined,
      timeRange: '12:00 — 18:00',
    ),
    _EnergySlot(
      timeOfDay: 'evening',
      label: 'Noche',
      icon: Icons.nights_stay_outlined,
      timeRange: '18:00 — 00:00',
    ),
  ];

  bool _isSaving = false;

  void _setLevel(_EnergySlot slot, int level) {
    setState(() => slot.level = level);
  }

  Color _energyColor(int level) {
    if (level >= 8) return AppColors.success;
    if (level >= 5) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sleepColor = AppColors.sleep;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Energia del Dia'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: sleepColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              label: 'Registro de energia en tres momentos del dia',
              child: Text(
                'Registra tu nivel de energia en 3 momentos del dia (escala 1-10)',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            // Daily overview summary
            if (_slots.any((s) => s.level != null)) ...[
              Card(
                key: const ValueKey('energy-summary-card'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: sleepColor.withAlpha(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _slots.where((s) => s.level != null).map((s) {
                      return Semantics(
                        label: '${s.label}: ${s.level}/10',
                        child: Column(
                          children: [
                            Icon(s.icon, color: sleepColor, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              '${s.level}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _energyColor(s.level!),
                              ),
                            ),
                            Text(
                              s.label,
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Three slots
            ...List.generate(_slots.length, (i) {
              final slot = _slots[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  key: ValueKey('energy-slot-${slot.timeOfDay}'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(slot.icon, color: sleepColor, size: 24),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  slot.label,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  slot.timeRange,
                                  style: theme.textTheme.labelSmall,
                                ),
                              ],
                            ),
                            const Spacer(),
                            if (slot.level != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _energyColor(slot.level!).withAlpha(30),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _energyColor(slot.level!)),
                                ),
                                child: Text(
                                  '${slot.level}/10',
                                  style: TextStyle(
                                    color: _energyColor(slot.level!),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Level selector: 1–10 chips
                        Semantics(
                          label: 'Nivel de energia para ${slot.label}',
                          child: Wrap(
                            spacing: 6,
                            children: List.generate(10, (lvl) {
                              final level = lvl + 1;
                              final isSelected = slot.level == level;
                              final color = _energyColor(level);
                              return Semantics(
                                button: true,
                                label: 'Nivel $level',
                                selected: isSelected,
                                child: FilterChip(
                                  key: ValueKey('energy-level-${slot.timeOfDay}-$level'),
                                  label: Text('$level'),
                                  selected: isSelected,
                                  selectedColor: color.withAlpha(60),
                                  checkmarkColor: color,
                                  labelStyle: TextStyle(
                                    color: isSelected ? color : null,
                                    fontWeight: isSelected ? FontWeight.bold : null,
                                  ),
                                  onSelected: (_) => _setLevel(slot, level),
                                ),
                              );
                            }),
                          ),
                        ),
                        if (slot.level != null) ...[
                          const SizedBox(height: 8),
                          Semantics(
                            label: 'Nota para ${slot.label}',
                            child: TextField(
                              key: ValueKey('energy-note-${slot.timeOfDay}'),
                              decoration: const InputDecoration(
                                hintText: 'Nota opcional...',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (v) => slot.note = v,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),
            Semantics(
              button: true,
              label: 'Guardar registros de energia',
              child: FilledButton.icon(
                key: const ValueKey('save-energy-button'),
                onPressed: (_slots.any((s) => s.level != null) && !_isSaving)
                    ? () async {
                        setState(() => _isSaving = true);
                        final notifier = ref.read(sleepNotifierProvider);
                        final now = DateTime.now();
                        final date =
                            DateTime(now.year, now.month, now.day);
                        bool anyError = false;
                        for (final slot in _slots) {
                          if (slot.level == null) continue;
                          final result = await notifier.logEnergy(
                            EnergyInput(
                              date: date,
                              timeOfDay: slot.timeOfDay,
                              level: slot.level!,
                              note: slot.note.isNotEmpty ? slot.note : null,
                            ),
                          );
                          if (result.isFailure) {
                            anyError = true;
                          }
                        }
                        if (!mounted) return;
                        setState(() => _isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              anyError
                                  ? 'Error al guardar energia'
                                  : 'Guardado!',
                            ),
                          ),
                        );
                        if (!anyError) Navigator.of(context).pop();
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: sleepColor,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Guardar Energia'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
