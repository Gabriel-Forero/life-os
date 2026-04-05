import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/features/mental/domain/mental_input.dart';

// ---------------------------------------------------------------------------
// Predefined tags
// ---------------------------------------------------------------------------

const _predefinedTags = [
  'trabajo',
  'familia',
  'ejercicio',
  'sueno',
  'nutricion',
  'social',
  'estres',
  'gratitud',
  'ansiedad',
  'calma',
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class MoodLogScreen extends ConsumerStatefulWidget {
  const MoodLogScreen({super.key});

  @override
  ConsumerState<MoodLogScreen> createState() => _MoodLogScreenState();
}

class _MoodLogScreenState extends ConsumerState<MoodLogScreen> {
  int _valence = 3; // 1–5 (negative → positive)
  int _energy = 3; // 1–5 (low → high)
  final _selectedTags = <String>{};
  final _journalController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  int get _moodScore {
    final v = (_valence - 1) / 4.0 * 50.0;
    final e = (_energy - 1) / 4.0 * 50.0;
    return (v + e).round().clamp(0, 100);
  }

  String get _moodQuadrant {
    if (_valence >= 3 && _energy >= 3) return 'Activo y Positivo';
    if (_valence >= 3 && _energy < 3) return 'Tranquilo y Positivo';
    if (_valence < 3 && _energy >= 3) return 'Activo y Negativo';
    return 'Bajo y Negativo';
  }

  Color get _moodColor {
    if (_moodScore >= 75) return AppColors.success;
    if (_moodScore >= 50) return AppColors.mental;
    if (_moodScore >= 25) return AppColors.warning;
    return AppColors.error;
  }

  String _valenceLabel(int v) => switch (v) {
        1 => 'Muy negativo',
        2 => 'Negativo',
        3 => 'Neutral',
        4 => 'Positivo',
        5 => 'Muy positivo',
        _ => '',
      };

  String _energyLabel(int e) => switch (e) {
        1 => 'Muy baja',
        2 => 'Baja',
        3 => 'Media',
        4 => 'Alta',
        5 => 'Muy alta',
        _ => '',
      };

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        if (_selectedTags.length < 10) _selectedTags.add(tag);
      }
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final notifier = ref.read(mentalNotifierProvider);
    await notifier.logMood(MoodInput(
      date: DateTime.now(),
      valence: _valence,
      energy: _energy,
      tags: _selectedTags.toList(),
      journalNote: _journalController.text.trim().isEmpty
          ? null
          : _journalController.text.trim(),
    ));

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado de animo registrado: $_moodScore puntos'),
          backgroundColor: _moodColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mentalColor = AppColors.mental;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Estado de Animo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: mentalColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mood Score Badge
            Semantics(
              label: 'Puntuacion de animo: $_moodScore — $_moodQuadrant',
              child: Card(
                key: const ValueKey('mood-score-card'),
                color: _moodColor.withAlpha(25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: _moodColor, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_moodScore',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _moodColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Puntuacion',
                            style: TextStyle(color: _moodColor, fontSize: 12),
                          ),
                          Text(
                            _moodQuadrant,
                            style: TextStyle(
                              color: _moodColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Valence × Energy 5×5 Grid
            Card(
              key: const ValueKey('mood-grid-card'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selecciona tu estado',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Valencia: ${_valenceLabel(_valence)}',
                            style: const TextStyle(fontSize: 12)),
                        Text('Energia: ${_energyLabel(_energy)}',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 5x5 grid — X axis = valence (1-5), Y axis = energy (5-1, top=high)
                    Semantics(
                      label: 'Cuadricula de estado de animo 5 por 5',
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: GridView.builder(
                          key: const ValueKey('mood-grid'),
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                          ),
                          itemCount: 25,
                          itemBuilder: (context, index) {
                            final col = index % 5 + 1; // valence 1–5
                            final row = 5 - (index ~/ 5); // energy 5–1 (top=high)
                            final isSelected = col == _valence && row == _energy;
                            final cellColor = _cellColor(col, row);

                            return Semantics(
                              button: true,
                              selected: isSelected,
                              label: 'Valencia $col, Energia $row',
                              child: GestureDetector(
                                key: ValueKey('mood-cell-$col-$row'),
                                onTap: () => setState(() {
                                  _valence = col;
                                  _energy = row;
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? cellColor
                                        : cellColor.withAlpha(60),
                                    borderRadius: BorderRadius.circular(6),
                                    border: isSelected
                                        ? Border.all(color: Colors.white, width: 2)
                                        : null,
                                    boxShadow: isSelected
                                        ? [BoxShadow(color: cellColor.withAlpha(120), blurRadius: 6)]
                                        : null,
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.circle, color: Colors.white, size: 14)
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Axis labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('← Negativo', style: TextStyle(fontSize: 10)),
                        const Text('Valencia', style: TextStyle(fontSize: 10)),
                        const Text('Positivo →', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Tags
            Card(
              key: const ValueKey('mood-tags-card'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Etiquetas (max. 10)',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Selecciona etiquetas de estado de animo',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _predefinedTags.map((tag) {
                          final isSelected = _selectedTags.contains(tag);
                          return Semantics(
                            button: true,
                            selected: isSelected,
                            label: tag,
                            child: FilterChip(
                              key: ValueKey('tag-$tag'),
                              label: Text(tag),
                              selected: isSelected,
                              selectedColor: mentalColor.withAlpha(60),
                              checkmarkColor: mentalColor,
                              labelStyle: TextStyle(
                                color: isSelected ? mentalColor : null,
                              ),
                              onSelected: (_) => _toggleTag(tag),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Journal
            Card(
              key: const ValueKey('mood-journal-card'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reflexion (opcional)',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Campo de diario de estado de animo',
                      child: TextField(
                        key: const ValueKey('journal-note-field'),
                        controller: _journalController,
                        maxLength: 280,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Como te sientes hoy...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Semantics(
              button: true,
              label: 'Guardar estado de animo',
              child: FilledButton.icon(
                key: const ValueKey('save-mood-button'),
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: mentalColor,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.mood),
                label: Text(_isSaving ? 'Guardando...' : 'Guardar Estado de Animo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns a color based on the valence/energy quadrant.
  Color _cellColor(int valence, int energy) {
    if (valence >= 3 && energy >= 3) return AppColors.success; // activated positive
    if (valence >= 3 && energy < 3) return AppColors.mental; // deactivated positive
    if (valence < 3 && energy >= 3) return AppColors.warning; // activated negative
    return AppColors.error; // deactivated negative
  }
}
