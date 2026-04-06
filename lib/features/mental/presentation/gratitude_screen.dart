import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/features/mental/domain/mental_input.dart';

class GratitudeScreen extends ConsumerStatefulWidget {
  const GratitudeScreen({super.key});

  @override
  ConsumerState<GratitudeScreen> createState() => _GratitudeScreenState();
}

class _GratitudeScreenState extends ConsumerState<GratitudeScreen> {
  final _ctrl1 = TextEditingController();
  final _ctrl2 = TextEditingController();
  final _ctrl3 = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _ctrl1.dispose();
    _ctrl2.dispose();
    _ctrl3.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t1 = _ctrl1.text.trim();
    final t2 = _ctrl2.text.trim();
    final t3 = _ctrl3.text.trim();

    if (t1.isEmpty && t2.isEmpty && t3.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe al menos una cosa por la que estes agradecido'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final lines = <String>[];
    if (t1.isNotEmpty) lines.add('1. $t1');
    if (t2.isNotEmpty) lines.add('2. $t2');
    if (t3.isNotEmpty) lines.add('3. $t3');
    final journalNote = lines.join('\n');

    final notifier = ref.read(mentalNotifierProvider);
    await notifier.logMood(MoodInput(
      date: DateTime.now(),
      valence: 4,
      energy: 3,
      tags: const ['gratitud'],
      journalNote: journalNote,
    ));

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gratitud registrada!'),
          backgroundColor: AppColors.mental,
        ),
      );
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mentalColor = AppColors.mental;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Gratitud'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: mentalColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              key: const ValueKey('gratitude-header-card'),
              color: mentalColor.withAlpha(20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.favorite, color: mentalColor, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'Hoy agradezco...',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: mentalColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Escribe tres cosas por las que te sientes agradecido hoy',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: mentalColor.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Entry 1
            _GratitudeField(
              key: const ValueKey('gratitude-field-1'),
              number: 1,
              controller: _ctrl1,
              mentalColor: mentalColor,
            ),

            const SizedBox(height: 12),

            // Entry 2
            _GratitudeField(
              key: const ValueKey('gratitude-field-2'),
              number: 2,
              controller: _ctrl2,
              mentalColor: mentalColor,
            ),

            const SizedBox(height: 12),

            // Entry 3
            _GratitudeField(
              key: const ValueKey('gratitude-field-3'),
              number: 3,
              controller: _ctrl3,
              mentalColor: mentalColor,
            ),

            const SizedBox(height: 24),

            Semantics(
              button: true,
              label: 'Guardar entradas de gratitud',
              child: FilledButton.icon(
                key: const ValueKey('save-gratitude-button'),
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: mentalColor,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.favorite),
                label:
                    Text(_isSaving ? 'Guardando...' : 'Guardar Gratitud'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GratitudeField extends StatelessWidget {
  const _GratitudeField({
    super.key,
    required this.number,
    required this.controller,
    required this.mentalColor,
  });

  final int number;
  final TextEditingController controller;
  final Color mentalColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: mentalColor.withAlpha(40),
              child: Text(
                '$number',
                style: TextStyle(
                  color: mentalColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                label: 'Campo de gratitud $number',
                child: TextField(
                  controller: controller,
                  maxLength: 120,
                  decoration: InputDecoration(
                    hintText: 'Hoy agradezco...',
                    border: InputBorder.none,
                    counterStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withAlpha(120),
                      fontSize: 10,
                    ),
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
